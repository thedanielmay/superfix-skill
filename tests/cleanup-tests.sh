#!/bin/bash
# Tests for criteria cleanup: names outside work/ in a stub or round folder, and
# special files (FIFO, socket, immutable flag) at the top level (superfix-skill#113).
# No model runs, no network, no sandbox. Needs: python3. macOS only for the uchg case.
# Usage: bash tests/cleanup-tests.sh
# ROOT=<another checkout> runs these tests against that checkout's files (used to show a test fails before its fix).
ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
T="$(mktemp -d "${TMPDIR:-/tmp}/cleanup-tests.XXXXXX")"
trap 'rm -rf "$T"' EXIT
C="python3 -I $ROOT/skills/superfix/references/crit.py"
pass=0; fail=0
t() { local name="$1" want="$2"; shift 2; local out rcgot; out="$("$@" 2>&1)"; rcgot=$?
  if printf '%s' "$out" | tr '\n' '|' | grep -qE "$want"; then pass=$((pass+1)); echo "ok   $name"; else fail=$((fail+1)); echo "FAIL $name: want /$want/ got: $(printf '%s' "$out" | tr '\n' '|' | cut -c1-300) (rc $rcgot)"; fi; }
has() { printf '%s' "$2" | grep -qE "$1" && echo FOUND || echo MISSING; }

cat > "$T/mk.py" <<'PY'
import hashlib, pathlib, sys
home, wid = pathlib.Path(sys.argv[1]), sys.argv[2]
new = len(sys.argv) > 3 and sys.argv[3] in ("new", "pass")
passed = len(sys.argv) > 3 and sys.argv[3] == "pass"
D = home / ".superfix" / "runs" / ("r-" + wid)
F = D / "workorder" / "folder"
for d in (F / "work", F / "checks"):
    d.mkdir(parents=True)
(F / "work" / "data.csv").write_text("email\nx@x.org\n")
(F / "workorder.md").write_text(f"WORK-ORDER: {wid}\nCHECKS-KIND: criteria\n")
for n in ("crit.py", "lock", "attempts", "done-when.md"):
    (F / "checks" / n).write_text(n + "\n")
lock = "".join(f"{hashlib.sha256((F / 'checks' / n).read_bytes()).hexdigest()}  folder/checks/{n}\n"
               for n in ("crit.py", "lock", "attempts", "done-when.md"))
(D / "workorder" / "lock").write_text(lock)
R = home / "superfix-workorders" / wid
for d in (R / "work", R / "checks"):
    d.mkdir(parents=True)
(R / "work" / "data.csv").write_text("email\nx@x.org\n")
(R / "checks" / "crit.py").write_text("crit.py\n")
(R / "workorder.md").write_text(f"WORK-ORDER: {wid}\nCHECKS-KIND: criteria\n")
if new:
    # a job locked by this version: the inode in the lock, one recorded return, a round r2 holding the stub
    import json, os
    s = os.stat(R)
    with open(D / "workorder" / "lock", "a") as f:
        f.write(f"jobdir {s.st_dev} {s.st_ino}\n")
    rets = [{"n": 1}]
    if passed:
        (D / "work").mkdir()
        (D / "work" / "wo1-data.csv").write_text("email\nx@x.org\n")
        (D / "work" / "other.csv").write_text("email\ny@x.org\n")
        rets = [{"n": 1, "failing": 0, "copy": str(D / "work" / "wo1-data.csv")}]
    (D / "workorder" / "returns.json").write_text(json.dumps(rets))
    (R / "r2" / "work").mkdir(parents=True)
    (R / "r2" / "work" / "data.csv").write_text("email\nx@x.org\n")
    (R / "r2" / "workorder.md").write_bytes((F / "workorder.md").read_bytes())
print(D)
PY
mk() { python3 "$T/mk.py" "$T/home" "$@"; }
cleanup() { HOME="$T/home" $C wo-cleanup --run "$1"; }
R() { echo "$T/home/superfix-workorders/$1"; }
export T

