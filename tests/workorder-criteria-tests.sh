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
restore() { rm -rf "$M_RF"; mkdir -p "$(dirname "$M_RF")"; cp -r "$M_PRISTINE" "$M_RF"; }
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
t wo-data-done-when 'WORKORDER-DATA' plant "echo 'Contact jane@example.org about rows.' >> \"$M_RF/checks/done-when.md\""
t wo-no-yes-gates-check 'WORKORDER-NO-YES' sh -c 'restore; sed "/^## Decision/,\$d" "$M_BODYDEC" > "$T/body-nodec.md"; python3 -I "$M_RD/crit.py" wo-check --wo "$M_RF/workorder.md" --run "$M_RD" --body "$T/body-nodec.md"'
t wo-no-yes-answer-no 'WORKORDER-NO-YES' sh -c 'restore; sed "s/: yes$/: no/" "$M_BODYDEC" > "$T/body-no.md"; python3 -I "$M_RD/crit.py" wo-check --wo "$M_RF/workorder.md" --run "$M_RD" --body "$T/body-no.md"'
t wo-no-body-names-cause 'no body given' sh -c 'restore; python3 -I "$M_RD/crit.py" wo-check --wo "$M_RF/workorder.md" --run "$M_RD"'
t wo-data-yes-case-insensitive '^WORKORDER-OK$' sh -c 'restore; sed "s/: yes$/: YES/" "$M_BODYDEC" > "$T/body-YES.md"; python3 -I "$M_RD/crit.py" wo-check --wo "$M_RF/workorder.md" --run "$M_RD" --body "$T/body-YES.md"'

# ---- DOC COMMANDS (workorder.md criteria commands run exactly as documented) ----
cat > "$T/docrun.py" <<'EOF'
import re, sys
md, k1, k2, rd, rf, dest, body, head, findings, cf = (sys.argv + [""] * 11)[1:11]
md = open(md).read()
line = next(l for l in md.splitlines() if k1 in l and k2 in l)
cmd = next(m.group(1) for m in re.finditer(r"`([^`]*)`", line) if k1 in m.group(1))
cmd = cmd.replace('"F/workorder.md"', f'"{rf}/workorder.md"').replace('"D"', f'"{rd}"').replace('"F"', f'"{rf}"')
cmd = cmd.replace("<destination>", dest).replace("<new folder>", dest).replace("<journal file>", body)
cmd = cmd.replace('"<criteria folder>/attempts"', f'"{cf}/attempts"').replace('"<criteria folder>"', f'"{cf}"')
cmd = cmd.replace("wo<n>", f"wo{head}").replace("<findings file>", findings)
print(f"python3 -I \"{rd}/crit.py\" {cmd}")
EOF
t wo-doc-check-ok '^WORKORDER-OK$' bash -c 'eval "$(python3 "$T/docrun.py" "$ROOT/skills/superfix/references/workorder.md" wo-check F/workorder.md "$M_RD" "$M_RF" "$T/docdest" "$M_BODYDEC" 1 "$T/find-ok.txt" "$M_RCRC")"'
t wo-doc-baseline-ok '^BASELINE-OK$' bash -c 'eval "$(python3 "$T/docrun.py" "$ROOT/skills/superfix/references/workorder.md" wo-baseline --folder "$M_RD" "$M_RF" "$T/docdest" "$M_BODYDEC" 1 "$T/find-ok.txt" "$M_RCRC")"'
t wo-doc-lock-ok 'WORKORDER-LOCKED' bash -c 'rm -rf "$HOME/superfix-workorders/thedanielmay+superfix-testbed+csv-wo1"; eval "$(python3 "$T/docrun.py" "$ROOT/skills/superfix/references/workorder.md" wo-lock --folder "$M_RD" "$M_RF" "$HOME/superfix-workorders/thedanielmay+superfix-testbed+csv-wo1" "$M_BODYDEC" 1 "$T/find-ok.txt" "$M_RCRC")"; rm -rf "$HOME/superfix-workorders/thedanielmay+superfix-testbed+csv-wo1"'
t wo-process-scope-wording 'PROCESS-SCOPE' sh -c 'grep -q "process held in a file" "$ROOT/skills/superfix/SKILL.md" && grep -q "process held in a file" "$ROOT/skills/superfix/references/workorder.md" && echo PROCESS-SCOPE'
t wo-post-stop-wording 'POST-STOP' sh -c 'grep -q "every outcome, a stop included, is posted as in item 5" "$ROOT/skills/superfix/references/workorder.md" && echo POST-STOP'
t wo-cleanup-docs 'DOCS-OK' sh -c 'grep -q "a stop deletes everything" "$ROOT/skills/superfix/references/criteria.md" && grep -q "a stop deletes everything" "$ROOT/skills/superfix/references/workorder.md" && grep -q "CLEANUP-INCOMPLETE" "$ROOT/skills/superfix/references/workorder.md" && echo DOCS-OK'
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
cat > "$T/modes.py" <<'EOF'
import os, stat, sys
d = sys.argv[1]
bad = []
for r, ds, fs in os.walk(d):
    for x in ds:
        if stat.S_IMODE(os.stat(os.path.join(r, x)).st_mode) != 0o700:
            bad.append(os.path.join(r, x))
    for x in fs:
        if stat.S_IMODE(os.stat(os.path.join(r, x)).st_mode) != 0o600:
            bad.append(os.path.join(r, x))
print("MODES-OK" if not bad else "MODES-BAD " + " ".join(bad[:3]))
EOF
cat > "$T/nodata.py" <<'EOF'
import os, sys
bad = []
for r in sys.argv[1:]:
    for dirpath, dirnames, filenames in os.walk(r):
        for f in filenames:
            if f.endswith(".csv") or f.endswith(".tsv"):
                bad.append(os.path.join(dirpath, f))
