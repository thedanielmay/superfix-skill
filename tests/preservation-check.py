#!/usr/bin/env python3
"""Compare every skill .md line of the last release with the working tree.

Usage: python3 tests/preservation-check.py [ROOT] [--tag vX.Y.Z] [--just FILE]

- ROOT: the worktree root (default: the current folder).
- --tag: the release to compare against. Default: the newest v* tag
  reachable from HEAD~ (so a release commit is never compared with itself).
- --just: the justification file. Default: tests/preservation-<version>.md,
  with <version> from .claude-plugin/plugin.json.

Every non-blank line of every .md file under skills/superfix/ in the old tag
is looked up in the new tree by its place: the file plus the plain text of
its nearest heading above it (a heading line's place is its own text, so
adding a new section above a heading does not move it). Lines inside fenced code blocks count like any other line; a "#" line
inside a fence is not a heading.

- Same text at the same place: kept, not printed.
- Same text only at another place (other heading or other file): MOVED.
- Text nowhere in the new tree: REMOVED.

MOVED and REMOVED lines each need a justification line:
  - <file> > <heading> :: <exact old line> :: <reason>
<file> > <heading> is the OLD place exactly as printed. For a MOVED line the
reason must also name the new place (its heading text). The last output
line is "N unjustified"; the exit code is 1 when N is above 0.
"""
import argparse, json, pathlib, subprocess, sys

SKILL_DIR = "skills/superfix"


def git(root, *args):
    return subprocess.run(["git", "-C", str(root), *args], capture_output=True,
                          text=True, check=True).stdout


def places(text, fname):
    """Yield (stripped line, place) for every non-blank line."""
    heading, fence = "(top)", None
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
            heading = s.lstrip("#").strip()
            place = f"{fname} > {heading}"
        yield s, place


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("root", nargs="?", default=".")
    ap.add_argument("--tag")
    ap.add_argument("--just")
    a = ap.parse_args()
    root = pathlib.Path(a.root).resolve()

    tag = a.tag
    if not tag:
        tags = git(root, "tag", "--merged", "HEAD~", "--list", "v*",
                   "--sort=-v:refname").split()
        if not tags:
            print("ERROR: no v* tag reachable from HEAD~; pass --tag")
            print("1 unjustified")
            return 1
        tag = tags[0]
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
    new_files = sorted((root / SKILL_DIR).rglob("*.md"))
    new_at = {}  # line -> set of places in the new tree
    for p in new_files:
        rel = str(p.relative_to(root))
        for s, place in places(p.read_text(), rel):
            new_at.setdefault(s, set()).add(place)
    print(f"Old files ({len(old_files)}): {', '.join(old_files)}")
    print(f"New files ({len(new_files)}): "
          f"{', '.join(str(p.relative_to(root)) for p in new_files)}")

    just = {}
    if just_path.exists():
        for l in just_path.read_text().splitlines():
            if l.startswith("- ") and l.count(" :: ") >= 2:
                place, rest = l[2:].split(" :: ", 1)
                line, reason = rest.rsplit(" :: ", 1)
                just[(place.strip(), line.strip())] = reason.strip()
    else:
        print(f"No justification file at {just_path}")

    bad = moved = removed = 0
    used = set()
    for f in old_files:
        seen = set()
        for s, place in places(git(root, "show", f"{tag}:{f}"), f):
            if (s, place) in seen:
                continue
            seen.add((s, place))
            where = new_at.get(s, set())
            if place in where:
                continue
            key = (place, s)
            reason = just.get(key)
            if reason is not None:
                used.add(key)
            if where:
                moved += 1
                kind = "MOVED"
                ok = reason is not None and any(
                    w.split(" > ", 1)[1] in reason for w in where)
                extra = "\t-> " + " | ".join(sorted(where))
            else:
                removed += 1
                kind, ok, extra = "REMOVED", reason is not None, ""
            bad += not ok
            print(f"{'justified' if ok else 'UNJUSTIFIED'}\t{kind}\t{place}\t{s}{extra}")
    unused = sorted(set(just) - used)
    for key in unused:
        print(f"unused justification\t{key[0]}\t{key[1]}")
    print(f"{removed} removed, {moved} moved, {len(unused)} unused justifications")
    print(f"{bad} unjustified")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
