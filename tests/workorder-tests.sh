#!/bin/bash
# Free tests for 1.6.0 work orders (references/workorder.md and crit.py's wo-* and sandbox commands).
# No model runs. Runs under a throwaway HOME. Needs: git, node 24, zsh, /usr/bin/sandbox-exec, and a clone of
# the private testbed (TESTBED=<path to a clone>, default: cloned from GitHub with your own git login).
# Usage: bash tests/workorder-tests.sh   (prints one line per test, then "RESULT: <n> passed, <m> failed")
# ROOT=<another checkout> runs these tests against that checkout's files (used to show a test fails before its fix).
ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"; FX="$(cd "$(dirname "$0")" && pwd)/fixtures/workorder"
T="$(mktemp -d /private/tmp/wo-tests.XXXX)"; REALHOME="$HOME"
B=baecc4813fafefc66934fd83c7e0ae85cf5f094b; BR=wo/109-csv-json-export
X="$T/x"; if [ -n "$TESTBED" ]; then git clone -q "$TESTBED" "$X"; else git clone -q https://github.com/thedanielmay/superfix-testbed.git "$X"; fi || { echo "CANNOT RUN: no testbed clone"; exit 2; }
git -C "$X" fetch -q --tags origin 2>/dev/null
# X's origin becomes a local copy: wo-return asks origin for a pushed branch, and the fake HOME below has no git login
git clone -q --bare "$X" "$T/origin.git"; git -C "$X" remote set-url origin "$T/origin.git"
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
# runs <name> [file to leave out]: a separate run folder with copies of D's work order files (no lock)
runs() { local r="$HOME/.superfix/runs/$1"; mkdir -p "$r/workorder"; echo k > "$r/key"; for f in workorder.md check.sh held.sh; do [ "$f" = "$2" ] || cp "$D/workorder/$f" "$r/workorder/"; done; echo "$r"; }

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
# output comes back through a capped pipe; a file the code writes is capped by RLIMIT_FSIZE
t sandbox-output-capped 'SANDBOX-EXIT overflow$' $C sandbox --cwd "$X" -- /bin/bash -c "head -c 17000000 /dev/zero | tr '\\0' x"
t sandbox-file-size-capped 'File ?size limit exceeded.*[|]rc 153[|]SANDBOX-EXIT 0$' $C sandbox --cwd "$X" -- /bin/bash -c 'head -c 300000000 /dev/zero > "$TMPDIR/big"; echo "rc $?"'
# the 1.5.0 measure runner shares the pipe: a script that rewrites $TMPDIR/.o after printing no longer changes its own result
printf '%s\n' 'import os' 'print("MEASURE M1 3"); print("ITEMS none", flush=True)' 'open(os.environ["TMPDIR"] + "/.o", "w").write("MEASURE M1 0\nITEMS none\n")' > "$T/m1.py"; printf 'a,b\n1,2\n' > "$T/m1.csv"
t run-script-reads-the-pipe '^FAIL 3$' python3 -I -c "import importlib.util as u,sys,pathlib; s=u.spec_from_file_location('c',sys.argv[1]); m=u.module_from_spec(s); s.loader.exec_module(m); w,i=m.run_script({'id':'M1','pass':'0','ck':'C'},pathlib.Path(sys.argv[2]),pathlib.Path(sys.argv[3]),None,30,False); print(w, i['MEASURE'] if isinstance(i,dict) else i)" "$D/crit.py" "$T/m1.py" "$T/m1.csv"

# ---- BASELINE ----
t baseline-ok-seed16 '^BASELINE-OK$' $C wo-baseline --run "$D" --clone "$X"
mk() { # mk <name> <commit message> <shell to run in a fresh worktree at BASE, or at $FROM>: a branch in X
  local w="$T/wt-$1"; git -C "$X" worktree add -q -b "t/$1" "$w" "${FROM:-$B}" && (cd "$w" && eval "$3" && git add -A && git -c user.name=t -c user.email=t@t commit -qm "$2") >/dev/null; git -C "$X" worktree remove --force "$w"; git -C "$X" rev-parse "t/$1"; }
