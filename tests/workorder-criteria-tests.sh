#!/bin/bash
# Free tests for 1.6.1 criteria work orders (references/workorder.md kind criteria and crit.py's woc-* commands).
# No model runs. Runs under a throwaway HOME. Needs: git, python3, /usr/bin/sandbox-exec.
# Uses the local fixtures in ~/superfix-handoff/scripts/seed15 (no testbed clone, no network).
# Usage: bash tests/workorder-criteria-tests.sh   (prints one line per test, then "RESULT: <n> passed, <m> failed")
# ROOT=<another checkout> runs these tests against that checkout's files (used to show a test fails before its fix).
ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"; SEED=~/superfix-handoff/scripts/seed15
export ROOT SEED
T="$(mktemp -d /private/tmp/wo-crit-tests.XXXX)"; REALHOME="$HOME"
export HOME="$T/home"; mkdir -p "$HOME"
export T REALHOME SEED ROOT
pass=0; fail=0
t() { local name="$1" want="$2"; shift 2; local out; out="$("$@" 2>&1)"
  if printf '%s' "$out" | tr '\n' '|' | grep -qE "$want"; then pass=$((pass+1)); echo "ok   $name"; else fail=$((fail+1)); echo "FAIL $name: want /$want/ got: $(printf '%s' "$out" | tr '\n' '|' | cut -c1-300)"; fi; }
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
mkdir -p "$T/src"; cp "$SEED/overlay/data/members-export.csv" "$T/src/members-export.csv"
# model-side attempt in the real criteria folder
doattempt() { python3 -I "$1/crit.py" attempt --run "$1" --attempts "$2/attempts" --scripts "$2" --label "$4" --body "$3" --measure "P1-C1=$5" --measure "P1-K1=$5"; }
# returned folder from a handed folder, deduped to <keep> removals
# returned folder from a handed folder, deduped to <keep> removals
retfix() { rm -rf "$T/$1"; mkdir -p "$T/$1"; cp -r "$2" "$T/$1/folder"; python3 "$T/dedupe.py" "$T/$1/folder/work/members-export.csv" "$T/$1/folder/work/members-export.csv" "$3"; }

mkdir -p "$T/src"; cp "$SEED/overlay/data/members-export.csv" "$T/src/members-export.csv"
# ---- MAIN RIG (real 1.5.0 job plus stub folder work order) ----
eval "$(python3 "$(dirname "$0")/mkrig.py" "$HOME" test-csv-wo thedanielmay+superfix-testbed+csv-wo1 "$T/src/members-export.csv" work/members-export.csv M)"
[ -n "$M_RD" ] || { echo "CANNOT RUN: main rig build failed"; exit 2; }
export M_RD M_RF M_RCRC M_DEST M_BODYDEC M_PRISTINE
M_PRISTINE="$T/pristine-main"; cp -r "$M_RF" "$M_PRISTINE"
restore() { rm -rf "$M_RF"; mkdir -p "$(dirname "$M_RF")"; cp -r "$M_PRISTINE" "$M_RF"; echo yes > "$M_RD/workorder/data-yes"; }
export -f restore 2>/dev/null || true
t stub-lock-names-stub-only "data $M_RF/work/members-export.csv" cat "$M_RF/checks/lock"
t stub-lock-no-original-path 'NO-SEED-PATH' sh -c '! grep -q "seed15" "$M_RF/checks/lock" && echo NO-SEED-PATH'

