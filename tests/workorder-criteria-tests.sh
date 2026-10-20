#!/bin/bash
# Free tests for 1.6.1 criteria work orders (references/workorder.md kind criteria and crit.py's woc-* commands).
# No model runs. Runs under a throwaway HOME. Needs: git, python3, /usr/bin/sandbox-exec.
# Uses the local fixtures in ~/superfix-handoff/scripts/seed15 (no testbed clone, no network).
# Usage: bash tests/workorder-criteria-tests.sh   (prints one line per test, then "RESULT: <n> passed, <m> failed")
# ROOT=<another checkout> runs these tests against that checkout's files (used to show a test fails before its fix).
ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"; SEED=~/superfix-handoff/scripts/seed15
T="$(mktemp -d /private/tmp/wo-crit-tests.XXXX)"; REALHOME="$HOME"
ID=thedanielmay+superfix-testbed+csv-wo1
export HOME="$T/home"; mkdir -p "$HOME"
D="$HOME/.superfix/runs/test-csv-wo"; F="$D/workorder/folder"
export T D F ID SEED REALHOME
pass=0; fail=0
t() { local name="$1" want="$2"; shift 2; local out; out="$("$@" 2>&1)"
  if printf '%s' "$out" | tr '\n' '|' | grep -qE "$want"; then pass=$((pass+1)); echo "ok   $name"; else fail=$((fail+1)); echo "FAIL $name: want /$want/ got: $(printf '%s' "$out" | tr '\n' '|' | cut -c1-300)"; fi; }
restore() { rm -rf "$F"; mkdir -p "$D/workorder"; cp -r "$T/pristine" "$F"; echo yes > "$D/workorder/data-yes"; }
export -f restore 2>/dev/null || true
need() { command -v "$1" >/dev/null || { echo "CANNOT RUN: no $1"; exit 2; }; }
need python3; need git; [ -x /usr/bin/sandbox-exec ] || { echo "CANNOT RUN: no sandbox-exec"; exit 2; }
[ -f "$SEED/overlay/data/members-export.csv" ] || { echo "CANNOT RUN: no seed15 fixtures"; exit 2; }
cat > "$T/dedupe.py" <<'EOF'
import csv, sys
src, dst, keep_n = sys.argv[1], sys.argv[2], int(sys.argv[3])
rows = list(csv.DictReader(open(src, newline="", encoding="utf-8")))
seen, out, removed = set(), [], 0
for r in rows:
    k = r["email"].strip().lower()
    if k in seen and removed < keep_n:
        removed += 1
        continue
    seen.add(k); out.append(r)
