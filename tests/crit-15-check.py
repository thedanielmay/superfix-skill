#!/usr/bin/env python3
"""CRIT-1.5-CHANGED: every 1.5.0 crit.py command must stay byte for byte identical to v1.6.0.

Only WO_KINDS and the cmd_wo_* commands (and their helpers) may change in 1.6.1.
Usage: python3 tests/crit-15-check.py [path-to-criteria.md]
Prints CRIT-1.5-CHANGED <names> and exits 1 on any difference, else CRIT-1.5-UNCHANGED.
The plan names measure, baseline, lock, attempt, finish, later, amend, comment,
sendcheck and verify; later has no cmd_ function (later criteria ride inside
attempt and finish), so the checked set is the other nine.
"""
import re
import subprocess
import sys

COMMANDS = ["cmd_measure", "cmd_baseline", "cmd_lock", "cmd_attempt",
            "cmd_finish", "cmd_amend", "cmd_comment", "cmd_sendcheck", "cmd_verify"]
CRIT_PATH = "skills/superfix/references/criteria.md"


def block(text):
    m = re.search(r"(?ms)^# --- crit.py start ---\n(.*)^# --- crit.py end ---$", text)
    if not m:
        print("CRIT-1.5-CHANGED (no crit.py block)")
        sys.exit(1)
    return m.group(1)


def funcs(py):
    out = {}
    for m in re.finditer(r"(?ms)^def (\w+)\(.*?(?=^def |\Z)", py):
        out[m.group(1)] = m.group(0)
    return out


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else CRIT_PATH
    now = funcs(block(open(path).read()))
    old_md = subprocess.run(["git", "show", f"v1.6.0:{CRIT_PATH}"],
                            capture_output=True, text=True)
    if old_md.returncode:
        print("CRIT-1.5-CHANGED (cannot read v1.6.0 text)")
        return 1
    old = funcs(block(old_md.stdout))
    changed = [c for c in COMMANDS if now.get(c) != old.get(c)]
    missing = [c for c in COMMANDS if c not in now or c not in old]
    if changed or missing:
        print("CRIT-1.5-CHANGED " + " ".join(changed + missing))
        return 1
    print("CRIT-1.5-UNCHANGED " + " ".join(COMMANDS))
    return 0


if __name__ == "__main__":
    sys.exit(main())