# ---- WORKORDER words ----
t wo-check-ok '^WORKORDER-OK$' python3 -I "$M_RD/crit.py" wo-check --wo "$M_RF/workorder.md" --run "$M_RD" --body "$M_BODYDEC"
plant() { restore; eval "$1"; python3 -I "$M_RD/crit.py" wo-check --wo "$M_RF/workorder.md" --run "$M_RD" --body "$M_BODYDEC"; }
t wo-ticklist-missing 'WORKORDER-TICKLIST P1-K1' plant "sed -i '' '/Distinct members/d' \"$M_RF/workorder.md\""
t wo-ticklist-must 'WORKORDER-TICKLIST Distinct members' plant "sed -i '' 's/must be 112 (today 112)/must be 111/' \"$M_RF/workorder.md\""
t wo-ticklist-body-pass 'WORKORDER-TICKLIST P1-C1 \(not the locked body' plant "sed -i '' 's/must be 0 (today 8, rows 14, 15 and 62)/must be at most 3 (today 8)/' \"$M_RF/workorder.md\" \"$M_RF/checks/done-when.md\""
t wo-crit-sha 'WORKORDER-CRIT-SHA' plant "echo '# x' >> \"$M_RF/checks/crit.py\""
t wo-no-copy 'WORKORDER-NO-COPY' plant "echo 'M9,X,x@x.org,2024-01-01,45' >> \"$M_RF/work/members-export.csv\""
t wo-data 'WORKORDER-DATA' plant "sed -i '' 's#^SOURCE:.*#SOURCE: data/members-export.csv (contact jane@example.org)#' \"$M_RF/workorder.md\""
t wo-no-yes-gates-check 'WORKORDER-NO-YES' sh -c 'restore; rm "$M_RD/workorder/data-yes"; python3 -I "$M_RD/crit.py" wo-check --wo "$M_RF/workorder.md" --run "$M_RD" --body "$M_BODYDEC"'
t wo-lock-path 'WORKORDER-LOCK-PATH' plant "sed -i '' 's#^data .*#data /elsewhere/members-export.csv#' \"$M_RF/checks/lock\""
t wo-path-named-refused 'WORKORDER-PATH' sh -c 'restore; python3 -I "$M_RD/crit.py" wo-lock --run "$M_RD" --folder "$M_RF" --dest "$T/other-place" --body "$M_BODYDEC"'
restore

# ---- BASELINE ----
t wo-baseline-ok '^BASELINE-OK$' python3 -I "$M_RD/crit.py" wo-baseline --run "$M_RD" --folder "$M_RF" --body "$M_BODYDEC"
t wo-baseline-mismatch 'BASELINE-MISMATCH P1-C1' bash -c 'restore; python3 "$T/dedupe.py" "$M_RF/work/members-export.csv" "$M_RF/work/members-export.csv" 8; python3 -I "$M_RD/crit.py" wo-baseline --run "$M_RD" --folder "$M_RF" --body "$M_BODYDEC"; restore'

# ---- LOCK ----
t wo-lock-ok 'WORKORDER-LOCKED' python3 -I "$M_RD/crit.py" wo-lock --run "$M_RD" --folder "$M_RF" --dest "$M_DEST" --body "$M_BODYDEC"
t wo-lock-file-count 'FILE-COUNT-9' sh -c 'test "$(find "$M_DEST" -type f | wc -l)" -eq 9 && echo FILE-COUNT-9'
t wo-lock-no-runtime-files 'NO-RUNTIME' sh -c 'test -z "$(find "$M_DEST" -name VERIFY.txt -o -name records -o -name head)" && echo NO-RUNTIME'
t wo-no-yes-gates-lock 'WORKORDER-LOCK-REFUSED' sh -c 'rm "$M_RD/workorder/data-yes"; python3 -I "$M_RD/crit.py" wo-lock --run "$M_RD" --folder "$M_RF" --dest "$M_DEST-r2" --body "$M_BODYDEC"; echo yes > "$M_RD/workorder/data-yes"'

# ---- RETURN (executor fixes all 8 dupes, then the half fix) ----
retfix ret1 "$M_DEST" 8
t wo-return-ok 'RETURN-CRITERIA-COPIED wo1 .* attempts 1' python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/ret1/folder" --body "$M_BODYDEC"
t wo-return-original-moved 'RETURN-ORIGINAL-MOVED' sh -c 'echo "M9,X,x@x.org,2024-01-01,45" >> "$M_RD/work/members-export.csv"; python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/ret1/folder" --body "$M_BODYDEC"; cp "$SEED/overlay/data/members-export.csv" "$M_RD/work/members-export.csv"'
t wo-return-files-over 'RETURN-FILES-OVER .*work/extra.txt' sh -c 'rm -rf "$T/retx"; cp -r "$M_DEST" "$T/retx"; echo x > "$T/retx/work/extra.txt"; python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/retx" --body "$M_BODYDEC"'
t wo-return-no-copy 'RETURN-NO-COPY' sh -c 'rm -rf "$T/retn"; cp -r "$M_DEST" "$T/retn"; rm "$T/retn/work/members-export.csv"; python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/retn" --body "$M_BODYDEC"'
t wo-return-checks-changed 'RETURN-FILES-OVER .*CHECKS-CHANGED' sh -c 'rm -rf "$T/retc"; cp -r "$M_DEST" "$T/retc"; echo "# x" >> "$T/retc/checks/measure-P1-C1.py"; python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/retc" --body "$M_BODYDEC"'

