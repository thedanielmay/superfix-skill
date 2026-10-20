#!/usr/bin/env python3
"""Build one criteria work-order rig: a real 1.5.0 criteria job plus a stub folder work order.
Usage: mkrig.py <home> <run-key> <work-id> <orig-csv> <stub-rel> [--cut] [prefix]
  [prefix]    variable prefix for the printed assignments (RD=... becomes P_RD=...)
  <home>      throwaway HOME
  <run-key>   run folder name under $home/.superfix/runs
  <work-id>   WORK-ORDER value (also the stub key)
  <orig-csv   the original data file (copied with crit.py copy, so .sf-orig exists;
              its basename must equal the stub file's basename)
  <stub-rel   FILES name inside the folder, e.g. work/members-export.csv
  --cut       the stub copy holds only row,email,joined (BASE is the cut sha)
Prints shell assignments: RD= RCRC= RF= DEST= BODYDEC= (eval them).
Needs: ROOT env (checkout whose crit.py to extract), SEED env (seed15 dir), CRITBIN env (python3 crit path? no: uses RD/crit.py).
"""
import hashlib
import os
import pathlib
import re
import subprocess
import sys

HOME = pathlib.Path(sys.argv[1])
RUN = sys.argv[2]
WID = sys.argv[3]
ORIG = pathlib.Path(sys.argv[4])
STUBREL = sys.argv[5]
if len(sys.argv) > 6 and sys.argv[6] == "--cut":
    CUT = True
    P = (sys.argv[7] + "_") if len(sys.argv) > 7 else ""
else:
    CUT = False
    P = (sys.argv[6] + "_") if len(sys.argv) > 6 else ""
ROOT = os.environ["ROOT"]
SEED = pathlib.Path(os.environ["SEED"])

D = HOME / ".superfix" / "runs" / RUN
RC = HOME / ".superfix" / "journal" / "test-crit" / "criteria" / RUN
F = D / "workorder" / "folder"
for d in (D / "work", RC, F / "work", F / "checks"):
    d.mkdir(parents=True, exist_ok=True)
(D / "key").write_text("runkey\n")


def sh(*args):
    e = dict(os.environ)
    e["HOME"] = str(HOME)
    r = subprocess.run(args, capture_output=True, text=True, env=e)
    if r.returncode:
        print("COMMAND FAILED:", " ".join(args))
        print(r.stdout[-2000:])
        print(r.stderr[-500:])
        raise SystemExit(1)
    return r


def extract_crit():
    src = pathlib.Path(ROOT) / "skills" / "superfix" / "references" / "criteria.md"
    txt, on, out = src.read_text().splitlines(), False, []
    for l in txt:
        if l.startswith("# --- crit.py start ---"):
            on = True
        if on:
            out.append(l)
        if l.startswith("# --- crit.py end ---"):
            on = False
    (D / "crit.py").write_text("\n".join(out) + "\n")


extract_crit()
C = [sys.executable, "-I", str(D / "crit.py")]
for m in ("measure-P1-C1.py", "measure-P1-K1.py"):
    (RC / m).write_bytes((SEED / "measures" / m).read_bytes())
body = (
    "# Journal file mode\n\n## Problems\n### P1 duplicate members (members sheet)\n"
    "Coverage: Everything else\n\n## Done when\n"
    "- P1-C1 [check] duplicate members: rows whose email, with spaces trimmed and case ignored, "
    "matches an earlier row; the earliest joined date wins and keeps its own fee; pass: 0; "
    "how: measure-P1-C1.py; who: Superfix\n"
    "- P1-K1 [check] distinct members: by email with spaces trimmed and case ignored; "
    "pass: 112 (today's count); how: measure-P1-K1.py; who: Superfix\n"
)
(D / "body.md").write_text(body)
sh(*C, "copy", "--run", str(D), "--src", str(ORIG))
realname = pathlib.Path(ORIG).name
base = pathlib.Path(STUBREL).name
# real 1.5.0 job on the recorded copy
sh(*C, "baseline", "--run", str(D), "--scripts", str(RC), "--body", str(D / "body.md"),
   "--attempts", str(RC / "attempts"), "--label", "base",
   "--measure", f"P1-C1={D / 'work' / realname}", "--measure", f"P1-K1={D / 'work' / realname}")
