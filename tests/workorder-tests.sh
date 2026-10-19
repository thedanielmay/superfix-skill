#!/bin/bash
# Free tests for 1.6.0 work orders (references/workorder.md and crit.py's wo-* and sandbox commands).
# No model runs. Runs under a throwaway HOME. Needs: git, node 24, /usr/bin/sandbox-exec, and a clone of
# the private testbed (TESTBED=<path to a clone>, default: cloned from GitHub with your own git login).
# Usage: bash tests/workorder-tests.sh   (prints one line per test, then "RESULT: <n> passed, <m> failed")
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; FX="$ROOT/tests/fixtures/workorder"
T="$(mktemp -d /private/tmp/wo-tests.XXXX)"; REALHOME="$HOME"
B=baecc4813fafefc66934fd83c7e0ae85cf5f094b; BR=wo/109-csv-json-export
X="$T/x"; if [ -n "$TESTBED" ]; then git clone -q "$TESTBED" "$X"; else git clone -q https://github.com/thedanielmay/superfix-testbed.git "$X"; fi || { echo "CANNOT RUN: no testbed clone"; exit 2; }
git -C "$X" fetch -q --tags origin 2>/dev/null
export HOME="$T/home"; mkdir -p "$HOME"; D="$HOME/.superfix/runs/thedanielmay+superfix-testbed+109"; mkdir -p "$D/workorder"; echo k > "$D/key"
awk '/^# --- crit.py start ---$/{f=1} f{print} /^# --- crit.py end ---$/{f=0}' "$ROOT/skills/superfix/references/criteria.md" > "$D/crit.py"
C="python3 -I $D/crit.py"; pass=0; fail=0
t() { local name="$1" want="$2"; shift 2; local out; out="$("$@" 2>&1)"
  if printf '%s' "$out" | tr '\n' '|' | grep -qE "$want"; then pass=$((pass+1)); echo "ok   $name"; else fail=$((fail+1)); echo "FAIL $name: want /$want/ got: $(printf '%s' "$out" | tr '\n' '|' | cut -c1-300)"; fi; }
# the example work order is the template in workorder.md, exactly
awk '/^~~~~$/{n++; next} n==1' "$ROOT/skills/superfix/references/workorder.md" > "$T/example.md"
sed -n '/^# BEGIN CHECKS$/,/^# END CHECKS$/p' "$T/example.md" | sed '1d;$d' > "$T/check.sh"
cp "$T/example.md" "$D/workorder/workorder.md"; cp "$T/check.sh" "$D/workorder/check.sh"; cp "$FX/e1-held.sh" "$D/workorder/held.sh"
chk() { $C wo-check --wo "$1" --check "$T/check.sh" --clone "$X"; }
plant() { sed -e "$1" "$T/example.md" > "$T/p.md"; chk "$T/p.md"; }

# ---- WORKORDER ----
t wo-check-example-ok '^WORKORDER-OK$' chk "$T/example.md"
t wo-check-checks-sha-real '^fa15474eaed13017249c1d692e4e9f5b512ab7e8ad333ee3a65c149187ace969' shasum -a 256 "$T/check.sh"
t wo-check-missing-line 'WORKORDER-MISSING BRANCH' plant '/^BRANCH: /d'
t wo-check-placeholder 'WORKORDER-NOT-FRESH line [0-9]+ \(a placeholder' plant 's/^The stock report prints as text only\./The stock report <fill in>./'
t wo-check-tick 'WORKORDER-NOT-FRESH line [0-9]+ \(a ticked box' plant 's/^- \[ \] 1 report.js/- [x] 1 report.js/'
t wo-check-changed-checks 'WORKORDER-CHECKS-SHA' plant 's/^# needs node v24 (tested with v24.19.0)/# needs node v24 (tested with v24.19.1)/'
t wo-check-expected-not-in-steps 'WORKORDER-EXPECTED-NOT-IN-STEPS C3' plant 's/so xml gives "exit 2, stderr: unknown format: xml"/so xml exits 2/'
t wo-check-unmarked-new-file 'WORKORDER-FILE-NOT-AT-BASE test/cli.test.js' plant 's#test/cli.test.js (new)#test/cli.test.js#'
t wo-check-marked-existing 'WORKORDER-NEW-EXISTS report.js' plant 's#^FILES: report.js,#FILES: report.js (new),#'
t wo-check-baseline-id 'WORKORDER-NOT-IN-BASELINE K1' plant 's/, K1 PASS$//'
t frame-wo-check-kind-criteria '^WORKORDER-KIND criteria$' plant 's/^CHECKS-KIND: code$/CHECKS-KIND: criteria/'