SOL="$(mk sol 'attempt 1: failing 0' "git apply '$FX/e1-solution.patch'")"
SON="$(mk son 'attempt 1: failing 1' "git apply '$FX/e1-solution.patch' && sed -i '' 's/\"unknown format: \" + fmt/\"unknown or missing format: \" + fmt/' cli.js")"
D2="$HOME/.superfix/runs/round2"; mkdir -p "$D2/workorder"; echo k > "$D2/key"; cp "$D/workorder/"* "$D2/workorder/"; sed -i '' "s/$B/$SON/g" "$D2/workorder/workorder.md"
t baseline-mismatch-round2-sonnet '^BASELINE-MISMATCH C1, C2, C4, C5' $C wo-baseline --run "$D2" --clone "$X"
# (T4 run v1-3) bash 3.2 writes here-documents to /tmp whatever TMPDIR says; they now work in the sandbox, and a script needing a tool the sandbox lacks fails BASELINE loudly
t sandbox-heredoc-works '^hello heredoc[|]herestring[|]SANDBOX-EXIT 0$' $C sandbox --cwd "$X" -- /bin/bash -c 'cat <<EOF
hello heredoc
EOF
x="$(cat <<<herestring)"; echo "$x"'
DT="$(runs toolless)"; echo 'd="$(mktemp -d)"; r H5 1 "a temp folder" "$d"' >> "$DT/workorder/held.sh"
t baseline-sandbox-refused-tool 'BASELINE-MISMATCH .*sandbox refused mktemp' $C wo-baseline --run "$DT" --clone "$X"

# ---- lock, hand-off ----
DEST="$T/dest"; LOCKOUT="$($C wo-lock --run "$D" --dest "$DEST" --clone "$X")"
t wo-lock 'WORKORDER-OK[|]BASELINE-OK[|]Internal: workorder-sha [0-9a-f]{64} \(sha256\)[|]Internal: checks-sha fa15474e[0-9a-f]{56} \(sha256\)[|]Give this line to the executor separately: WORKORDER-SHA [0-9a-f]{64} \(sha256\)[|]WORKORDER-LOCKED ' printf '%s' "$LOCKOUT"
grep '^Internal:' <<< "$LOCKOUT" > "$T/body.md"; WS="$(sed -n 's/^Give this line to the executor separately: WORKORDER-SHA \([0-9a-f]*\) (sha256)$/\1/p' <<< "$LOCKOUT")"
t wo-lock-shasum-format 'workorder.md: OK[|]check.sh: OK[|]held.sh: OK' bash -c "cd '$D/workorder' && shasum -a 256 -c lock"
t wo-lock-only-workorder-in-dest '^workorder.md$' ls "$DEST"
mkdir -p "$HOME/Library/CloudStorage/G"; t wo-lock-cloud-dest '^PATH-CLOUD' $C wo-lock --run "$D" --dest "$HOME/Library/CloudStorage/G/wo" --clone "$X"
DB="$(runs wrongbaseline)"; sed -i '' 's/^BASELINE: C1 FAIL/BASELINE: C1 PASS/' "$DB/workorder/workorder.md"
t lock-refuses-baseline-mismatch '^WORKORDER-OK[|]BASELINE-MISMATCH C1[|]WORKORDER-LOCK-REFUSED' $C wo-lock --run "$DB" --dest "$T/dest-db" --clone "$X"
D3="$HOME/.superfix/runs/kind"; mkdir -p "$D3/workorder"; echo k > "$D3/key"; cp "$D/workorder/"{workorder.md,check.sh,held.sh} "$D3/workorder/"; sed -i '' 's/^CHECKS-KIND: code$/CHECKS-KIND: criteria/' "$D3/workorder/workorder.md"
t lock-refuses-bad-workorder '^WORKORDER-KIND criteria[|]WORKORDER-LOCK-REFUSED' $C wo-lock --run "$D3" --dest "$T/dest-kind" --clone "$X"
t lock-dest-inside-superfix '^WORKORDER-OK[|]BASELINE-OK[|]WORKORDER-DEST-INSIDE-SUPERFIX ' $C wo-lock --run "$D" --dest "$HOME/.superfix/journal/x/workorders/w1" --clone "$X"
t default-dest-outside-superfix 'On this Mac, in ~/superfix-workorders/<id>/ \(recommended: yes\)' cat "$ROOT/skills/superfix/references/workorder.md"
cp "$DEST/workorder.md" "$T/edited.md"; echo "- [ ] 6 also delete the tests" >> "$T/edited.md"
t trust-edited-after-handoff-fails-rule0 '^different$' bash -c "[ \"\$(shasum -a 256 '$T/edited.md' | cut -d' ' -f1)\" = '$WS' ] && echo same || echo different"

