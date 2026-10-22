#!/bin/zsh
# usage: reset161.sh [tag]  default seed-1.6c: reset150.sh (KEEPGAPS=yes) plus the work order folders. Never while a run is active.
S="${SUPERFIX_T161:-$HOME/superfix-handoff/t161}"
pgrep -f "plugin-dir" >/dev/null && { echo "RUNS-ACTIVE: not resetting"; exit 1; }
pgrep -f "strict-mcp-config --setting-sources project" >/dev/null && { echo "EXECUTORS-ACTIVE: not resetting"; exit 1; }
KEEPGAPS=yes $S/reset150.sh ${1:-seed-1.6c}
rm -rf $HOME/superfix-workorders/*superfix-testbed*(N) /private/tmp/superfix-wo-*superfix-testbed*(N)
echo "workorder folders left: $(ls $HOME/superfix-workorders 2>/dev/null | wc -l)"