# ---- P2: the widened sandbox ----
git -C "$X" checkout -q --detach "$B"
t p2-sandbox-same-six 'CHECK C1 FAIL.*CHECK C2 FAIL.*CHECK C3 FAIL.*CHECK C4 FAIL.*CHECK C5 FAIL.*CHECK K1 PASS.*SANDBOX-EXIT 0' $C sandbox --cwd "$X" -- /bin/bash "$T/check.sh"
printf '%s\n' 'curl -s -m 5 https://example.com >/dev/null 2>&1 && echo CURL-OK || echo CURL-BLOCKED' "cat '$REALHOME/.ssh/known_hosts' >/dev/null 2>&1 && echo SSH-READ-OK || echo SSH-READ-BLOCKED" 'node -e "require(\"https\").get(\"https://example.com\",()=>console.log(\"NODE-NET-OK\")).on(\"error\",()=>console.log(\"NODE-NET-BLOCKED\"))"' "echo x > '$REALHOME/wo-sbx-write' 2>/dev/null && echo WRITE-OK || echo WRITE-BLOCKED" > "$T/probe.sh"
t p2-sandbox-blocks 'CURL-BLOCKED.*SSH-READ-BLOCKED.*NODE-NET-BLOCKED.*WRITE-BLOCKED' $C sandbox --cwd "$X" -- /bin/bash "$T/probe.sh"
t p2-sandbox-missing '^SANDBOX-MISSING' env SUPERFIX_TEST_NO_SANDBOX=1 $C sandbox --cwd "$X" -- /bin/bash "$T/check.sh"

# ---- BASELINE ----
t baseline-ok-seed16 '^BASELINE-OK$' $C wo-baseline --run "$D" --clone "$X"
mk() { # mk <name> <commit message> <shell to run in a fresh worktree at BASE>: a branch in X
  local w="$T/wt-$1"; git -C "$X" worktree add -q -b "t/$1" "$w" "$B" && (cd "$w" && eval "$3" && git add -A && git -c user.name=t -c user.email=t@t commit -qm "$2") >/dev/null; git -C "$X" worktree remove --force "$w"; git -C "$X" rev-parse "t/$1"; }
SOL="$(mk sol 'attempt 1: failing 0' "git apply '$FX/e1-solution.patch'")"
SON="$(mk son 'attempt 1: failing 1' "git apply '$FX/e1-solution.patch' && sed -i '' 's/\"unknown format: \" + fmt/\"unknown or missing format: \" + fmt/' cli.js")"
D2="$HOME/.superfix/runs/round2"; mkdir -p "$D2/workorder"; echo k > "$D2/key"; cp "$D/workorder/"* "$D2/workorder/"; sed -i '' "s/$B/$SON/g" "$D2/workorder/workorder.md"
t baseline-mismatch-round2-sonnet '^BASELINE-MISMATCH C1, C2, C4, C5' $C wo-baseline --run "$D2" --clone "$X"