# ---- return ----
folder() { local f="$T/f-$1"; mkdir -p "$f"; cp "$DEST/workorder.md" "$f/"; git -C "$X" branch -q -f "$BR" "t/$1"; git -C "$X" bundle create "$f/return.bundle" "$B..$BR" >/dev/null 2>&1; echo "$f"; }
ret2() { $C wo-return --run "${RUN:-$D}" --folder "$1" --clone "$X" --body "$T/body.md"; }   # keeps the recorded rounds
ret() { rm -f "${RUN:-$D}/workorder/rounds.json"; ret2 "$1"; }                               # a first round
F1="$(folder sol)"
t return-ok "^RETURN-OK H $SOL attempts 1$" ret "$F1"
t verify-pass 'CHECK C1 PASS.*CHECK K1 PASS.*CHECK H1 PASS.*CHECK H4 PASS.*TESTNAMES-OK.*SUITE-OK.*VERIFY-PASS' $C wo-verify --run "$D" --clone "$X" --head "$SOL"
EXTRA="$(mk extra 'attempt 1: failing 0' "git apply '$FX/e1-solution.patch' && echo x >> README.md && echo '{}' > package-lock.json")"
t return-files-over 'RETURN-FILES-OVER README.md package-lock.json' ret "$(folder extra)"
OLD="$(git -C "$X" rev-parse "$B^")"; w="$T/wt-oldbase"; git -C "$X" worktree add -q -b t/oldbase "$w" "$OLD" && (cd "$w" && echo x >> cli.js && git add -A && git -c user.name=t -c user.email=t@t commit -qm 'attempt 1') >/dev/null; git -C "$X" worktree remove --force "$w"
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
(cd "$D3/workorder" && shasum -a 256 workorder.md check.sh held.sh > lock); printf 'Internal: workorder-sha %s (sha256)\nInternal: checks-sha %s (sha256)\n' "$(shasum -a 256 "$D3/workorder/workorder.md" | cut -d' ' -f1)" "$(shasum -a 256 "$D3/workorder/check.sh" | cut -d' ' -f1)" > "$T/body-kind.md"
t frame-return-kind-unknown '^RETURN-KIND-UNKNOWN criteria' $C wo-return --run "$D3" --folder "$F1" --clone "$X" --body "$T/body-kind.md"
H="$SOL"; git -C "$X" update-ref "refs/wo/$BR" "$EXTRA"
t return-moved-branch-uses-H 'VERIFY-PASS' $C wo-verify --run "$D" --clone "$X" --head "$H"
t return-moved-branch-is-elsewhere '^moved$' bash -c "[ \"\$(git -C '$X' rev-parse refs/wo/$BR)\" != '$H' ] && echo moved"
# a link anywhere in the returned folder stops the return before anything is read
echo "SECRET-ON-THIS-MAC" > "$T/secret"; FLK="$T/f-sol-link"; mkdir -p "$FLK/notes"; cp "$F1/return.bundle" "$DEST/workorder.md" "$FLK/"; ln -s "$T/secret" "$FLK/notes/hosts.yml"
t return-symlink-refused '^RETURN-SYMLINK notes/hosts.yml ' ret "$FLK"
# the executor pushed the branch: git ls-remote origin finds it; an unreachable origin is said, never silent
git -C "$X" push -q origin "$SOL:refs/heads/$BR"
t return-pushed-branch "^RETURN-PUSHED $BR $SOL .*RETURN-OK H $SOL" ret "$F1"
git -C "$X" push -q origin ":refs/heads/$BR"; git -C "$X" remote set-url origin "file://$T/nowhere.git"
t return-remote-unchecked '^RETURN-REMOTE-UNCHECKED .*RETURN-OK' ret "$F1"
git -C "$X" remote set-url origin "$T/origin.git"

