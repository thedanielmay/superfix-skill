# Comment gate: no data means no clean verdict (superfix-skill#98)

Plan for the fourth-round fix of the comment gate in Superfix 1.6.2, on branch `fix/98-comment-gate-no-data` from `release/1.6.2` at c4edaf1.

## The problem in one line

`wo-scan-comment` compares a comment against the data files that happen to be in the run folder at that moment. When the run folder holds no data file the list of values is empty, so the scan finds nothing, prints `SCAN-VALUES-CLEAN` and writes a receipt, and `wo-post` opens the gate for a comment that names a member.

## What changes and why

1. `skills/superfix/references/crit.py`
   - `woc_comment_corpus(D, extra)`: the corpus is split in two. The trusted files are the ones the caller names with `--data` plus the locked original (the data the run locked): a trusted file that cannot be read refuses the scan, because a scan that compared nothing must not print a clean verdict. The extra files are the run work copies and the originals the run's own `.sf-orig` records name: they widen the comparison when they can be read and are skipped when they cannot, so an unreadable extra never blocks a run.
   - `cmd_wo_scan_comment`: a repeatable `--data` option, a `--no-data` declaration and an `--asked` flag for a cloud file. With no data file to compare it prints `SCAN-NO-DATA`, exits 1, writes no receipt and withdraws any receipt the same bytes had before, so nothing downstream can read it as a clean scan. A trusted file that cannot be read gets its own word (`SCAN-NO-FILE`), a cloud or online-only one `ASK-FIRST`, so a typo can never look like "this run holds no data". With `--no-data` the caller declares that the run holds no data file: the receipt records that basis and the scan prints `SCAN-NO-DATA-DECLARED` (rc 0), so the post still goes through the same two commands. The comment's file name is scanned with the body, the non-alphanumerics folded to spaces, so a slugified name still holds the value, and only the distinctive values count (an ordinary word like Active is not a file name). The receipt is written whole or not at all (a temporary file and a rename) and carries an end marker.
   - `cmd_wo_post`: the receipt must hold the digest, the file name, the basis and the end marker, so a receipt cut short mid-write does not open the gate. The basis decides: a real comparison prints `POST-OK`, a declared no-data run prints `POST-OK-DECLARED`, and a file whose sha changed since the scan prints `POST-REFUSED`.
   - `woc_distinctive_values`: a tab-separated data file is read per cell, not as one long row, so a member name in a `.tsv` is caught like it is in a `.csv`.
   - `woc_comment_value_hits`: the run's own `Internal:` records stay unscanned, as on the base: they hold the run's own records (a hash, an approval), not data. Every other line is scanned, the AI detail included.
   - `woc_cleanup_full` and `cmd_wo_cleanup`: the scan receipts are working files of the comment gate, not records, so the cleanup that runs on a stop deletes them and names any it could not delete. A pass keeps them, because the final comment is scanned after that cleanup.
   - the `wo-scan-comment` parser gains `--data`, `--no-data` and `--asked`.
2. `skills/superfix/SKILL.md` and the root `SKILL.md` (the two must stay identical): one inline line with the rule. SKILL.md was at 434 of 440 lines, so 6 lines were free.
3. `skills/superfix/references/workorder.md`: the rule in full, for the work order flows (the Stop gate comment, the code kind final comment and the criteria return path).
4. `skills/superfix/references/criteria.md`: one line that says the scan receipts are working files, not records, so a stop deletes them and a pass keeps them.
5. `tests/workorder-criteria-tests.sh`: one row per fix, each failing on the base and passing after.
6. `docs/superpowers/plans/`: this plan and the context file.

## Key design decisions