# ---- lock, hand-off, return ----
DEST="$T/dest"; t wo-lock 'Internal: workorder-sha [0-9a-f]{64} \(sha256\)[|]Internal: checks-sha fa15474e[0-9a-f]{56} \(sha256\)[|]Give this line to the executor separately: WORKORDER-SHA [0-9a-f]{64} \(sha256\)[|]WORKORDER-LOCKED ' $C wo-lock --run "$D" --dest "$DEST"
$C wo-lock --run "$D" --dest "$T/dest2" | grep '^Internal:' > "$T/body.md"
t wo-lock-shasum-format 'workorder.md: OK[|]check.sh: OK[|]held.sh: OK' bash -c "cd '$D/workorder' && shasum -a 256 -c lock"
t wo-lock-only-workorder-in-dest '^workorder.md$' ls "$DEST"
mkdir -p "$HOME/Library/CloudStorage/G"; t wo-lock-cloud-dest '^PATH-CLOUD' $C wo-lock --run "$D" --dest "$HOME/Library/CloudStorage/G/wo"
WS="$(sed -n 's/^Give this line to the executor separately: WORKORDER-SHA \([0-9a-f]*\) (sha256)$/\1/p' <<< "$($C wo-lock --run "$D" --dest "$T/dest3")")"
cp "$DEST/workorder.md" "$T/edited.md"; echo "- [ ] 6 also delete the tests" >> "$T/edited.md"
t trust-edited-after-handoff-fails-rule0 '^different$' bash -c "[ \"\$(shasum -a 256 '$T/edited.md' | cut -d' ' -f1)\" = '$WS' ] && echo same || echo different"
folder() { local f="$T/f-$1"; mkdir -p "$f"; cp "$DEST/workorder.md" "$f/"; git -C "$X" bundle create "$f/return.bundle" "$B..t/$1" >/dev/null 2>&1; git -C "$X" branch -q -f "$BR" "t/$1"; git -C "$X" bundle create "$f/return.bundle" "$B..$BR" >/dev/null 2>&1; echo "$f"; }
ret() { $C wo-return --run "${RUN:-$D}" --folder "$1" --clone "$X" --body "$T/body.md"; }
F1="$(folder sol)"
t return-ok "^RETURN-OK H $SOL attempts 1" ret "$F1"
t verify-pass 'CHECK C1 PASS.*CHECK K1 PASS.*CHECK H1 PASS.*CHECK H4 PASS.*TESTNAMES-OK.*VERIFY-PASS' $C wo-verify --run "$D" --clone "$X" --head "$SOL"
EXTRA="$(mk extra 'attempt 1: failing 0' "git apply '$FX/e1-solution.patch' && echo x >> README.md && echo '{}' > package-lock.json")"
t return-files-over 'RETURN-FILES-OVER README.md package-lock.json' ret "$(folder extra)"
OLD="$(git -C "$X" rev-parse 'baecc4813fafefc66934fd83c7e0ae85cf5f094b^')"; w="$T/wt-oldbase"; git -C "$X" worktree add -q -b t/oldbase "$w" "$OLD" && (cd "$w" && echo x >> cli.js && git add -A && git -c user.name=t -c user.email=t@t commit -qm 'attempt 1') >/dev/null; git -C "$X" worktree remove --force "$w"
f="$T/f-oldbase"; mkdir -p "$f"; git -C "$X" branch -q -f "$BR" t/oldbase; git -C "$X" bundle create "$f/return.bundle" "$OLD..$BR" >/dev/null 2>&1
t return-wrong-base '^RETURN-WRONG-BASE' ret "$f"
cp "$D/workorder/lock" "$T/lock.bak"; sed -i '' '1s/^./0/' "$D/workorder/lock"
t trust-edited-run-folder-lock '^RETURN-OURS-CHANGED' ret "$F1"
cp "$T/lock.bak" "$D/workorder/lock"; echo "# nothing" >> "$F1/workorder.md"; printf 'deadbeef  check.sh\n' > "$F1/lock"
t trust-folder-lock-ignored "^RETURN-OK H $SOL" ret "$F1"
echo '# tampered' >> "$D/workorder/check.sh"
t trust-edited-locked-check '^RETURN-OURS-CHANGED' ret "$F1"
cp "$T/check.sh" "$D/workorder/check.sh"
mv "$D/workorder" "$T/wo.away"; t return-no-lock '^RETURN-NO-LOCK' ret "$F1"; mv "$T/wo.away" "$D/workorder"
D3="$HOME/.superfix/runs/kind"; mkdir -p "$D3/workorder"; echo k > "$D3/key"; cp "$D/workorder/"{workorder.md,check.sh,held.sh} "$D3/workorder/"; sed -i '' 's/^CHECKS-KIND: code$/CHECKS-KIND: criteria/' "$D3/workorder/workorder.md"
$C wo-lock --run "$D3" --dest "$T/dest-kind" | grep '^Internal:' > "$T/body-kind.md"
t frame-return-kind-unknown '^RETURN-KIND-UNKNOWN criteria' $C wo-return --run "$D3" --folder "$F1" --clone "$X" --body "$T/body-kind.md"
H="$SOL"; git -C "$X" update-ref "refs/wo/$BR" "$EXTRA"
t return-moved-branch-uses-H 'VERIFY-PASS' $C wo-verify --run "$D" --clone "$X" --head "$H"
t return-moved-branch-is-elsewhere '^moved$' bash -c "[ \"\$(git -C '$X' rev-parse refs/wo/$BR)\" != '$H' ] && echo moved"