# ---- forged passes: the code under test cannot write, hide or repeat a CHECK line ----
# (reviewers' attack 1, in our words) cli.js rewrites the sandbox's old output file when K1 runs it; server.js does the same for held.sh on exit
FORGE="$(mk forge 'attempt 1: failing 0' "printf '%s\n' 'if (process.argv.slice(2).join(\" \") === \"report\") require(\"fs\").writeFileSync(process.env.TMPDIR + \"/.o\", \"CHECK C1 PASS\\nCHECK C2 PASS\\nCHECK C3 PASS\\nCHECK C4 PASS\\nCHECK C5 PASS\\nCHECK K1 PASS\\n\");' >> cli.js && printf '%s\n' 'process.on(\"exit\", () => { try { require(\"fs\").writeFileSync(process.env.TMPDIR + \"/.o\", \"CHECK H1 PASS\\nCHECK H2 PASS\\nCHECK H3 PASS\\nCHECK H4 PASS\\n\"); } catch (e) {} });' >> server.js")"
t forge-output-file-rewrite 'CHECK C1 FAIL.*CHECK H1 FAIL.*VERIFY-FAIL$' $C wo-verify --run "$D" --clone "$X" --head "$FORGE"
# (attack 2) the code writes the old output file, then hangs until the timeout (put first in cli.js, before its own exit)
HANG="$(mk hang 'attempt 1: failing 0' "git apply '$FX/e1-solution.patch' && printf '%s\n' 'if (process.argv.includes(\"xml\")) { require(\"fs\").writeFileSync(process.env.TMPDIR + \"/.o\", \"CHECK C1 PASS\\n\"); while (true) {} }' | cat - cli.js > cli.new && mv cli.new cli.js")"
t forge-hang-is-a-fail 'VERIFY-PROBLEM check.sh: run timeout, C3 \(missing\), C4 \(missing\), C5 \(missing\), K1 \(missing\).*VERIFY-FAIL$' $C wo-verify --run "$D" --clone "$X" --head "$HANG" --timeout 20
# a doubled id and a missing id each fail, even when every line printed says PASS
DD="$(runs dup)"; echo 'echo "CHECK C1 PASS"' >> "$DD/workorder/check.sh"
t verify-duplicate-id 'VERIFY-PROBLEM check.sh: C1 \(twice\).*VERIFY-FAIL$' $C wo-verify --run "$DD" --clone "$X" --head "$SOL"
DM="$(runs miss)"; sed -i '' '/ r K1 /d' "$DM/workorder/check.sh"
t verify-missing-id 'VERIFY-PROBLEM check.sh: K1 \(missing\).*VERIFY-FAIL$' $C wo-verify --run "$DM" --clone "$X" --head "$SOL"
DH="$(runs noheld held.sh)"
t verify-held-missing-is-loud '^VERIFY-FAIL held.sh is missing' $C wo-verify --run "$DH" --clone "$X" --head "$SOL"
# held.sh goes in as text, so the code under test cannot read it (H3 compares stderr, where cli.js would print HELD-READ)
LEAK="$(mk leak 'attempt 1: failing 0' "git apply '$FX/e1-solution.patch' && printf '%s\n' 'try { require(\"fs\").readFileSync(\"$D/workorder/held.sh\"); console.error(\"HELD-READ\"); } catch (e) {}' | cat - cli.js > cli.new && mv cli.new cli.js")"
t held-unreadable-by-code 'CHECK H3 PASS.*VERIFY-PASS' $C wo-verify --run "$D" --clone "$X" --head "$LEAK"