print("NO-DATA" if not bad else "DATA-LEFT " + " ".join(bad[:4]))
EOF
t wo-lock-modes 'MODES-OK' python3 "$T/modes.py" "$M_DEST"
t wo-no-yes-gates-lock 'WORKORDER-LOCK-REFUSED' sh -c 'sed "/^## Decision/,\$d" "$M_BODYDEC" > "$T/body-nodec.md"; python3 -I "$M_RD/crit.py" wo-lock --run "$M_RD" --folder "$M_RF" --dest "$M_DEST-r2" --body "$T/body-nodec.md"'

# ---- RETURN (executor leaves 3 dupes: Superfix's own verdict is FAIL, no ending yet) ----
retfix ret1 "$M_DEST" 5
t wo-return-ok 'RETURN-CRITERIA-COPIED wo1 .* attempts 1' python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/ret1/folder" --body "$M_BODYDEC"
t wo-return-original-moved 'RETURN-ORIGINAL-MOVED' sh -c 'echo "M9,X,x@x.org,2024-01-01,45" >> "$T/src/members-export.csv"; python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/ret1/folder" --body "$M_BODYDEC"; cp "$SEED/overlay/data/members-export.csv" "$T/src/members-export.csv"'
t wo-return-files-over 'RETURN-FILES-OVER .*work/extra.txt' sh -c 'rm -rf "$T/retx"; cp -r "$M_DEST" "$T/retx"; echo x > "$T/retx/work/extra.txt"; python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/retx" --body "$M_BODYDEC"'
t wo-return-no-copy 'RETURN-NO-COPY' sh -c 'rm -rf "$T/retn"; cp -r "$M_DEST" "$T/retn"; rm "$T/retn/work/members-export.csv"; python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/retn" --body "$M_BODYDEC"'
t wo-return-checks-changed 'RETURN-FILES-OVER .*CHECKS-CHANGED' sh -c 'rm -rf "$T/retc"; cp -r "$M_DEST" "$T/retc"; echo "# x" >> "$T/retc/checks/measure-P1-C1.py"; python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/retc" --body "$M_BODYDEC"'
t wo-return-drafts-rejected-csv 'RETURN-FILES-OVER .*work/drafts/note.md' sh -c 'rm -rf "$T/retd"; cp -r "$M_DEST" "$T/retd"; mkdir -p "$T/retd/work/drafts"; echo hi > "$T/retd/work/drafts/note.md"; python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/retd" --body "$M_BODYDEC"'
t wo-return-checks-sub-rejected 'RETURN-FILES-OVER .*CHECKS-CHANGED' sh -c 'rm -rf "$T/rets"; cp -r "$M_DEST" "$T/rets"; mkdir -p "$T/rets/checks/sub"; echo x > "$T/rets/checks/sub/evil.py"; python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/rets" --body "$M_BODYDEC"'
t wo-return-kind-flip 'RETURN-OURS-CHANGED' sh -c 'rm -rf "$T/retk"; cp -r "$M_DEST" "$T/retk"; sed -i "" "s/^CHECKS-KIND: criteria$/CHECKS-KIND: code/" "$T/retk/workorder.md"; python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/retk" --body "$M_BODYDEC"'
t wo-return-code-run-criteria-folder 'RETURN-OURS-CHANGED' sh -c 'rm -rf "$T/fakerun"; mkdir -p "$T/fakerun/workorder"; echo "abc  workorder.md" > "$T/fakerun/workorder/lock"; python3 -I "$M_RD/crit.py" wo-return --run "$T/fakerun" --folder "$T/ret1/folder" --body "$M_BODYDEC"'
t wo-return-binary-workorder 'RETURN-OURS-CHANGED' sh -c 'rm -rf "$T/retb"; cp -r "$M_DEST" "$T/retb"; printf "\377\376\000binary-binary" > "$T/retb/workorder.md"; python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/retb" --body "$M_BODYDEC"'

