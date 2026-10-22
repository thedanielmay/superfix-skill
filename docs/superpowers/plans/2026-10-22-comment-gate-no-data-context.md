# Context: comment-gate-no-data

## Problem Profile
- Primary type: bug
- Secondary type: security (a member name can reach a public comment and the gate cannot see it)
- Complexity: Moderate
- Skill manifest: systematic-debugging, code-explorer (inline), then the bug execute sequence (test first, implement, tests, simplify, code review, code security audit, silent failure hunt, verification before completion)

## Problem Description

[superfix-skill#98](https://github.com/thedanielmay/superfix-skill/issues/98): the comment scan passes when there is no data to compare.

`wo-scan-comment` and `wo-post` (added in [superfix-skill#93](https://github.com/thedanielmay/superfix-skill/issues/93)) compare a comment against the data files that are in the run folder at that moment: the locked original plus the copies under `work/`. When the run folder holds no data, the list of values to look for is empty, so every comment is clean and the gate opens. On `release/1.6.2` at 046e580 a comment that names a member and a join date, run through both commands in an empty run folder, printed `SCAN-VALUES-CLEAN` and then `POST-OK`.

The gate does not bite on the Stop gate comment of a criteria run (the data is copied into the run folder at go, after that comment is posted), on a code kind work order (no data file in the run folder at all), or on a criteria run whose working copies were already cleaned before the post. Severity 3: a member name could reach a public comment.

## Plan

Path: docs/superpowers/plans/2026-10-22-comment-gate-no-data.md

## Key decisions from exploration
- The refusal belongs in the tool: a scan that compared nothing must print `SCAN-NO-DATA`, exit 1 and write no receipt, because the receipt is the only thing `wo-post` checks.
- The refusal keys on the data file, not on the value list: a data file that holds only counts was compared and found nothing (a clean verdict), while a run that names no data file was not compared at all (the refusal).
- "This run holds no data" is declared, not guessed: the run names the data file it read with `--data`, or says it holds none with `--no-data` and the receipt records that basis. `SCAN-NO-DATA` is the exact condition that hides a leak, so it must not also be the licence to post.
- A file the scan cannot read is a refusal, never a skip: the value reader quietly skips anything that is not a regular file, so a symlink or a huge file would have become an empty value list and then a clean verdict.
- The trusted files are the `--data` files and the locked original; the run's own copies widen the comparison when they can be read and are skipped when they cannot.
- The rule the model must always follow is one inline line in SKILL.md; it covers every comment posted from the run, and the file posted is the file scanned, scanned before the post and the cleanup. The full wording lives in workorder.md.
- The receipt holds the digest, the file name, what was compared (the paths and their shas) and an end marker, and the scan writes it whole or not at all. The post refuses a cut receipt and refuses when the data changed since the scan. It is evidence, not a capability: the tool is detective, not preventive.
- The three smaller findings in the issue are fixed with it: the file name is scanned, a cut-short receipt does not open the gate, and a stop deletes the receipts.

## Relevant files
- skills/superfix/references/crit.py: `woc_comment_corpus`, `cmd_wo_scan_comment`, `cmd_wo_post`, `woc_cleanup_full` and the `wo-scan-comment` parser. The crit-15 check allows changes only inside `cmd_wo_*` and `woc_*`.
- skills/superfix/SKILL.md: the inline rule (one line; the file is at 434 of 440 lines). The root SKILL.md must stay identical to it.
- skills/superfix/references/workorder.md: the rule in full, for the work order flows.
- tests/workorder-criteria-tests.sh: the rows that pin the fix (the scan and post rows live around line 795).
- tests/preservation-1.6.1.md: a justification for every existing line of skills/superfix/*.md that the change removes or rewrites. Pure additions need no entry.
- tests/crit-15-check.py: the guard for the 1.5.0 commands.

## Evidence

- The head's own repro, run by hand on c4edaf1: `wo-scan-comment` in an empty run folder printed `SCAN-VALUES-CLEAN` (rc 0) for a comment holding `M7777`, `Quixotic Zanzibar` and a join date, and `wo-post` then printed `POST-OK`. The head has no `--data` option: `crit.py: error: unrecognized arguments: --data`.
- The same comment scanned in a run folder whose `work/` holds the members file gave `SCAN-VALUE id (comment line 3)`, rc 1, so the value comparison works and the corpus is its only source: the value list of the empty run folder is `[]`, of the populated one it holds the member name.
- The corpus is `woc_comment_corpus` = the locked original (from the lock's `origpath`) plus the `work/` copies; the data reaches the run folder at go, after the Stop gate comment is posted, and a code kind work order never has a data file.
