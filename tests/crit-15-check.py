#!/usr/bin/env python3
"""CRIT-1.5-CHANGED: everything in the crit.py block that is not 1.6.1's own work
must stay byte for byte identical to v1.6.0.

Compared: every top-level function except cmd_wo_* and woc_* helpers (cmd_remind
stops at the work-orders comment: the WO constants below it are checked
separately), the module lines except WO_KINDS / WO_REQUIRED_CRITERIA / the
import delta below, and main() except the contiguous wo-parser block (wo-check
through wo-sendback).
Allowed 1.6.1 differences, and nothing else:
- WO_KINDS = {"code", "criteria"} (was {"code"});
- the WO_REQUIRED_CRITERIA line (new);
- `, contextlib` and `, io` inside the single stdlib import line (for capturing
  the 1.5.0 progress output inside wo-sendback);
- the wo-parser block in main() (optional --clone/--run/--folder/--findings/
  --attempts/--scripts for the wo commands).
Usage: python3 tests/crit-15-check.py [path-to-criteria.md]
Prints CRIT-1.5-CHANGED <names> and exits 1 on any other difference, else
CRIT-1.5-UNCHANGED. The plan names measure, baseline, lock, attempt, finish,
later, amend, comment, sendcheck and verify; later has no cmd_ function (later
criteria ride inside attempt and finish).
"""
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


def spans(py):
    """[(name, body)] for every top-level def (span to the next ^def or the end)."""
    return [(m.group(1), m.group(0))
            for m in re.finditer(r"(?ms)^def (\w+)\(.*?(?=^def |\Z)", py)]


def defs(py):
    out = {}
    for name, body in spans(py):
        if name == "cmd_remind":
            body = body.split("# ---------- work orders")[0]
        out[name] = body
    return out


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


def norm_rest(py):
    """Module text with every top-level def span removed, minus the
    allowlisted 1.6.1 lines (the two WO constants, the import delta)."""
    rest = re.sub(r"(?ms)^def \w+\(.*?(?=^def |\Z)", "", py)
    lines = [l for l in rest.splitlines()
             if not re.match(r"^WO_KINDS = ", l.strip())
             and not re.match(r"^WO_REQUIRED_CRITERIA = ", l.strip())]
    return "\n".join(lines).replace(", contextlib", "").replace(", io", "")


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
        if n == "main":
            mine, theirs = strip_wo_parsers(mine), strip_wo_parsers(theirs) if theirs else None
        if theirs is None or mine != theirs:
            bad.append(n)
    bad += sorted(n for n in old_f if not n.startswith(SKIP_DEF) and n not in now_f)
    if norm_rest(now_py) != norm_rest(old_py):
        bad.append("module-text")
    if bad:
        print("CRIT-1.5-CHANGED " + " ".join(sorted(set(bad))))
        return 1
    kept = sorted(n for n in now_f if not n.startswith(SKIP_DEF))
    print(f"CRIT-1.5-UNCHANGED {len(kept)} functions")
    return 0


if __name__ == "__main__":
    sys.exit(main())
