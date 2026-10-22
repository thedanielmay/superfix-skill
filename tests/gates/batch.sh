#!/bin/bash
# usage: batch.sh <list file> <log>: run each line (a chain command) with at most 6 at a time, 30 s apart at start
S="${SUPERFIX_T161:-$HOME/superfix-handoff/t161}"
n=0; while read -r line; do [ -z "$line" ] && continue
  while [ "$(jobs -rp | wc -l)" -ge 6 ]; do sleep 20; done
  ( eval "$S/$line"; echo "CHAIN-DONE $line" ) >> $2 2>&1 & n=$((n+1)); sleep 30
done < $1; wait; echo "BATCH-DONE $1" >> $2