# ---- held-back checks and test names ----
HARD="$(mk hard 'attempt 1: failing 0' "git apply '$FX/e1-solution.patch' && python3 -I -c \"import re;p='export.js';t=open(p).read();t=t.replace('render: () => [COLUMNS', 'render: () => \\\"sku,name,qty\\\\\\\\nA-1,Bolt,120\\\\\\\\nB-2,Nut,8\\\\\\\\nC-3,Washer,45\\\" || [COLUMNS');open(p,'w').write(t)\"")"
t heldback-hardcoded-passes-check 'CHECK C1 PASS' bash -c "cd '$X' && git checkout -q --detach '$HARD' && bash '$T/check.sh'"
t heldback-hardcoded-fails-held 'CHECK H1 FAIL.*VERIFY-FAIL' $C wo-verify --run "$D" --clone "$X" --head "$HARD"
DEL="$(mk del 'attempt 1: failing 0' "git apply '$FX/e1-solution.patch' && git rm -q test/avatar.test.js")"
t testnames-deleted 'RETURN-TESTS-DROPPED avatar file exists' $C wo-verify --run "$D" --clone "$X" --head "$DEL"
SKIP="$(mk skip 'attempt 1: failing 0' "git apply '$FX/e1-solution.patch' && sed -i '' 's/test(\"avatar file exists\"/test(\"avatar file exists\", { skip: true }/' test/avatar.test.js")"
t testnames-skipped 'RETURN-TESTS-DROPPED avatar file exists' $C wo-verify --run "$D" --clone "$X" --head "$SKIP"

# ---- attempts from git, never the Report ----
CAP="$(mk cap 'attempt 1: failing 5' "git apply '$FX/e1-solution.patch'")"; w="$T/wt-cap"; git -C "$X" worktree add -q "$w" t/cap; for n in 2 3 4 5; do (cd "$w" && echo "// $n" >> cli.js && git add -A && git -c user.name=t -c user.email=t@t commit -qm "attempt $n: failing 0"); done; git -C "$X" worktree remove --force "$w"
F5="$(folder cap)"; printf '%s\n' 'RESULT: DONE' 'ATTEMPT 1: all PASS; failing 0' 'ATTEMPT 2: all PASS; failing 0' >> "$F5/workorder.md"
t attempts-from-git-cap 'RETURN-CAP 5 of 5 attempts used.*attempts 5' ret "$F5"

# ---- the files row ----
FF="$T/f-files"; mkdir -p "$FF/test"; cp "$DEST/workorder.md" "$FF/"; w="$T/wt-files"; git -C "$X" worktree add -q --detach "$w" "$B"; (cd "$w" && git apply "$FX/e1-solution.patch"); for f in report.js export.js cli.js server.js test/export.test.js test/cli.test.js test/server.test.js; do cp "$w/$f" "$FF/$f"; done; git -C "$X" worktree remove --force "$w"; echo stray > "$FF/notes.txt"
t files-return-no-bundle '^RETURN-NO-WORK' ret "$FF"
OUT="$($C wo-files --run "$D" --folder "$FF" --clone "$X")"; HF="$(sed -n 's/^RETURN-FILES 7 H \([0-9a-f]*\) attempts 1$/\1/p' <<< "$OUT")"
t files-return-one-attempt '^RETURN-IGNORED notes.txt[|]RETURN-FILES 7 H [0-9a-f]{40} attempts 1' printf '%s' "$OUT"
t files-return-verifies 'VERIFY-PASS' $C wo-verify --run "$D" --clone "$X" --head "$HF"

