#!/bin/bash
# usage: cont.sh <name> [extra words]: a fresh Superfix session: "continue superfix on issue N", the folder back at its destination
S="${SUPERFIX_T161:-$HOME/superfix-handoff/t161}"
n=$1; N=$(cat $S/runs/$n.issue); k=$(ls $S/runs/$n-cont*.txt 2>/dev/null | wc -l | tr -d ' '); f=$S/runs/$n-cont$((k+1)).txt
printf '%s' "Use the superfix:superfix skill (invoke it with the Skill tool): continue superfix on issue #$N in thedanielmay/superfix-testbed. The work order folder came back at $(ls -d $HOME/superfix-workorders/*+$N-wo* | tail -1). You are in a clone of that repo.${2:+ $2}" > $f
$S/trun161.sh $n $f >/dev/null