- The refusal lives in the tool, not only in the wording. A scan that compared nothing must not print a clean verdict, and must not write a receipt, because the receipt is the only thing `wo-post` looks at.
- The refusal keys on the data file, not on the value list. A data file that holds only counts was compared, and the comparison found nothing, so that is a clean verdict; a run that names no data file at all was not compared, and that is the refusal. The issue's own wording ("it must not print SCAN-VALUES-CLEAN unless the scan was given the values to check") is this rule.
- "This run holds no data" is a declared fact, not an absence the tool guesses. `SCAN-NO-DATA` is the exact condition that hides a leak, so it must not also be the licence to post: the run either names the data file it read with `--data`, or says it holds none with `--no-data`, and the receipt records which. Without the declaration the code kind path could never post, because its run folder never holds a data file.
- A file the scan cannot read is a refusal, never a skip. The value reader quietly skips anything that is not a regular file, so a symlink or a huge file would have turned into an empty value list and then into a clean verdict. The scan checks the trusted files itself first and refuses with `SCAN-NO-FILE`.
- The cloud guard covers the whole trusted set, not only `--data`: a cloud original in the run folder is read the same way `copy` reads it, so it needs the owner's yes there too.
- The rule the model must always follow is inline in SKILL.md, because reference-file reads are unreliable. It covers every comment posted from the run, not only the two the issue names, and it says that the file posted is the file scanned and that the scan comes before the post and the cleanup.
- The receipt is evidence, not a capability: it shows what was compared and with which sha, the end marker catches a torn write and the post refuses when the data changed since the scan. It does not stop a model that decides to write one, and the tool is detective, not preventive (the repo says so in criteria.md).
- The three smaller findings in the issue are fixed in the same change, each with its own test: the file name is scanned, a cut-short receipt does not open the gate, and a stop deletes the receipts.

## Not in scope

- The 1.5.0 criteria mode's own commands. The crit-15 check guards them, and the issue's fix list names the 1.6.x paths.
- Any change to a 1.5.0 command in crit.py. The crit-15 check must still print `CRIT-1.5-UNCHANGED 106 functions`.
- The live gate chains under `tests/gates`. They cost money and reset the testbed, so they do not run in this change.
- The version in `.claude-plugin/plugin.json`, the `main` branch, any merge, tag or release.

## Checks, all green before the PR

```
python3 tests/preservation-check.py .
bash tests/workorder-tests.sh
bash tests/workorder-criteria-tests.sh
python3 tests/crit-15-check.py skills/superfix/references/crit.py
```

## The red-green rows

| Row | Base | After |
|---|---|---|
| a scan in a run folder with no data file | `SCAN-VALUES-CLEAN`, rc 0, a receipt | `SCAN-NO-DATA`, rc 1, no receipt |
| a scan in a run folder that holds only a notes file | `SCAN-VALUES-CLEAN`, rc 0 | `SCAN-NO-DATA`, rc 1, no receipt |
| the same scan with `--data <the owner's original>` on a comment that names a member | no `--data` option | `SCAN-VALUE`, rc 1, no receipt |
| the same scan with `--data` on a clean comment | no `--data` option | `SCAN-VALUES-CLEAN`, rc 0, a receipt, and `wo-post` prints `POST-OK` |
| the same scan with `--no-data` | no `--no-data` option | `SCAN-NO-DATA-DECLARED`, rc 0, a receipt that records the basis, and `wo-post` prints `POST-OK-DECLARED` |
| a `--data` file that does not exist | no `--data` option | `SCAN-NO-FILE`, rc 1, no receipt |
| a `--data` file that is a symlink | no `--data` option | `SCAN-NO-FILE`, rc 1, no receipt |
| a `--data` file that is tab separated | no `--data` option | `SCAN-VALUE`, rc 1, no receipt |
| a `--data` file that holds only counts | no `--data` option | `SCAN-VALUES-CLEAN`, rc 0 (the comparison happened and found nothing) |
| `wo-post` on a receipt cut short mid-write | `POST-OK` | `POST-REFUSED`, rc 1 |
| `wo-post` when the data changed after the scan | `POST-OK` | `POST-REFUSED`, rc 1 |
| a refused scan after a clean one | `POST-OK` | `POST-REFUSED`, rc 1 (the refusal withdraws the receipt) |
| a comment whose file name holds a distinctive value | `SCAN-VALUES-CLEAN` | `SCAN-VALUE`, rc 1 |
| the cleanup on a stop (a code run and a criteria run) | the receipt stays | the receipt is gone |
| a pass cleanup | the receipt stays | the receipt stays |