with open(dst, "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys())
    w.writeheader(); w.writerows(out)
EOF

# ---- build the stub (1.5.0 baseline+lock on the stub itself, then the 1.6.1 folder files) ----
mkdir -p "$D/work" "$F/work" "$F/checks"; echo runkey > "$D/key"
cp "$SEED/overlay/data/members-export.csv" "$D/work/members-export.csv"
echo "$ID" > "$F/key"; cp "$D/work/members-export.csv" "$F/work/members-export.csv"
awk '/^# --- crit.py start ---$/{f=1} f{print} /^# --- crit.py end ---$/{f=0}' "$ROOT/skills/superfix/references/criteria.md" > "$D/crit.py"
cp "$D/crit.py" "$F/checks/crit.py"
cp "$SEED/measures/measure-P1-C1.py" "$SEED/measures/measure-P1-K1.py" "$F/checks/"
cat > "$T/body.md" <<'EOF'
# Journal file mode

## Problems
### P1 duplicate members (members sheet)
Coverage: Everything else

## Done when
- P1-C1 [check] duplicate members: rows whose email, with spaces trimmed and case ignored, matches an earlier row; the earliest joined date wins and keeps its own fee; pass: 0; how: measure-P1-C1.py; who: Superfix
- P1-K1 [check] distinct members: by email with spaces trimmed and case ignored; pass: 112 (today's count); how: measure-P1-K1.py; who: Superfix
EOF
SC="$F/checks"
export SC
python3 -I "$D/crit.py" baseline --run "$F" --scripts "$SC" --body "$T/body.md" --attempts "$SC/attempts" --label base --measure "P1-C1=$F/work/members-export.csv" --measure "P1-K1=$F/work/members-export.csv" > "$T/stub-base.out" 2>&1
python3 -I "$D/crit.py" lock --scripts "$SC" --by "the owner at the keyboard" --run "$F" --attempts "$SC/attempts" --body "$T/body.md" --data "$F/work/members-export.csv" --approved P1 > "$T/stub-lock.out" 2>&1
MKDW() { python3 - "$T/stub-lock.out" "$F" <<'EOF'
import re, sys, pathlib
lock_out, F = open(sys.argv[1]).read(), pathlib.Path(sys.argv[2])
(F / "checks/done-when.md").write_text(
    "## Done when\n"
    "- P1-C1 [script] Duplicate members: must be 0 (today 8, rows 14, 15 and 62)\n"
    "- P1-K1 [script] Distinct members: must be 112 (today 112)\n"
    "Internal: criteria-sha " + re.search(r"Internal: criteria-sha ([0-9a-f]{64})", lock_out).group(1) + " (sha256), locked test, approved by the owner at the keyboard\n"
    "Internal: crit-sha " + re.search(r"Internal: crit-sha ([0-9a-f]{64})", lock_out).group(1) + " (sha256)\n")
EOF
}
MKWO() { python3 - "$F" "$ID" <<'EOF'
import hashlib, pathlib, sys
F, ID = pathlib.Path(sys.argv[1]), sys.argv[2]
base = hashlib.sha256((F / "work/members-export.csv").read_bytes()).hexdigest()
names = ["crit.py", "measure-P1-C1.py", "measure-P1-K1.py", "lock", "attempts", "done-when.md"]
block = "".join(f"{hashlib.sha256((F / 'checks' / n).read_bytes()).hexdigest()}  checks/{n}\n" for n in names)
csha = hashlib.sha256(block.encode()).hexdigest()
(F / "workorder.md").write_text(
    "# Work order: dedupe members-export.csv (testbed seed-1.5)\n"
    f"WORK-ORDER: {ID}\nCHECKS-KIND: criteria\n"
    "SOURCE: data/members-export.csv (a copy is in work/; you never get the original)\n"
    f"BASE: {base} (sha256)\nFILES: work/members-export.csv\nLIMITS: 5 attempts\n"
    f"CHECKS-SHA: {csha} (sha256)\nBASELINE: P1-C1 FAIL, P1-K1 PASS\n"
    "DELIVER: hand the folder back, with the changed copy in work/\n"
    "\n## Done when (tick each line when it passes)\n"
    "- [ ] [script] Duplicate members: must be 0 (today 8, rows 14, 15 and 62)\n"
    "- [ ] [script] Distinct members: must be 112 (today 112)\n"
    "- [ ] [Superfix verifies] for each duplicate, the row kept is the earliest joined date\n"
    "\n## CHECKS (do not edit; Step 0 checks them)\n```bash\n# BEGIN CHECKS\n" + block + "# END CHECKS\n```\n")
EOF
}
MKDW; MKWO; echo yes > "$D/workorder/data-yes"
cp -r "$F" "$T/pristine"
t stub-baseline-numbers 'FAIL P1-C1 8 items 14 15 62.*ATTEMPT-SAVED 0' cat "$T/stub-base.out"
t stub-lock-names-stub-only "data $F/work/members-export.csv" cat "$SC/lock"
t stub-lock-no-original-path 'NO-SEED-PATH' sh -c '! grep -q "seed15" "$SC/lock" && echo NO-SEED-PATH'

# ---- WORKORDER words ----
t wo-check-ok '^WORKORDER-OK$' python3 -I "$D/crit.py" wo-check --wo "$F/workorder.md" --run "$D"
plant() { restore; eval "$1"; python3 -I "$D/crit.py" wo-check --wo "$F/workorder.md" --run "$D"; }
t wo-ticklist-missing 'WORKORDER-TICKLIST P1-K1' plant "sed -i '' '/Distinct members/d' \"$F/workorder.md\""
t wo-ticklist-must 'WORKORDER-TICKLIST Distinct members' plant "sed -i '' 's/must be 112 (today 112)/must be 111/' \"$F/workorder.md\""
t wo-crit-sha 'WORKORDER-CRIT-SHA' plant "echo '# x' >> \"$F/checks/crit.py\""
t wo-no-copy 'WORKORDER-NO-COPY' plant "echo 'M9,X,x@x.org,2024-01-01,45' >> \"$F/work/members-export.csv\""
t wo-data 'WORKORDER-DATA' plant "sed -i '' 's#^SOURCE:.*#SOURCE: data/members-export.csv (contact jane@example.org)#' \"$F/workorder.md\""
t wo-no-yes-gates-check 'WORKORDER-NO-YES' sh -c "restore; rm \"$D/workorder/data-yes\"; python3 -I \"$D/crit.py\" wo-check --wo \"$F/workorder.md\" --run \"$D\""
t wo-lock-path 'WORKORDER-LOCK-PATH' plant "sed -i '' 's#^data .*#data /elsewhere/members-export.csv#' \"$F/checks/lock\""
t wo-path-named-refused 'WORKORDER-PATH' sh -c "restore; python3 -I \"$D/crit.py\" wo-lock --run \"$D\" --folder \"$F\" --dest \"$T/other-place\""
restore

# ---- BASELINE ----
t wo-baseline-ok '^BASELINE-OK$' python3 -I "$D/crit.py" wo-baseline --run "$D" --folder "$F"
t wo-baseline-mismatch 'BASELINE-MISMATCH P1-C1' bash -c 'restore; python3 "$T/dedupe.py" "$F/work/members-export.csv" "$F/work/members-export.csv" 8; python3 -I "$D/crit.py" wo-baseline --run "$D" --folder "$F"; restore'

# ---- LOCK ----
DEST="$HOME/superfix-workorders/$ID"; export DEST HOME
t wo-lock-ok 'WORKORDER-LOCKED' python3 -I "$D/crit.py" wo-lock --run "$D" --folder "$F" --dest "$DEST"
t wo-lock-file-count 'FILE-COUNT-9' sh -c 'test "$(find "$DEST" -type f | wc -l)" -eq 9 && echo FILE-COUNT-9'
t wo-lock-no-runtime-files 'NO-RUNTIME' sh -c 'test -z "$(find "$DEST" -name VERIFY.txt -o -name records -o -name head)" && echo NO-RUNTIME'
t wo-no-yes-gates-lock 'WORKORDER-LOCK-REFUSED' sh -c 'rm "$D/workorder/data-yes"; python3 -I "$D/crit.py" wo-lock --run "$D" --folder "$F" --dest "$DEST-r2"; echo yes > "$D/workorder/data-yes"'

# ---- RETURN (executor fixes all 8 dupes, then a half fix) ----
retfix() { rm -rf "$T/$1"; mkdir -p "$T/$1"; cp -r "$DEST" "$T/$1/folder"; python3 "$T/dedupe.py" "$T/$1/folder/work/members-export.csv" "$T/$1/folder/work/members-export.csv" "$2"; }
retfix ret1 8
t wo-return-ok 'RETURN-CRITERIA-COPIED wo1 .* attempts 1' python3 -I "$D/crit.py" wo-return --run "$D" --folder "$T/ret1/folder" --body "$T/body.md"
t wo-return-original-moved 'RETURN-ORIGINAL-MOVED' sh -c 'echo "M9,X,x@x.org,2024-01-01,45" >> "$D/work/members-export.csv"; python3 -I "$D/crit.py" wo-return --run "$D" --folder "$T/ret1/folder" --body "$T/body.md"; cp "$SEED/overlay/data/members-export.csv" "$D/work/members-export.csv"'
t wo-return-files-over 'RETURN-FILES-OVER .*work/extra.txt' sh -c 'rm -rf "$T/retx"; cp -r "$DEST" "$T/retx"; echo x > "$T/retx/work/extra.txt"; python3 -I "$D/crit.py" wo-return --run "$D" --folder "$T/retx" --body "$T/body.md"'
t wo-return-no-copy 'RETURN-NO-COPY' sh -c 'rm -rf "$T/retn"; cp -r "$DEST" "$T/retn"; rm "$T/retn/work/members-export.csv"; python3 -I "$D/crit.py" wo-return --run "$D" --folder "$T/retn" --body "$T/body.md"'
t wo-return-checks-changed 'RETURN-FILES-OVER .*CHECKS-CHANGED' sh -c 'rm -rf "$T/retc"; cp -r "$DEST" "$T/retc"; echo "# x" >> "$T/retc/checks/measure-P1-C1.py"; python3 -I "$D/crit.py" wo-return --run "$D" --folder "$T/retc" --body "$T/body.md"'

# ---- VERIFY (on the passing wo1) ----
printf 'Duplicate members: met (lines 14, 15)\n' > "$T/find-ok.txt"
printf 'Duplicate members: met (lines 9999)\n' > "$T/find-bad.txt"
t wo-verify-pass 'VERIFY-PASS' python3 -I "$D/crit.py" wo-verify --run "$D" --head wo1
t wo-verify-findings 'FINDING-LINE-MISSING' python3 -I "$D/crit.py" wo-verify --run "$D" --head wo1 --findings "$T/find-bad.txt"
t wo-verify-findings-ok 'VERIFY-PASS' python3 -I "$D/crit.py" wo-verify --run "$D" --head wo1 --findings "$T/find-ok.txt"

# ---- SENDBACK (fail-first sequence under a fresh record) ----
resetreturns() { rm -f "$D/workorder/returns.json"; rm -f "$D"/work/wo*-members-export.csv; }
resetreturns
retfix ret2 5
python3 -I "$D/crit.py" wo-return --run "$D" --folder "$T/ret2/folder" --body "$T/body.md" >/dev/null 2>&1
t wo-verify-fail 'VERIFY-FAIL' python3 -I "$D/crit.py" wo-verify --run "$D" --head wo1
t wo-sendback-ready 'SENDBACK-READY' python3 -I "$D/crit.py" wo-sendback --run "$D" --dest "$HOME/superfix-workorders/$ID-r2"
t wo-sendback-carries-copy 'sendback.md.*work/members-export.csv' sh -c 'find "$HOME/superfix-workorders/$ID-r2" -type f | sort | tr "\n" "|"'
t wo-sendback-nothing 'SENDBACK-NOTHING' sh -c 'rm -f "$D/workorder/returns.json"; rm -f "$D"/work/wo*-members-export.csv; rm -rf "$T/ret1"; mkdir -p "$T/ret1"; cp -r "$DEST" "$T/ret1/folder"; python3 "$T/dedupe.py" "$T/ret1/folder/work/members-export.csv" "$T/ret1/folder/work/members-export.csv" 8; python3 -I "$D/crit.py" wo-return --run "$D" --folder "$T/ret1/folder" --body "$T/body.md" >/dev/null 2>&1; python3 -I "$D/crit.py" wo-verify --run "$D" --head wo1 >/dev/null 2>&1; python3 -I "$D/crit.py" wo-sendback --run "$D" --dest "$HOME/superfix-workorders/$ID-r3"'

# ---- OLD LOCK (locked under the v1.5.0 tool, worked under the new one) ----
O="$T/oldlock"; mkdir -p "$O/home"; export OHOME="$O/home"
git -C "$ROOT" show v1.5.0:skills/superfix/references/criteria.md > "$T/crit-150.md"
awk '/^# --- crit.py start ---$/{f=1} f{print} /^# --- crit.py end ---$/{f=0}' "$T/crit-150.md" > "$T/crit150.py"
python3 -c "import ast; ast.parse(open('$T/crit150.py').read())" && echo "old tool extracts"
OD="$O/home/.superfix/runs/old-job"; OC="$O/home/.superfix/journal/test-old/criteria/old-job"
mkdir -p "$OD/work" "$OC"; echo runkey > "$OD/key"
cp "$T/crit150.py" "$OD/crit.py"
cp "$SEED/measures/measure-P1-C1.py" "$SEED/measures/measure-P1-K1.py" "$OC/"
cp "$SEED/overlay/data/members-export.csv" "$T/members-export.csv"
HOME="$O/home" python3 -I "$OD/crit.py" copy --run "$OD" --src "$T/members-export.csv" >/dev/null 2>&1
HOME="$O/home" python3 -I "$OD/crit.py" baseline --run "$OD" --scripts "$OC" --body "$T/body.md" --attempts "$OC/attempts" --label base --measure "P1-C1=$OD/work/members-export.csv" --measure "P1-K1=$OD/work/members-export.csv" >/dev/null 2>&1
HOME="$O/home" python3 -I "$OD/crit.py" lock --scripts "$OC" --by "the owner at the keyboard" --run "$OD" --attempts "$OC/attempts" --body "$T/body.md" --data "$OD/work/members-export.csv" --approved P1 > "$T/old-lock.out" 2>&1
cp "$T/body.md" "$T/old-body.md"
grep "Internal: criteria-sha" "$T/old-lock.out" >> "$T/old-body.md"
t old-lock-under-150 'Internal: crit-sha a0e80862' cat "$T/old-lock.out"
# the fixed section 5 command, run for real: reuse when the sha matches, loud stop when not, extract when no lock
SEC5LINE="$(grep -n '^umask 077; D=' "$ROOT/skills/superfix/references/criteria.md" | head -1 | cut -d: -f1)"
RUNSEC5() { sed -e "s#<run-key>#$2#g" -e "s#<criteria folder>#$3#g" -e "s#<skill dir>#$4#g" "$ROOT/skills/superfix/references/criteria.md" | sed -n "${SEC5LINE}p" > "$T/sec5.sh"; HOME="$1" bash "$T/sec5.sh"; }
rm -f "$OD/crit.py"
t sec5-reuses-locked-tool 'CRIT-READY .* \(the locked tool\)' RUNSEC5 "$O/home" old-job "$OC" "$ROOT/skills/superfix"
t sec5-reused-tool-measures 'FAIL P1-C1 8' env HOME="$O/home" python3 -I "$OD/crit.py" measure --run "$OD" --scripts "$OC" --body "$T/old-body.md" --attempts "$OC/attempts" --id P1-C1 --script "$OC/measure-P1-C1.py" --data "$OD/work/members-export.csv" --out probe --expect FAIL
echo "# tamper" >> "$OC/crit.py"
t sec5-mismatch-stops-loud 'CRIT-SHA-MISMATCH' RUNSEC5 "$O/home" old-job "$OC" "$ROOT/skills/superfix"
git -C "$ROOT" show v1.5.0:skills/superfix/references/criteria.md 2>/dev/null | awk '/^# --- crit.py start ---$/{f=1} f{print} /^# --- crit.py end ---$/{f=0}' > "$OC/crit.py"
mkdir -p "$T/fresh/home/.superfix/runs/rk"; echo k > "$T/fresh/home/.superfix/runs/rk/key"; mkdir -p "$T/freshcrit"
t sec5-fresh-extracts 'CRIT-READY .*crit.py$' RUNSEC5 "$T/fresh/home" rk "$T/freshcrit" "$ROOT/skills/superfix"
# attempt, VERIFY, finish and sendcheck under the reused 1.5.0 tool
cp "$T/body.md" "$O/home/body.md"
python3 "$T/dedupe.py" "$OD/work/members-export.csv" "$OD/work/fixed.csv" 8
python3 - "$OC/attempts" "$T/prev150.md" <<'EOF'
import hashlib, sys
lines = open(sys.argv[1]).read().splitlines()
open(sys.argv[2], "w").write(f"attempts: {len(lines)} lines, head {hashlib.sha256(lines[-1].encode()).hexdigest()[:8]}\n")
EOF
t old-attempt-saved 'ATTEMPT-SAVED 1' env HOME="$O/home" python3 -I "$OD/crit.py" attempt --run "$OD" --attempts "$OC/attempts" --scripts "$OC" --label a1 --body "$T/old-body.md" --prev-comment "$T/prev150.md" --measure "P1-C1=$OD/work/fixed.csv" --measure "P1-K1=$OD/work/fixed.csv"
if [ "$(shasum -a 256 "$OC/crit.py" | cut -d' ' -f1)" = "$(sed -n 's/^crit //p' "$OC/lock")" ]; then C150SAME="SAME-SHA"; else C150SAME="DIFFERENT"; fi
t old-tool-not-overwritten '^SAME-SHA$' echo "$C150SAME"
t old-verify-ok 'VERIFY-OK' bash "$OC/VERIFY.txt"
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"python3 -I '"$OD"'/crit.py attempt --run '"$OD"' --scripts '"$OC"'"}}]}}' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Read","input":{"path":"x"}}]}}' > "$T/log150.jsonl"
t old-sendcheck-clean 'SEND-CLEAN' env HOME="$O/home" python3 -I "$OD/crit.py" sendcheck --log "$T/log150.jsonl" --repo owner/repo --allow-dir "$O/home" --scripts "$OC"
t old-finish-clean 'ORIGINAL-UNCHANGED.*WORK-DELETED' env HOME="$O/home" python3 -I "$OD/crit.py" finish --run "$OD"

