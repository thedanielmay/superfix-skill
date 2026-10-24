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
print(D)
PY
mk() { local wid="$1"; python3 "$T/mk.py" "$T/home" "$wid"; }
cleanup() { HOME="$T/home" $C wo-cleanup --run "$1"; }
R() { echo "$T/home/superfix-workorders/$1"; }

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

echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