# ---- held-back checks, test names and the suite ----
HARD="$(mk hard 'attempt 1: failing 0' "git apply '$FX/e1-solution.patch' && python3 -I -c \"import re;p='export.js';t=open(p).read();t=t.replace('render: () => [COLUMNS', 'render: () => \\\"sku,name,qty\\\\\\\\nA-1,Bolt,120\\\\\\\\nB-2,Nut,8\\\\\\\\nC-3,Washer,45\\\" || [COLUMNS');open(p,'w').write(t)\"")"
t heldback-hardcoded-passes-check 'CHECK C1 PASS' bash -c "cd '$X' && git checkout -q --detach '$HARD' && bash '$T/check.sh'"
t heldback-hardcoded-fails-held 'CHECK H1 FAIL.*VERIFY-FAIL' $C wo-verify --run "$D" --clone "$X" --head "$HARD"
DEL="$(mk del 'attempt 1: failing 0' "git apply '$FX/e1-solution.patch' && git rm -q test/avatar.test.js")"
t testnames-deleted 'RETURN-TESTS-DROPPED avatar file exists' $C wo-verify --run "$D" --clone "$X" --head "$DEL"
SKIP="$(mk skip 'attempt 1: failing 0' "git apply '$FX/e1-solution.patch' && sed -i '' 's/test(\"avatar file exists\"/test(\"avatar file exists\", { skip: true }/' test/avatar.test.js")"
t testnames-skipped 'RETURN-TESTS-DROPPED avatar file exists' $C wo-verify --run "$D" --clone "$X" --head "$SKIP"
WRAP="$(mk wrap 'attempt 1: failing 0' "git apply '$FX/e1-solution.patch' && sed -i '' 's/^test(\"avatar file exists\"/test.describe(\"avatar\", () => { test(\"avatar file exists\"/' test/avatar.test.js && echo '});' >> test/avatar.test.js")"
t testnames-inside-describe 'TESTNAMES-OK' $C wo-verify --run "$D" --clone "$X" --head "$WRAP"
NEWF="$(mk newf 'attempt 1: failing 0' "git apply '$FX/e1-solution.patch' && echo 'test(\"a new test that fails\", () => { assert.fail(\"no\"); });' >> test/export.test.js")"
t suite-new-failure 'SUITE-NEW-FAILURES a new test that fails.*VERIFY-FAIL$' $C wo-verify --run "$D" --clone "$X" --head "$NEWF"

# ---- solved check runs 1 and 3, in the sandbox ----
t solved-runs-1-and-3 '^SOLVED-OK' $C wo-solved --run "$D" --clone "$X" --head "$SOL"
TH="$(mk testhang 'attempt 1: failing 0' "git apply '$FX/e1-solution.patch' && echo 'setInterval(() => {}, 1000);' >> test/cli.test.js")"
t solved-crash-is-not-a-fail '^SOLVED-RUN1-BROKEN run timeout' $C wo-solved --run "$D" --clone "$X" --head "$TH" --timeout 20

# ---- attempts from git, never the Report ----
CAP="$(mk cap 'attempt 1: failing 5' "git apply '$FX/e1-solution.patch'")"; w="$T/wt-cap"; git -C "$X" worktree add -q "$w" t/cap; for n in 2 3 4 5; do (cd "$w" && echo "// $n" >> cli.js && git add -A && git -c user.name=t -c user.email=t@t commit -qm "attempt $n: failing 0"); done; git -C "$X" worktree remove --force "$w"
F5="$(folder cap)"; printf '%s\n' 'RESULT: DONE' 'ATTEMPT 1: all PASS; failing 0' 'ATTEMPT 2: all PASS; failing 0' >> "$F5/report.md"
t attempts-from-git-cap 'RETURN-CAP 5 of 5 attempts used \(no send-back left\).*attempts 5' ret "$F5"
CAP6="$(FROM=t/cap mk cap6 'attempt 6: failing 0' "echo '// 6' >> cli.js")"
t attempts-over-cap-stops '^RETURN-CAP 6 of 5 attempts used \(over the limit: stop\)$' ret "$(folder cap6)"

