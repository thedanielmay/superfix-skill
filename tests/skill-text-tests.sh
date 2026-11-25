#!/bin/bash
# Tests for 1.6.4 skill text, Part 2 (superfix-skill#107 items 6 to 8).
# No model runs, no network. Each case greps the reference file that holds the rule.
# Usage: bash tests/skill-text-tests.sh
# ROOT=<another checkout> runs these tests against that checkout's files (used to show a test fails before its fix).
ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
D="$ROOT/skills/superfix/references"; S="$ROOT/skills/superfix/SKILL.md"
pass=0; fail=0
t() { local name="$1" want="$2" rc=""; shift 2; if [[ "$1" =~ ^[0-9]+$ ]]; then rc="$1"; shift; fi; local out rcgot; out="$("$@" 2>&1)"; rcgot=$?
  if printf '%s' "$out" | tr '\n' '|' | grep -qE "$want" && { [ -z "$rc" ] || [ "$rcgot" = "$rc" ]; }; then pass=$((pass+1)); echo "ok   $name"; else fail=$((fail+1)); echo "FAIL $name: want /$want/ rc ${rc:-any} got: $(printf '%s' "$out" | tr '\n' '|' | cut -c1-300) (rc $rcgot)"; fi; }
has() { grep -q -F -- "$2" "$1" && echo FOUND || echo MISSING; }
absent() { grep -q -F -- "$2" "$1" && echo PRESENT || echo ABSENT; }

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
t e123-zsh '^FOUND$' has "$D/execute.md" 'use `${=T}`'
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

# issue 121, the trimmed Red Flags: a line budget on SKILL.md, one change-pipeline ban, and the two kept bullets
count_where() { bash -c "$2" "$1"; }
t i121-lines '^MAX-400-OK$' count_where "$S" 'n=$(wc -l < "$0"); if [ "$n" -le 400 ]; then echo MAX-400-OK; else echo "MAX-400-FAIL $n"; fi'
t i121-ban-once '^BAN-ONCE-OK$' count_where "$S" 'n=$(grep -c change-pipeline "$0"); if [ "$n" -eq 1 ]; then echo BAN-ONCE-OK; else echo "BAN-ONCE-FAIL $n"; fi'
t i121-two-bullets '^BULLETS-2$' count_where "$S" 'n=$(awk "/^## Red Flags/,/^## Out of Scope/" "$0" | grep -c "^- "); echo "BULLETS-$n"'
# 1.7.0 part one (superfix-skill#125): the two new settings keys
t p125-seven-keys '^FOUND$' has "$D/project.md" "Only these eight keys exist"
t p125-closing-doc '^FOUND$' has "$D/project.md" '`closing: auto` (the default) keeps the Phase 4 rule'
t p125-model-doc '^FOUND$' has "$D/project.md" '`model:` is a default for the fix stage only'
t p125-closing-skill '^FOUND$' has "$S" '`closing: refs` forbids it'
t p125-model-skill '^FOUND$' has "$S" "which the Model and Effort Policy can still raise"
# 1.7.0 part one (superfix-skill#125): the independent review stage
t p125-review-heading '^FOUND$' has "$S" "### Independent review (Moderate, Complex, or any gate or prompt text change)"
t p125-review-verdict '^FOUND$' has "$S" 'INDEPENDENT-REVIEW PASS|FAIL <n> findings'
t p125-review-limits '^FOUND$' has "$D/execute.md" "Limits:"
t p125-review-exec '^FOUND$' has "$D/execute.md" 'One verdict comment on the PR: `INDEPENDENT-REVIEW PASS|FAIL <n> findings`'
t p125-lines '^MAX-400-OK$' count_where "$S" 'n=$(wc -l < "$0"); if [ "$n" -le 400 ]; then echo MAX-400-OK; else echo "MAX-400-FAIL $n"; fi'
# 1.7.0 part two (superfix-skill#127): the side-findings key and its filing rules
t p127-side-findings-row '^FOUND$' has "$D/project.md" '| `side-findings` | `list` or `file`; what the run does with a finding outside the job | no |'
t p127-side-findings-settings '^FOUND$' has "$D/project.md" '`side-findings=file` when the run may file'
t p127-side-findings-skill '^FOUND$' has "$S" '`superfix:side-finding` and assigned'
t p127-side-findings-journal '^FOUND$' has "$D/journal-close.md" 'Found while working on [<repo>#<N>](https://github.com/<owner>/<repo>/issues/<N>)'
t p127-side-finding-label '^FOUND$' has "$D/journal-close.md" 'colour `1D76DB`'
t p127-side-findings-cap '^FOUND$' has "$D/journal-close.md" 'At most 5 a run; the sixth and later stay under'