r = sh(*C, "lock", "--scripts", str(RC), "--by", "the owner at the keyboard", "--run", str(D),
       "--attempts", str(RC / "attempts"), "--body", str(D / "body.md"),
       "--data", str(D / "work" / realname), "--approved", "P1")
m = re.search(r"Internal: criteria-sha ([0-9a-f]{64})", r.stdout)
bodydec = body + ("\n## Decision\n"
                  f"Data yes: {base} ({'only the columns row, email, joined' if CUT else 'the whole file'}): yes\n"
                  f"Internal: criteria-sha {m.group(1)} (sha256), locked 2026-10-21 00:00, approved by the owner at the keyboard\n")
(D / "body-dec.md").write_text(bodydec)
# stub folder
(F / "key").write_text(WID + "\n")
if CUT:
    import csv
    rows = list(csv.DictReader(open(D / "work" / realname, newline="", encoding="utf-8")))
    with open(F / STUBREL, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["row", "email", "joined"])
        w.writeheader()
        for n, rr in enumerate(rows, start=2):
            w.writerow({"row": n, "email": rr["email"], "joined": rr["joined"]})
else:
    (F / STUBREL).write_bytes((D / "work" / base).read_bytes())
(F / "checks" / "crit.py").write_bytes((D / "crit.py").read_bytes())
for m in ("measure-P1-C1.py", "measure-P1-K1.py"):
    (F / "checks" / m).write_bytes((RC / m).read_bytes())
sh(*C, "baseline", "--run", str(F), "--scripts", str(F / "checks"), "--body", str(D / "body.md"),
   "--attempts", str(F / "checks" / "attempts"), "--label", "base",
   "--measure", f"P1-C1={F / STUBREL}", "--measure", f"P1-K1={F / STUBREL}")
r = sh(*C, "lock", "--scripts", str(F / "checks"), "--by", "the owner at the keyboard", "--run", str(F),
       "--attempts", str(F / "checks" / "attempts"), "--body", str(D / "body.md"),
       "--data", str(F / STUBREL), "--approved", "P1")
m1 = re.search(r"Internal: criteria-sha ([0-9a-f]{64})", r.stdout)
m2 = re.search(r"Internal: crit-sha ([0-9a-f]{64})", r.stdout)
(F / "checks" / "done-when.md").write_text(
    "## Done when\n"
    "- P1-C1 [script] Duplicate members: must be 0 (today 8, rows 14, 15 and 62)\n"
    "- P1-K1 [script] Distinct members: must be 112 (today 112)\n"
    f"Internal: criteria-sha {m1.group(1)} (sha256), locked test, approved by the owner at the keyboard\n"
    f"Internal: crit-sha {m2.group(1)} (sha256)\n")
sha = hashlib.sha256((F / STUBREL).read_bytes()).hexdigest()
names = ["crit.py", "measure-P1-C1.py", "measure-P1-K1.py", "lock", "attempts", "done-when.md"]
block = "".join(f"{hashlib.sha256((F / 'checks' / n).read_bytes()).hexdigest()}  checks/{n}\n" for n in names)
csha = hashlib.sha256(block.encode()).hexdigest()
(F / "workorder.md").write_text(
    "# Work order: dedupe members-export.csv (testbed seed-1.5)\n"
    f"WORK-ORDER: {WID}\nCHECKS-KIND: criteria\n"
    "SOURCE: data/members-export.csv (a copy is in work/; you never get the original)\n"
    f"BASE: {sha} (sha256)\nFILES: {STUBREL}\nLIMITS: 5 attempts\n"
    f"CHECKS-SHA: {csha} (sha256)\nBASELINE: P1-C1 FAIL, P1-K1 PASS\n"
    "DELIVER: hand the folder back, with the changed copy in work/\n"
    "\n## Done when (tick each line when it passes)\n"
    "- [ ] [script] Duplicate members: must be 0 (today 8, rows 14, 15 and 62)\n"
    "- [ ] [script] Distinct members: must be 112 (today 112)\n"
    "- [ ] [Superfix verifies] for each duplicate, the row kept is the earliest joined date\n"
    "\n## CHECKS (do not edit; Step 0 checks them)\n```bash\n# BEGIN CHECKS\n" + block + "# END CHECKS\n```\n")
print(f"{P}RD={D}")
print(f"{P}RCRC={RC}")
print(f"{P}RF={F}")
print(f"{P}DEST={HOME / 'superfix-workorders' / WID}")
print(f"{P}BODYDEC={D / 'body-dec.md'}")
