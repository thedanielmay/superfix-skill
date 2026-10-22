#!/bin/bash
# Gate R1: a NORMAL code run, no work order words, on the 1.6.1 plugin.
# usage: r1.sh r1-<k>   (one chain per call; the caller decides how many to start)
# Same harness as w1code.sh and v3.sh: same plugin dir (trun161.sh PLUG default
# $HOME/projects/skills-dev/superfix-1.6.1), same DISALLOW list inside trun161.sh,
# same testbed clone, same "No reminder" answers, same auto-answer of follow-up
# stop questions (up to 2 extra replies). The only difference from w1code.sh:
# the prompt carries no work order, executor or hand over words, and there is no
# cold executor step, because a normal run does the work itself.
. "${SUPERFIX_T161:-$HOME/superfix-handoff/t161}/w2lib.sh"
n=$1; [ -n "$n" ] || { echo "usage: r1.sh r1-<k>"; exit 1; }
R=thedanielmay/superfix-testbed
# one issue per chain: the R1 pricing issue (seed-1.4.1)
N=$(gh issue create --repo $R --title "The Subscribe button on the pricing page is cut off ($n)" --body "On public/pricing.html the Subscribe button is cut off at the bottom of the plan card, so part of it cannot be clicked. Fix it so the whole button shows and works." | sed 's#.*/##'); echo $N > $S/runs/$n.issue
# the prompt: plain Superfix request on a code issue, no work order words
printf '%s' "Use the superfix:superfix skill (invoke it with the Skill tool) on this: issue #$N in $R (use gh to read it). You are in a clone of that repo." > $S/runs/$n.txt
$S/trun161.sh $n $S/runs/$n.txt >/dev/null
# first answer: recommended answers, no reminder, keep executing
reply $n "Use your recommended answer for every question; where you give none, yes. No reminder: do not create one. Keep executing."
# up to 2 more answers if the stop gate is still waiting on questions
for i in 1 2; do gh issue view $N --repo $R --json body -q .body | grep -m1 "^\*\*Status" | grep -qi "question" || break; reply $n "Use your recommended answer for every question; where you give none, yes. No reminder: do not create one. Keep executing."; done
# end state: print the Status line and any PR link the run left on the issue
echo "r1 $n issue $N finished: $(gh issue view $N --repo $R --json body -q .body | grep -m1 '^\*\*Status' | cut -c1-160)"
gh issue view $N --repo $R --json comments -q '.comments[].body' | grep -oE 'https://github.com/thedanielmay/superfix-testbed/pull/[0-9]+' | tail -1
echo "no work order folder expected for issue $N; check: ls -d \$HOME/superfix-workorders/*+$N-* 2>/dev/null"