# a clean rig is CLEANUP-OK (the baseline every other case is measured against)
D="$(mk clean)"; t clean-rig '^CLEANUP-OK' cleanup "$D"

# a stray csv at the round folder top level must not survive a clean report
D="$(mk straycsv)"; echo "email" > "$(R straycsv)/members-export.csv"
t stray-csv-clean '^CLEANUP-OK' cleanup "$D"
t stray-csv-deleted 'MISSING' has 'members-export.csv' "$(ls "$(R straycsv)" | tr '\n' ' ')"
# a stray return bundle is the same case
D="$(mk bundle)"; echo "bundle" > "$(R bundle)/return.bundle"
t stray-bundle-clean '^CLEANUP-OK' cleanup "$D"
t stray-bundle-deleted 'MISSING' has 'return.bundle' "$(ls "$(R bundle)" | tr '\n' ' ')"
# a stray directory is listed, never deleted
D="$(mk straydir)"; mkdir -p "$(R straydir)/notes"; echo keep > "$(R straydir)/notes/a.txt"
t stray-dir-named 'CLEANUP-INCOMPLETE.*notes' cleanup "$D"
t stray-dir-kept 'FOUND' has 'a.txt' "$(ls "$(R straydir)/notes" | tr '\n' ' ')"
# a stray link is listed, and the file it points at is untouched
D="$(mk straylink)"; echo precious > "$T/canary.txt"; ln -s "$T/canary.txt" "$(R straylink)/link.csv"
t stray-link-named 'CLEANUP-INCOMPLETE.*link.csv' cleanup "$D"
t stray-link-canary 'precious' cat "$T/canary.txt"
# the round folder's own work/ is gone after the clean rig's cleanup
t clean-rig-work-gone 'MISSING' has '(^| )work( |$)' "$(ls "$(R clean)" | tr '\n' ' ')"

# a FIFO named report.md at the stub top level is not silently skipped
D="$(mk fifo)"; mkfifo "$T/home/.superfix/runs/r-fifo/workorder/folder/report.md"
t fifo-report-named 'CLEANUP-INCOMPLETE.*report.md' cleanup "$D"
# a socket named report.md at the stub top level is not silently skipped
D="$(mk sock)"; python3 - "$T/s.sock" "$T/home/.superfix/runs/r-sock/workorder/folder/report.md" <<'PY'
import os, socket, sys
s = socket.socket(socket.AF_UNIX); s.bind(sys.argv[1]); s.close()
os.rename(sys.argv[1], sys.argv[2])
PY
t sock-report-named 'CLEANUP-INCOMPLETE.*report.md' cleanup "$D"
# an immutable file is listed, and the flag says why (macOS only)
if command -v chflags >/dev/null; then
  D="$(mk uchg)"; echo x > "$T/home/.superfix/runs/r-uchg/workorder/folder/report.md"; chflags uchg "$T/home/.superfix/runs/r-uchg/workorder/folder/report.md"
  t uchg-report-named 'CLEANUP-INCOMPLETE.*report.md' cleanup "$D"
  chflags nouchg "$T/home/.superfix/runs/r-uchg/workorder/folder/report.md" 2>/dev/null
fi
# a FIFO inside work/ is deleted, not opened (a read would hang)
D="$(mk fifowork)"; mkfifo "$T/home/.superfix/runs/r-fifowork/workorder/folder/work/pipe"
t fifo-work-clean '^CLEANUP-OK' cleanup "$D"
t fifo-work-deleted 'MISSING' has 'pipe' "$(ls "$T/home/.superfix/runs/r-fifowork/workorder/folder/work" 2>/dev/null | tr '\n' ' ')"