# ---- CUT COLUMNS (the cut copy baselines the same, the map-back keeps every other column) ----
CU="$T/cutstub"; mkdir -p "$CU/home"; export CHOME="$CU/home"
CD="$CU/home/.superfix/runs/cut-wo"; CF="$CD/workorder/folder"; CSC="$CF/checks"
mkdir -p "$CD/work" "$CF/work" "$CSC"; echo runkey > "$CD/key"
python3 - "$SEED/overlay/data/members-export.csv" "$CD/work/full.csv" <<'EOF'
import csv, sys
rows = list(csv.DictReader(open(sys.argv[1], newline="", encoding="utf-8")))
with open(sys.argv[2], "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys())
    w.writeheader(); w.writerows(rows)
EOF
python3 - "$CD/work/full.csv" "$CF/work/cut.csv" <<'EOF'
import csv, sys
rows = list(csv.DictReader(open(sys.argv[1], newline="", encoding="utf-8")))
with open(sys.argv[2], "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=["row", "email", "joined"])
    w.writeheader()
    for n, r in enumerate(rows, start=2):
        w.writerow({"row": n, "email": r["email"], "joined": r["joined"]})
EOF
cp "$D/crit.py" "$CD/crit.py"; cp "$CD/crit.py" "$CSC/crit.py"
cp "$SEED/measures/measure-P1-C1.py" "$SEED/measures/measure-P1-K1.py" "$CSC/"
echo cutkey > "$CF/key"
HOME="$CU/home" python3 -I "$CD/crit.py" baseline --run "$CF" --scripts "$CSC" --body "$T/body.md" --attempts "$CSC/attempts" --label base --measure "P1-C1=$CF/work/cut.csv" --measure "P1-K1=$CF/work/cut.csv" > "$T/cut-base.out" 2>&1
t cut-baseline-same 'FAIL P1-C1 8 items 14 15 62.*PASS P1-K1 112' cat "$T/cut-base.out"
python3 - "$CF/work/cut.csv" "$CF/work/cut-fixed.csv" "$CD/work/full.csv" "$CD/work/mapped.csv" <<'EOF'
import csv, sys
cut, fixed, full, mapped = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
rows = list(csv.DictReader(open(cut, newline="", encoding="utf-8")))
seen, kept = set(), []
for r in rows:
    k = r["email"].strip().lower()
    if k in seen:
        continue
    seen.add(k); kept.append(int(r["row"]))
with open(fixed, "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=["row", "email", "joined"])
    w.writeheader()
    for r in rows:
        if int(r["row"]) in kept:
            w.writerow(r)
full_rows = list(csv.DictReader(open(full, newline="", encoding="utf-8")))
with open(mapped, "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=full_rows[0].keys())
    w.writeheader()
    for n, r in enumerate(full_rows, start=2):
        if n in kept:
            w.writerow(r)
print("kept", len(kept))
EOF
t cut-mapback-counts 'MEASURE P1-C1 0.*MEASURE P1-K1 112' sh -c 'python3 -I "'"$CSC"'/measure-P1-C1.py" "'"$CD"'/work/mapped.csv"; python3 -I "'"$CSC"'/measure-P1-K1.py" "'"$CD"'/work/mapped.csv"'
cat > "$T/keepcols.py" <<'EOF'
import csv, sys
full = {(r["email"], r["name"], r["fee"]) for r in csv.DictReader(open(sys.argv[1], newline="", encoding="utf-8"))}
mapped = [(r["email"], r["name"], r["fee"]) for r in csv.DictReader(open(sys.argv[2], newline="", encoding="utf-8"))]
print("KEPT-COLUMNS" if all(m in full for m in mapped) and len(mapped) == 112 else "COLUMNS-CHANGED")
EOF
t cut-mapback-keeps-columns '^KEPT-COLUMNS$' python3 "$T/keepcols.py" "$CD/work/full.csv" "$CD/work/mapped.csv"

# ---- CRIT-1.5-CHANGED (a one-byte edit to a 1.5.0 command fails it) ----
t crit-15-unchanged 'CRIT-1.5-UNCHANGED' python3 "$ROOT/tests/crit-15-check.py" "$ROOT/skills/superfix/references/criteria.md"
cp "$ROOT/skills/superfix/references/criteria.md" "$T/crit-tampered.md"
python3 - "$T/crit-tampered.md" <<'EOF'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("def cmd_measure(a):\n", "def cmd_measure(a):  # x\n", 1)
open(p, "w").write(s)
EOF
t crit-15-changed-fails 'CRIT-1.5-CHANGED cmd_measure' sh -c 'python3 "'"$ROOT"'/tests/crit-15-check.py" "'"$T"'/crit-tampered.md"; test $? -ne 0'

echo "RESULT: $pass passed, $fail failed"
export HOME="$REALHOME"
