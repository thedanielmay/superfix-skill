# The gate tools

The harness that drives the live gates for a Superfix release. These scripts run
Superfix itself, against a private testbed repo, with `claude -p`. They cost money
every time they run, and they reset the testbed, so read the file you are about to
run.

Nothing here is part of the skill's behaviour. The skill never runs these; they
run the skill.

## Before you run anything

- They need a clone of the private testbed `thedanielmay/superfix-testbed` and a
  `gh` login that can read it.
- They need the seed fixtures: `~/superfix-handoff/scripts/seed15`.
- They need a place to work. Every script takes its scratch directory from
  `SUPERFIX_T161`, and defaults to `$HOME/superfix-handoff/t161`. Make it first:
  `mkdir -p "$HOME/superfix-handoff/t161"`.
- The scripts call `claude` with `--plugin-dir` and the plugin copy you point
  `PLUG` at. A Superfix session is a real model session: about 1 to 5 USD a chain,
  more for the bigger ones. The 1.6.1 re-run spent 123.79 USD on the 24 chains in
  `runs/` and 1.27 USD on the cold executors in `ex/`.
- The reset script closes every open issue and pull request on the testbed,
  deletes the branches, force-pushes the seed tag to the testbed's `main`, and
  removes the testbed's run folders. Only ever point it at the testbed.

## What each file does

| File | What it does |
|---|---|
| `reset161.sh <seed>` | the wrapper: calls `reset150.sh` with the seed name, then clears the handed work order folders |
| `reset150.sh <seed>` | the reset itself: closes the testbed's issues and pull requests, deletes its branches, force-pushes the seed to `main`, clears the testbed run folders |
| `batch.sh <list> <log>` | runs the chain commands in a list file, at most 6 at a time, 30 seconds apart, and writes to the log |
| `r1.sh <chain name>` | one normal code run: opens the pricing issue in the testbed, runs Superfix on it with no work order words, answers the stop gate, and leaves it at "Ready for review" |
| `w2lib.sh` | the shared helpers the chains use: the work order folder lookup, the snapshot, and the reply function that resumes the session |
| `trun161.sh <name> <prompt file> [session id]` | one Superfix session on the plugin copy, with the DISALLOW list: `gws`, `osascript`, `tw` and writes into CloudStorage are refused by the harness, and the `gws` shim goes on PATH |
| `exec161.sh <name> <model> <folder> <sha>` | one cold executor: a fresh session with the Phase 0 settings, given the work order folder and its sha |
| `carry161.sh <name> <exec name> <model>` | copies the handed folder to the cold executor, runs it, and copies the folder back |
| `cont161.sh <name>` | the continue session: "continue superfix on issue N", with the folder back at its destination |
| `sidof.sh <transcript>` | prints the session id inside a transcript, so the next session can resume it |
| `check161.py <chain>` | the facts about one chain: the issue, the labels, the words the tool printed, the pull requests, the cost |
| `check160s.py <chain>` | the older part of the same checker, which `check161.py` calls |
| `woout.py <transcript> [pattern]` | the Bash calls in a transcript that match a pattern, with the tail of their output |
| `judgeL.py <exec dir> <issue>` | judges a cold executor's returned folder: the report, the unchanged work order and checks, the files outside FILES, and the locked measure scripts run by the harness |
| `sum.sh <chain>` | the compact summary of one chain, the same shape the gate notes use |

## The pass rules

Each gate has its own rule set, written as greppable lines. The ones the 1.6.1
re-run used:

**A criteria work order chain (V3).** The return is accepted, the verify passes,
and the three runs of the criteria solved check behave:
```
RETURN-CRITERIA-COPIED
VERIFY-PASS
the counts meet your checks
```
and the work order line in the issue says `Work order: VERIFIED PASS`.

**A normal code run (R1).** The issue reaches a pull request, no work order words
appear in the transcript, no `CRITERIA-` word appears, and no work order folder is
created for the issue.

**A cold executor code work order (w1c).** The return is accepted, the verify
passes, the solved check passes, and a pull request is open:
```
RETURN-OK
VERIFY-PASS
SOLVED-OK
```

**A stale original (V6).** The return stops with `RETURN-ORIGINAL-MOVED`, nothing
is measured, and the stop is posted on the issue.

**An upgrade chain.** The verify passes under the new version with no
`CRIT-SHA-MISMATCH`, and the `crit` line in the lock is the same sha as the tool
of the version that locked it.

## The 1.6.2 gates

The scripts for the 1.6.2 release gates, with the pass rules and the estimated
costs, are in `~/superfix-handoff/out162/gates-1.6.2.md` and
`~/superfix-handoff/out162/gates/`. Those are the newer, self-contained versions:
they take the seed name as a mandatory argument, they refuse to run without it,
and they check that this harness still carries the DISALLOW list before they start.