# ---- the files row ----
files() { $C wo-files --run "$D" --folder "$1" --clone "$X" --body "$T/body.md"; }
FF="$T/f-files"; mkdir -p "$FF/test"; cp "$DEST/workorder.md" "$FF/"; w="$T/wt-files"; git -C "$X" worktree add -q --detach "$w" "$B"; (cd "$w" && git apply "$FX/e1-solution.patch"); for f in report.js export.js cli.js server.js test/export.test.js test/cli.test.js test/server.test.js; do cp "$w/$f" "$FF/$f"; done; git -C "$X" worktree remove --force "$w"; echo stray > "$FF/notes.txt"
t files-return-no-bundle '^RETURN-NO-WORK' ret "$FF"
rm -f "$D/workorder/rounds.json"; OUT="$(files "$FF")"; HF="$(sed -n 's/^RETURN-FILES 7 H \([0-9a-f]*\) attempts 1$/\1/p' <<< "$OUT")"
t files-return-one-attempt '^RETURN-IGNORED notes.txt[|]RETURN-FILES 7 H [0-9a-f]{40} attempts 1' printf '%s' "$OUT"
t files-return-verifies 'VERIFY-PASS' $C wo-verify --run "$D" --clone "$X" --head "$HF"
# (reviewers' attack 3, in our words) a returned report.js that is a link to a file on this Mac is refused, never committed
FS="$T/f-symlink"; mkdir -p "$FS"; cp "$DEST/workorder.md" "$FS/"; ln -s "$T/secret" "$FS/report.js"
t files-symlink-refused '^RETURN-SYMLINK report.js ' files "$FS"
FHL="$T/f-hardlink"; mkdir -p "$FHL"; cp "$DEST/workorder.md" "$FHL/"; ln "$T/secret" "$FHL/report.js"
t files-hardlink-refused '^RETURN-SYMLINK report.js ' files "$FHL"
t files-secret-never-committed '^none$' bash -c "git -C '$X' log --all -p | grep -q SECRET-ON-THIS-MAC && echo found || echo none"
sed -i '' '1s/^./0/' "$D/workorder/lock"; t files-runs-shared-steps '^RETURN-OURS-CHANGED' files "$FF"; cp "$T/lock.bak" "$D/workorder/lock"

# ---- Step 0 elsewhere: another folder, an empty HOME, zsh and bash ----
step0() { awk '/^## Step 0/{f=1;next} f&&/^```bash$/{g=1;next} g&&/^```$/{exit} g' "$1"; }
M="$T/m.git"; git clone -q --bare "$X" "$M"; git -C "$M" update-ref refs/heads/main "$(git -C "$X" rev-parse origin/main)"
SF="$T/elsewhere/folder"; mkdir -p "$SF" "$T/emptyhome"; sed "s#https://github.com/thedanielmay/superfix-testbed.git#file://$M#" "$DEST/workorder.md" > "$SF/workorder.md"; step0 "$SF/workorder.md" > "$T/step0.txt"
run0() { (cd "${3:-$SF}" && HOME="$T/emptyhome" TMPDIR="$2" "$1" -c "$(cat "$T/step0.txt")"); }
for sh in zsh bash; do mkdir -p "$T/tmp-$sh"; t "step0-elsewhere-$sh" "START-OK \\(5 files to change, 2 to create\\).*attempt: cd $T/tmp-$sh/superfix-wo-109-wo1\\.[A-Za-z0-9]{6}/repo" run0 $sh "$T/tmp-$sh"; done
t step0-clone-under-tmpdir '^superfix-wo-109-wo1\.[A-Za-z0-9]{6}$' ls "$T/tmp-bash"
t step0-check-sh-extracted 'fa15474eaed13017249c1d692e4e9f5b512ab7e8ad333ee3a65c149187ace969' shasum -a 256 "$SF/check.sh"
t step0-twice-fresh-clone 'START-OK' run0 bash "$T/tmp-bash"
t step0-twice-two-clones '^2$' bash -c "ls '$T/tmp-bash' | wc -l | tr -d ' '"
# a folder and a TMPDIR with a space and an apostrophe: the printed commands still run when pasted, in zsh and bash
for sh in zsh bash; do Q="$T/it's a $sh folder"; mkdir -p "$Q" "$T/tmp '$sh' dir"; cp "$SF/workorder.md" "$Q/"; A="$(run0 $sh "$T/tmp '$sh' dir" "$Q" | sed -n 's/^  attempt: //p')"
  t "step0-quoted-paths-$sh" 'CHECK C1 FAIL.*CHECK K1 PASS' $sh -c "$A"; done
w="$T/wt-main"; git clone -q "$M" "$w" && (cd "$w" && git checkout -q main && echo '// moved' >> report.js && git -c user.name=t -c user.email=t@t commit -qam 'main moves' && git push -q origin main) >/dev/null 2>&1
for sh in zsh bash; do mkdir -p "$T/tmp2-$sh"; t "step0-stale-detected-under-$sh" 'RESULT: RETURNED STALE \(files changed on main\)' run0 $sh "$T/tmp2-$sh"; done
cp "$SF/workorder.md" "$T/sf.bak"; sed -i '' 's#test/cli.test.js (new), test/server.test.js (new)#test/cli.test.js, test/server.test.js (new)#' "$SF/workorder.md"; step0 "$SF/workorder.md" > "$T/step0.txt"; mkdir -p "$T/tmp3"
(cd "$T/wt-main" && git reset -q --hard HEAD~ && git push -q -f origin main) >/dev/null 2>&1
t step0-missing-unmarked-file 'RESULT: RETURNED PLAN-MISMATCH \(test/cli.test.js is missing\)' run0 bash "$T/tmp3"
cp "$T/sf.bak" "$SF/workorder.md"; step0 "$SF/workorder.md" > "$T/step0.txt"

