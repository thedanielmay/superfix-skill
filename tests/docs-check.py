#!/usr/bin/env python3
"""Mechanical checks for README.md and docs/guide/*.md. Run: python3 docs-check.py <repo>. Exit 1 on any failure."""
import re, subprocess, sys, pathlib
repo = pathlib.Path(sys.argv[1]).resolve()
files = [repo / "README.md"] + sorted((repo / "docs" / "guide").glob("*.md"))
bad = []
tags = subprocess.run(["git", "-C", str(repo), "tag"], capture_output=True, text=True).stdout.split()
KW = ("flowchart", "graph", "sequenceDiagram", "stateDiagram", "stateDiagram-v2", "classDiagram", "erDiagram", "gantt", "journey")
for f in files:
    if not f.exists():
        bad.append(f"{f}: missing"); continue
    t = f.read_text()
    n = t.count("\u2013") + t.count("\u2014")
    if n: bad.append(f"{f.name}: {n} em/en dashes")
    for m in re.finditer(r"\]\(([^)#\s]+)(#[^)]*)?\)", t):
        u = m.group(1)
        if u.startswith(("http", "mailto:")): continue
        if not (f.parent / u).resolve().exists(): bad.append(f"{f.name}: broken link {u}")
    for m in re.finditer(r"`((?:skills|tests|docs|references|\.github|\.claude-plugin)/[\w./-]+|[\w-]+\.(?:py|md|sh|json|yml))`", t):
        p = m.group(1)
        cands = [repo / p, repo / "skills/superfix/references" / p, repo / "tests" / p, repo / "docs/guide" / p, repo / "skills/superfix" / p, repo / ".github/workflows" / p, repo / ".claude-plugin" / p]
        if not any(c.exists() for c in cands) and "<" not in p and "*" not in p and p not in ("report.md", "project.md", "config.json"):
            bad.append(f"{f.name}: named file not found {p}")
    for m in re.finditer(r"```mermaid\n(.*?)```", t, re.S):
        body = m.group(1).strip()
        if not body.startswith(KW): bad.append(f"{f.name}: mermaid block starts with {body.split()[0]!r}")
        if body.count("[") != body.count("]") or body.count("(") != body.count(")") or body.count("{") != body.count("}"):
            bad.append(f"{f.name}: mermaid block has unbalanced brackets")
        if len(body.splitlines()) > 40: bad.append(f"{f.name}: mermaid block over 40 lines, split it")
    for m in re.finditer(r"\b(?:v|version )?(1\.\d+\.\d+)\b", t):
        if f.name == "versions.md" and ("v" + m.group(1)) not in tags and m.group(1) not in ("1.0.0",):
            bad.append(f"{f.name}: version {m.group(1)} has no git tag")
# The key count in the prose must match the key table, so a new key cannot land in only some pages (1.7.0).
WORDS = {"four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9}
proj = repo / "skills/superfix/references/project.md"
if proj.exists():
    lines = proj.read_text().splitlines()
    start = next((k for k, l in enumerate(lines) if "| Repeatable |" in l), None)
    rows = 0
    for l in (lines[start + 1:] if start is not None else []):
        if not l.strip().startswith("|"):
            break
        if l.strip().startswith("| `"):
            rows += 1
    for f, pat in ((proj, r"Only these (\w+) keys exist"), (repo / "docs/guide/settings-file.md", r"Only these (\w+) keys exist"), (repo / "README.md", r"with (\w+) keys")):
        if not f.exists():
            bad.append(f"{f.name}: missing"); continue
        m = re.search(pat, f.read_text())
        if not m:
            bad.append(f"{f.name}: key count sentence not found"); continue
        n = WORDS.get(m.group(1).lower())
        if n != rows:
            bad.append(f"{f.name}: says {m.group(1)} keys, the project.md table has {rows}")
print("\n".join(sorted(set(bad))) or "DOCS-CHECK-OK")
sys.exit(1 if bad else 0)
