#!/bin/zsh
# usage: trun160.sh <name> <prompt-file> [session-id-to-resume]: one Superfix session on the 1.6.0 worktree, normal user settings
S="${SUPERFIX_T161:-$HOME/superfix-handoff/t161}"
PLUG=${PLUG:-$HOME/projects/skills-dev/superfix-1.6.1}
n=$1; pf=$2; sid=$3; d=$S/runs/$n
if [ -z "$sid" ] && [ ! -d $d ]; then git clone -q https://github.com/thedanielmay/superfix-testbed.git $d; fi
cd $d
k=1; out=$S/runs/$n.jsonl; while [ -e $out ]; do k=$((k+1)); out=$S/runs/$n-$k.jsonl; done
DISALLOW='Bash(gws:*),Bash(osascript:*),Bash(tw:*),Edit($HOME/Library/CloudStorage/**),Write($HOME/Library/CloudStorage/**)'
args=(-p --allowedTools 'Skill,Read,Write,Edit,Bash,Agent,Grep,Glob' --permission-mode acceptEdits --max-turns ${MAXTURNS:-150} --output-format stream-json --verbose "--disallowedTools=$DISALLOW")
[ -n "$sid" ] && args+=(--resume "$sid")
PATH="$S/shim:$PATH" claude --plugin-dir "$PLUG" "${args[@]}" "$(cat $pf)" > $out 2> $out.err
echo done > $out.done
echo $out