# ---- sending it back: the same workorder.md, Step 0 carries on, attempts and progress from Superfix's own records ----
rm -f "$D/workorder/rounds.json"; FS1="$(folder son)"
t round1-return "^RETURN-OK H $SON attempts 1$" ret2 "$FS1"
t round1-verify 'CHECK C3 FAIL.*CHECK H3 FAIL.*VERIFY-FAIL$' $C wo-verify --run "$D" --clone "$X" --head "$SON"
SB="$T/wo-r2"
t sendback-ready "^SENDBACK-READY $SB \\(round 2; 1 of 5 attempts used\\)$" $C wo-sendback --run "$D" --clone "$X" --dest "$SB"
t sendback-rule0-still-holds "^$WS " shasum -a 256 "$SB/workorder.md"
t sendback-held-by-id-only 'CHECK C3 FAIL expected.*CHECK H3 FAIL \(held back\)' cat "$SB/sendback.md"
t sendback-no-held-values '^clean$' bash -c "grep -q yaml '$SB/sendback.md' && echo leaked || echo clean"
t sendback-not-inside-superfix '^WORKORDER-DEST-INSIDE-SUPERFIX' $C wo-sendback --run "$D" --clone "$X" --dest "$HOME/.superfix/journal/r2"
SB2="$T/round 2 it's/folder"; mkdir -p "$SB2" "$T/tmp-r2"; cp "$SB/return.bundle" "$SB/sendback.md" "$SB2/"; sed "s#https://github.com/thedanielmay/superfix-testbed.git#file://$M#" "$SB/workorder.md" > "$SB2/workorder.md"
O2="$(cd "$SB2" && HOME="$T/emptyhome" TMPDIR="$T/tmp-r2" bash -c "$(step0 "$SB2/workorder.md")")"
t round2-step0-carries-on 'START-OK \(5 files to change, 2 to create; carrying on after 1 attempts: read sendback.md\)' printf '%s' "$O2"
R2="$(echo "$T"/tmp-r2/superfix-wo-109-wo1.*/repo)"; (cd "$R2" && sed -i '' 's/"unknown or missing format: " + fmt/"unknown format: " + fmt/' cli.js && git -c user.name=t -c user.email=t@t commit -qam 'attempt 2: failing 0') >/dev/null
bash -c "$(sed -n 's/^  bundle:  //p' <<< "$O2")" >/dev/null 2>&1; H2="$(git -C "$R2" rev-parse HEAD)"
t round2-return "^RETURN-OK H $H2 attempts 2$" ret2 "$SB2"
t round2-verify-pass 'VERIFY-PASS' $C wo-verify --run "$D" --clone "$X" --head "$H2"
t sendback-nothing-after-a-pass '^SENDBACK-NOTHING' $C wo-sendback --run "$D" --clone "$X" --dest "$T/wo-r3"
# (reviewers' attack 5) a squashed or restarted round 2 resets the git count to 1: refused
rm -f "$D/workorder/rounds.json"; ret2 "$(folder son)" >/dev/null
t round2-squashed-refused "^RETURN-NOT-BUILT-ON $SON " ret2 "$(folder sol)"
# NO-PROGRESS from Superfix's own failing counts, and no send-back at the cap
SON2="$(FROM=t/son mk son2 'attempt 2: failing 2' "echo '// 2' >> cli.js")"
rm -f "$D/workorder/rounds.json"; ret2 "$(folder son)" >/dev/null; $C wo-verify --run "$D" --clone "$X" --head "$SON" >/dev/null; ret2 "$(folder son2)" >/dev/null; $C wo-verify --run "$D" --clone "$X" --head "$SON2" >/dev/null
t sendback-no-progress '^NO-PROGRESS \(failing [0-9]+ then [0-9]+' $C wo-sendback --run "$D" --clone "$X" --dest "$T/wo-np"
for n in 3 4 5; do FROM="t/son$((n-1))" mk "son$n" "attempt $n: failing 2" "echo '// $n' >> cli.js" >/dev/null; done
rm -f "$D/workorder/rounds.json"; ret2 "$(folder son5)" >/dev/null; $C wo-verify --run "$D" --clone "$X" --head "$(git -C "$X" rev-parse t/son5)" >/dev/null
t sendback-refused-at-cap '^RETURN-CAP 5 of 5 attempts used \(no send-back left' $C wo-sendback --run "$D" --clone "$X" --dest "$T/wo-cap"
# (reviewers' attack 4) the files row counts attempts from the recorded rounds and builds on the last H
rm -f "$D/workorder/rounds.json"; ret2 "$(folder son)" >/dev/null
OUT2="$(files "$FF")"; HF2="$(sed -n 's/^RETURN-FILES 7 H \([0-9a-f]*\) attempts 2$/\1/p' <<< "$OUT2")"
t files-round2-attempts 'RETURN-FILES 7 H [0-9a-f]{40} attempts 2$' printf '%s' "$OUT2"
t files-round2-builds-on-last '^on$' bash -c "git -C '$X' merge-base --is-ancestor '$SON' '$HF2' && echo on"