# 1.7.0 part two (superfix-skill#127): the research type and its one validation pass
t p127-research-type '^FOUND$' has "$S" '| Labels: `research` with no change requested; the owner asks what is true, to find out, to investigate or to compare, and asks for no change | `research` |'
t p127-research-before-bug 'BEFORE-BUG' sh -c 'f="$0"; [ "$(grep -n "research. with no change requested" "$f" | cut -d: -f1)" -lt "$(grep -n "\`bug\`, \`regression\`" "$f" | cut -d: -f1)" ] && echo BEFORE-BUG' "$S"
t p127-research-draft '^FOUND$' has "$D/research.md" 'never into the issue body yet'
t p127-research-pointer '^FOUND$' has "$S" 'references/research.md'
t p127-research-report '^FOUND$' has "$D/research.md" '## The report'
t p127-research-confirmed '^FOUND$' has "$D/research.md" 'CONFIRMED'
t p127-research-corrected '^FOUND$' has "$D/research.md" 'CORRECTED <what is right>'
t p127-research-refuted '^FOUND$' has "$D/research.md" 'REFUTED <why>'
t p127-research-no-branch '^FOUND$' has "$D/research.md" 'makes no code change, no branch and no PR'
t p127-research-publish-last '^FOUND$' has "$D/research.md" 'Publish only after that: the filtered report goes into the `## Report` section'
t p127-research-limits '^FOUND$' has "$D/research.md" '## Limits'
t p127-research-zero '^FOUND$' has "$D/research.md" 'A report with zero validated claims cannot be posted as a conclusion'

# superfix-skill#156: a stale plugin copy must be easy to spot
PJ="$ROOT/.claude-plugin/plugin.json"; C="$ROOT/CONTRIBUTING.md"
# body_version <SKILL.md> <version>: the first non-blank line after the front matter must end "(version <version>)"
body_version() { local l; l="$(awk 'f==2 && NF {print; exit} /^---$/ {f++}' "$1")"; [ "$l" = "# Superfix Orchestrator (version $2)" ] && echo MATCH || echo "MISMATCH: $l"; }
meta_version() { local v; v="$(sed -n '2,/^---$/p' "$1" | sed -n 's/^  version: "\(.*\)"$/\1/p')"; [ "$v" = "$2" ] && echo MATCH || echo "MISMATCH: $v"; }
V="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$PJ")"
t v156-body-line1-version '^MATCH$' body_version "$S" "$V"
t v156-meta-version '^MATCH$' meta_version "$S" "$V"
t v156-checker-catches-wrong '^MISMATCH' body_version "$S" "0.0.0"
pcheck_same() { python3 -I - "$ROOT/tests/preservation-check.py" <<'PY'
import importlib.util, sys
s = importlib.util.spec_from_file_location("pc", sys.argv[1]); m = importlib.util.module_from_spec(s); s.loader.exec_module(m)
a = list(m.places("# T (version 1.2.3)\nbody\n", "f")); b = list(m.places("# T\nbody\n", "f"))
print("SAME" if a == b else f"DIFFERENT {a} {b}")
PY
}
t v156-preservation-ignores-version-tail '^SAME$' pcheck_same
t v156-contributing-restart-last '^FOUND$' bash -c "l=\$(sed -n '/^## Releasing and deploying/,/^## /p' '$C' | grep -E '^[0-9]+\. ' | tail -1); printf '%s' \"\$l\" | grep -qi 'restart Claude Code' && echo FOUND || echo \"MISSING: \$l\""

# issue 172: check visibility before the first post; a public security run posts neutral text only
t i172-skill-visibility '^FOUND$' has "$S" 'Visibility: PUBLIC|PRIVATE|INTERNAL'
t i172-skill-security '^FOUND$' has "$S" 'the full diagnosis stays in the file-mode journal'
t i172-journal-visibility '^FOUND$' has "$D/journal.md" 'gh repo view <owner>/<repo> --json visibility -q .visibility'
t i172-journal-security '^FOUND$' has "$D/journal.md" 'Security problem diagnosed; details are in the local journal'

# issue 173: a full-suite baseline before the fix, and a single-test re-run before calling a test new
t i173-baseline-run '^FOUND$' has "$D/execute.md" "run the full test suite once at approval-sha"
t i173-flaky-rerun '^FOUND$' has "$D/execute.md" "re-run that single test once; if the re-run passes, call it flaky"

# issue 174: narrow the trigger, lighten a Simple fix with one problem
t i174-trigger-name '^FOUND$' has "$S" 'starts on "superfix", on an issue'
t i174-trigger-issue-forms '^FOUND$' has "$S" '"issue #N", "fix #N", "implement #N"'
t i174-trigger-pull-request '^FOUND$' has "$S" 'to take a change through to a pull request'
t i174-trigger-criteria '^FOUND$' has "$S" 'or data clean-up against criteria the owner approves'
t i174-trigger-no-catchall '^ABSENT$' absent "$S" 'a request to fix, build or'
t i174-simple-body '^FOUND$' has "$S" 'the body holds only the Status line, ## Problems and ## Done when'
t i174-simple-labels '^FOUND$' has "$S" 'not set (simple)'
t i174-simple-diagram '^FOUND$' has "$S" 'The diagram question never applies to Simple'
t i174-simple-journal-body '^FOUND$' has "$D/journal.md" 'writes only the Status line, ## Problems and ## Done when in the body'
t i174-simple-journal-labels '^FOUND$' has "$D/journal.md" 'not set (simple)'
t i174-simple-three-lines '^FOUND$' has "$D/journal.md" 'three lines (problem, fix, effort) and "Go?"'

# issue 175: define the run folder where it is first used in SKILL.md
t i175-run-folder '^FOUND$' has "$S" '`<D>` is the run folder, `$HOME/.superfix/runs/<run-key>`'
t i175-run-folder-pointer '^FOUND$' has "$S" 'references/redaction.md, Run folder'

echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
