# Plan: a stop ends clean, and the kept record is named

Plan for [superfix-skill#94](https://github.com/thedanielmay/superfix-skill/issues/94), on `release/1.6.2`.

## What changes and why

| File | What changes | Why |
|---|---|---|
| `skills/superfix/references/crit.py` | `woc_cleanup_full` splits the leftovers in two. `left` holds paths that may hold personal data. `kept` holds the records, which are not data. A `.sf-orig` file whose content parses as one sha256 and one path is a record: it goes into `kept`, never into `left`, and it is still deleted when the named original still hashes the same. The kept records are printed on a `CLEANUP-KEPT` line, so every path that runs the cleanup names them. | The record holds one sha256 and one path, 110 bytes, and the success line already says "records kept". Listing it with the data copies tells the owner to delete a harmless file by hand and makes the cleanup exit 1, so a stop never reaches `CLEANUP-OK`. The same false alarm hit a job whose original sits on cloud or is online-only, because a placeholder original could not be hashed. |
| `skills/superfix/references/criteria.md` | the one sentence that says a stop deletes everything is corrected to say what a stop leaves and names the `CLEANUP-KEPT` line. | The docs would otherwise promise a clean stop that the tool does not deliver. |
| `skills/superfix/references/workorder.md` | the same sentence in the return step, in the same shape. | The two files describe one behaviour; they must read the same way. |
| `tests/workorder-criteria-tests.sh` | four new tests, one existing test changed, the docs test moved to the new words, the move check rewritten. | The failing test first, and the guards that keep the warning's teeth. |
| `tests/preservation-1.6.1.md` | two justification lines for the edited sentences. | The preservation check compares every changed line of the .md files under `skills/superfix/` against the tag. |

## The tests, in order

1. **The failing test.** A rig whose original has one edited fee cell (the V6 shape), then `wo-cleanup` must print `CLEANUP-OK`, exit 0, and name the record on a `CLEANUP-KEPT` line. It fails on the base commit with `CLEANUP-INCOMPLETE` and exit 1.
2. **The no-data sweep.** The same rig, swept for `.csv` and `.tsv` files under the run folder and the work order folder: none may be left. A success line that leaves a copy behind would be a lie.
3. **The guard.** A file named `*.sf-orig` whose bytes do not parse as a hash and a path is not a record: it may hold anything, so it stays a leftover, the cleanup prints `CLEANUP-INCOMPLETE` and exits 1.
4. **The unchanged behaviour.** A record whose original still hashes the same is still deleted, so the run folder ends with no orphan record. The existing test `wo-cleanup-ok` covers the happy path; `wo-cleanup-orphan-unchanged-deletes` covers the orphan.

## Key design decisions

- The record is a kept record, not a leftover. It stays on disk because it is the evidence that the original moved, and the cleanup names it so the owner sees what is left.
- The split is two lists, not one list with a filter, so a path that really may hold personal data is never confused with a record.
- A record whose original cannot be hashed, because the original is on cloud, is online-only, or cannot be read, is still a record. It is kept, and the reason is named. Before, a cloud original was reported as personal data, which is the same false alarm this fix removes.
- The change sits in `woc_cleanup_full` only. It is in the set the 1.5.0 check does not compare, so `CRIT-1.5-UNCHANGED 106 functions` still prints. Measured with a probe copy of the tool that had a comment added inside the cleanup body: the check still printed `CRIT-1.5-UNCHANGED 106 functions`.
- The kept records are printed where the cleanup runs, not by the caller, so the stop path, the verify path and the send-back path all name them.
- The tool's bytes change, so the sha256 of the tool moves and the crit-sha of newly locked jobs changes. Jobs locked under an earlier version keep their own copy of the tool and keep working. The 1.6.2 release notes get one line about it.

## What is explicitly not in scope

- The scan receipts the 1.6.2 post gate leaves, `D/scan-<sha>.txt`. They are not removed by the cleanup either, and the same split would apply. It goes on the deferred list.
- The handed folders under `~/superfix-workorders`. The cleanup does not touch them and never did.
- Any 1.5.0 command. The crit-15 check guards them and must keep printing 106 functions.
- The README lines that still say the tool is inside `criteria.md`. They are wrong today, but they belong to the documentation pass, not to this fix.
- Three pre-existing gaps the review found in the same function, none of them caused by this change: a rounds folder that cannot be read aborts the cleanup with `ERROR wo-cleanup PermissionError` and no path named; the work-order id is taken from the stub and is never checked against the lock, so a stub that does not match the lock makes the cleanup scan the wrong folders; a record whose data copy still exists is left unnamed. Each wants its own issue and its own test.

## The risk, and how it shows up

The risk is that something which is not harmless stops being reported. The guard test covers it: a file named `.sf-orig` that does not parse as a record is still a leftover and the cleanup still exits 1. A second risk is that the success line becomes a lie, so the no-data sweep has to pass and the kept records are named in the output.

## How it is checked

- The failing check from the issue body, re-run at the end.
- The free suites: 110 work order tests and 221 criteria tests, with the new tests failing on the base and passing after.
- The preservation check at 0 unjustified, and `CRIT-1.5-UNCHANGED 106 functions`.
