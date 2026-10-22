#!/bin/bash
# WARNING: this runs a model with Bash and acceptEdits and no sandbox. It simulates a cold outside executor, so run it only
# on a throwaway folder on a machine you accept that risk on. Outward commands are denied below; that is not isolation.
# usage: exec161.sh <name> <sonnet|haiku> <work order folder to copy> <WORKORDER-SHA hex>: one cold executor run (Phase 0 settings)
S="${SUPERFIX_T161:-$HOME/superfix-handoff/t161}"
n=$1; m=$2; src=$3; sha=$4; d=$S/ex/$n
[ -e "$d" ] && { echo "exists $d"; exit 1; }
mkdir -p "$d/tmp"; cp -R "$src" "$d/folder"
prompt="WORKORDER-SHA $sha (sha256)
Carry out workorder.md exactly."
cd "$d/folder" && env TMPDIR="$d/tmp" CLAUDE_CODE_DISABLE_CLAUDE_MDS=1 CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 CLAUDE_CODE_DISABLE_ADVISOR_TOOL=1 \
  claude -p --strict-mcp-config --setting-sources project --model "$m" --max-turns 60 \
  --allowedTools "Read,Write,Edit,Bash,Grep,Glob" --disallowedTools "Bash(gh:*),Bash(curl:*),Bash(wget:*),Bash(ssh:*),Bash(scp:*),Bash(git push:*)" --permission-mode acceptEdits \
  --output-format stream-json --verbose "$prompt" > "$d/run.jsonl" 2> "$d/run.err"
echo "rc=$?" > "$d/done"
