#!/usr/bin/env python3
"""Compare every skill .md line of the last release with the working tree.

Usage: python3 tests/preservation-check.py [ROOT] [--tag vX.Y.Z] [--just FILE]

- ROOT: the worktree root (default: the current folder).
- --tag: the release to compare against. Default: the newest tag named
  exactly vX.Y.Z (pre-release tags such as v1.4.0-rc1 are skipped) that is
  reachable from HEAD~, so a release commit is never compared with itself.
- --just: the justification file. Default: tests/preservation-<version>.md,
  with <version> from .claude-plugin/plugin.json.

Every non-blank line of every .md file under skills/superfix/ in the old tag
is looked up in the new tree by its place: the file plus the plain text of
its nearest heading above it.
- Lines before the first heading have the place "(start of file)".
- A heading line's place is its own text, so adding a section above a
  heading does not move it.
- A heading text used again in the same file gets its occurrence number
  from the second one on: "Plan (2)".
- Lines inside fenced code blocks count like any other line; a "#" line
  inside a fence is not a heading.
- Indentation is ignored: lines are compared after stripping spaces.
- Lines are counted: two identical lines under one heading need two in the
  new tree at that place.

Each missing occurrence is reported as:
- MOVED: the same text has gained occurrences at another place (another
  heading or another file).
- REMOVED: otherwise.

Each reported line needs a justification line:
  - <file> > <heading> :: <exact old line> :: <reason>
<file> > <heading> is the OLD place exactly as printed. For a MOVED line the
reason must contain both the old place and a new place in full
("<file> > <heading>"), so a short heading cannot match by accident.

The last output line is "N unjustified" and the exit code is 1 when N is
above 0. When git cannot give a tag or a file (no usable tag, no HEAD~ in a
shallow clone) it prints one line starting "CANNOT RUN" and exits 2.
"""
import argparse, json, pathlib, re, subprocess, sys
from collections import Counter

SKILL_DIR = "skills/superfix"
RELEASE = re.compile(r"^v[0-9]+\.[0-9]+\.[0-9]+$")


class CannotRun(Exception):
    pass


def git(root, *args):
    r = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True)
    if r.returncode:
        msg = (r.stderr.strip().splitlines() or ["no output"])[-1]
        raise CannotRun(f"git {' '.join(args)} failed: {msg}")
    return r.stdout


def places(text, fname):
    """Yield (stripped line, place) for every non-blank line."""
    heading, fence, seen = "(start of file)", None, Counter()
    for raw in text.splitlines():
        s = raw.strip()
        if not s:
            continue
        place = f"{fname} > {heading}"
        if fence is None and (s.startswith("```") or s.startswith("~~~")):
            fence = s[:3]
        elif fence is not None and s.startswith(fence):
            fence = None
        elif fence is None and s.startswith("#") and s.lstrip("#").startswith(" "):
            text_ = s.lstrip("#").strip()
            seen[text_] += 1
            heading = text_ if seen[text_] == 1 else f"{text_} ({seen[text_]})"
            place = f"{fname} > {heading}"
        yield s, place


def count(text, fname):
    return Counter(places(text, fname))


def default_tag(root):
    try:
        git(root, "rev-parse", "--verify", "-q", "HEAD~")
    except CannotRun:
        raise CannotRun("HEAD~ does not exist (shallow clone or first commit); "
                        "fetch full history or pass --tag")
    tags = [t for t in git(root, "tag", "--merged", "HEAD~", "--list", "v*",
                           "--sort=-v:refname").split() if RELEASE.match(t)]
    if not tags:
        raise CannotRun("no vX.Y.Z tag reachable from HEAD~; fetch tags or pass --tag")
    return tags[0]


def run(a):
    root = pathlib.Path(a.root).resolve()
    tag = a.tag or default_tag(root)
    if a.just:
        just_path = pathlib.Path(a.just)
        if not just_path.is_absolute():
            just_path = root / just_path
    else:
        version = json.loads((root / ".claude-plugin/plugin.json").read_text())["version"]
        just_path = root / "tests" / f"preservation-{version}.md"
    print(f"Comparing against tag {tag}; justifications from {just_path}")

    old_files = [f for f in git(root, "ls-tree", "-r", "--name-only", tag,
                                SKILL_DIR + "/").split() if f.endswith(".md")]
    if not old_files:
        raise CannotRun(f"tag {tag} has no .md files under {SKILL_DIR}/")
    old = Counter()
    for f in old_files:
        old += count(git(root, "show", f"{tag}:{f}"), f)
    new_files = sorted((root / SKILL_DIR).rglob("*.md"))
    new = Counter()
    for p in new_files:
        new += count(p.read_text(), str(p.relative_to(root)))
    print(f"Old files ({len(old_files)}): {', '.join(old_files)}")
    print(f"New files ({len(new_files)}): "
          f"{', '.join(str(p.relative_to(root)) for p in new_files)}")

    # gained[s] = {place: occurrences of s gained there}
    gained = {}
    for (s, place), n in new.items():
        if n > old[(s, place)]:
            gained.setdefault(s, {})[place] = n - old[(s, place)]

    just = {}
    if just_path.exists():
        for l in just_path.read_text().splitlines():
            if l.startswith("- ") and l.count(" :: ") >= 2:
                place, rest = l[2:].split(" :: ", 1)
                line, reason = rest.rsplit(" :: ", 1)
                just[(place.strip(), line.strip())] = reason.strip()
    else:
        print(f"No justification file at {just_path}")

    bad = n_moved = n_removed = 0
    used = set()
    for (s, place), n_old in old.items():
        missing = n_old - new[(s, place)]
        if missing <= 0:
            continue
        key = (place, s)
        reason = just.get(key)
        if reason is not None:
            used.add(key)
        to = gained.get(s, {})
        moved = min(missing, sum(to.values()))
        removed = missing - moved
        if moved:
            n_moved += moved
            ok = reason is not None and place in reason and any(w in reason for w in to)
            bad += moved if not ok else 0
            times = f" (x{moved})" if moved > 1 else ""
            print(f"{'justified' if ok else 'UNJUSTIFIED'}\tMOVED{times}\t{place}\t{s}"
                  f"\t-> {' | '.join(sorted(to))}")
        if removed:
            n_removed += removed
            ok = reason is not None
            bad += removed if not ok else 0
            times = f" (x{removed})" if removed > 1 else ""
            print(f"{'justified' if ok else 'UNJUSTIFIED'}\tREMOVED{times}\t{place}\t{s}")
    unused = sorted(set(just) - used)
    for key in unused:
        print(f"unused justification\t{key[0]}\t{key[1]}")
    print(f"{n_removed} removed, {n_moved} moved, {len(unused)} unused justifications")
    print(f"{bad} unjustified")
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("root", nargs="?", default=".")
    ap.add_argument("--tag")
    ap.add_argument("--just")
    try:
        return run(ap.parse_args())
    except (CannotRun, FileNotFoundError, KeyError, json.JSONDecodeError) as e:
        print(f"CANNOT RUN: {e}")
        return 2


if __name__ == "__main__":
    sys.exit(main())