# ---- VERIFY (verdicts from Superfix's own recorded attempt) ----
printf 'for each duplicate, the row kept is the earliest joined date: met (lines 14, 15)\n' > "$T/find-ok.txt"
printf 'for each duplicate, the row kept is the earliest joined date: met (lines 9999)\n' > "$T/find-bad.txt"
printf 'for each duplicate, the row kept is the earliest joined date: not met (lines 14, 15)\n' > "$T/find-notmet.txt"
t wo-verify-no-attempt 'VERIFY-NO-ATTEMPT wo1' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1
t wo-verify-no-return 'VERIFY-NO-RETURN wo9' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo9 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC"
doattempt "$M_RD" "$M_RCRC" "$M_BODYDEC" wo1 "$M_RD/work/wo1-members-export.csv" >/dev/null 2>&1
t wo-verify-fail 'VERIFY-FAIL' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-ok.txt"
t wo-verify-sha-mismatch 'VERIFY-SHA-MISMATCH wo1' sh -c 'cp "$M_RD/work/wo1-members-export.csv" "$T/wo1bak.csv"; echo "M9,X,x@x.org,2024-01-01,45" >> "$M_RD/work/wo1-members-export.csv"; python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-ok.txt"; cp "$T/wo1bak.csv" "$M_RD/work/wo1-members-export.csv"'
t wo-verify-findings 'FINDING-LINE-MISSING' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-bad.txt"
t wo-verify-no-findings 'FINDING-MISSING' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC"
t wo-verify-not-met 'FINDING-NOT-MET' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-notmet.txt"
printf 'for each duplicate, the row kept is the earliest joined date: unmet (lines 14, 15)\n' > "$T/find-unmet.txt"
printf 'for each duplicate, the row kept is the earliest joined date: isn'"'"'t met (lines 14, 15)\n' > "$T/find-isnt.txt"
printf 'for each duplicate, the row kept is the earliest joined date: met? no, failed (lines 3)\n' > "$T/find-nofailed.txt"
t wo-verify-unmet 'FINDING-NOT-MET' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-unmet.txt"
t wo-verify-isnt-met 'FINDING-NOT-MET' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-isnt.txt"
t wo-verify-met-no-failed 'FINDING-NOT-MET' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-nofailed.txt"
printf 'for each duplicate, the row kept is the earliest joined date: metadata looks wrong (lines 14)\n' > "$T/find-metadata.txt"
printf 'for each duplicate, the row kept is the earliest joined date: methodology broken\n' > "$T/find-methodology.txt"
printf 'for each duplicate, the row kept is the earliest joined date: met? nope, wrong\n' > "$T/find-nope.txt"
printf 'for each duplicate, the row kept is the earliest joined date: met = false\n' > "$T/find-equals.txt"
printf 'for each duplicate, the row kept is the earliest joined date: met-ish, wrong\n' > "$T/find-ish.txt"
printf 'for each duplicate, the row kept is the earliest joined date: met (see guideline 3)\n' > "$T/find-guideline.txt"
t wo-verify-metadata 'FINDING-MISSING' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-metadata.txt"
t wo-verify-methodology 'FINDING-MISSING' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-methodology.txt"
t wo-verify-met-nope 'FINDING-MISSING' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-nope.txt"
t wo-verify-met-equals 'FINDING-MISSING' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-equals.txt"
t wo-verify-met-ish 'FINDING-MISSING' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-ish.txt"
t wo-verify-guideline 'FINDING-LINE-MISSING' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-guideline.txt"
printf 'for each duplicate, the row kept is the earliest joined date: met (lines 14, 15)\nSome other thing: met (lines 3)\n' > "$T/find-unknown.txt"
t wo-verify-unknown-tick 'FINDING-UNKNOWN-TICK' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-unknown.txt"
cat > "$T/splitfinding.py" <<'EOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("c", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
cases = [
    ("Duplicate members: met (lines 3, 4)", ("Duplicate members", "met", " (lines 3, 4)")),
    ("Duplicate members: not met (lines 3, 4)", ("Duplicate members", "not met", " (lines 3, 4)")),
    ("Step 2: follow the guide: met (lines 3)", ("Step 2: follow the guide", "met", " (lines 3)")),
    ("Step 2: follow the guide: not met (lines 3)", ("Step 2: follow the guide", "not met", " (lines 3)")),
    ("Duplicate members: unmet (lines 3)", None),
    ("Duplicate members: isn't met (lines 3)", None),
    ("Duplicate members: looks fine", None),
    ("Duplicate members: metadata looks wrong (lines 14)", None),
    ("Duplicate members: methodology broken", None),
    ("Duplicate members: met? nope, wrong", None),
    ("Duplicate members: met = false", None),
    ("Duplicate members: met-ish, wrong", None),
    ("Duplicate members: met (see guideline 3)", ("Duplicate members", "met", " (see guideline 3)")),
    ("Duplicate members: NOT MET (lines 3)", ("Duplicate members", "not met", " (lines 3)")),
]
bad = [c for c, want in cases if m.woc_split_finding(c) != want]
print("SPLIT-OK" if not bad else "SPLIT-BAD " + " | ".join(bad))
EOF
t wo-split-finding-parser 'SPLIT-OK' python3 "$T/splitfinding.py" "$M_RD/crit.py"
t wo-sendback-after-notmet 'SENDBACK-READY' python3 -I "$M_RD/crit.py" wo-sendback --run "$M_RD" --dest "$M_DEST-r2" --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC"
t wo-sendback-cloud-refused 'WORKORDER-PATH' python3 -I "$M_RD/crit.py" wo-sendback --run "$M_RD" --dest "$HOME/Library/CloudStorage/X/$ID-r2" --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC"
t wo-sendback-elsewhere-refused 'WORKORDER-PATH' python3 -I "$M_RD/crit.py" wo-sendback --run "$M_RD" --dest /private/tmp/elsewhere-wo --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC"
t wo-sendback-no-datayes 'WORKORDER-NO-YES' sh -c 'sed "/^## Decision/,\$d" "$M_BODYDEC" > "$T/body-nodec2.md"; python3 -I "$M_RD/crit.py" wo-sendback --run "$M_RD" --dest "$M_DEST-r2" --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$T/body-nodec2.md"'
t wo-sendback-mode-700 '700 700' sh -c 'stat -f "%Lp" "$M_DEST-r2" "$M_DEST-r2/work" | tr "\n" " "; echo'
t wo-sendback-keeps-copy 'work/members-export.csv' sh -c 'test -f "$M_DEST-r2/work/members-export.csv" && echo work/members-export.csv'

# ---- G: .sf-orig edge cases (the lock binds the real original, not just the run copy) ----
t wo-sforig-missing-refuses 'WORKORDER-LOCK-REFUSED' sh -c 'rm -rf "$M_DEST"; mv "$M_RD/work/members-export.csv.sf-orig" "$T/sf.bak"; python3 -I "$M_RD/crit.py" wo-lock --run "$M_RD" --folder "$M_RF" --dest "$M_DEST" --body "$M_BODYDEC"; cp "$T/sf.bak" "$M_RD/work/members-export.csv.sf-orig"; rm -rf "$M_DEST"'
t wo-sforig-garbage-refuses 'WORKORDER-LOCK-REFUSED' sh -c 'rm -rf "$M_DEST"; cp "$M_RD/work/members-export.csv.sf-orig" "$T/sf.bak"; echo "garbage" > "$M_RD/work/members-export.csv.sf-orig"; python3 -I "$M_RD/crit.py" wo-lock --run "$M_RD" --folder "$M_RF" --dest "$M_DEST" --body "$M_BODYDEC"; cp "$T/sf.bak" "$M_RD/work/members-export.csv.sf-orig"; rm -rf "$M_DEST"'
t wo-sforig-disambiguates 'ORIGSHA-RIGHT' sh -c 'rm -rf "$M_DEST"; mkdir -p "$T/src2"; cp "$SEED/overlay/data/refunds-log.csv" "$T/src2/refunds-log.csv"; python3 -I "$M_RD/crit.py" copy --run "$M_RD" --src "$T/src2/refunds-log.csv" >/dev/null 2>&1; python3 -I "$M_RD/crit.py" wo-lock --run "$M_RD" --folder "$M_RF" --dest "$M_DEST" --body "$M_BODYDEC" >/dev/null 2>&1; test "$(sed -n "s/^origsha //p" "$M_RD/workorder/lock")" = "$(shasum -a 256 "$T/src/members-export.csv" | cut -d" " -f1)" && echo ORIGSHA-RIGHT; rm -rf "$M_DEST" "$M_RD/work/refunds-log.csv" "$M_RD/work/refunds-log.csv.sf-orig"'
t wo-src-deleted-moved 'RETURN-ORIGINAL-MOVED' sh -c 'mv "$T/src/members-export.csv" "$T/src-hidden.csv"; python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/ret1/folder" --body "$M_BODYDEC"; mv "$T/src-hidden.csv" "$T/src/members-export.csv"'

