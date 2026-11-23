# Superfix 1.9.0 release notes

Issue: [superfix-skill#167](https://github.com/thedanielmay/superfix-skill/issues/167).

## What changes

- A finished criteria job leaves no folder under `~/superfix-workorders/<id>`.
  - `wo-cleanup` is the last step of every ending except a send-back, after the final comment is posted. No ending deletes the job folder by itself.
  - Until `wo-cleanup` runs, the data stays in `~/superfix-workorders`.
  - A pass keeps only the verified copy and leaves the job folder empty. When you take the copy or say stop, `wo-cleanup --all` deletes the copy and the job folder.
  - Every other ending (RETURN-CAP, NO-PROGRESS, a stop, a refused send-back) deletes everything.
  - The empty `~/superfix-workorders` folder stays.
- Send-back rounds now live inside the job folder: `<id>/r2/`, not `<id>-r2/`. Round 1 stays at `<id>/`.
  - A job already running keeps its old `<id>-r2/` folder, and its next round goes into `<id>/r3/`.
- Deleted files do not go to the Trash. Only your own backups can bring them back.
- Every deleted path is written to `workorder/cleanup-log` in the run folder, on your Mac.
  - No command prints the log and no comment holds it.

## How a swapped folder is refused

- The lock records the job folder's device and inode when the work order is locked.
- Clean-up opens `~/superfix-workorders`, then the job folder, then each sub-folder, and keeps each one open while it deletes inside it.
- A folder replaced by a link, or by a copy restored from a backup, is refused and nothing in it is deleted.
- A job locked by an older version has no inode record. It gets the open-handle protection and the older link checks.

## What to know

- A stray item keeps the folder in place. The output has a `KEPT <path> (<reason>)` line for it, naming the top-level item and a count, never a name from inside `work/`.
- An older `<id>-r<n>/` folder with no `workorder.md`, or one that names another id, is left alone.
- Folders from jobs that finished before this version are not swept. An empty one is safe to delete.
  - To clean one that still holds files, run `wo-cleanup --run <old run folder>`.
- A job id with a slash or a leading dot is refused with `WORKORDER-ID-BAD`.
- Known limit: on Linux, a bind mount made inside `work/` has the same device number, so the walk does not see it as another disk.
- A process running as the same user on the same Mac stays out of scope, as decided on #65.