# ---- VERIFY (verdicts from Superfix's own recorded attempt) ----
printf 'Duplicate members: met (lines 14, 15)\n' > "$T/find-ok.txt"
printf 'Duplicate members: met (lines 9999)\n' > "$T/find-bad.txt"
t wo-verify-no-attempt 'VERIFY-NO-ATTEMPT wo1' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC"
t wo-verify-no-return 'VERIFY-NO-RETURN wo9' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo9 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC"
doattempt "$M_RD" "$M_RCRC" "$M_BODYDEC" wo1 "$M_RD/work/wo1-members-export.csv" >/dev/null 2>&1
t wo-verify-pass 'VERIFY-PASS' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC"
t wo-verify-findings 'FINDING-LINE-MISSING' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-bad.txt"
t wo-verify-findings-ok 'VERIFY-PASS' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-ok.txt"

# ---- SENDBACK (fail-first sequence under a fresh record) ----
t wo-sendback-nothing 'SENDBACK-NOTHING' python3 -I "$M_RD/crit.py" wo-sendback --run "$M_RD" --dest "$M_DEST-r2" --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC"

# ---- PROGRESS RIG (8 then 3 then 1: every return moved, send-back goes) ----
eval "$(python3 "$(dirname "$0")/mkrig.py" "$HOME" test-prog-wo thedanielmay+superfix-testbed+prog-wo1 "$T/src/members-export.csv" work/members-export.csv P)"
[ -n "$P_RD" ] || { echo "CANNOT RUN: prog rig build failed"; exit 2; }
export P_RD P_RF P_RCRC P_DEST P_BODYDEC
python3 -I "$P_RD/crit.py" wo-lock --run "$P_RD" --folder "$P_RF" --dest "$P_DEST" --body "$P_BODYDEC" >/dev/null 2>&1
retfix Pret1 "$P_DEST" 5
python3 -I "$P_RD/crit.py" wo-return --run "$P_RD" --folder "$T/Pret1/folder" --body "$P_BODYDEC" >/dev/null 2>&1
doattempt "$P_RD" "$P_RCRC" "$P_BODYDEC" wo1 "$P_RD/work/wo1-members-export.csv" >/dev/null 2>&1
t wo-prog-verify1 'VERIFY-FAIL' python3 -I "$P_RD/crit.py" wo-verify --run "$P_RD" --head wo1 --attempts "$P_RCRC/attempts" --scripts "$P_RCRC" --body "$P_BODYDEC"
retfix Pret2 "$P_DEST" 7
python3 -I "$P_RD/crit.py" wo-return --run "$P_RD" --folder "$T/Pret2/folder" --body "$P_BODYDEC" >/dev/null 2>&1
doattempt "$P_RD" "$P_RCRC" "$P_BODYDEC" wo2 "$P_RD/work/wo2-members-export.csv" >/dev/null 2>&1
t wo-prog-verify2 'VERIFY-FAIL' python3 -I "$P_RD/crit.py" wo-verify --run "$P_RD" --head wo2 --attempts "$P_RCRC/attempts" --scripts "$P_RCRC" --body "$P_BODYDEC"
t wo-prog-sendback-ready 'SENDBACK-READY' python3 -I "$P_RD/crit.py" wo-sendback --run "$P_RD" --dest "$HOME/superfix-workorders/thedanielmay+superfix-testbed+prog-wo1-r3" --attempts "$P_RCRC/attempts" --scripts "$P_RCRC" --body "$P_BODYDEC"

