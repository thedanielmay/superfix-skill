#!/usr/bin/env python3
"""List every non-blank 1.2.0 line missing from 1.3.0; fail on unjustified ones."""
import pathlib, subprocess, sys
ROOT = pathlib.Path(sys.argv[1])            # worktree root
FILES = ["skills/superfix/SKILL.md"] + [f"skills/superfix/references/{n}.md"
         for n in ("journal", "explore", "execute", "inventory")]
def old(path):
    return subprocess.run(["git", "-C", str(ROOT), "show", f"v1.2.0:{path}"],
                          capture_output=True, text=True, check=True).stdout
new = set()
for p in (ROOT / "skills/superfix").rglob("*.md"):
    new |= {l.strip() for l in p.read_text().splitlines() if l.strip()}
just = set()
for l in (ROOT / "tests/preservation-1.3.0.md").read_text().splitlines():
    if l.startswith("- ") and " :: " in l:
        just.add(l[2:].rsplit(" :: ", 1)[0].strip())
bad = 0
for f in FILES:
    for i, l in enumerate(old(f).splitlines(), 1):
        s = l.strip()
        if s and s not in new:
            tag = "justified" if s in just else "UNJUSTIFIED"
            bad += tag == "UNJUSTIFIED"
            print(f"{tag}\t{f}:{i}\t{s}")
print(f"{bad} unjustified"); sys.exit(1 if bad else 0)