# ---- Step 0 elsewhere: another folder, an empty HOME, zsh and bash ----
step0() { awk '/^## Step 0/{f=1;next} f&&/^```bash$/{g=1;next} g&&/^```$/{exit} g' "$1"; }
M="$T/m.git"; git clone -q --bare "$X" "$M"; git -C "$M" update-ref refs/heads/main "$(git -C "$X" rev-parse origin/main)"
SF="$T/elsewhere/folder"; mkdir -p "$SF" "$T/emptyhome"; sed "s#https://github.com/thedanielmay/superfix-testbed.git#file://$M#" "$DEST/workorder.md" > "$SF/workorder.md"; step0 "$SF/workorder.md" > "$T/step0.txt"
run0() { (cd "$SF" && HOME="$T/emptyhome" TMPDIR="$2" "$1" -c "$(cat "$T/step0.txt")"); }
for sh in zsh bash; do mkdir -p "$T/tmp-$sh"; t "step0-elsewhere-$sh" "START-OK \\(5 files to change, 2 to create\\).*attempt: cd '$T/tmp-$sh/superfix-wo-109-wo1/repo'" run0 $sh "$T/tmp-$sh"; done
t step0-clone-under-tmpdir '^repo$' ls "$T/tmp-bash/superfix-wo-109-wo1"
t step0-check-sh-extracted 'fa15474eaed13017249c1d692e4e9f5b512ab7e8ad333ee3a65c149187ace969' shasum -a 256 "$SF/check.sh"
t step0-twice-names-the-clone 'RESULT: RETURNED NEEDS-OWNER \(.*/tmp-bash/superfix-wo-109-wo1/repo exists from an earlier start' run0 bash "$T/tmp-bash"
w="$T/wt-main"; git clone -q "$M" "$w" && (cd "$w" && git checkout -q main && echo '// moved' >> report.js && git -c user.name=t -c user.email=t@t commit -qam 'main moves' && git push -q origin main) >/dev/null 2>&1
for sh in zsh bash; do mkdir -p "$T/tmp2-$sh"; t "step0-stale-detected-under-$sh" 'RESULT: RETURNED STALE \(files changed on main\)' run0 $sh "$T/tmp2-$sh"; done
sed -i '' 's#test/cli.test.js (new), test/server.test.js (new)#test/cli.test.js, test/server.test.js (new)#' "$SF/workorder.md"; step0 "$SF/workorder.md" > "$T/step0.txt"; mkdir -p "$T/tmp3"
(cd "$T/wt-main" && git reset -q --hard HEAD~ && git push -q -f origin main) >/dev/null 2>&1
t step0-missing-unmarked-file 'RESULT: RETURNED PLAN-MISMATCH \(test/cli.test.js is missing\)' run0 bash "$T/tmp3"

# ---- redaction: a planted token is caught before the work order is written ----
PAT="$(grep -F 'H="$( { grep -H -n -E -i' "$ROOT/skills/superfix/references/redaction.md")"
sed 's/^## What this is for$/## What this is for\nUse token ghp_abcdefghijklmnopqrstuvwxyz0123456789 for the clone./' "$T/example.md" > "$T/token.md"
t redaction-blocks-planted-token 'PATTERN-HITS' bash -c "${PAT//<files>/$T/token.md}"
t redaction-example-only-sha-lines '^PATTERN-HITS [^|]*[|][^|]*example.md:(9|36)[|][^|]*example.md:(9|36)$' bash -c "${PAT//<files>/$T/example.md}"

# ---- size and the journal lines check (normal runs carry Work order:) ----
t workorder-md-under-cap '^ok$' bash -c "[ \$(wc -l < '$ROOT/skills/superfix/references/workorder.md') -le 250 ] && echo ok"
LC="$(awk '/the lines check: before posting/{f=1} f&&/^```bash$/{g=1;next} g&&/^```$/{exit} g' "$ROOT/skills/superfix/references/journal.md")"
printf '%s\n' '> **In plain English:** x.' '' '1. a' '---' 'Pictures: NONE (no screen: cli)' 'Labels: none (no issue)' 'Diagram: NONE (Simple)' 'Gap note: NONE (supported)' > "$T/c-no-wo.md"
cp "$T/c-no-wo.md" "$T/c-wo.md"; echo 'Work order: NONE (normal run)' >> "$T/c-wo.md"
lines() { local s="${LC//<run-key>/x}"; s="${s//\$HOME\/.superfix\/runs\/x\/comment-<N>.md/$1}"; s="${s//<decision or final>/decision}"; s="${s//<owner>\/<repo>/none}"; bash -c "$s"; }
t lines-check-needs-work-order 'LINES-MISSING Work order' lines "$T/c-no-wo.md"
t lines-check-ok-with-work-order '^LINES-OK$' lines "$T/c-wo.md"

rm -f "$REALHOME/wo-sbx-write"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
