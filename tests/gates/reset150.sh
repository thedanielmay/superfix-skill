#!/bin/zsh
# usage: reset150.sh [tag]  default seed-1.4.1: reset the private testbed and the gap repo
S="${SUPERFIX_T161:-$HOME/superfix-handoff/t161}"
R=thedanielmay/superfix-testbed; T=${1:-seed-1.5}; KEEPGAPS=${KEEPGAPS:-no}
for n in $(gh pr list --repo $R --state open --json number -q '.[].number'); do gh pr close $n --repo $R --delete-branch >/dev/null 2>&1; done
for n in $(gh issue list --repo $R --state open --json number -q '.[].number'); do gh issue close $n --repo $R >/dev/null 2>&1; done
gh release delete assets --repo $R --yes --cleanup-tag >/dev/null 2>&1
for l in superfix:awaiting-decision superfix:approved superfix:gap; do gh label delete "$l" --repo $R --yes >/dev/null 2>&1; done
cd $S/testbed && git fetch -q --tags origin
for b in $(git ls-remote --heads origin | awk '{print $2}' | sed 's#refs/heads/##' | grep -v '^main$'); do git push -q origin --delete $b 2>/dev/null; done
git push -q -f origin $T:main
rm -rf $HOME/.superfix/runs/thedanielmay+superfix-testbed+*(N) $HOME/.superfix/journal/thedanielmay-superfix-testbed*(N) $HOME/.superfix/gaps   # only the testbed (21 Oct 2026): other runs, such as a Superfix run on its own repo, must survive a reset
if [ "$KEEPGAPS" != yes ]; then for n in $(gh issue list --repo thedanielmay/superfix-gaps --state open --json number -q '.[].number'); do gh issue close $n --repo thedanielmay/superfix-gaps >/dev/null 2>&1; done; fi
echo "reset-done to $T; releases: $(gh release list --repo $R | wc -l); gap notes open: $(gh issue list --repo thedanielmay/superfix-gaps --state open --json number -q length)"
