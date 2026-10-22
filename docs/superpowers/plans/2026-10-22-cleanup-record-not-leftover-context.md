# Context: cleanup-record-not-leftover

## Problem Profile
- Primary type: bug
- Secondary type: none
- Complexity: Moderate
- Skill manifest: superpowers:systematic-debugging, feature-dev:code-explorer, superpowers:test-driven-development, superpowers:verification-before-completion

## Problem Description
[superfix-skill#94](https://github.com/thedanielmay/superfix-skill/issues/94): after a stop, `wo-cleanup` deletes the data copies but leaves `work/<file>.sf-orig`, then prints `CLEANUP-INCOMPLETE ... (personal data may remain: delete these by hand)` and exits 1. The leftover is 310 bytes in the issue's own measurement and 110 bytes in a fresh rig: one sha256 and the path of the original. A scan of the whole run folder found no member row, name or email in it. The warning is too strict, and a stop never reaches `CLEANUP-OK`.

## Plan
Path: docs/superpowers/plans/2026-10-22-cleanup-record-not-leftover.md

## Key Decisions from Exploration
- The record is a kept record, not a leftover: it stays on disk, it is named in the output, and the cleanup ends `CLEANUP-OK`. The success line already says "records kept", so the leftover list is the bug.
- The leftover list is split in two, `left` and `kept`, so a path that may hold personal data is never confused with a record.
- A file named `.sf-orig` that parses as one sha256 and one path is a record, whatever became of its original: moved, on cloud, online-only or unreadable. A file that does not parse may hold anything, so it stays a leftover.
- The change stays in `woc_cleanup_full`, which the 1.5.0 check does not compare, so the 106 functions stay byte identical.
- The tool's bytes change, so the crit-sha of newly locked jobs moves. The release notes get one line.

## Relevant Files
- `skills/superfix/references/crit.py`: `woc_cleanup_full` (from line 2623) builds the leftover list, `cmd_wo_cleanup` (from line 2818) prints the word and the exit code.
- `skills/superfix/references/criteria.md`: line 164 says a stop deletes everything.
- `tests/workorder-criteria-tests.sh`: the cleanup tests, including `wo-cleanup-ok` (line 304) and `wo-cleanup-incomplete` (line 383).
- `tests/preservation-1.6.1.md`: the justification file the preservation check reads while the plugin version is 1.6.1.

## Evidence
The failing check, on a rig whose original had one fee cell edited, the same shape as the V6 stop runs:
```
CLEANUP-INCOMPLETE <run>/work/members-export.csv.sf-orig (personal data may remain: delete these by hand)
exit code: 1
```
The leftover is 110 bytes, one line, the sha256 of the original and the path of the original. A scan of the whole run folder for member names found none.

Why it happens:
1. `crit.py:2704` skips every `.sf-orig` file while it walks `work/`, so the record is neither deleted nor reported there.
2. `crit.py:2712` walks the records again: a record whose named original still hashes the same is deleted (`crit.py:2759`), and a record whose original has changed goes into the leftover list (`crit.py:2755`), as does a malformed one (`crit.py:2738`) or one whose original is a placeholder (`crit.py:2747`).
3. `crit.py:2763` prints every leftover with the words "personal data may remain" and returns not clean, so `cmd_wo_cleanup` (`crit.py:2818`) exits 1 without printing `CLEANUP-OK`.
4. The same branch caught a record whose original is on cloud or online-only, because a placeholder original cannot be hashed, so the false alarm was not rare.
