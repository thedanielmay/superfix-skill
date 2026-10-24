# Superfix 1.6.5 release notes (draft, not released yet)

The items [superfix-skill#113](https://github.com/thedanielmay/superfix-skill/issues/113) asks for. Claude writes the final notes from this file at release time.

## Rollback from 1.6.1 to 1.6.0

Rolling back from 1.6.1 to 1.6.0 breaks a job locked under 1.6.1: the older tool reads the newer lock and VERIFY prints `CRIT-SHA-MISMATCH`.

What to say in the run: finish the job on the version it was locked under. A run folder carries its own copy of the tool, so a job that has one keeps working; the mismatch is a sign that the copy and the lock's `crit` line disagree. Do not move a locked run back a version by hand.

## Jobs locked under 1.5.0

A job locked under 1.5.0 keeps the 1.5.0 tool, with the weakness 1.6.0 closed: the 1.5.0 tool reads a forged `.o` file as output. That is acceptable for a job finishing on the tool it locked under, which is the only way a 1.5.0 lock is read. Moving such a job to 1.6.5 would change its checks mid-run, so it stays.

## What changes in 1.6.5

- Cleanup no longer prints `CLEANUP-OK` while a stray sits at the top of the stub or a round folder. Every name there other than `work`, `checks`, `workorder.md` and `key` is a stray: a regular file or a link goes, a directory, a FIFO, a socket or a hardlinked file is listed in `CLEANUP-INCOMPLETE`. A FIFO or socket named `report.md` used to be skipped silently.
- The work order check shares its missing key and freshness loops between the code kind and the criteria kind. The two exclusion lists stay apart, and `wo_head` is untouched, so the 1.5.0 guard still prints `CRIT-1.5-UNCHANGED 106 functions`.
- A work order's new `KINDS:` line makes the refused kinds mechanical. `wo-check` and `wo-lock` print `WORKORDER-KIND-REFUSED` for `qik`, `live`, `sheet`, `doc` or any kind outside code and criteria, and for a code plus criteria mix, before any copy of the owner's data is made. A work order with no `KINDS:` line keeps the old behaviour.

## The crit-sha moves in 1.6.5

The tool's bytes change with the two code items above, so `crit.py`'s sha256 differs from 1.6.4's. Jobs locked under 1.6.4 keep their own copy of the tool and are not affected; jobs locked from 1.6.5 record the new sha. A rollback from 1.6.5 to 1.6.4 is the 1.6.1 to 1.6.0 case above.