# ---- STOP RIG (8 then 3 then 3 then 3: two in a row did not move) ----
eval "$(python3 "$(dirname "$0")/mkrig.py" "$HOME" test-stop-wo thedanielmay+superfix-testbed+stop-wo1 "$T/src/members-export.csv" work/members-export.csv S)"
[ -n "$S_RD" ] || { echo "CANNOT RUN: stop rig build failed"; exit 2; }
export S_RD S_RF S_RCRC S_DEST S_BODYDEC
python3 -I "$S_RD/crit.py" wo-lock --run "$S_RD" --folder "$S_RF" --dest "$S_DEST" --body "$S_BODYDEC" >/dev/null 2>&1
sret() { rm -rf "$T/$1"; mkdir -p "$T/$1"; cp -r "$S_DEST" "$T/$1/folder"; python3 "$T/dedupe.py" "$T/$1/folder/work/members-export.csv" "$T/$1/folder/work/members-export.csv" "$2"; if [ -n "$3" ]; then python3 - "$T/$1/folder/work/members-export.csv" "$3" <<'EOF'
import csv, sys
p, spec = sys.argv[1], sys.argv[2]
with open(p, newline="", encoding="utf-8") as f:
    rows = list(f)
a, b = (int(x) - 1 for x in spec.split(","))
rows[a], rows[b] = rows[b], rows[a]
with open(p, "w", newline="", encoding="utf-8") as f:
    f.writelines(rows)
EOF
fi; }
sret Sret1 5
python3 -I "$S_RD/crit.py" wo-return --run "$S_RD" --folder "$T/Sret1/folder" --body "$S_BODYDEC" >/dev/null 2>&1
doattempt "$S_RD" "$S_RCRC" "$S_BODYDEC" wo1 "$S_RD/work/wo1-members-export.csv" >/dev/null 2>&1
python3 -I "$S_RD/crit.py" wo-verify --run "$S_RD" --head wo1 --attempts "$S_RCRC/attempts" --scripts "$S_RCRC" --body "$S_BODYDEC" >/dev/null 2>&1
sret Sret2 5 2,3
python3 -I "$S_RD/crit.py" wo-return --run "$S_RD" --folder "$T/Sret2/folder" --body "$S_BODYDEC" >/dev/null 2>&1
doattempt "$S_RD" "$S_RCRC" "$S_BODYDEC" wo2 "$S_RD/work/wo2-members-export.csv" >/dev/null 2>&1
python3 -I "$S_RD/crit.py" wo-verify --run "$S_RD" --head wo2 --attempts "$S_RCRC/attempts" --scripts "$S_RCRC" --body "$S_BODYDEC" >/dev/null 2>&1
sret Sret3 5 3,4
python3 -I "$S_RD/crit.py" wo-return --run "$S_RD" --folder "$T/Sret3/folder" --body "$S_BODYDEC" >/dev/null 2>&1
doattempt "$S_RD" "$S_RCRC" "$S_BODYDEC" wo3 "$S_RD/work/wo3-members-export.csv" >/dev/null 2>&1
python3 -I "$S_RD/crit.py" wo-verify --run "$S_RD" --head wo3 --attempts "$S_RCRC/attempts" --scripts "$S_RCRC" --body "$S_BODYDEC" >/dev/null 2>&1
t wo-stop-sendback-refused 'NO-PROGRESS' python3 -I "$S_RD/crit.py" wo-sendback --run "$S_RD" --dest "$HOME/superfix-workorders/thedanielmay+superfix-testbed+stop-wo1-r4" --attempts "$S_RCRC/attempts" --scripts "$S_RCRC" --body "$S_BODYDEC"

