#!/bin/bash
# usage: sum.sh <name>: compact chain summary
S="${SUPERFIX_T161:-$HOME/superfix-handoff/t161}"
n=$1; python3 $S/check161.py $n > $S/runs/$n.check 2>&1
grep -E "^## |^Status|^Work order|^Criteria:|^cost|^Data yes|recommended on a data|^dedupe|'counts|'Ready|'solved|'not met|'met \(|'LATER|'Refs|'Closes|'Any copy|^folder |lock data|workorder: |run folder work" $S/runs/$n.check | cut -c1-230
for f in $(ls $S/runs/$n.jsonl $S/runs/$n-[0-9]*.jsonl 2>/dev/null); do echo "  -- $(basename $f): $(python3 $S/woout.py $f 'crit|git push|gh pr' | grep -v '^CMD' | sort -u | cut -c1-90 | tr '\n' ';' | cut -c1-600)"; done
N=$(cat $S/runs/$n.issue); ls ~/.superfix/runs/*+$N/work/neg 2>/dev/null | sed 's/^/  neg-left: /' | tr '\n' ' '; echo