# ---- CLOUD SYMLINK (a symlinked default tree is still a cloud folder) ----
mv "$HOME/superfix-workorders" "$T/swo-real"; mkdir -p "$HOME/Library/CloudStorage/WO"; ln -s "$HOME/Library/CloudStorage/WO" "$HOME/superfix-workorders"
t wo-lock-cloud-symlink-refused 'PATH-CLOUD' python3 -I "$M_RD/crit.py" wo-lock --run "$M_RD" --folder "$M_RF" --dest "$M_DEST" --body "$M_BODYDEC"
python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo1 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-bad.txt" >/dev/null 2>&1
t wo-sendback-cloud-symlink-refused 'PATH-CLOUD' python3 -I "$M_RD/crit.py" wo-sendback --run "$M_RD" --dest "$M_DEST-r2" --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC"
rm "$HOME/superfix-workorders"; mv "$T/swo-real" "$HOME/superfix-workorders"

# ---- PLAIN SYMLINK (a symlinked default tree refuses even off-cloud) ----
mv "$HOME/superfix-workorders" "$T/swo-plain"; mkdir -p "$T/plain"; ln -s "$T/plain" "$HOME/superfix-workorders"
t wo-lock-symlink-refused 'WORKORDER-SYMLINK' python3 -I "$M_RD/crit.py" wo-lock --run "$M_RD" --folder "$M_RF" --dest "$M_DEST" --body "$M_BODYDEC"
rm "$HOME/superfix-workorders"; mv "$T/swo-plain" "$HOME/superfix-workorders"
rm -rf "$T/retO"; cp -r "$T/ret1" "$T/retO"; cp "$T/src/members-export.csv" "$T/retO/folder/work/members-export.csv"
python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/retO/folder" --body "$M_BODYDEC" >/dev/null 2>&1
doattempt "$M_RD" "$M_RCRC" "$M_BODYDEC" wo2 "$M_RD/work/wo2-members-export.csv" >/dev/null 2>&1
t wo-verify-wo2-fail 'VERIFY-FAIL' python3 -I "$M_RD/crit.py" wo-verify --run "$M_RD" --head wo2 --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC" --findings "$T/find-ok.txt"
mv "$HOME/superfix-workorders" "$T/swo-plain2"; ln -s "$T/plain" "$HOME/superfix-workorders"
t wo-sendback-symlink-refused 'WORKORDER-SYMLINK' python3 -I "$M_RD/crit.py" wo-sendback --run "$M_RD" --dest "$M_DEST-r3" --attempts "$M_RCRC/attempts" --scripts "$M_RCRC" --body "$M_BODYDEC"
rm "$HOME/superfix-workorders"; mv "$T/swo-plain2" "$HOME/superfix-workorders"
t wo-return-ignores-returned-note 'RETURN-CRITERIA-COPIED' sh -c 'rm -rf "$T/retnote"; cp -r "$T/ret1" "$T/retnote"; echo "note for the next round" > "$T/retnote/folder/RETURNED-1.md"; python3 -I "$M_RD/crit.py" wo-return --run "$M_RD" --folder "$T/retnote/folder" --body "$M_BODYDEC"'

# ---- ENDING RIG (a pass cleans everything: rounds, stub copy, run copies) ----
eval "$(python3 "$(dirname "$0")/mkrig.py" "$HOME" test-end-wo thedanielmay+superfix-testbed+end-wo1 "$T/src/members-export.csv" work/members-export.csv E)"
[ -n "$E_RD" ] || { echo "CANNOT RUN: ending rig build failed"; exit 2; }
export E_RD E_RF E_RCRC E_DEST E_BODYDEC
python3 -I "$E_RD/crit.py" wo-lock --run "$E_RD" --folder "$E_RF" --dest "$E_DEST" --body "$E_BODYDEC" >/dev/null 2>&1
retfix Eret1 "$E_DEST" 8
python3 -I "$E_RD/crit.py" wo-return --run "$E_RD" --folder "$T/Eret1/folder" --body "$E_BODYDEC" >/dev/null 2>&1
doattempt "$E_RD" "$E_RCRC" "$E_BODYDEC" wo1 "$E_RD/work/wo1-members-export.csv" >/dev/null 2>&1
mkdir -p "$E_RD/work/neg/sub"; cp "$T/src/members-export.csv" "$E_RD/work/neg/neg-p9.csv"; cp "$T/src/members-export.csv" "$E_RD/work/neg/sub/neg-p8.csv"
mkdir -p "$E_DEST-r9/work"; echo stale > "$E_DEST-r9/work/stale.csv"
t wo-doc-verify-ok 'VERIFY-PASS' bash -c 'eval "$(python3 "$T/docrun.py" "$ROOT/skills/superfix/references/workorder.md" wo-verify "--head wo" "$E_RD" "$E_RF" "$T/docdest" "$E_BODYDEC" 1 "$T/find-ok.txt" "$E_RCRC")"'
t wo-ending-pass-keeps-copy 'KEPT-COPY' sh -c 'test "$(find "$E_RD/work" "$E_DEST" "$E_DEST-r9" -name "*.csv")" = "$E_RD/work/wo1-members-export.csv" && echo KEPT-COPY'
t wo-sendback-nothing 'SENDBACK-NOTHING' sh -c 'rm -rf "$E_DEST-r2"; mkdir -p "$E_DEST-r8/work"; echo stale > "$E_DEST-r8/work/stale.csv"; mkdir -p "$E_DEST/work"; echo rebuilt > "$E_DEST/work/rebuilt.csv"; python3 -I "$E_RD/crit.py" wo-sendback --run "$E_RD" --dest "$E_DEST-r2" --attempts "$E_RCRC/attempts" --scripts "$E_RCRC" --body "$E_BODYDEC"'
t wo-sendback-nothing-cleans 'KEPT-COPY' sh -c 'test "$(find "$E_RD/work" "$E_DEST" "$E_DEST-r8" -name "*.csv")" = "$E_RD/work/wo1-members-export.csv" && echo KEPT-COPY'
t wo-reverify-after-ending 'VERIFY-PASS' python3 -I "$E_RD/crit.py" wo-verify --run "$E_RD" --head wo1 --attempts "$E_RCRC/attempts" --scripts "$E_RCRC" --body "$E_BODYDEC" --findings "$T/find-ok.txt"
t wo-orphan-finish-clean 'WORK-DELETED' python3 -I "$E_RD/crit.py" finish --run "$E_RD"

