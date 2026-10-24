#!/bin/bash
# Tests for the fixed style list in the comment gate: a rules line that says no dashes
# makes a comment holding U+2013 or U+2014 fail wo-scan-comment, which writes no receipt,
# so wo-post refuses the comment (superfix-skill#127).
# The dash characters are built from byte escapes, never typed, so this file holds none.
# No model runs, no network, no sandbox. Needs: python3.
# Usage: bash tests/style-check-tests.sh
# ROOT=<another checkout> runs these tests against that checkout's files (used to show a test fails before its fix).
ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
T="$(mktemp -d "${TMPDIR:-/tmp}/style-check-tests.XXXXXX")"
trap 'rm -rf "$T"' EXIT
C=(python3 -I "$ROOT/skills/superfix/references/crit.py")
RUN="$T/run"; REPO="$T/repo"; SET="$REPO/.superfix"
mkdir -p "$RUN" "$SET"
EN="$(printf '\xe2\x80\x93')"; EM="$(printf '\xe2\x80\x94')"
pass=0; fail=0
t() { local name="$1" want="$2"; shift 2; local out rcgot; out="$("$@" 2>&1)"; rcgot=$?
  if printf '%s' "$out" | tr '\n' '|' | grep -qE "$want"; then pass=$((pass+1)); echo "ok   $name"; else fail=$((fail+1)); echo "FAIL $name: want /$want/ got: $(printf '%s' "$out" | tr '\n' '|' | cut -c1-300) (rc $rcgot)"; fi; }
rules() { printf '%b\n' "$1" > "$SET/project.md"; }
comment() { printf '%b\n' "$2" > "$T/$1.md"; }
scan() { "${C[@]}" wo-scan-comment --run "$RUN" --comment "$T/$1.md" --repo "$REPO" --no-data; }
post() { "${C[@]}" wo-post --run "$RUN" --comment "$T/$1.md"; }

# 1. no rules file: nothing to enforce, the comment passes and no style line appears
rm -f "$SET/project.md"
comment plain 'Body.\n\nA plain line.'
t norules-passes 'SCAN-NO-DATA-DECLARED' scan plain
other-rule() { printf '%s' "$1" | grep -qE 'STYLE-' && echo STYLE-LINE || echo NO-STYLE-LINE; }
t norules-no-style-line 'NO-STYLE-LINE' other-rule "$(scan plain)"

# 2. the dash rule and a clean comment: STYLE-CLEAN, and the scan leaves a receipt
rules 'rules: no em or en dashes anywhere'
comment clean 'Body.\n\nA plain line.'
t clean-scan 'STYLE-CLEAN' scan clean
t clean-scan-post 'POST-OK-DECLARED' post clean

# 3. an en dash fails the scan, names the line it is on, and leaves no receipt
comment endash "Body.\n\nSome text here ${EN} here.\nMore text."
t endash-fails 'STYLE-DASH 3 \(' scan endash
t endash-no-receipt 'POST-REFUSED' post endash

# 4. an em dash fails the same way
comment emdash "Body.\n\nSome text here ${EM} here."
t emdash-fails 'STYLE-DASH 3 \(' scan emdash

# 5. a dash inside a code fence still fails: the gate cannot tell
comment fence "Body.\n\n\`\`\`\nA line with ${EN} in it.\n\`\`\`"
t fence-dash-fails 'STYLE-DASH 4 \(' scan fence

# 6. the number is the dash line, not the first line
comment later "Body.\n\nOne.\nTwo.\nThree ${EM} three.\nFour."
t later-line-number 'STYLE-DASH 5 \(' scan later

# 7. another rule line is shown and never enforced
rules 'rules: tabs not spaces\nrules: keep the README short'
t other-rule-shown 'STYLE-RULE tabs not spaces' scan later
t other-rule-not-enforced 'SCAN-NO-DATA-DECLARED' scan later

# 8. the two phrases, any case; a near miss is not one of them
rules 'rules: No Dashes please'
t variant-no-dashes 'STYLE-DASH 5 \(' scan later
rules 'rules: NO EM OR EN DASHES ANYWHERE'
t variant-upper 'STYLE-DASH 5 \(' scan later
rules 'rules: no em dashes, use a comma'
t variant-near-miss 'SCAN-NO-DATA-DECLARED' scan later

# 9. the same comment passes once the dash is gone: the gate is the dash, not the file
rules 'rules: no dashes'
comment fixed 'Body.\n\nOne.\nTwo.\nThree here three.\nFour.'
t fixed-passes 'STYLE-CLEAN' scan fixed

echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
