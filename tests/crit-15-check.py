#!/usr/bin/env python3
"""CRIT-1.5-CHANGED: everything in the crit.py block that is not 1.6.1's own work
must stay byte for byte identical to v1.6.0.

Compared: every top-level function except cmd_wo_* and woc_* helpers (cmd_remind
stops at the work-orders comment: the WO constants below it are checked with
the module lines), main() except the contiguous wo-parser block (wo-check
through wo-sendback), and every other line of the block except WO_KINDS,
WO_REQUIRED_CRITERIA, WOC_* module constants and the `, contextlib` / `, io`
import delta.
Skipped regions use exact AST boundaries, so a line smuggled between two
functions (even between two skipped ones) is still compared.
Allowed 1.6.1 differences, and nothing else:
- WO_KINDS = {"code", "criteria"} (was {"code"});
- the WO_REQUIRED_CRITERIA line (new);
- `, contextlib` and `, io` inside the single stdlib import line (for capturing
  the 1.5.0 progress output inside wo-sendback);
- the bodies of def cmd_wo_* and def woc_* (any new helper), and the wo-parser
  block in main() (optional --clone/--run/--folder/--findings/--attempts/
  --scripts for the wo commands).
Usage: python3 tests/crit-15-check.py [path-to-criteria.md]
Prints CRIT-1.5-CHANGED <names> and exits 1 on any other difference, else
CRIT-1.5-UNCHANGED. The plan names measure, baseline, lock, attempt, finish,
later, amend, comment, sendcheck and verify; later has no cmd_ function (later
criteria ride inside attempt and finish).
"""
import ast
import re
import subprocess
import sys

CRIT_PATH = "skills/superfix/references/criteria.md"
SKIP_DEF = ("cmd_wo_", "woc_")


def block(text):
    m = re.search(r"(?ms)^# --- crit.py start ---\n(.*)^# --- crit.py end ---$", text)
    if not m:
        print("CRIT-1.5-CHANGED (no crit.py block)")
        sys.exit(1)
    return m.group(1)


def tree_of(py):
    try:
        return ast.parse(py)
    except SyntaxError:
        print("CRIT-1.5-CHANGED (crit.py block does not parse)")
        sys.exit(1)


def defs(py):
    """{name: body} for every top-level def; cmd_remind stops at the
    work-orders comment (the WO constants below it are module lines)."""
    out = {}
    for m in re.finditer(r"(?ms)^def (\w+)\(.*?(?=^def |\Z)", py):
        name, body = m.group(1), m.group(0)
        if name == "cmd_remind":
            body = body.split("# ---------- work orders")[0]
        out[name] = body
    return out


def kept_lines(py):
    """Kept lines: everything outside skipped def bodies (exact AST boundaries),
    minus the wo-parser block and the allowlisted WO_KINDS / WO_REQUIRED_CRITERIA /
    WOC_* lines and the import delta. Blank lines are ignored: removing a
    skipped def leaves its padding behind, which carries no meaning."""
    py = strip_wo_parsers(py)
    skip = set()
    for n in ast.walk(tree_of(py)):
        if isinstance(n, ast.FunctionDef) and n.col_offset == 0 and n.name.startswith(SKIP_DEF):
            skip.update(range(n.lineno - 1, n.end_lineno))
    out = []
    for i, l in enumerate(py.splitlines()):
        if i in skip or not l.strip():
            continue
        s = l.strip()
        if re.match(r"^WO_KINDS = ", s):
            continue
        if re.match(r"^WO_REQUIRED_CRITERIA = ", s):
            continue
        if re.match(r"^WOC_", s):
            continue
        out.append(l)
    return "\n".join(out).replace(", contextlib", "").replace(", io", "")


def strip_wo_parsers(text):
    """Drop the contiguous wo-parser block (wo-check line through wo-sendback line)."""
    lines, out, skip = text.splitlines(), [], False
    for l in lines:
        s = l.strip()
        if re.match(r"^(s = )?p\(\"wo-check\"", s):
            skip = True
        if skip:
            if re.match(r"^(s = )?p\(\"wo-sendback\"", s):
                skip = False
            continue
        out.append(l)
    return "\n".join(out)


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else CRIT_PATH
    now_py = block(open(path).read())
    old_md = subprocess.run(["git", "show", f"v1.6.0:{CRIT_PATH}"],
                            capture_output=True, text=True)
    if old_md.returncode:
        print("CRIT-1.5-CHANGED (cannot read v1.6.0 text)")
        return 1
    old_py = block(old_md.stdout)
    now_f, old_f = defs(now_py), defs(old_py)
    bad = []
    for n in sorted(now_f):
        if n.startswith(SKIP_DEF):
            continue
        mine, theirs = now_f[n], old_f.get(n)
        if n == "main" and theirs is not None:
            mine, theirs = strip_wo_parsers(mine), strip_wo_parsers(theirs)
        if theirs is None or mine != theirs:
            bad.append(n)
    bad += sorted(n for n in old_f if not n.startswith(SKIP_DEF) and n not in now_f)
    if kept_lines(now_py) != kept_lines(old_py):
        bad.append("module-text")
    if bad:
        print("CRIT-1.5-CHANGED " + " ".join(sorted(set(bad))))
        return 1
    kept = sorted(n for n in now_f if not n.startswith(SKIP_DEF))
    print(f"CRIT-1.5-UNCHANGED {len(kept)} functions")
    return 0


if __name__ == "__main__":
    sys.exit(main())