# ---- FINISH RIG (finish leaves the stub copy; wo-cleanup removes it) ----
eval "$(python3 "$(dirname "$0")/mkrig.py" "$HOME" test-fin-wo thedanielmay+superfix-testbed+fin-wo1 "$T/src/members-export.csv" work/members-export.csv N)"
[ -n "$N_RD" ] || { echo "CANNOT RUN: finish rig build failed"; exit 2; }
export N_RD N_RF N_RCRC N_DEST N_BODYDEC
python3 -I "$N_RD/crit.py" wo-lock --run "$N_RD" --folder "$N_RF" --dest "$N_DEST" --body "$N_BODYDEC" >/dev/null 2>&1
t wo-finish-runs 'WORK-DELETED' python3 -I "$N_RD/crit.py" finish --run "$N_RD"
t wo-finish-leaves-stub-copy 'STUB-COPY-LEFT' sh -c 'test -f "$N_RF/work/members-export.csv" && echo STUB-COPY-LEFT'
mkdir -p "$N_RD/work/neg/sub"; cp "$T/src/members-export.csv" "$N_RD/work/neg/neg-p9.csv"; cp "$T/src/members-export.csv" "$N_RD/work/neg/sub/neg-p8.csv"
t wo-cleanup-ok 'CLEANUP-OK' python3 -I "$N_RD/crit.py" wo-cleanup --run "$N_RD"
t wo-cleanup-cleans 'NO-DATA' python3 "$T/nodata.py" "$N_RD" "$N_DEST"

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
t wo-doc-sendback-ready 'SENDBACK-READY' bash -c 'eval "$(python3 "$T/docrun.py" "$ROOT/skills/superfix/references/workorder.md" wo-sendback --attempts "$P_RD" "$P_RF" "$HOME/superfix-workorders/thedanielmay+superfix-testbed+prog-wo1-r3" "$P_BODYDEC" 1 "$T/find-ok.txt" "$P_RCRC")"'
t wo-sendback-modes 'MODES-OK' python3 "$T/modes.py" "$HOME/superfix-workorders/thedanielmay+superfix-testbed+prog-wo1-r3"
rm -rf "$T/Pret3"; cp -r "$T/Pret2" "$T/Pret3"
python3 -I "$P_RD/crit.py" wo-return --run "$P_RD" --folder "$T/Pret3/folder" --body "$P_BODYDEC" >/dev/null 2>&1
doattempt "$P_RD" "$P_RCRC" "$P_BODYDEC" wo3 "$P_RD/work/wo3-members-export.csv" >/dev/null 2>&1
t wo-flat-carried 'FLAT wo3' python3 -I "$P_RD/crit.py" wo-verify --run "$P_RD" --head wo3 --attempts "$P_RCRC/attempts" --scripts "$P_RCRC" --body "$P_BODYDEC"
rm -rf "$T/Pret4"; cp -r "$T/Pret2" "$T/Pret4"
python3 -I "$P_RD/crit.py" wo-return --run "$P_RD" --folder "$T/Pret4/folder" --body "$P_BODYDEC" >/dev/null 2>&1
doattempt "$P_RD" "$P_RCRC" "$P_BODYDEC" wo4 "$P_RD/work/wo4-members-export.csv" >/dev/null 2>&1
python3 -I "$P_RD/crit.py" wo-verify --run "$P_RD" --head wo4 --attempts "$P_RCRC/attempts" --scripts "$P_RCRC" --body "$P_BODYDEC" >/dev/null 2>&1
t wo-flat-no-progress 'NO-PROGRESS' python3 -I "$P_RD/crit.py" wo-sendback --run "$P_RD" --dest "$HOME/superfix-workorders/thedanielmay+superfix-testbed+prog-wo1-r5" --attempts "$P_RCRC/attempts" --scripts "$P_RCRC" --body "$P_BODYDEC"
t wo-flat-no-progress-cleans 'NO-DATA' python3 "$T/nodata.py" "$P_RD" "$P_DEST" "$HOME/superfix-workorders/thedanielmay+superfix-testbed+prog-wo1-r3"
t wo-cleanup-incomplete 'CLEANUP-INCOMPLETE' sh -c 'mkdir -p "$P_RD/work/locked2"; cp "$T/src/members-export.csv" "$P_RD/work/locked2/secret.csv"; chflags uchg "$P_RD/work/locked2/secret.csv"; python3 -I "$P_RD/crit.py" wo-cleanup --run "$P_RD"; chflags nouchg "$P_RD/work/locked2/secret.csv"'

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
mkdir -p "$HOME/superfix-workorders/thedanielmay+superfix-testbed+stop-wo1-r9/work"; echo stale > "$HOME/superfix-workorders/thedanielmay+superfix-testbed+stop-wo1-r9/work/stale.csv"
t wo-stop-sendback-refused 'NO-PROGRESS' python3 -I "$S_RD/crit.py" wo-sendback --run "$S_RD" --dest "$HOME/superfix-workorders/thedanielmay+superfix-testbed+stop-wo1-r4" --attempts "$S_RCRC/attempts" --scripts "$S_RCRC" --body "$S_BODYDEC"
t wo-stop-cleans-rounds 'NO-DATA' python3 "$T/nodata.py" "$S_RD" "$S_DEST" "$HOME/superfix-workorders/thedanielmay+superfix-testbed+stop-wo1-r9"

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
t wo-cap-sixth-return-refused 'RETURN-CAP 6 of 5' sh -c 'rm -rf "$T/Kret6"; cp -r "$K_DEST" "$T/Kret6"; mkdir -p "$T/Kret6/work"; cp "$K_RD/work/wo5-members-export.csv" "$T/Kret6/work/members-export.csv"; python3 -I "$K_RD/crit.py" wo-return --run "$K_RD" --folder "$T/Kret6" --body "$K_BODYDEC"'
t wo-cap-sendback-refused 'RETURN-CAP' sh -c 'mkdir -p "$HOME/superfix-workorders/thedanielmay+superfix-testbed+cap-wo1-r7/work"; echo stale > "$HOME/superfix-workorders/thedanielmay+superfix-testbed+cap-wo1-r7/work/stale.csv"; python3 -I "$K_RD/crit.py" wo-sendback --run "$K_RD" --dest "$HOME/superfix-workorders/thedanielmay+superfix-testbed+cap-wo1-r6" --attempts "$K_RCRC/attempts" --scripts "$K_RCRC" --body "$K_BODYDEC"'
t wo-cap-cleans-rounds 'NO-DATA' python3 "$T/nodata.py" "$K_RD" "$K_DEST" "$HOME/superfix-workorders/thedanielmay+superfix-testbed+cap-wo1-r7"

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

