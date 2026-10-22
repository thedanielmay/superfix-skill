#!/bin/bash
# usage: carry.sh <name> <exec name> <model>: copy the newest work order folder of the chain's issue to a cold executor, run it, carry the folder back
S="${SUPERFIX_T161:-$HOME/superfix-handoff/t161}"
n=$1; e=$2; m=$3; N=$(cat $S/runs/$n.issue); W=$(ls -d $HOME/superfix-workorders/*+$N-wo* | tail -1)
[ -f "$W/workorder.md" ] || { echo "NO-WORKORDER for $n"; exit 1; }
$S/exec161.sh $e $m "$W" "$(shasum -a 256 "$W/workorder.md" | cut -d' ' -f1)"
rm -rf "$W"; cp -R $S/ex/$e/folder "$W"