# ---- the job folder goes with its rounds (superfix-skill#167) ----
echo keep > "$T/home/keep.txt"
D="$(mk jobgone new)"; out="$(cleanup "$D")"
t job-folder-gone '^CLEANUP-OK.*cleanup-log' echo "$out"
t job-folder-removed 'GONE' sh -c 'test ! -e "$T/home/superfix-workorders/jobgone" && test -d "$T/home/superfix-workorders" && echo GONE'
t log-lists-every-path 'jobgone/r2/work/data.csv.*jobgone/work/data.csv' sh -c 'tr "\n" " " < "$1/workorder/cleanup-log"' x "$D"
t log-mode-600 '^600$' stat -f %Lp "$D/workorder/cleanup-log"
t log-not-printed 'MISSING' has 'data.csv' "$out"
t canary-home-kept 'keep' cat "$T/home/keep.txt"
D="$(mk oa new)"; mk ob new >/dev/null; cleanup "$D" >/dev/null
t other-job-untouched 'x@x.org' cat "$(R ob)/work/data.csv"
D="$(mk sa new)"; mk sa-r2 new >/dev/null; cleanup "$D" >/dev/null
t sibling-other-job-untouched 'x@x.org' cat "$(R sa-r2)/work/data.csv"
t sibling-job-itself-gone 'GONE' sh -c 'test ! -e "$T/home/superfix-workorders/sa" && echo GONE'
D="$(mk leg)"; mkdir -p "$(R leg)-r2/work"; echo x > "$(R leg)-r2/work/x.csv"; echo s > "$(R leg)-r2/sendback.md"; echo "WORK-ORDER: leg" > "$(R leg)-r2/workorder.md"
t legacy-siblings-cleaned '^CLEANUP-OK' cleanup "$D"
t legacy-siblings-gone 'GONE' sh -c 'test ! -e "$T/home/superfix-workorders/leg" && test ! -e "$T/home/superfix-workorders/leg-r2" && echo GONE'
D="$(mk inode new)"; mv "$(R inode)" "$T/inode-aside"; cp -R "$T/inode-aside" "$(R inode)"; echo c > "$(R inode)/work/canary.txt"
t job-inode-mismatch-refused 'KEPT .*not the one Superfix made.*CLEANUP-INCOMPLETE' cleanup "$D"
t job-inode-canary-kept 'FOUND' has 'canary.txt' "$(ls "$(R inode)/work" | tr '\n' ' ')"
D="$(mk lnk new)"; mkdir -p "$T/decoy/work"; echo d > "$T/decoy/work/canary.txt"; mv "$(R lnk)" "$T/lnk-aside"; ln -s "$T/decoy" "$(R lnk)"
t job-symlink-refused 'KEPT .*a link, not a folder.*CLEANUP-INCOMPLETE' cleanup "$D"
t job-symlink-canary-kept 'd' cat "$T/decoy/work/canary.txt"
D="$(mk fake new)"; mkdir "$(R fake)/r7"; echo n > "$(R fake)/r7/notes.txt"
t fake-round-kept 'KEPT .*r7' cleanup "$D"
t fake-round-notes-kept 'FOUND' has 'notes.txt' "$(ls "$(R fake)/r7" | tr '\n' ' ')"
D="$(mk ed new)"; echo changed >> "$(R ed)/r2/workorder.md"
t edited-round-listed 'KEPT .*r2' cleanup "$D"
t edited-round-work-cleared 'MISSING' has '(^| )work( |$)' "$(ls "$(R ed)/r2" | tr '\n' ' ')"
t edited-round-file-kept 'FOUND' has 'workorder.md' "$(ls "$(R ed)/r2" | tr '\n' ' ')"
D="$(python3 "$T/mk.py" "$T/home2" ..)"
t id-dotdot-refused 'CLEANUP-INCOMPLETE' env HOME="$T/home2" $C wo-cleanup --run "$D"
t id-dotdot-canary 'x@x.org' cat "$T/home2/work/data.csv"
D="$(mk straydir2)"; mkdir -p "$(R straydir2)/notes"; echo keep > "$(R straydir2)/notes/a.txt"; cleanup "$D" >/dev/null
t stray-dir-keeps-job 'FOUND' has 'notes' "$(ls "$(R straydir2)" | tr '\n' ' ')"

