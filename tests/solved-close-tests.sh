#!/bin/bash
# Tests for 1.6.4 solved check run 3, merged tree, zero checks, closing verify (superfix-skill#107 items 2 to 5).
# No model runs, no network. Needs: git.
# Usage: bash tests/solved-close-tests.sh
# ROOT=<another checkout> runs these tests against that checkout's files (used to show a test fails before its fix).
ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
pass=0; fail=0
t() { local name="$1" want="$2" rc=""; shift 2; if [[ "$1" =~ ^[0-9]+$ ]]; then rc="$1"; shift; fi; local out rcgot; out="$("$@" 2>&1)"; rcgot=$?
  if printf '%s' "$out" | tr '\n' '|' | grep -qE "$want" && { [ -z "$rc" ] || [ "$rcgot" = "$rc" ]; }; then pass=$((pass+1)); echo "ok   $name"; else fail=$((fail+1)); echo "FAIL $name: want /$want/ rc ${rc:-any} got: $(printf '%s' "$out" | tr '\n' '|' | cut -c1-300) (rc $rcgot)"; fi; }
has() { grep -q -F -- "$2" "$1" && echo FOUND || echo MISSING; }
absent() { grep -q -F -- "$2" "$1" && echo PRESENT || echo ABSENT; }

# item 2: run 3 reverts only the fix's own named files, and runs 1 and 3 name the failing guard
t run3-named-files '^FOUND$' has "$ROOT/SKILL.md" "checkout <approval-sha> -- <fix files that existed, no test paths>; git -C <s3> rm -q -f -- <files the fix added>"
t run3-no-range-revert '^ABSENT$' absent "$ROOT/SKILL.md" "diff <approval-sha>..HEAD -- . ':!test' ':!tests'"
t run1-names-guard '^FOUND$' has "$ROOT/SKILL.md" "name the expected failing guard and check its line fired"
t run3-same-guard '^FOUND$' has "$ROOT/SKILL.md" "expect failure through the same named guard"
# run 3 behaves on a real repo: the fix modifies one file and ADDS another (the case that used to error and revert nothing)
R3="$(grep -F 'git -C <s3> checkout <approval-sha> --' "$ROOT/SKILL.md" | head -1 | sed 's/^ *`//; s/`; *$//')"
run3() { local d; d="$(mktemp -d "${TMPDIR:-/tmp}/run3-test.XXXXXX")"; ( cd "$d" && git init -q r && cd r && git config user.email a@b && git config user.name n && echo a > a.txt && git add . && git commit -qm base \
  && A="$(git rev-parse HEAD)" && echo b >> a.txt && echo new > new.txt && git add . && git commit -qm fix && git worktree add -q --detach ../s3 HEAD \
  && cmd="${R3//<s3>/..\/s3}"; cmd="${cmd//<approval-sha>/$A}"; cmd="${cmd//<fix files that existed, no test paths>/a.txt}"; cmd="${cmd//<files the fix added>/new.txt}" \
  && eval "$cmd" && [ "$(cat ../s3/a.txt)" = a ] && [ ! -e ../s3/new.txt ] && echo REVERTED-BOTH ); }
t run3-reverts-modified-and-added '^REVERTED-BOTH$' run3
# item 3: merged tree rule lives in execute.md
t merged-tree-reprove '^FOUND$' has "$ROOT/skills/superfix/references/execute.md" "merge main into the branch and re-prove"
t merged-tree-not-tested '^FOUND$' has "$ROOT/skills/superfix/references/execute.md" "merged tree not re-tested"
# item 4: zero registered checks is not green, via the 1.6.3 checks key
t zero-checks-not-green '^FOUND$' has "$ROOT/SKILL.md" "zero registered checks is NOT green"
t checks-key-pointer '^FOUND$' has "$ROOT/SKILL.md" "python3 references/project.py <repo>"
# item 5: closing verify lives in journal.md
t closing-refs '^FOUND$' has "$ROOT/skills/superfix/references/journal.md" "closingIssuesReferences"
t close-by-hand '^FOUND$' has "$ROOT/skills/superfix/references/journal.md" "close it by hand with a comment"

echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