# ---- CAP RIG (five moving returns, then the cap) ----
eval "$(python3 "$(dirname "$0")/mkrig.py" "$HOME" test-cap-wo thedanielmay+superfix-testbed+cap-wo1 "$T/src/members-export.csv" work/members-export.csv K)"
[ -n "$K_RD" ] || { echo "CANNOT RUN: cap rig build failed"; exit 2; }
export K_RD K_RF K_RCRC K_DEST K_BODYDEC
python3 -I "$K_RD/crit.py" wo-lock --run "$K_RD" --folder "$K_RF" --dest "$K_DEST" --body "$K_BODYDEC" >/dev/null 2>&1
for n in 1 2 3 4 5; do
  rm -rf "$T/Kret$n"; mkdir -p "$T/Kret$n"; cp -r "$K_DEST" "$T/Kret$n/folder"
  python3 "$T/dedupe.py" "$T/Kret$n/folder/work/members-export.csv" "$T/Kret$n/folder/work/members-export.csv" "$n"
  python3 -I "$K_RD/crit.py" wo-return --run "$K_RD" --folder "$T/Kret$n/folder" --body "$K_BODYDEC" >/dev/null 2>&1
  doattempt "$K_RD" "$K_RCRC" "$K_BODYDEC" "wo$n" "$K_RD/work/wo$n-members-export.csv" >/dev/null 2>&1
  python3 -I "$K_RD/crit.py" wo-verify --run "$K_RD" --head "wo$n" --attempts "$K_RCRC/attempts" --scripts "$K_RCRC" --body "$K_BODYDEC" >/dev/null 2>&1
done
t wo-cap-sendback-refused 'RETURN-CAP' python3 -I "$K_RD/crit.py" wo-sendback --run "$K_RD" --dest "$HOME/superfix-workorders/thedanielmay+superfix-testbed+cap-wo1-r6" --attempts "$K_RCRC/attempts" --scripts "$K_RCRC" --body "$K_BODYDEC"
t wo-cap-sixth-return-refused 'RETURN-CAP 6 of 5' sh -c 'rm -rf "$T/Kret6"; cp -r "$K_DEST" "$T/Kret6"; python3 -I "$K_RD/crit.py" wo-return --run "$K_RD" --folder "$T/Kret6" --body "$K_BODYDEC"'