# ---- review fixes on #167 ----
# MUST-FIX 1: a legacy sibling is deleted only on a positive match of its workorder.md id
D="$(mk budget)"; mkdir -p "$(R budget)-r2"; echo mine > "$(R budget)-r2/personal-notes.txt"
out="$(cleanup "$D")"
t sibling-no-workorder-survives 'mine' cat "$(R budget)-r2/personal-notes.txt"
t sibling-no-workorder-named 'KEPT .*budget-r2' echo "$out"
t sibling-no-workorder-contents-unnamed 'MISSING' has 'personal-notes' "$out"
D="$(mk bud2)"; mkdir -p "$(R bud2)-r2"; echo mine > "$(R bud2)-r2/personal-notes.txt"; echo "WORK-ORDER: someone-else" > "$(R bud2)-r2/workorder.md"
cleanup "$D" >/dev/null
t sibling-other-id-survives 'mine' cat "$(R bud2)-r2/personal-notes.txt"

# MUST-FIX 2: a pass keeps only the verified copy; the second run (or --all) removes the rest
D="$(mk jobp pass)"; out="$(cleanup "$D")"
t pass-cleanup-ok 'CLEANUP-OK jobp.*checked copy' echo "$out"
t pass-keeps-only-copy 'wo1-data.csv' sh -c 'ls "$1/work"' x "$D"
t pass-drops-other-copy 'MISSING' has 'other.csv' "$(ls "$D/work")"
t pass-drops-rounds-and-work 'EMPTY' sh -c 'test -d "$1" && test -z "$(ls -A "$1")" && echo EMPTY' x "$(R jobp)"
t pass-second-run-all 'CLEANUP-OK' sh -c 'HOME="$T/home" '"$C"' wo-cleanup --run "$1" --all' x "$D"
t pass-all-removes-job 'GONE' sh -c 'test ! -e "$1" && test ! -e "$2/work/wo1-data.csv" && echo GONE' x "$(R jobp)" "$D"
D="$(mk jobq pass)"; cleanup "$D" >/dev/null; rm "$D/work/wo1-data.csv"
t pass-copy-taken-then-clean 'CLEANUP-OK' cleanup "$D"
t pass-copy-taken-job-gone 'GONE' sh -c 'test ! -e "$1" && echo GONE' x "$(R jobq)"

# SHOULD-FIX b: KEPT names the top folder and a count, never a nested name
if command -v chflags >/dev/null; then
  D="$(mk nest new)"; echo a > "$(R nest)/work/alice-smith.csv"; chflags uchg "$(R nest)/work/alice-smith.csv"
  out="$(cleanup "$D")"
  t kept-no-nested-name 'MISSING' has 'alice' "$out"
  t kept-top-name-and-count 'KEPT .*nest/work \(1 item' echo "$out"
  t kept-full-path-in-log 'alice-smith.csv' cat "$D/workorder/cleanup-log"
  chflags nouchg "$(R nest)/work/alice-smith.csv"
fi

# SHOULD-FIX c: the log is opened without following a link and is forced to mode 600
D="$(mk logmode new)"; : > "$D/workorder/cleanup-log"; chmod 644 "$D/workorder/cleanup-log"; cleanup "$D" >/dev/null
t log-existing-forced-600 '^600$' stat -f %Lp "$D/workorder/cleanup-log"
D="$(mk loglink new)"; echo canary > "$T/log-canary.txt"; ln -s "$T/log-canary.txt" "$D/workorder/cleanup-log"
t log-symlink-refused 'CLEANUP-LOG-REFUSED' cleanup "$D"
t log-symlink-canary-intact '^canary$' cat "$T/log-canary.txt"
t log-symlink-job-kept 'x@x.org' cat "$(R loglink)/work/data.csv"

echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
