#!/bin/bash
# Tests for the mechanical refusal of the refused kinds and the code plus criteria mix
# (superfix-skill#113, item 6). No model runs, no network, no sandbox. Needs: python3.
# Usage: bash tests/workorder-kinds-tests.sh
# ROOT=<another checkout> runs these tests against that checkout's files.
ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
T="$(mktemp -d "${TMPDIR:-/tmp}/wo-kinds-tests.XXXXXX")"
trap 'rm -rf "$T"' EXIT
C="python3 -I $ROOT/skills/superfix/references/crit.py"
pass=0; fail=0
t() { local name="$1" want="$2"; shift 2; local out; out="$("$@" 2>&1)"
  if printf '%s' "$out" | tr '\n' '|' | grep -qE "$want"; then pass=$((pass+1)); echo "ok   $name"; else fail=$((fail+1)); echo "FAIL $name: want /$want/ got: $(printf '%s' "$out" | tr '\n' '|' | cut -c1-240)"; fi; }
absent() { local name="$1" no="$2"; shift 2; local out; out="$("$@" 2>&1)"
  if printf '%s' "$out" | tr '\n' '|' | grep -qE "$no"; then fail=$((fail+1)); echo "FAIL $name: /$no/ printed"; else pass=$((pass+1)); echo "ok   $name"; fi; }
wo() { local f="$T/$1" kind="$2" kinds="$3"; { printf '%s\n' 'WORK-ORDER: kinds1' "CHECKS-KIND: $kind"; [ -n "$kinds" ] && printf 'KINDS: %s\n' "$kinds"; printf '%s\n' 'FILES: work/a.csv' '' '## Checklist' '- [ ] run the check'; } > "$f"; echo "$f"; }

# a refused kind is refused, in either kind of work order
t criteria-qik-refused 'WORKORDER-KIND-REFUSED qik' $C wo-check --wo "$(wo crit-qik.md criteria qik)"
t code-qik-refused 'WORKORDER-KIND-REFUSED qik' $C wo-check --wo "$(wo code-qik.md code qik)"
t criteria-live-refused 'WORKORDER-KIND-REFUSED live' $C wo-check --wo "$(wo crit-live.md criteria live)"
t code-doc-refused 'WORKORDER-KIND-REFUSED doc' $C wo-check --wo "$(wo code-doc.md code doc)"
# a code plus criteria mix is refused
t mix-refused 'WORKORDER-KIND-REFUSED mix' $C wo-check --wo "$(wo mix.md code "code criteria")"
t mix-refused-criteria 'WORKORDER-KIND-REFUSED mix' $C wo-check --wo "$(wo mix2.md criteria "criteria code")"
# a single allowed kind is not refused
absent code-alone-not-refused 'KIND-REFUSED' $C wo-check --wo "$(wo code-ok.md code code)"
absent criteria-alone-not-refused 'KIND-REFUSED' $C wo-check --wo "$(wo crit-ok.md criteria criteria)"
# a work order with no KINDS line keeps the old behaviour
absent no-kinds-line-not-refused 'KIND-REFUSED' $C wo-check --wo "$(wo nokinds.md criteria '')"
# an unknown CHECKS-KIND keeps its own early refusal
t unknown-kind-still-first '^WORKORDER-KIND firmware$' $C wo-check --wo "$(wo firmware.md firmware code)"
absent unknown-kind-not-kinds-refusal 'KIND-REFUSED' $C wo-check --wo "$(wo firmware.md firmware code)"

echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