# ---- CUT RIG (a cut copy all the way through check, lock and return) ----
eval "$(python3 "$(dirname "$0")/mkrig.py" "$HOME" test-cut-wo thedanielmay+superfix-testbed+cut-wo1 "$T/src/members-export.csv" work/cut.csv --cut U)"
[ -n "$U_RD" ] || { echo "CANNOT RUN: cut rig build failed"; exit 2; }
export U_RD U_RF U_RCRC U_DEST U_BODYDEC
t wo-cut-check-ok '^WORKORDER-OK$' python3 -I "$U_RD/crit.py" wo-check --wo "$U_RF/workorder.md" --run "$U_RD" --body "$U_BODYDEC"
t wo-cut-baseline-ok '^BASELINE-OK$' python3 -I "$U_RD/crit.py" wo-baseline --run "$U_RD" --folder "$U_RF" --body "$U_BODYDEC"
t wo-cut-lock-ok 'WORKORDER-LOCKED' python3 -I "$U_RD/crit.py" wo-lock --run "$U_RD" --folder "$U_RF" --dest "$U_DEST" --body "$U_BODYDEC"
rm -rf "$T/Uret"; mkdir -p "$T/Uret"; cp -r "$U_DEST" "$T/Uret/folder"
python3 - "$T/Uret/folder/work/cut.csv" <<'EOF'
import csv, sys
rows = list(csv.DictReader(open(sys.argv[1], newline="", encoding="utf-8")))
seen, out = set(), []
for r in rows:
    if r["email"].strip().lower() in seen:
        continue
    seen.add(r["email"].strip().lower()); out.append(r)
