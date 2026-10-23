#!/bin/bash
# Tests for 1.6.4 skill text, Part 2 (superfix-skill#107 items 6 to 8).
# No model runs, no network. Each case greps the reference file that holds the rule.
# Usage: bash tests/skill-text-tests.sh
# ROOT=<another checkout> runs these tests against that checkout's files (used to show a test fails before its fix).
ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
D="$ROOT/skills/superfix/references"; S="$ROOT/SKILL.md"
pass=0; fail=0
t() { local name="$1" want="$2" rc=""; shift 2; if [[ "$1" =~ ^[0-9]+$ ]]; then rc="$1"; shift; fi; local out rcgot; out="$("$@" 2>&1)"; rcgot=$?
  if printf '%s' "$out" | tr '\n' '|' | grep -qE "$want" && { [ -z "$rc" ] || [ "$rcgot" = "$rc" ]; }; then pass=$((pass+1)); echo "ok   $name"; else fail=$((fail+1)); echo "FAIL $name: want /$want/ rc ${rc:-any} got: $(printf '%s' "$out" | tr '\n' '|' | cut -c1-300) (rc $rcgot)"; fi; }
has() { grep -q -F -- "$2" "$1" && echo FOUND || echo MISSING; }

# item 6 (diagnose.md)
t d108-hypotheses '^FOUND$' has "$D/diagnose.md" "issue said X, measured Y"
t d17-stated-control '^FOUND$' has "$D/diagnose.md" "Run the issue's stated negative control before relying on it"
t d76-stated-guard '^FOUND$' has "$D/diagnose.md" "must fail through the stated guard"
t d45-readers '^FOUND$' has "$D/diagnose.md" ".claude/skills"
t d65-positive-control '^FOUND$' has "$D/diagnose.md" "Every scan carries a positive control"
# item 7 (execute.md, journal.md, SKILL.md)
t e10-worktree '^FOUND$' has "$D/execute.md" "git -C <repo> worktree add"
t e13-background '^FOUND$' has "$D/execute.md" "run_in_background from the start"
t e38-tail '^FOUND$' has "$D/execute.md" "quote the tail"
t e52-no-k '^FOUND$' has "$D/execute.md" "never \`-k <word>\`"
t e58-show-current '^FOUND$' has "$D/execute.md" "git branch --show-current"
t j73-date '^FOUND$' has "$D/journal.md" "run \`date\` and compute it"
t e85-one-suite '^FOUND$' has "$D/execute.md" "Never run two suites in one worktree at once"
t e105-no-stash '^FOUND$' has "$D/execute.md" "Never stash in a worktree flow"
t e118-safe-order '^FOUND$' has "$D/execute.md" "the safe order"
t j121-blocked '^FOUND$' has "$D/journal.md" "blocked by a permission check at <step>"
t e122-moves '^FOUND$' has "$D/execute.md" "Checklist for move-only refactors"
t e123-zsh '^FOUND$' has "$D/execute.md" "use \`${=T}\`"
t e124-wrong-level '^FOUND$' has "$D/execute.md" "the rule is at the wrong level"
t e128-prev-head '^FOUND$' has "$D/execute.md" "against the PREVIOUS head"
t e130-fail-closed '^FOUND$' has "$D/execute.md" "fail closed"
t e131-hit-count '^FOUND$' has "$D/execute.md" "the hit count, each hit line"
t e132-bytecode '^FOUND$' has "$D/execute.md" "PYTHONDONTWRITEBYTECODE=1"
t e138-body-fields '^FOUND$' has "$D/execute.md" "never memory"
t s140-cannot-occur '^FOUND$' has "$S" "the filed defect cannot occur"
# item 8 (decisions)
t x25-tests-only '^FOUND$' has "$D/execute.md" "replaces the solved check with negative controls"
t x14-review-depth '^FOUND$' has "$D/execute.md" "Scale review depth to the diff"
t x90-active-time '^FOUND$' has "$S" "counting active time only"
t x95-loose-ends '^FOUND$' has "$D/execute.md" "are not scope creep"
t x129-mutant '^FOUND$' has "$D/execute.md" "must kill a mutant"
t x86-merge-exempt '^FOUND$' has "$D/execute.md" "Merge commits are exempt from the session-trailer rule"

echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
