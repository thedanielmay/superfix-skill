# shared helpers for wave 2 chains (source it)
S="${SUPERFIX_T161:-$HOME/superfix-handoff/t161}"
wodir() { ls -d $HOME/superfix-workorders/*+$(cat $S/runs/$1.issue)-wo* 2>/dev/null | tail -1; }
snap() { local W=$(wodir $1); [ -d "$W" ] && rm -rf $S/src/$1 && cp -R "$W" $S/src/$1; }
reply() { local f=$S/runs/$1-r$(date +%s).txt; printf '%s' "$2" > $f; $S/trun161.sh $1 $f "$($S/sidof.sh $(ls -t $S/runs/$1.jsonl $S/runs/$1-[0-9]*.jsonl | head -1))" >/dev/null; }