with open(sys.argv[1], "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=["row", "email", "joined"])
    w.writeheader(); w.writerows(out)
print("cut fixed rows:", len(out))
EOF
t wo-cut-return-ok 'RETURN-CRITERIA-COPIED wo1' python3 -I "$U_RD/crit.py" wo-return --run "$U_RD" --folder "$T/Uret/folder" --body "$U_BODYDEC"
t wo-cut-base-is-placed-copy 'BASE-IS-PLACED-COPY' sh -c 'test "$(shasum -a 256 "$U_RF/work/cut.csv" | cut -d" " -f1)" = "$(sed -n "s/^BASE: //p" "$U_RF/workorder.md" | cut -d" " -f1)" && echo BASE-IS-PLACED-COPY'
doattempt "$U_RD" "$U_RCRC" "$U_BODYDEC" wo1 "$U_RD/work/wo1-cut.csv" >/dev/null 2>&1
printf 'for each duplicate, the row kept is the earliest joined date: met (lines 14, 15)\n' > "$T/find-cut.txt"
t wo-cut-verify-pass 'VERIFY-PASS' python3 -I "$U_RD/crit.py" wo-verify --run "$U_RD" --head wo1 --attempts "$U_RCRC/attempts" --scripts "$U_RCRC" --body "$U_BODYDEC" --findings "$T/find-cut.txt"
t wo-cut-verify-cleans 'KEPT-COPY' sh -c 'test "$(find "$U_RD/work" "$U_DEST" -name "*.csv")" = "$U_RD/work/wo1-cut.csv" && echo KEPT-COPY'
t wo-stop-deletes-all 'NO-DATA' sh -c 'python3 -I "$U_RD/crit.py" wo-cleanup --run "$U_RD" >/dev/null 2>&1; python3 "$T/nodata.py" "$U_RD" "$U_DEST"'

# ---- I: process drafts allowed; dead locals scan ----
eval "$(python3 "$(dirname "$0")/mkrig.py" "$HOME" test-proc-wo thedanielmay+superfix-testbed+proc-wo1 "$T/src/members-export.csv" work/members-export.csv Q)"
[ -n "$Q_RD" ] || { echo "CANNOT RUN: proc rig build failed"; exit 2; }
export Q_RD Q_RF Q_RCRC Q_DEST Q_BODYDEC
python3 - "$Q_RF/workorder.md" <<'EOF'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
t = p.read_text().replace("FILES: work/members-export.csv\n", "FILES: work/members-export.csv, work/drafts/\n")
p.write_text(t)
print("FILES now names drafts")
EOF
t wo-proc-lock-ok 'WORKORDER-LOCKED' python3 -I "$Q_RD/crit.py" wo-lock --run "$Q_RD" --folder "$Q_RF" --dest "$Q_DEST" --body "$Q_BODYDEC"
t wo-drafts-refused-nonprocess 'RETURN-FILES-OVER .*work/drafts/note.md' sh -c 'rm -rf "$T/retp"; cp -r "$Q_DEST" "$T/retp"; mkdir -p "$T/retp/work/drafts"; echo "please approve" > "$T/retp/work/drafts/note.md"; python3 -I "$Q_RD/crit.py" wo-return --run "$Q_RD" --folder "$T/retp" --body "$Q_BODYDEC" --attempts "$Q_RCRC/attempts" --scripts "$Q_RCRC"'
python3 - "$Q_BODYDEC" "$T/body-doctored.md" <<'EOF'
import pathlib, sys
t = pathlib.Path(sys.argv[1]).read_text()
t = t.replace("## Decision", "- P2-C1 [owner] refund process: the guide says how a refund is paid; pass: you tick all 2 items below; how: checklist; who: owner sign-off\n  - [ ] the guide gives the refund timeframe in days\n  - [ ] every see step points at a step that exists\n\n## Decision", 1)
pathlib.Path(sys.argv[2]).write_text(t)
print("doctored body written")
EOF
t wo-drafts-unlocked-body-refused 'CRITERIA-CHANGED' sh -c 'rm -rf "$T/retu"; cp -r "$Q_DEST" "$T/retu"; mkdir -p "$T/retu/work/drafts"; echo "please approve" > "$T/retu/work/drafts/note.md"; python3 -I "$Q_RD/crit.py" wo-return --run "$Q_RD" --folder "$T/retu" --body "$T/body-doctored.md" --attempts "$Q_RCRC/attempts" --scripts "$Q_RCRC"'

# ---- DIVERGED STUB (stub check-only, real criteria owner: the gate reads real) ----
python3 - "$Q_RD/body.md" "$T/body-own.md" <<'EOF'
import pathlib, sys
t = pathlib.Path(sys.argv[1]).read_text()
t += "- P2-C1 [owner] refund process: the guide says how a refund is paid; pass: you tick all 2 items below; how: checklist; who: owner sign-off\n  - [ ] the guide gives the refund timeframe in days\n  - [ ] every see step points at a step that exists\n"
pathlib.Path(sys.argv[2]).write_text(t)
print("owner body written")
EOF
rm -f "$Q_RCRC/lock" "$Q_RCRC/attempts"; rm -rf "$Q_RCRC/records"
python3 -I "$Q_RD/crit.py" baseline --run "$Q_RD" --scripts "$Q_RCRC" --body "$T/body-own.md" --attempts "$Q_RCRC/attempts" --label base --measure "P1-C1=$Q_RD/work/members-export.csv" --measure "P1-K1=$Q_RD/work/members-export.csv" >/dev/null 2>&1
QLOCKOUT="$(python3 -I "$Q_RD/crit.py" lock --scripts "$Q_RCRC" --by "the owner at the keyboard" --run "$Q_RD" --attempts "$Q_RCRC/attempts" --body "$T/body-own.md" --data "$Q_RD/work/members-export.csv" --approved "P1,P2")"
QSHA="$(printf '%s\n' "$QLOCKOUT" | sed -n 's/^Internal: criteria-sha \([0-9a-f]*\).*/\1/p')"
{ cat "$T/body-own.md"; printf '\n## Decision\nData yes: members-export.csv (the whole file): yes\nP2: You chose no '"'"'must not get worse'"'"' check, so a fix could break something unnoticed.\nInternal: criteria-sha %s (sha256), locked 2026-10-21 00:00, approved by the owner at the keyboard\n' "$QSHA"; } > "$T/body-dec2.md"
t wo-diverged-drafts-allowed 'RETURN-CRITERIA-COPIED' sh -c 'rm -rf "$T/retd2"; cp -r "$Q_DEST" "$T/retd2"; mkdir -p "$T/retd2/work/drafts"; echo hi > "$T/retd2/work/drafts/note.md"; python3 -I "$Q_RD/crit.py" wo-return --run "$Q_RD" --folder "$T/retd2" --body "$T/body-dec2.md" --attempts "$Q_RCRC/attempts" --scripts "$Q_RCRC"'
# ---- J: process drafts allowed (owner criterion in the body) ----
eval "$(python3 "$(dirname "$0")/mkrig.py" "$HOME" test-procjob-wo thedanielmay+superfix-testbed+procjob-wo1 "$T/src/members-export.csv" work/members-export.csv --owner J)"
[ -n "$J_RD" ] || { echo "CANNOT RUN: process rig build failed"; exit 2; }
export J_RD J_RF J_RCRC J_DEST J_BODYDEC
python3 - "$J_RF/workorder.md" <<'EOF'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
t = p.read_text().replace("FILES: work/members-export.csv\n", "FILES: work/members-export.csv, work/drafts/\n")
p.write_text(t)
print("FILES now names drafts")
EOF
t wo-proc-lock-ok 'WORKORDER-LOCKED' python3 -I "$J_RD/crit.py" wo-lock --run "$J_RD" --folder "$J_RF" --dest "$J_DEST" --body "$J_BODYDEC"
t wo-proc-drafts-allowed 'RETURN-CRITERIA-COPIED' sh -c 'rm -rf "$T/retj"; cp -r "$J_DEST" "$T/retj"; mkdir -p "$T/retj/work/drafts"; echo "please approve" > "$T/retj/work/drafts/note.md"; python3 -I "$J_RD/crit.py" wo-return --run "$J_RD" --folder "$T/retj" --body "$J_BODYDEC" --attempts "$J_RCRC/attempts" --scripts "$J_RCRC"'
cat > "$T/deadlocals.py" <<'EOF'
import ast, sys
src = open(sys.argv[1]).read()
i = src.index("# --- crit.py start ---")
src = src[i:src.index("# --- crit.py end ---")]
tree = ast.parse(src)
bad = []
for n in ast.walk(tree):
    if isinstance(n, ast.FunctionDef) and (n.name.startswith("woc_") or n.name.startswith("cmd_wo_")):
        loads, stores = set(), set()
        for m in ast.walk(n):
            if isinstance(m, ast.Name):
                if isinstance(m.ctx, ast.Load):
                    loads.add(m.id)
                else:
                    stores.add(m.id)
        args = {a.arg for a in n.args.args}
        bad += [f"{n.name}:{v}" for v in sorted(stores - loads - args) if not v.startswith("_")]
print("NO-DEAD-LOCALS" if not bad else "DEAD " + " ".join(bad))
EOF
t wo-dead-locals 'NO-DEAD-LOCALS' python3 "$T/deadlocals.py" "$ROOT/skills/superfix/references/criteria.md"

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

# ---- CRIT-1.5-CHANGED (a one-byte edit to 1.5.0 code fails it) ----
t crit-15-unchanged 'CRIT-1.5-UNCHANGED' python3 "$ROOT/tests/crit-15-check.py" "$ROOT/skills/superfix/references/criteria.md"
cat > "$T/tamper.py" <<'EOF'
import sys
p, which = sys.argv[1], sys.argv[2]
arg = sys.argv[3] if len(sys.argv) > 3 else ""
lines = open(p).read().splitlines()
if which.startswith("append:"):
    anchor = which.split(":", 1)[1]
    i = next(k for k, l in enumerate(lines) if l.startswith(anchor))
    lines.insert(i, 'SANDBOX_TOOLS.append("/usr/bin/curl")')
elif which == "insert":
    anchor, code = arg.split(":::", 1)
    i = next(k for k, l in enumerate(lines) if l.startswith(anchor))
    lines.insert(i + 1, code)
elif which == "defarg":
    i = next(k for k, l in enumerate(lines) if l.startswith(f"def {arg}("))
    assert lines[i].endswith("):"), lines[i][-20:]
    lines[i] = lines[i][:-2] + ', _x=globals().__setitem__("WO_LIMIT", 99)' + lines[i][-2:]
elif which == "wokinds":
    i = next(k for k, l in enumerate(lines) if l.startswith("WO_KINDS = "))
    lines[i] = 'WO_KINDS = {"code"}'
elif which == "woreqcrit-or":
    i = next(k for k, l in enumerate(lines) if l.startswith("WO_REQUIRED_CRITERIA = "))
    lines[i] = lines[i] + ' or [SANDBOX_TOOLS.append("/usr/bin/curl")]'
elif which == "wocx":
    i = next(k for k, l in enumerate(lines) if l.startswith("WOC_APPROVED_RX"))
    lines.insert(i, 'WOC_X = SANDBOX_TOOLS.append("/usr/bin/curl")')
elif which == "wolimit6":
    i = next(k for k, l in enumerate(lines) if l.startswith("WO_LIMIT = "))
    lines[i] = "WO_LIMIT = 6"
elif which == "woreq":
    i = next(k for k, l in enumerate(lines) if l.startswith("WO_REQUIRED = ["))
    assert not lines[i].startswith("WO_REQUIRED_CRITERIA"), lines[i][:40]
    lines[i] = lines[i].replace('"DELIVER"]', '"DELIVER", "X"]', 1)
elif which.startswith("line:"):
    _, pre, post = which.split(":", 2)
    i = next(k for k, l in enumerate(lines) if l.startswith(pre))
    lines[i] = lines[i].replace(post, post + "  # x", 1)
else:
    i = next(k for k, l in enumerate(lines) if l.startswith(f"def {which}("))
    lines[i] = lines[i] + "  # x"
open(p, "w").write("\n".join(lines) + "\n")
EOF
tamperrun() { cp "$ROOT/skills/superfix/references/criteria.md" "$T/crit-tampered.md"; python3 "$T/tamper.py" "$T/crit-tampered.md" "$1" "$2"; _nm="$(printf '%s %s' "$1" "$2" | tr -c 'A-Za-z0-9' '_' | sed 's/_*$//')"; t "crit-15-changed-fails-$_nm" "$3" sh -c 'python3 "'"$ROOT"'/tests/crit-15-check.py" "'"$T"'/crit-tampered.md"; test $? -ne 0'; }
for _fn in run_script profile cmd_progress cmd_lockcheck cmd_measure; do
  tamperrun "$_fn" "" "CRIT-1.5-CHANGED .*$_fn"
done
for _fn in "append:def woc_approved(" wolimit6 woreq "line:R_CALL = re.compile:R_CALL = re.compile"; do
  tamperrun "$_fn" "" "CRIT-1.5-CHANGED"
done
tamperrun insert '    s = p("wo-lock":::    sp.choices["lockcheck"].set_defaults(f=cmd_wo_lock)' "CRIT-1.5-CHANGED .*parsers"
tamperrun insert '    s = p("wo-lock":::    SANDBOX_TOOLS.append("/usr/bin/curl")' "CRIT-1.5-CHANGED .*parsers"
tamperrun woreqcrit-or "" "CRIT-1.5-CHANGED .*WO_REQUIRED_CRITERIA"
tamperrun wocx "" "CRIT-1.5-CHANGED .*WOC_X"
tamperrun defarg woc_tick "CRIT-1.5-CHANGED .*woc_tick"
tamperrun wokinds "" "CRIT-1.5-CHANGED .*WO_KINDS"

echo "RESULT: $pass passed, $fail failed"
export HOME="$REALHOME"
