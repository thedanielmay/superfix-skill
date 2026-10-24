#!/bin/bash
# Tests for the shared header and freshness helpers in crit.py (superfix-skill#113, item 5).
# No model runs, no network, no sandbox. Needs: python3.
# Usage: bash tests/wo-dedupe-tests.sh
# ROOT=<another checkout> runs these tests against that checkout's files.
ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
T="$(mktemp -d "${TMPDIR:-/tmp}/wo-dedupe-tests.XXXXXX")"
trap 'rm -rf "$T"' EXIT
C="python3 -I $ROOT/skills/superfix/references/crit.py"
pass=0; fail=0
t() { local name="$1" want="$2"; shift 2; local out; out="$("$@" 2>&1)"
  if printf '%s' "$out" | tr '\n' '|' | grep -qE "$want"; then pass=$((pass+1)); echo "ok   $name"; else fail=$((fail+1)); echo "FAIL $name: want /$want/ got: $(printf '%s' "$out" | tr '\n' '|' | cut -c1-300)"; fi; }
absent() { local name="$1" no="$2"; shift 2; local out; out="$("$@" 2>&1)"
  if printf '%s' "$out" | tr '\n' '|' | grep -qE "$no"; then fail=$((fail+1)); echo "FAIL $name: /$no/ printed"; else pass=$((pass+1)); echo "ok   $name"; fi; }

# one copy of each problem line: the helper is called, not copied
t one-missing-loop 'ONE' python3 - "$ROOT/skills/superfix/references/crit.py" <<'PY'
import pathlib, sys
t = pathlib.Path(sys.argv[1]).read_text()
n = t.count('bad.append(f"WORKORDER-MISSING {k} (found {n} times)")')
print("ONE" if n == 1 else f"COUNT {n}")
PY
t one-not-fresh-loop 'ONE' python3 - "$ROOT/skills/superfix/references/crit.py" <<'PY'
import pathlib, sys
t = pathlib.Path(sys.argv[1]).read_text()
n = t.count("(a ticked box)")
print("ONE" if n == 1 else f"COUNT {n}")
PY

# the exclusion lists stay different: a shell fragment passes the code kind, fails criteria
printf '%s\n' 'WORK-ORDER: dedupe1' 'CHECKS-KIND: code' 'FILES: a.py' '' '## Checklist' '- [ ] run the check' 'o=<other> not a placeholder in a code checklist' > "$T/code.md"
printf '%s\n' 'WORK-ORDER: dedupe2' 'CHECKS-KIND: criteria' 'FILES: work/a.csv' '' '## Checklist' '- [ ] run the check' 'o=<other> is a placeholder in a criteria checklist' > "$T/crit.md"
absent code-shell-line-not-flagged 'placeholders? outside|NOT-FRESH line .* placeholder' $C wo-check --wo "$T/code.md"
t criteria-shell-line-flagged 'WORKORDER-NOT-FRESH line 7 \(a placeholder outside' $C wo-check --wo "$T/crit.md"

# the missing key problem keeps its shape for both key sets
t code-missing-key 'WORKORDER-MISSING CHECKS-SHA \(found 0 times\)' $C wo-check --wo "$T/code.md"
t criteria-missing-key 'WORKORDER-MISSING CHECKS-SHA \(found 0 times\)' $C wo-check --wo "$T/crit.md"

# an unknown kind still returns early, before the freshness problems
printf '%s\n' 'WORK-ORDER: dedupe3' 'CHECKS-KIND: firmware' '' '## Checklist' '- [ ] run' 'o=<other>' > "$T/bad.md"
t kind-early '^WORKORDER-KIND firmware$' $C wo-check --wo "$T/bad.md"
absent kind-no-freshness 'NOT-FRESH' $C wo-check --wo "$T/bad.md"

# a ticked box and an all ticked list are still reported
printf '%s\n' 'WORK-ORDER: dedupe4' 'CHECKS-KIND: code' '' '## Checklist' '- [x] run' > "$T/ticked.md"
t ticked-box 'WORKORDER-NOT-FRESH line 5 \(a ticked box\)' $C wo-check --wo "$T/ticked.md"
t no-unticked-step 'WORKORDER-NOT-FRESH \(no unticked step\)' $C wo-check --wo "$T/ticked.md"
absent code-checklist-line-not-placeholder 'NOT-FRESH line .* placeholder' $C wo-check --wo "$T/code.md"

echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
