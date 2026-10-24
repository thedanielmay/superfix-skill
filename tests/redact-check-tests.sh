#!/bin/bash
# Tests for the 1.6.4 redaction gate (superfix-skill#107 item 1).
# No model runs, no network. Needs: python3.
# Usage: bash tests/redact-check-tests.sh
# ROOT=<another checkout> runs these tests against that checkout's files (used to show a test fails before its fix).
ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
T="$(mktemp -d "${TMPDIR:-/tmp}/redact-tests.XXXXXX")"
trap 'rm -rf "$T"' EXIT
RC="python3 -I $ROOT/skills/superfix/references/redact-check.py"
pass=0; fail=0
t() { local name="$1" want="$2" rc=""; shift 2; if [[ "$1" =~ ^[0-9]+$ ]]; then rc="$1"; shift; fi; local out rcgot; out="$("$@" 2>&1)"; rcgot=$?
  if printf '%s' "$out" | tr '\n' '|' | grep -qE "$want" && { [ -z "$rc" ] || [ "$rcgot" = "$rc" ]; }; then pass=$((pass+1)); echo "ok   $name"; else fail=$((fail+1)); echo "FAIL $name: want /$want/ rc ${rc:-any} got: $(printf '%s' "$out" | tr '\n' '|' | cut -c1-300) (rc $rcgot)"; fi; }
has() { grep -q -F -- "$2" "$1" && echo FOUND || echo MISSING; }

mkdir -p "$T/run" && echo k > "$T/run/key"
echo "hello world" > "$T/clean.txt"
printf 'Use token ghp_abcdefghijklmnopqrstuvwxyz0123456789 for the clone.\n' > "$T/token.md"

# the script with its positive control
t self-test '^SELF-TEST-OK$' 0 $RC --self-test
# failing input: all input files missing is ERROR, never PATTERN-CLEAN
t missing-files-error '^ERROR' 1 $RC --run "$T/run" -- /tmp/does-not-exist-aaa /tmp/does-not-exist-bbb
t missing-files-no-false-clean '^NO-FALSE-PASS$' 0 bash -c "$RC --run '$T/run' -- /tmp/does-not-exist-aaa | grep -q PATTERN-CLEAN && echo FALSE-PASS || echo NO-FALSE-PASS"
# failing input: a planted secret blocks
echo "my-secret-token-xyz123" > "$T/run/secrets"
echo "my-secret-token-xyz123" > "$T/leak.txt"
t planted-secret-blocked '^BLOCKED' 1 $RC --run "$T/run" -- "$T/leak.txt"
rm -f "$T/run/secrets"
# failing input: no run folder stops
t no-run-folder '^NO-RUN-FOLDER' 1 $RC --run "$T/nope" -- "$T/clean.txt"
# clean input passes both checks
t clean-input '^NO-LIST[|]PATTERN-CLEAN$' 0 $RC --run "$T/run" -- "$T/clean.txt"
# positive control: a planted token pattern hits and the run decides
t positive-control-token '^NO-LIST[|]PATTERN-HITS' 0 $RC --run "$T/run" -- "$T/token.md"
# the session trailer is excluded from the keyword group only: a token on that line still hits
printf 'Claude-Session: https://claude.ai/code/session_abc then ghp_abcdefghijklmnopqrstuvwxyz0123456789\n' > "$T/trailer-token.md"
printf 'Claude-Session: https://claude.ai/code/session_01NbsQYHppYAWe6CgtgQwJm1\n' > "$T/trailer.md"
t trailer-plus-token-hits '^NO-LIST[|]PATTERN-HITS' 0 $RC --run "$T/run" -- "$T/trailer-token.md"
t trailer-alone-clean '^NO-LIST[|]PATTERN-CLEAN$' 0 $RC --run "$T/run" -- "$T/trailer.md"
# the self-test notices a broken long-token group
sed 's/^LONG = re.compile(.*/LONG = re.compile(r"(?!)")/' "$ROOT/skills/superfix/references/redact-check.py" > "$T/broken.py"
t selftest-catches-broken-long '^SELF-TEST-FAIL$' 1 python3 -I "$T/broken.py" --self-test
# the gate snippets exit 1 on their failure words
t redaction-gate-rule '^FOUND$' has "$ROOT/skills/superfix/references/redaction.md" "exits 1 on BLOCKED, ERROR and NO-RUN-FOLDER"
t label-add-exits-1 '^FOUND$' has "$ROOT/skills/superfix/references/journal.md" 'LABEL-ADD-FAILED $L"; exit 1'
t label-create-exits-1 '^FOUND$' has "$ROOT/skills/superfix/references/journal.md" 'LABEL-CREATE-FAILED $L"; exit 1'
t gap-note-exits-1 '^FOUND$' has "$ROOT/skills/superfix/references/gaps.md" 'GAP-NOTE-BLOCKED missing"; exit 1'
t diagram-source-exits-1 '^FOUND$' has "$ROOT/skills/superfix/references/diagrams.md" 'DIAGRAM-SOURCE-BLOCKED missing"; exit 1'
t failing-input-test-rule '^FOUND$' has "$ROOT/skills/superfix/references/redaction.md" "gets a failing-input test"

echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
