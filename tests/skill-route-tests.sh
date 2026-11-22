#!/bin/bash
# Tests for the skill route (agent-tools#8 stage 4). No model runs, no network.
# The detection cases extract and run the snippet from skill-route.md, so they test the real text.
# Usage: bash tests/skill-route-tests.sh
# ROOT=<another checkout> runs these tests against that checkout's files.
ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
D="$ROOT/skills/superfix/references"; S="$ROOT/skills/superfix/SKILL.md"; R="$D/skill-route.md"
T="$(mktemp -d "${TMPDIR:-/tmp}/skill-route.XXXXXX")"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
t() { local name="$1" want="$2" rc=""; shift 2; if [[ "$1" =~ ^[0-9]+$ ]]; then rc="$1"; shift; fi; local out rcgot; out="$("$@" 2>&1)"; rcgot=$?
  if printf '%s' "$out" | tr '\n' '|' | grep -qE "$want" && { [ -z "$rc" ] || [ "$rcgot" = "$rc" ]; }; then pass=$((pass+1)); echo "ok   $name"; else fail=$((fail+1)); echo "FAIL $name: want /$want/ rc=${rc:-any}, got rc=$rcgot: $(printf '%s' "$out" | head -c 160)"; fi; }
has() { grep -q -F -- "$2" "$1" && echo FOUND || echo MISSING; }
hasnot() { grep -q -F -- "$2" "$1" && echo FOUND || echo ABSENT; }
# detect <folder>: run the fenced snippet from skill-route.md on the folder.
detect() { local snip; snip="$(sed -n '/^```bash$/,/^```$/p' "$R" | sed '1d;$d')"; [ -n "$snip" ] || { echo NO-SNIPPET; return; }; bash -c "$snip"$'\n''is_skill_target "$1"' _ "$1"; }
mk() { mkdir -p "$T/$1/$(dirname "$2")"; printf '%b' "$3" > "$T/$1/$2"; }
GOOD='---\nname: x\ndescription: d\n---\nbody\n'

# pointer and file
t route-pointer '^FOUND$' has "$S" '### Skill route (when the target is a skill)'
t route-pointer-size '^OK$' bash -c "n=\$(sed -n '/^### Skill route/,\$p' '$S' | sed -n '1,/^\$/p' | grep -c .); [ \"\$n\" -le 8 ] && echo OK || echo \"TOO-LONG \$n\""
t route-file-flag '^FOUND$' has "$R" '--skill-review'
t route-file-check '^FOUND$' has "$R" "the skill repo's own checker"
t route-file-missing '^FOUND$' has "$R" 'not installed'
t route-file-away '^FOUND$' has "$R" 'is not a pick'
t route-no-owner-path '^ABSENT$' hasnot "$R" '/Users/'
t route-no-copy-stage '^ABSENT$' hasnot "$R" 'Stage 3'
t route-no-copy-critic '^ABSENT$' hasnot "$R" 'critic-'
t route-no-copy-claims '^ABSENT$' hasnot "$R" 'claims.py'

# detection
mk valid SKILL.md "$GOOD"
mk nested skills/x/SKILL.md "$GOOD"
mk code main.py 'print(1)\n'; mk code README.md '# r\n'
mk fixture tests/fixtures/SKILL.md "$GOOD"; mk fixture main.py 'x\n'
mk badfront SKILL.md '# no frontmatter\nname: x\ndescription: d\n'
mk noname SKILL.md '---\ndescription: d\n---\n'
t route-detect-skill '^SKILL-TARGET$' detect "$T/valid"
t route-detect-nested '^SKILL-TARGET$' detect "$T/nested"
t route-not-skill-code '^NOT-SKILL$' detect "$T/code"
t route-not-skill-fixture '^NOT-SKILL$' detect "$T/fixture"
t route-not-skill-bad-front '^NOT-SKILL$' detect "$T/badfront"
t route-not-skill-no-name '^NOT-SKILL$' detect "$T/noname"

# length cap
t route-skillmd-cap '^OK$' bash -c "n=\$(wc -l < '$S'); [ \"\$n\" -le 352 ] && echo OK || echo \"TOO-LONG \$n\""

echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
