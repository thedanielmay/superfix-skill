# Versions

One entry per tagged release from 1.1.0 to 1.6.5. The details come from the GitHub release notes where one was published. Ten of the tags in this range have no GitHub release note; for those the entry records the tag date and the tag's commit subject, and says that the release contents are not documented.

The current release is 1.6.5, tagged on 24 October 2026.

## 1.6.5

Tag date: 2026-10-24. Release note: [Superfix 1.6.5](https://github.com/thedanielmay/superfix-skill/releases/tag/v1.6.5).

In plain words: the clean-up step now removes the leftovers it used to call clean, the two work order checks share their loops, and a work order of a kind Superfix cannot do is refused before any of the owner's data is copied.

- Every name at the top of a job stub or round folder other than `work`, `checks`, `workorder.md` and `key` counts as a stray. A regular file or link is removed. A directory, FIFO, socket or hardlinked file is listed in `CLEANUP-INCOMPLETE` and left alone. A FIFO or socket named `report.md` used to be skipped silently.
- The work order check shares its missing key and freshness loops between the code kind and the criteria kind. The two exclusion lists stay separate, and the 1.5.0 guard still prints `CRIT-1.5-UNCHANGED 106 functions`.
- A `KINDS:` line makes `wo-check` and `wo-lock` print `WORKORDER-KIND-REFUSED` for `qik`, `live`, `sheet`, `doc` or any kind outside code and criteria, and for a code plus criteria mix, before any copy of the owner's data is made. A work order with no `KINDS:` line behaves as before.

Known limits in the release note: rolling back from 1.6.1 to 1.6.0 breaks a job locked under 1.6.1 (`CRIT-SHA-MISMATCH`), so a locked job is finished on the version it was locked under; a job locked under 1.5.0 keeps the 1.5.0 tool, including the weakness 1.6.0 closed, because moving it to a newer version would change its checks mid-run; the `crit.py` sha256 changes in 1.6.5, and jobs locked under 1.6.4 keep their own copy.

Not done, as the release note says: single-directory cleanup with rounds as subfolders needs a migration decision, because it moves where folders are handed off and returned; file-descriptor-safe deletion needs Python 3.11 and defends a same-user race that stays out of scope; an executor running as the same user on the same Mac stays out of scope.

Tests reported: new `cleanup-tests` (15), `wo-dedupe-tests` (11) and `workorder-kinds-tests` (11); the existing suites unchanged and passing, work order 115, criteria 240, project 52, redaction 16, solved check 11 and skill text 29.

## 1.6.4

Tag date: 2026-10-23. Release note: [Superfix 1.6.4](https://github.com/thedanielmay/superfix-skill/releases/tag/v1.6.4).

In plain words: three safeguards that used to be instructions are now real checks that fail loudly, the solved check reverts only the fix's own files, and a handful of short rules from the engine review are in the skill text.

- The redaction pattern check is one script, `references/redact-check.py`, run with `--run <run-folder> -- <files>` or `--self-test`. It prints the exact-string word and then `PATTERN-CLEAN` or `PATTERN-HITS`, and exits 1 on `BLOCKED`, `ERROR` or `NO-RUN-FOLDER`.
- The label, diagram and gap gate snippets now exit 1 on failure.
- Zero registered checks is no longer reported as green.
- Solved check run 3 reverts only the fix's own files and names the expected failing guard. A fix that adds a new file used to revert nothing.
- If main moved after the proof, the run records "merged tree not re-tested" and verifies the closing state after the merge.
- Skill text: issue claims are hypotheses; the issue's own control is run; readers are listed with counts; scans need a positive control; tests-only work gets a one-paragraph type; review depth scales with the diff; the budget counts active time; loose ends found in review are not scope creep; the mutant rule applies only to rows that pin a gate or check; merge commits are exempt from the trailer.

Known limits in the release note: the 29 skill-text tests check that the wording is present, not that the rules work; the three new test scripts are not in CI, as with the work order tests.

Tests reported: 115 work order, 240 criteria, 52 settings, 16 redaction, 11 solved check and 29 skill text. Preservation: 18 removed lines, all justified, 0 unjustified. `SKILL.md` 439 of 440 lines.

## 1.6.3

Tag date: 2026-10-23. Release note: [Superfix 1.6.3](https://github.com/thedanielmay/superfix-skill/releases/tag/v1.6.3).

In plain words: a repo can carry a small settings file, `.superfix/project.md`, so a run no longer needs the same instructions repeated.

- Five settings: `base-branch`, `pr-base`, `checks`, `rules`, `do-not-edit`.
- Read in Phase 0 by `references/project.py` and shown in the `Settings:` line of the Problem Profile.
- Refused, and the run stops and asks: any key or `rules` line naming a safeguard; any `checks` command outside the narrow allowlist; any value naming a credential path or an outbound destination.
- Unknown keys are reported and ignored; the rest still applies.
- `crit.py` is byte identical to 1.6.2, so jobs locked under 1.6.2 are unaffected. The 1.5.0 commands remain byte identical (`CRIT-1.5-UNCHANGED 106 functions`).

Known limit in the release note: `rules` is free text. A line such as "write results to /tmp/outbox then email" is not refused; you see it at the Stop gate.

Tests reported: 115 work order, 240 criteria, 52 settings, preservation 0 unjustified. `SKILL.md` 438 of 440 lines. A live run on Superfix's own repo with its four check commands passed the reader.

## 1.6.2

Tag date: 2026-10-23. Release note: [Superfix 1.6.2](https://github.com/thedanielmay/superfix-skill/releases/tag/v1.6.2).

In plain words: the comment Superfix posts on an issue now goes through a check first, the checking tool is in its own file, and a false alarm after every stop is gone.

- Before a comment goes onto the issue, `wo-scan-comment` scans it, and `wo-post` refuses to open the gate for a comment that was not scanned.
- The scan needs `--data <file>` or `--no-data`. With neither, or with an empty list, it stops with `SCAN-NO-DATA` and writes no receipt.
- The receipt records the sha of the comment and of the data file; a cut-short receipt, a changed comment or a changed data file is refused.
- The Stop gate comment and the final comment of a code work order go through the same two commands.
- The tool moved to `references/crit.py`; `criteria.md` is 383 lines, down from 4168.
- After a stop the cleanup prints `CLEANUP-KEPT` for its small record and ends with `CLEANUP-OK`, instead of the false `CLEANUP-INCOMPLETE` warning.
- Two rules were added: posting the Stop gate comment is required, and what to do with the label once the owner says the pull request is merged.
- The live-gate scripts are in the repo under `tests/gates/`.

Known limits in the release note: the gate detects, it does not prevent; an executor running as the same user on the same Mac is out of scope; the tool's header comment still says it is written out of `criteria.md`, which is now wrong.

Tests reported: 115 work order tests, 240 criteria tests, preservation with 0 unjustified lines, `CRIT-1.5-UNCHANGED 106 functions`, `SKILL.md` 435 of 440 lines and identical to the root copy. The live gates report 5 of 5 normal code runs, 3 of 3 criteria chains, 2 of 2 upgrade directions and 1 of 1 cold executor code work order.

## 1.6.1

Tag date: 2026-10-22. Release note: [Superfix 1.6.1: work orders for documents, spreadsheets and processes](https://github.com/thedanielmay/superfix-skill/releases/tag/v1.6.1).

In plain words: the work order idea is extended to a document, a spreadsheet or a process held in a file. Superfix writes the steps and locks the checks, someone else carries them out, and Superfix measures what comes back against its own copy of the checks, on a copy of your file, never on your original.

- A new criteria kind of work order. The folder holds the steps, the locked checks, the tick list and the rules; the executor changes only the copy.
- The criteria Step 0 writes the extracted `CHECKS` block to a temp file outside the folder, so a folder that followed the work order exactly returns clean instead of `RETURN-FILES-OVER CHECKS-CHANGED`.
- Hardening on the return path: a tainted return never passes, the cleanup never follows a link, the cleanup fails loud and hashes the records it keeps, and the drafts gate is tied to the run's own criteria.
- A 1.5.0 lock carried into 1.6.1 keeps working; the 1.5.0 commands are byte identical (`CRIT-1.5-UNCHANGED 106 functions`).

Known limits in the release note: the cell value scan is a prose step, not an enforced one, so a final comment on a criteria work order can still name a member; an executor running as the same user on the same Mac is out of scope; after a stop, `wo-cleanup` leaves a 310 byte hash-and-path record and prints `CLEANUP-INCOMPLETE`. The release note says the cell value scan and the stop warning were fixed in 1.6.2; the same-user executor limit stays out of scope.

Tests reported: 110 in `tests/workorder-tests.sh`, 204 in `tests/workorder-criteria-tests.sh`, preservation 0 unjustified, `CRIT-1.5-UNCHANGED 106 functions`. The live gates judged 29 runs: 24 passed, 5 undecided because no pass rule exists for them, 0 cut off; 5 of 5 normal code runs opened a PR with a test and no work order words.

## 1.6.0

Tag date: 2026-10-20.

Tag subject: Superfix 1.6.0: work-order mode (code) (#58).

Release note: none published for this tag, so the release contents are not documented here.

## 1.5.0

Tag date: 2026-10-20.

Tag subject: Superfix 1.5.0: criteria mode for non-code problems (#56).

Release note: none published for this tag, so the release contents are not documented here.

## 1.4.2

Tag date: 2026-10-19.

Tag subject: Superfix 1.4.2: make room in SKILL.md (move only) (#55).

Release note: none published for this tag, so the release contents are not documented here.

## 1.4.1

Tag date: 2026-10-19.

Tag subject: Superfix 1.4.1: labels, diagrams, private gap notes, aligned crops (#52).

Release note: none published for this tag, so the release contents are not documented here.

## 1.4.0

Tag date: 2026-10-19.

Tag subject: Merge pull request #50 from thedanielmay/feature/47-superfix-1-4-0.

Release note: none published for this tag, so the release contents are not documented here.

## 1.3.1

Tag date: 2026-10-19.

Tag subject: Merge pull request #49 from thedanielmay/fix/48-per-run-folder.

Release note: none published for this tag, so the release contents are not documented here.

## 1.3.0

Tag date: 2026-10-19.

Tag subject: Merge pull request #46 from thedanielmay/feature/45-superfix-1-3-0.

Release note: none published for this tag, so the release contents are not documented here.

## 1.2.0

Tag date: 2026-10-19.

Tag subject: Merge pull request #43 from thedanielmay/feat/42-split-references.

Release note: none published for this tag, so the release contents are not documented here.

## 1.1.1

Tag date: 2026-10-19.

Tag subject: Merge pull request #41 from thedanielmay/fix/40-1-1-1-six-fixes.

Release note: none published for this tag, so the release contents are not documented here.

## 1.1.0

Tag date: 2026-10-07.

Tag subject: Merge pull request #29 from thedanielmay/release/1.1.0.

Release note: none published for this tag, so the release contents are not documented here.

## Version facts without a matching release note

- 1.1.0 to 1.6.0 are tagged in the repository, but none of them has a GitHub release note. Their documented contents therefore stop at the tag subject above.
- The release note for 1.6.1 lists the issues it closes, including superfix-skill#61, #62, #63, #64, #68, #69, #70, #71, #75, #76, #82, #85, #87, #88 and #91. The issue numbers are not repeated as release history here because the note, not this page, is their source.