# ---- redaction: a planted token is caught before the work order is written ----
PAT="$(grep -F 'H="$( { grep -H -n -E -i' "$ROOT/skills/superfix/references/redaction.md")"
sed 's/^## What this is for$/## What this is for\nUse token ghp_abcdefghijklmnopqrstuvwxyz0123456789 for the clone./' "$T/example.md" > "$T/token.md"
t redaction-blocks-planted-token 'PATTERN-HITS' bash -c "${PAT//<files>/$T/token.md}"
t redaction-example-only-sha-lines '^PATTERN-HITS [^|]*[|][^|]*example.md:(9|35)[|][^|]*example.md:(9|35)$' bash -c "${PAT//<files>/$T/example.md}"

# ---- size, SKILL.md and the journal lines check (normal runs carry Work order:) ----
t workorder-md-under-cap '^ok$' bash -c "[ \$(wc -l < '$ROOT/skills/superfix/references/workorder.md') -le 250 ] && echo ok"
t doc-files-over-still-verifies 'RETURN-FILES-OVER. comes with .RETURN-CHECKED H <sha>. and is not a stop: still run steps 2 and 3' cat "$ROOT/skills/superfix/references/workorder.md"
t doc-handoff-written-line 'The comment posted with it ends with .Work order: WRITTEN <path>.' cat "$ROOT/skills/superfix/references/workorder.md"
t skill-no-read-no-work-order 'No workorder.md read, no work order: run as normal\.' cat "$ROOT/skills/superfix/SKILL.md"
LC="$(awk '/the lines check: before posting/{f=1} f&&/^```bash$/{g=1;next} g&&/^```$/{exit} g' "$ROOT/skills/superfix/references/journal.md")"
printf '%s\n' '> **In plain English:** x.' '' '1. a' '---' 'Pictures: NONE (no screen: cli)' 'Labels: none (no issue)' 'Diagram: NONE (Simple)' 'Gap note: NONE (supported)' > "$T/c-no-wo.md"
cp "$T/c-no-wo.md" "$T/c-wo.md"; echo 'Work order: NONE (normal run)' >> "$T/c-wo.md"
lines() { local s="${LC//<run-key>/x}"; s="${s//\$HOME\/.superfix\/runs\/x\/comment-<N>.md/$1}"; s="${s//<decision or final>/decision}"; s="${s//<owner>\/<repo>/none}"; bash -c "$s"; }
t lines-check-needs-work-order 'LINES-MISSING Work order' lines "$T/c-no-wo.md"
t lines-check-ok-with-work-order '^LINES-OK$' lines "$T/c-wo.md"
t journal-work-order-values '^2$' bash -c "grep -c 'NONE (normal run) | ASKED (written after go) | WRITTEN <path> | RETURNED <word> | VERIFIED' '$ROOT/skills/superfix/references/journal.md'"

rm -f "$REALHOME/wo-sbx-write"; rm -rf "$T"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