# ---- KPROG RIG (distinct members fall: NO-PROGRESS worse) ----
eval "$(python3 "$(dirname "$0")/mkrig.py" "$HOME" test-kprog-wo thedanielmay+superfix-testbed+kprog-wo1 "$T/src/members-export.csv" work/members-export.csv W)"
[ -n "$W_RD" ] || { echo "CANNOT RUN: kprog rig build failed"; exit 2; }
export W_RD W_RF W_RCRC W_DEST W_BODYDEC
python3 "$T/dedupe.py" "$W_RD/work/members-export.csv" "$W_RD/work/kbad.csv" 8
python3 - "$W_RD/work/kbad.csv" <<'EOF'
import csv, sys
rows = list(csv.DictReader(open(sys.argv[1], newline="", encoding="utf-8")))
rows = rows[:-2]
with open(sys.argv[1], "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=["member_id", "name", "email", "joined", "fee"])
    w.writeheader(); w.writerows(rows)
EOF
t wo-kprog-no-progress-worse 'NO-PROGRESS .*worse' sh -c 'python3 -I "$W_RD/crit.py" attempt --run "$W_RD" --attempts "$W_RCRC/attempts" --scripts "$W_RCRC" --label k1 --body "$W_BODYDEC" --measure "P1-C1=$W_RD/work/kbad.csv" --measure "P1-K1=$W_RD/work/kbad.csv" >/dev/null 2>&1; python3 -I "$W_RD/crit.py" progress --attempts "$W_RCRC/attempts" --scripts "$W_RCRC" --run "$W_RD" --body "$W_BODYDEC"'

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
cat > "$T/old-body.md" <<'EOF'
# Journal file mode

## Problems
### P1 duplicate members (members sheet)
Coverage: Everything else

## Done when
- P1-C1 [check] duplicate members: rows whose email, with spaces trimmed and case ignored, matches an earlier row; the earliest joined date wins and keeps its own fee; pass: 0; how: measure-P1-C1.py; who: Superfix
- P1-K1 [check] distinct members: by email with spaces trimmed and case ignored; pass: 112 (today's count); how: measure-P1-K1.py; who: Superfix
EOF
HOME="$O/home" python3 -I "$OD/crit.py" copy --run "$OD" --src "$T/members-export.csv" >/dev/null 2>&1
HOME="$O/home" python3 -I "$OD/crit.py" baseline --run "$OD" --scripts "$OC" --body "$T/old-body.md" --attempts "$OC/attempts" --label base --measure "P1-C1=$OD/work/members-export.csv" --measure "P1-K1=$OD/work/members-export.csv" >/dev/null 2>&1
HOME="$O/home" python3 -I "$OD/crit.py" lock --scripts "$OC" --by "the owner at the keyboard" --run "$OD" --attempts "$OC/attempts" --body "$T/old-body.md" --data "$OD/work/members-export.csv" --approved P1 > "$T/old-lock.out" 2>&1
cp "$T/old-body.md" "$T/old-body-dec.md"
grep "Internal: criteria-sha" "$T/old-lock.out" >> "$T/old-body-dec.md"
t old-lock-under-150 'Internal: crit-sha a0e80862' cat "$T/old-lock.out"
# the fixed section 5 command, run for real: reuse when the sha matches, loud stop when not, extract when no lock
SEC5LINE="$(grep -n '^umask 077; D=' "$ROOT/skills/superfix/references/criteria.md" | head -1 | cut -d: -f1)"
RUNSEC5() { sed -e "s#<run-key>#$2#g" -e "s#<criteria folder>#$3#g" -e "s#<skill dir>#$4#g" "$ROOT/skills/superfix/references/criteria.md" | sed -n "${SEC5LINE}p" > "$T/sec5.sh"; HOME="$1" bash "$T/sec5.sh"; }
rm -f "$OD/crit.py"
t sec5-reuses-locked-tool 'CRIT-READY .* \(the locked tool\)' RUNSEC5 "$O/home" old-job "$OC" "$ROOT/skills/superfix"
t sec5-reused-tool-measures 'FAIL P1-C1 8' env HOME="$O/home" python3 -I "$OD/crit.py" measure --run "$OD" --scripts "$OC" --body "$T/old-body-dec.md" --attempts "$OC/attempts" --id P1-C1 --script "$OC/measure-P1-C1.py" --data "$OD/work/members-export.csv" --out probe --expect FAIL
echo "# tamper" >> "$OC/crit.py"
t sec5-mismatch-stops-loud 'CRIT-SHA-MISMATCH' RUNSEC5 "$O/home" old-job "$OC" "$ROOT/skills/superfix"
git -C "$ROOT" show v1.5.0:skills/superfix/references/criteria.md 2>/dev/null | awk '/^# --- crit.py start ---$/{f=1} f{print} /^# --- crit.py end ---$/{f=0}' > "$OC/crit.py"
mkdir -p "$T/fresh/home/.superfix/runs/rk"; echo k > "$T/fresh/home/.superfix/runs/rk/key"; mkdir -p "$T/freshcrit"
t sec5-fresh-extracts 'CRIT-READY .*crit.py$' RUNSEC5 "$T/fresh/home" rk "$T/freshcrit" "$ROOT/skills/superfix"
# attempt, VERIFY, finish and sendcheck under the reused 1.5.0 tool
cp "$T/old-body.md" "$O/home/body.md"
python3 "$T/dedupe.py" "$OD/work/members-export.csv" "$OD/work/fixed.csv" 8
python3 - "$OC/attempts" "$T/prev150.md" <<'EOF'
import hashlib, sys
lines = open(sys.argv[1]).read().splitlines()
open(sys.argv[2], "w").write(f"attempts: {len(lines)} lines, head {hashlib.sha256(lines[-1].encode()).hexdigest()[:8]}\n")
EOF
t old-attempt-saved 'ATTEMPT-SAVED 1' env HOME="$O/home" python3 -I "$OD/crit.py" attempt --run "$OD" --attempts "$OC/attempts" --scripts "$OC" --label a1 --body "$T/old-body-dec.md" --prev-comment "$T/prev150.md" --measure "P1-C1=$OD/work/fixed.csv" --measure "P1-K1=$OD/work/fixed.csv"
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
cp "$M_RD/crit.py" "$CD/crit.py"; cp "$CD/crit.py" "$CSC/crit.py"
cp "$SEED/measures/measure-P1-C1.py" "$SEED/measures/measure-P1-K1.py" "$CSC/"
echo cutkey > "$CF/key"
HOME="$CU/home" python3 -I "$CD/crit.py" baseline --run "$CF" --scripts "$CSC" --body "$M_RD/body.md" --attempts "$CSC/attempts" --label base --measure "P1-C1=$CF/work/cut.csv" --measure "P1-K1=$CF/work/cut.csv" > "$T/cut-base.out" 2>&1
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
