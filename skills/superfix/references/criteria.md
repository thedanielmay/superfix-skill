# Criteria mode

New in 1.5.0 ([superfix-skill#54](https://github.com/thedanielmay/superfix-skill/issues/54)). SKILL.md (Criteria mode) says when to read this file: in full, before the stop, whenever any problem's Coverage line is "Everything else". A code-only or Qik-only run never reads it and writes `Criteria: NONE (no Everything else problem)`. Every rule of `references/redaction.md`, `references/journal.md` and `references/gaps.md` still holds; this file adds the criteria rules. Every command below writes each value out literally, because the shell keeps no variables between calls, and prints word lines: silence is never a pass.

### 1. Scope

- Data and document clean-ups (a CSV or sheet export, a guide, a list), checked against the owner's own rules, written as criteria and approved by him before any change.
- A process (how refunds, onboarding or approvals work): Superfix may draft or change the process document and sets a `later` criterion. It reports "change drafted (or adopted), effect measured on <date>: <result>", never "solved".
- No checkable criterion: when Superfix cannot draft one and the owner gives none (strategy, business prose, a judgement call), the problem stops at diagnosis, as before 1.5.0, and gets a gap note of kind "no checkable criterion" (section 20).
- Roadmap issues [superfix-skill#35](https://github.com/thedanielmay/superfix-skill/issues/35), [superfix-skill#36](https://github.com/thedanielmay/superfix-skill/issues/36) and [superfix-skill#37](https://github.com/thedanielmay/superfix-skill/issues/37) are optional helpers; their output can be a `how:`. A library of recurring criteria is LATER, not in 1.5.0.
- Criteria mode never applies to Code or Qik problems. They keep their own path, solved check and rules.

### 2. Criterion lines in ## Done when

One line per criterion. The id (`P1-C1`) is internal; every message to the owner uses the plain name.

```
- P1-C1 [check] duplicate members: rows whose email, with spaces trimmed and case ignored, matches an earlier row; the earliest joined date wins and keeps its own fee; pass: 0; how: measure-P1-C1.py; who: Superfix
- P1-K1 [check] distinct members: by email with spaces trimmed and case ignored; pass: 112 (today's count); how: measure-P1-K1.py; who: Superfix
- P2-C1 [later] refund time: median days from refund request to payment, over the refunds requested after the change was adopted, measured once there are at least 20 of them; pass: 3 or fewer; how: measure-P2-C1.py on the refunds log; who: re-measure on 2026-11-16
- P3-C1 [owner] mileage claim: a new staff member can claim mileage from the guide alone; pass: you tick all 3 items below; how: checklist; who: owner sign-off
  - [ ] the guide gives the mileage rate in cents per km
  - [ ] every "see step" points at a step that exists
  - [ ] a claim can be filled in without asking anyone
```

- Shape: `- P<k>-<C|K><n> [<kind>] <plain name>: <definition>; pass: <pass line>; how: <how>; who: <who>`. `C` lines say when the problem is gone; `K` lines say what must not get worse.
- The plain name is letters, digits, spaces and hyphens, starting with a letter, and unique in the issue (it is used in comma-separated lines and must never look like a numbered question).
- Kinds:
  - `check`: measured now by a script; `how: measure-<id>.py`; `who: Superfix`.
  - `later`: a baseline now and a dated re-measure; `how: measure-<id>.py ...`; `who: re-measure on <YYYY-MM-DD>`. A condition such as "at least 20 refunds" goes in the definition, and the script exits with an error until it holds (ERROR: not measurable yet).
  - `owner`: a checklist of at least 2 items, indented `  - [ ] ` lines under it, then the owner's sign-off; `how: checklist`; `who: owner sign-off`. "all <n> items" must match the number of items. Ticking a box never changes the lock (section 12).
- Every definition the measure depends on is in the line: what counts as a duplicate, which row wins, how a date or a fee is read. A date that could be read two ways (`03/04/2025`: March or April) is a numbered question, never a guess, and never written into the line.
- The pass line follows this grammar exactly; anything else (two conditions, "under 3", "clearer") is `CRITERIA-VAGUE`, and the owner is asked to rewrite it:

| Pass line | Means |
|---|---|
| `0`, `none`, `zero`, `no <things> left`, `no` | equal to 0 |
| `yes` | equal to 1 (a yes or no fact the script prints as 1 or 0) |
| `<N>`, `exactly <N>` | equal to N |
| `<N> or fewer`, `at most <N>`, `no more than <N>` | N or less |
| `fewer than <N>`, `less than <N>` | below N |
| `at least <N>`, `<N> or more` | N or more |
| `between <A> and <B>` | A to B, both included |
| `<N>% fewer than today` | at most floor(baseline x (1 - N/100)), rounded DOWN so it is never easier than the words; the baseline is the first measure of the current epoch (section 14) |

  A note in brackets with no digit may follow (`112 (today's count)`).
- Worked numbers for the K example (testbed fixture): 120 rows, minus 6 exact copies, minus 1 row whose email differs only in case, minus 1 row whose email has a trailing space = 112. Without trimming the count is 113, which is why the definition is written out.
- The owner's own words stay on the existing line `The owner's description no longer holds: "<words>"`: context only, never a pass (see 15, Checks met but the description still holds).

### 3. The plain block (above the `---`)

Per criterion, one line, before the numbered questions, in exactly this form:

`<plain name>. Today: <number> (rows <N>, <N> and <N>). Must be <pass line>.`

For example: `Duplicate members. Today: 8 (rows 14, 15 and 62). Must be 0.` and `Distinct members. Today: 112. Must be 112 (today's count).`

- The bracket holds ONLY `row <N>` or `rows <N>, <N> and <N>`, never a value, a name or a field's content; the field is already named by the plain name, so nothing personal is posted. No bracket when the script has no items. Row numbers are as the sheet shows them: the header is row 1, the first data row is row 2.
- The rows are the FIRST 3 of the baseline script's `ITEMS` (the script lists every row, in ascending order). `Must be` repeats the pass line word for word.
- An `owner` criterion's line says what is true today in words ("Mileage claim. Today: the guide has no mileage rate.") and lists the checklist below it.
- Approval covers this line and its rows.
- For guides and processes, one plain line above the questions: "Does anyone else use this (staff, customers)? Tell me if they should see the change first."
- A pass line outside the grammar: propose a rewrite in the grammar and show it here.

### 4. The questions

Exact, after the problem questions and before the budget question, two per problem in criteria mode, with no recommended answer and never in the Simple short form:

```
<n>. P<k> (problem <k>: <short name>): if every check above passes, would you consider this solved? (yes / no, and what is missing)
<n+1>. P<k>: what must not get worse, for you or anyone affected (staff, customers)? My suggestions: <K lines in plain words>. (reply "those", add your own, or "none")
```

- An unclear definition (a date that reads two ways, which row wins) gets its own numbered question before these two.
- Meanings:
  - "yes" to the first approves the `C` lines; "no ..." means rewrite them and ask again; anything else means not approved yet.
  - "those" keeps the suggested `K` lines; added words become new `K` lines, shown back for a yes; "none" means no guard, recorded in ## Decision as `P<k>: You chose no 'must not get worse' check, so a fix could break something unnoticed.`
  - Only "yes" to the first plus an answer to the second approves problem <k>.
- "Keep executing" (or "keep going", "yes to all") does not approve them, because these questions have no recommended answer. Say once, in chat and in the comment: `Keep executing does not approve the checks for problem <k>; I am waiting for your answers to questions <a> and <b>.` Ask again once more, at most; then park that problem with Status `Waiting for you: <n> questions` (the label rule applies). Code and Qik problems in the same issue go ahead on their own answers.
- Two more criteria questions, each with NO recommended answer (anything but an explicit yes is no), after the two above and before the budget question, only when they apply:
  - `<n>. The measure scripts cannot run in the macOS sandbox here (SANDBOX-MISSING), so nothing would stop a script reaching the network or writing files. Run them without it? (yes / no)`
  - `<n>. Commit the cleaned <file> to <owner/repo>? GitHub keeps every pushed commit even if the PR is closed, and they become public if the repo is ever made public. (yes / no, keep it on my Mac)` (section 9).
- Order of the optional questions after the budget question: the diagram question (diagrams.md; never for an Everything else problem), the reminder question (section 16), the `assets` question, and the create-issue question always last.

### 5. The criteria tool (`crit.py`)

`crit.py` is written into the run folder from this file, by a command, never typed out by hand, like `shot.py` in evidence.md. `<skill dir>` is this skill's base directory, written out in full:

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; if [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; else awk '/^# --- crit.py start ---$/{f=1} f{print} /^# --- crit.py end ---$/{f=0}' '<skill dir>/references/criteria.md' > "$D/crit.py" && grep -q '^# --- crit.py end ---$' "$D/crit.py" && echo "CRIT-READY $D/crit.py"; fi
```

Every command below starts `python3 -I "$HOME/.superfix/runs/<run-key>/crit.py"`. The same four arguments recur, always written out in full:
- `--run "$HOME/.superfix/runs/<run-key>"`: the run folder (redaction.md), deleted at the end of the run;
- `--scripts "<criteria folder>"`: `$HOME/.superfix/journal/<name>/criteria/<run-key>` (`<name>` as in journal.md's file-mode path: `<owner>-<repo>`, or the folder name without a remote). It holds the measure scripts, the `lock` file and the `attempts` file, never data, so it may outlive the run (a `later` re-check needs the locked scripts);
- `--attempts "<criteria folder>/attempts"`;
- `--body "<body file>"`: the issue body read fresh (`gh issue view <N> --json body -q .body > "$HOME/.superfix/runs/<run-key>/body-now.md"`), or the journal file in file mode.

Every path argument is resolved to its real path before the tool changes folder. Words: `CRIT-READY`, then the words of each command below.

After `RUN-MOVED` (journal.md, the create-issue question), move the criteria folder to the issue key too, before the lock:

```bash
S="$HOME/.superfix/journal/<name>/criteria/<journal run-key>"; T="$HOME/.superfix/journal/<name>/criteria/<owner>+<repo>+<N>"; if [ ! -d "$S" ]; then echo "CRITERIA-FOLDER-NONE $S"; elif [ -e "$T" ]; then echo "REFUSED-EXISTS $T"; else mv "$S" "$T" && echo CRITERIA-FOLDER-MOVED; fi
```

### 6. Shape check (free, before the stop and after every amendment)

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" shape --body "<body file>"
```

It prints `CRITERIA-SHAPE-OK <n>`, or one line per problem: `CRITERIA-BAD <id> <field>` (kind, fields, name, definition, how, who, checklist, date, id), `CRITERIA-VAGUE <id>` (the pass line is outside the grammar in section 2), `CRITERIA-NO-KEEP P<k>` (a problem with `C` lines, no `K` line and no recorded "none"). Fix the lines and run it again; never post with a problem line.

### 7. Measure scripts

- One per `check` or `later` criterion, exactly `<criteria folder>/measure-<id>.py`, written under `umask 077` with a quoted heredoc. Standard library only; it reads only the file named as its one argument, writes nothing, uses no network.
- It prints only `MEASURE <id> <number>` and `ITEMS <row numbers in ascending order, or none>`. **The tool decides PASS or FAIL itself** from the number and the pass line; a script may also print `DATA-SHA <sha256>` and a `PASS` or `FAIL` line, but any that disagrees is an error, and any other line (a value, a name, a debug print) is an error that is never shown.
- Template:

```python
import csv, sys
rows = list(csv.DictReader(open(sys.argv[1], newline="", encoding="utf-8")))
seen, items = set(), []
for n, r in enumerate(rows, start=2):        # the header is row 1
    k = r["email"].strip().lower()
    if k in seen:
        items.append(n)
    seen.add(k)
print("MEASURE P1-C1", len(items))
print("ITEMS", " ".join(map(str, items)) or "none")
```

- Read data with the `csv` module, never by splitting on commas: a quoted field with a comma (`"Nguyen, Linh"`) breaks a split.
- Run every script through the tool, never directly; `<out>` names the output folder (`base`, `try1`, `run1`, `run2`, `neg-P1-C1` ...):

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" measure --run "$HOME/.superfix/runs/<run-key>" --scripts "<criteria folder>" --body "<body file>" --attempts "<criteria folder>/attempts" --id <id> --script "<criteria folder>/measure-<id>.py" --data "<file>" --out <out> --expect <PASS or FAIL>
```

- It runs the script under `sandbox-exec` (no network, no file writes outside a temporary folder it deletes afterwards), with `python3 -I -B`, a cleaned environment, a 120 second limit and no shell. It computes the file's sha256 itself and writes `<run folder>/criteria/<out>/<id>.out`.
- It prints `PASS <id> <value> items <rows>` or `FAIL ...`, then `EXPECTED` or `UNEXPECTED <id> wanted <a> got <b>`. **A crash is ERROR, never FAIL.** Errors, each a stop:
  - `ERROR <id> <reason>`: a non-zero exit, a timeout, a missing or wrong `MEASURE` or `ITEMS` line, an unexpected line, `ITEMS` not ascending, a `DATA-SHA` that is not the file's;
  - `ERROR-VERDICT-DISAGREES` (the script's own PASS or FAIL is not what the pass line gives), `ERROR-ITEMS-OUT-OF-RANGE` (a row number above the file's row count, header included);
  - `ERROR-SCRIPT-NOT-LOCKED` (the script is not `measure-<id>.py` in the criteria folder, or after go its sha is not the locked one), `ERROR-DATA-NOT-LOCKED` (after go, the file is neither a locked original nor in the run folder's `work/`), `CRITERIA-CHANGED` (the lock no longer matches);
  - `SANDBOX-MISSING` (no `sandbox-exec`: nothing ran; ask the sandbox question in section 4; only after a yes add `--unsandboxed-ok`);
  - `ASK-FIRST <file>` (a cloud or online-only file: reading it can download it; ask the owner, then add `--asked`).
- Before the stop, on the ORIGINAL, `--out base`: each `C` must print `FAIL` with `ITEMS` whose first 3 rows are the rows in the plain block (else the failure is for the wrong reason: fix the script); a `C` that passes does not detect the problem: rewrite it; each `K` must print `PASS`. Then write the baseline attempt (section 14).
- Honest limit: a script that misreads the file quietly (no crash) is caught only when its `ITEMS` or its number differ from what the owner sees in the plain block.

### 8. Business figures

They follow redaction.md: a figure the owner calls private goes on the secrets list, and then blocks any post that holds it. The plain block and the pass lines use counts, and on a PUBLIC repo relative values ("20% fewer than today"), never amounts or row values.

### 9. Where the work happens

Work copies live in `$HOME/.superfix/runs/<run-key>/work/` and are DELETED when the job ends (solved, abandoned or stopped for good); the run folder delete at the end of the run removes them too. A `later` job keeps only numbers, data shas and the scripts in the criteria folder, never the data.
- While the owner still has to put a changed copy back (section 10), the job has not ended: the run folder and its `work/` stay (mode 700 and 600, on this Mac only), the stop message names the copy's path, and redaction.md's end-of-run delete waits until the export is measured or the owner says stop. Then `finish` runs first, then the delete.

**A data file in criteria mode (a CSV, a sheet export, any file of people, money or records) is never committed, on ANY repo, by default.** The cleaned file stays on the Mac; the PR, when there is one, holds only document changes and describes the data change in counts. Committing it needs an explicit yes to the numbered question in section 4, asked only on a repo that `visibility` reports PRIVATE.

| What | Change made on | Shown beside the original by | Undo |
|---|---|---|---|
| A document with no personal or financial data, in a git repo outside any cloud mount | the work branch | the PR diff | close the PR without merging (GitHub keeps the closed PR and its commits); after a merge, a revert |
| A data file, in any repo | a copy in `work/`; nothing committed (unless the owner said yes, above) | counts before and after; `diff -u` saved next to the copy | delete the copy |
| A file in a folder without git | a copy in `work/` | `diff -u` saved next to it; the original's sha256 checked unchanged at the end | delete the copy |
| Google Doc or Sheet, or a Drive mount file | a local copy (an online-only file is read only after asking) | as above | delete the copy |
| A process | a copy of the process description, messages as draft files in `work/` | the diff and a list of who would need to be told | delete the drafts |

- Repo visibility, once per run:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" visibility --repo '<owner>/<repo>'
```

  It prints `VISIBILITY-PRIVATE` or `VISIBILITY-PUBLIC (<why>)`. Unknown or a failed read is PUBLIC.
- A git repo that itself sits in a cloud mount is treated like a folder without git: copy in `work/`, no branch edit, because a branch edit there syncs to others. Check any path first:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" where "<path>"
```

  It prints `PATH-CLOUD <path>` or `PATH-LOCAL <path>`. Cloud means under `~/Library/CloudStorage`, `~/shared-drives`, `~/Dropbox`, `~/Library/Mobile Documents` (iCloud Drive), `~/Google Drive` or `~/OneDrive`, and also `~/Desktop` and `~/Documents` when iCloud's Desktop and Documents sync is on (detected by those folders inside iCloud Drive); symlinks are resolved and the comparison ignores case.
- Make the copy with the tool, which records the original's sha256:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" copy --run "$HOME/.superfix/runs/<run-key>" --src "<original>"
```

  It prints `COPY-READY <copy> sha <sha>`, `COPY-EXISTS`, `COPY-REFUSED`, `PATH-CLOUD` (the run folder itself syncs) or `ASK-FIRST <original>` (a cloud or online-only file; ask the owner, then add `--asked`). `--name <file name>` names the copy.
- At the end of the job:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" finish --run "$HOME/.superfix/runs/<run-key>"
```

  It prints `ORIGINAL-UNCHANGED <path>` for each original, then `WORK-DELETED`; or `ORIGINAL-CHANGED <path>` and `WORK-KEPT` (stop, tell the owner what changed, delete only after he answers); `ASK-FIRST` (hashing a cloud or online-only original can download it: ask, then `--asked`); or `WORK-NONE`.

### 10. The real file (Google Sheet, Drive file, any file the owner puts back himself)

- Final state: "ready, not verified on the real file"; Status `Waiting for you: put it back and give me an export`.
- On the export: never expect it to equal the copy (an export from Sheets is rarely byte for byte the same). Copy it in with `copy --src "<export>" --name export-<YYYY-MM-DD>.<ext>` (this records the export's own sha256), run the locked scripts on that copy, and write the attempt: every check passing means "verified on the real file". Say in the stop or final message: "Your export is still at <path>; it holds the data, so delete it when you are done." Superfix never deletes the owner's own files; its copy goes with `work/`.

### 11. Nothing leaves (never sent, never written outside)

**The principle: in criteria mode nothing leaves the repo, the run folder and the owner's Mac, by any route.** Messages to other people are draft files in `work/`; the owner sends them. The routes, none allowed:
- A tool call whose name contains `send`, `reply`, `forward`, `share`, `campaign`, `sms`, `invite`, `publish`, `create_event`, `update_event`, `add_comment`, `create_comment`, `create_task`, `manage_drive_access`, `set_drive_file_permissions`, `copy_file`, `create_file`, `update_file`, `update_values`, `append_values`, `upload_file`.
- Any MCP tool that creates, changes, moves or deletes something: Google Drive, Docs, Sheets, Slides, Gmail, Calendar, Slack, Teamwork, Qik, iCloud and the rest. Reading is allowed.
- An Artifact publish (or any Artifact action that writes), and Claude Docs `create`, `batch` and `update`.
- Through Bash: a `gws` write, `osascript` with `send`, a `tw` write, `gh gist`, `curl` or `wget` with `-d`, `--data*`, `-F`, `--form`, `-T`, `--upload-file`, `--json` or `-X POST|PUT|PATCH|DELETE`, `nc`, `ncat`, `scp`, `sftp`, `rsync`, `ditto`, and any `gh` call against a repo other than the work repo and the gap repo.
- A write into a cloud path (`where` prints `PATH-CLOUD`) by Write, Edit, `cp`, `mv`, `tee`, `ln`, `install`, a `>` or `>>` redirect, or a Python `open(..., "w")`.
- `git push` of a data file (section 9).
- The one exception: the owner's own reminder task (section 16), only after his explicit yes to that question.

The test harness (S13) checks a run's `stream-json` log for these routes, in the main thread and in subagents, with the same lists:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" sendcheck --log "<run.jsonl>"
```

It prints `SEND-CLEAN`, or `SEND-HIT line <n> <route>` for each hit, plus `SEND-REVIEW line <n> git push` (a push to check by hand).

### 12. Lock (at go, before any change)

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" lock --run "$HOME/.superfix/runs/<run-key>" --body "<body file>" --scripts "<criteria folder>" --attempts "<criteria folder>/attempts" --data "<each original data file>" --by "<gh login, or the owner at the keyboard>"
```

- It hashes (sha256) every `P<k>-` line of `## Done when` with its checklist lines (each checkbox read as `[ ]`, so ticking a box never changes the lock), every `measure-*.py` in the criteria folder, and the real path of each original named by `--data` (repeat it per file). It writes `<criteria folder>/lock` (the hash, each script's sha, each data path) and prints `Internal: criteria-sha <64 hex> (sha256), locked <YYYY-MM-DD HH:MM>, approved by <who>` and `CRITERIA-LOCKED`; or `CRITERIA-BAD ...` (no criteria, a missing script, no `--data`, no approver, or an output used by an attempt line of the current epoch that was measured with another version of a script: measure it again).
- The word `sha256` on the line lets redaction.md's pattern check pass the hash; never redact it. Any other sha in a comment or body is written next to the word `sha256` too.
- Write that line in ## Decision directly BEFORE the `Internal: approval-sha` line, which stays last. `<who>` is the GitHub login that wrote the approving reply, or "the owner at the keyboard" in chat. After an amendment, the newest line counts.
- Before every attempt, and on every restart:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" lockcheck --body "<body file>" --scripts "<criteria folder>" --run "$HOME/.superfix/runs/<run-key>" --attempts "<criteria folder>/attempts"
```

  It prints `CRITERIA-LOCK-OK`, `CRITERIA-CHANGED (<why>)` (a line, a script or the lock file changed since the lock: stop and ask; never fix the lock quietly), `CRITERIA-UNLOCKED` (no lock line: no fixing), or `ERROR-SCRIPT-NOT-LOCKED` / `ERROR-DATA-NOT-LOCKED` for a recorded output that was not made with the locked scripts and files. `measure`, `attempt`, `progress` and `comment` run the same checks themselves and stop on the same words.
- Owner sign-offs: ticks in the checklist are recorded, not locked:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" signoff --body "<body file>" --attempts "<criteria folder>/attempts"
```

  It appends `signoff <date> <id> <ticked>/<items>` and prints `SIGNOFF <id> <k> of <n> ticked` and `SIGNOFF-RECORDED`. Only the owner's reply "signed off" passes an `owner` criterion.

### 13. Amending

Only through new numbered questions (the Stop gate form). ## Decision gains `Criteria change <date>: "<old plain line>" is now "<new plain line>". Approved by <who> in chat <date time>.` and a new lock line. Then the shape check, a new lock, a new baseline (`--out base2`) and `attempt --from base2 --new-epoch`, which starts a new epoch (section 14). Without `--new-epoch`, `attempt` refuses a line under a new lock.

### 14. Attempts, epochs and the stop rule

The attempts file is `<criteria folder>/attempts`, written only by the tool from the output files (never typed):

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" attempt --run "$HOME/.superfix/runs/<run-key>" --scripts "<criteria folder>" --body "<body file>" --attempts "<criteria folder>/attempts" --from <out>
```

- It appends `<n> <YYYY-MM-DD HH:MM> data-sha <sha> from <out> lock <criteria-sha or none> P1-C1=<value> P1-K1=<value> ...` and prints `ATTEMPT-SAVED <n> (epoch <e>)`; or `ATTEMPT-SAME <n>` (the same file and values as the newest line: nothing written, so a version is never counted twice), `ATTEMPT-REFUSED <ids> ERROR`, `ATTEMPT-REFUSED no output files`, `ATTEMPT-REFUSED the criteria were amended ...`, or a lock word. `data-sha` is the measured file's sha256, or, with several files, the sha256 of their shas.
- Epochs: the first attempt writes `epoch 1 <date> lock <sha or none>`; `--new-epoch` (after an amendment) writes the next epoch line. Line 0 of the CURRENT epoch is its baseline: comments, progress, the stop rule and `% fewer than today` use only the current epoch. Old epochs stay in the file for audit.
- A problem whose criteria are all `owner` has no scripts and no attempts file.
- After every attempt after the baseline:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" progress --run "$HOME/.superfix/runs/<run-key>" --scripts "<criteria folder>" --body "<body file>" --attempts "<criteria folder>/attempts" --cap <attempts cap, default 5>
```

- Moved: at least one failing `C` got closer to its pass line AND no `C` or `K` got further from its pass line; any worsening is no progress. It prints `CHECKS-PASS <n>` (every `check` criterion meets its pass line: never a stop), `MOVED <n>`, `NO-PROGRESS <n> (worse: <names>)` or `NO-PROGRESS <n> (no failing check improved)`; `PROGRESS-NONE` with only the baseline.
- Two attempts in a row with no progress: `STOP-NO-PROGRESS` and the stop text, filled in: `"Two tries did not get closer: <plain name> went from <before> to <after> and <plain name> got worse. Work kept on <branch or copy>. Reply 1 to re-diagnose (about 20 minutes) or 2 to stop."` Write the branch or copy in place of `<branch or copy>`. Status `Waiting for you: 1 question`.
- The attempts cap reached: `STOP-CAP <n> of <cap> attempts`; a budget stop (SKILL.md Budget).

### 15. Three runs (the solved check in criteria mode)

- Run 1, the original: measure the original again (`--out run1`): every `C` `FAIL`, every `K` `PASS`, and the original's data sha equal to the epoch's line 0 (the original is unchanged).
- Run 2, the change (`--out run2`, then the attempt command `--from run2`, which prints `ATTEMPT-SAME` when run 2 measured the same file as the last try): every `C` `PASS`, every `K` `PASS` and no further from its pass line than in run 1.
- Run 3, negative control: make a scratch copy of the change in `work/neg/` with exactly ONE planted defect (one example row put back, for a `C`; one member deleted, for a `K`), and measure it with `--neg-of "<the changed copy>" --defect "<what was planted, in plain words, no row values>" --expect FAIL`. The tool refuses `ERROR-NEG-NOT-DISTINCT` (the negative copy equals the change or an original) and `ERROR-NEG-NOT-ONE-DEFECT` (not exactly one row added, removed or changed), and writes a `neg <date> <id> data-sha <sha> defect <words>` line (`NEG-RECORDED`). Run 3 outputs are never attempts.
- Any `ERROR` or `UNEXPECTED`, or a run 3 that passes: stop and ask, because locked criteria are never rewritten quietly.
- `later` and `owner` criteria are listed as waiting, never counted as passes.
- Checks met but the description still holds: when every check passes and the owner's description in ## Done when still seems true, say `All checks pass, but you said "<words>" and that still seems true, because <reason>.` Do not say solved; the issue stays open.
- A process is never "solved": "change drafted (or adopted), effect measured on <date>: <result>".

### 16. Later and owner

- `Refs`, not `Closes`: the PR body says `Refs #<N>` whenever any non-code problem has a `later` or `owner` criterion, is a process, or is in the "description still holds" case; with a `later` criterion it adds "Adopted, effect not measured yet. <plain name> is due on <date>." Status `Waiting for you: re-check on <date>`.
- The reminder question, at the stop, with NO recommended answer (anything but an explicit yes to it is no, like the create-issue question; "keep executing" never creates a task):

```
<n>. P<k>: add a reminder for <date> to re-check <plain name>? It would be one task in your own task list. (yes / no; I create nothing unless you say yes to this question)
```

  - Yes, with `gws`: at the end of the run, one task in the default list. The tool builds the request with `json.dumps` (no shell quoting) and sends the date in the form the API stores correctly (`YYYY-MM-DDT00:00:00.000Z` with the intended local date; a local offset stores the day before):

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" remind --name "<plain name>" --where "<issue link or journal path>" --date <YYYY-MM-DD>
```

    It prints `REMINDER-CREATED`, `REMINDER-FAILED` or `REMINDER-REFUSED` (a name outside the plain-name rule, quotes, `$` or backticks in the link or path, or a bad date). `--dry-run` only checks it.
  - Yes, without `gws` (or `REMINDER-FAILED`): one ready-to-paste line in the final comment: `Reminder for <date>: re-check <plain name> with "continue superfix on <issue link or journal path>".`
- No-repo jobs (file-mode journal): one line in `$HOME/.superfix/journal/INDEX.md` per waiting job, removed when the job ends:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" index add --job "<journal file path>" --waits "<what it waits for, for example re-check on 2026-11-16>"
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" index remove --job "<journal file path>"
```

  They print `INDEX-ADDED <index>`, `INDEX-REMOVED <index>`, `INDEX-NOT-LISTED <job>`, `INDEX-REFUSED` (`|`, quotes, `$`, backticks, backslashes or control characters) or `INDEX-BUSY` (another run holds the `INDEX.md.lock` folder for over 10 seconds). Every stop message for such a job prints the job's path and the index path.
- On "continue superfix on #N" (or the journal path): read the lock line, run the lock check, then the locked script on the data as it now is, counting only cases after the adoption date; write the attempt; report with the process wording.
- `owner`: the checklist in the final comment, Status `Waiting for you: sign-off on <plain name>`; the reply "signed off" passes it, anything wrong is a new attempt.
- Every one of these Status values starts "Waiting for you", so journal.md's label rule already applies. The issue stays open; nothing closes on its own.

### 17. Closing

When the last criterion passes or is signed off: post the final comment, then close only after `gh pr view <PR> --json state -q .state` returns `MERGED` (no PR: after the owner's reply). Then the `finish` command (section 9) and, for a no-repo job, `index remove`.

### 18. Comment check (before every post in criteria mode, after LINES-OK)

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" comment --comment "$HOME/.superfix/runs/<run-key>/comment-<N>.md" --kind <decision, stop or final> --run "$HOME/.superfix/runs/<run-key>" --scripts "<criteria folder>" --body "<body file>" --attempts "<criteria folder>/attempts"
```

- Lines inside code fences never count. `decision`: `Criteria: PROPOSED <n>` (or `APPROVED <n>`) once in the AI detail below the LAST `---`, with `<n>` equal to the `P<k>-` lines; one plain line per criterion above the FIRST `---`, in exactly the section 3 form.
- Every kind: `Criteria check: ` once, naming every criterion by its plain name, each `<plain name> <PASS|FAIL|ERROR|LATER YYYY-MM-DD|OWNER> (<value>)` or `(<before> -> <after>)`, separated by `, `.
- `final`: one table row per criterion, `| <plain name> | <before> | <after> | <must be> | <result> |`. Before and after are plain numbers (a `later` after may be `LATER YYYY-MM-DD`; an `owner` row reads `OWNER` in before, after and result); `must be` is the pass line word for word; the result is the computed one. Any other cell is `TABLE-CELL-UNCHECKED` and fails.
- **Every verdict is recomputed** from the newest measured value and the pass line; a PASS or FAIL in the comment that differs is a mismatch.
- Values are compared at fixed places only (the pass line's own number is not a measure): the plain line's Today number and rows against the epoch's line 0 and its outputs; the `Criteria check:` values against the newest line that has that criterion (`<before>` against line 0); the table cells likewise; and the newest line's values and data sha against its output files.
- A personal-data scan runs over the plain lines, the `Criteria check:` line and the table rows: an e-mail address, a phone-like number (8 or more digits), a link, or a run of 9 or more digits is `CRITERIA-PII <what>`.
- It prints `CRITERIA-OK`, or one line each: `CRITERIA-MISSING <what>`, `CRITERIA-COUNT <n>/<m>`, `CRITERIA-IDS-MISSING <names>`, `CRITERIA-PLAIN-BAD <name> (<why>)`, `CRITERIA-VALUE-MISMATCH <name> comment <a> measured <b>` (or `computed <b>`), `TABLE-CELL-UNCHECKED <name> <cell>`, `CRITERIA-PII <what>`, or a lock word. Post only after `LINES-OK` and `CRITERIA-OK`.

### 19. Final comment additions

- The callout says "fixed against the checks you approved" (a process: "change drafted (or adopted), effect measured on <date>: <result>").
- The table (section 18), one row per criterion, the plain name in the first cell.
- The change beside the original (the PR diff, or the counts, or the saved `diff -u` named by path on the Mac), the undo line from section 9's table (never "close the PR" alone: GitHub keeps a closed PR's commits), the waiting checks and their dates.
- The cost line for criteria jobs: `Cost: about <n> USD and <m> attempts (estimate; the run cannot read its own bill)`. Rough figures: Simple about 2 USD and 2 attempts, Moderate about 6 USD and 3.

### 20. Gap notes

- A problem with no checkable criterion (section 1) stops at diagnosis and gets one note (gaps.md), kind "no checkable criterion".
- One note when a criterion would have been `check` but Superfix had no tool or access to measure it, so it fell to `later` or `owner`.
- A problem fully handled in criteria mode gets no note.

### 21. Not tested lines (exact)

- `Not verified on the real file: you have not sent me an export yet.`
- `<plain name> is measured later, on <date>; not checked in this run.`
- `<plain name> needs your sign-off; not checked by me.`
- `The measure scripts ran without the macOS sandbox, as you agreed.` (only after the sandbox question's yes)

### The script

The tool, exactly as the command in section 5 writes it:

```python
# --- crit.py start ---
# superfix 1.5.0 criteria mode. Written into the run folder from
# references/criteria.md. Standard library only; run it with python3 -I.
# Every command prints word lines; silence is never a pass. It never prints
# a data value, a measure script's own output or a line of the measured file.
import argparse, collections, csv, datetime, hashlib, io, json, math, os, pathlib, re, shutil, subprocess, sys, tempfile, time

LINE = re.compile(r"^- (P(\d+)-([CK])(\d+)) \[([a-z]+)\] (.*)$")
FIELDS = re.compile(r"^(?P<name>[^:]*): (?P<defn>.*); pass: (?P<pass>.*?); how: (?P<how>.*?); who: (?P<who>.*)$")
NAME = re.compile(r"^[A-Za-z][A-Za-z0-9 -]*[A-Za-z0-9]$")
LOCK = re.compile(r"^Internal: criteria-sha ([0-9a-f]{64}) \(sha256\), locked (\d{4}-\d{2}-\d{2} \d{2}:\d{2}), approved by (.+)$")
BOX = re.compile(r"^(\s+- )\[[ xX]\]( .*)$")
CLOUD = ["Library/CloudStorage", "shared-drives", "Dropbox", "Library/Mobile Documents", "Google Drive", "OneDrive"]
NUM = r"-?\d+(?:\.\d+)?"
SF_DATALESS = 0x40000000
SAFE_TEXT = re.compile(r"^[^|\x00-\x1f\x7f'\"`$\\]+$")


def now():
    return datetime.datetime.now().strftime("%Y-%m-%d %H:%M")


def real(p):
    return pathlib.Path(os.path.realpath(os.path.expanduser(str(p))))


def sha_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 16), b""):
            h.update(b)
    return h.hexdigest()


def inside(p, folder):
    p, folder = str(real(p)).lower(), str(real(folder)).lower().rstrip("/") + "/"
    return p.startswith(folder)


def section(text, title):
    out, on = [], False
    for l in text.splitlines():
        if l.startswith("## "):
            on = l.strip() == "## " + title
            continue
        if on:
            out.append(l.rstrip())
    return out


def criteria(body_text):
    """The P<k>- lines of ## Done when, each with its indented lines below."""
    crit, cur = [], None
    for l in section(body_text, "Done when"):
        m = LINE.match(l)
        if m:
            cur = {"id": m.group(1), "p": int(m.group(2)), "ck": m.group(3), "kind": m.group(5),
                   "rest": m.group(6), "raw": [l], "list": []}
            crit.append(cur)
            f = FIELDS.match(m.group(6))
            cur.update(f.groupdict() if f else {})
        elif cur and l.startswith("  "):
            cur["raw"].append(l)
            if BOX.match(l):
                cur["list"].append(l)
        else:
            cur = None
    return crit


# Pass-line grammar. Returns (op, a, b) or None (VAGUE). A trailing note in
# brackets without digits is allowed: "112 (today's count)".
def target(p, baseline=None):
    s = re.sub(r"\s*\([^)0-9]*\)\s*$", "", p.strip().lower())
    n = NUM
    rules = [
        (r"(?:0|none|zero|no [a-z][a-z -]* left)", lambda m: ("eq", 0.0, None)),
        (r"yes", lambda m: ("eq", 1.0, None)),
        (r"no", lambda m: ("eq", 0.0, None)),
        (rf"({n}) or fewer|at most ({n})|no more than ({n})", lambda m: ("le", float(next(g for g in m.groups() if g)), None)),
        (rf"(?:fewer|less) than ({n})", lambda m: ("lt", float(m.group(1)), None)),
        (rf"at least ({n})|({n}) or more", lambda m: ("ge", float(next(g for g in m.groups() if g)), None)),
        (rf"({n})% fewer than today", lambda m: ("pct", float(m.group(1)), None)),
        (rf"between ({n}) and ({n})", lambda m: ("range", float(m.group(1)), float(m.group(2)))),
        (rf"(?:exactly )?({n})", lambda m: ("eq", float(m.group(1)), None)),
    ]
    for rx, f in rules:
        m = re.fullmatch(rx, s)
        if m:
            t = f(m)
            if t[0] == "range" and t[1] > t[2]:
                return None
            if t[0] == "pct":
                if not 0 < t[1] < 100:
                    return None
                if baseline is None:
                    return t
                # rounded DOWN, so the target is never easier than the words say
                return ("le", float(math.floor(baseline * (1 - t[1] / 100))), None)
            return t
    return None


def distance(t, v):
    op, a, b = t
    if op == "eq":
        return abs(v - a)
    if op == "le":
        return max(0.0, v - a)
    if op == "lt":
        return 0.0 if v < a else v - a + 1
    if op == "ge":
        return max(0.0, a - v)
    if op == "range":
        return 0.0 if a <= v <= b else min(abs(v - a), abs(v - b))
    return float("inf")


def verdict(c, v, baseline):
    t = target(c["pass"], baseline)
    if t is None or t[0] == "pct":
        return None
    return "PASS" if distance(t, v) == 0 else "FAIL"


def num(s):
    return float(s) if re.fullmatch(NUM, s or "") else None


def fmt(v):
    return str(int(v)) if v == int(v) else str(v)


def read_out(p):
    d = {}
    for l in pathlib.Path(p).read_text().splitlines():
        k, _, v = l.partition(" ")
        d[k] = v
    return d


def icloud_desktop():
    base = pathlib.Path.home() / "Library/Mobile Documents/com~apple~CloudDocs"
    return [n for n in ("Desktop", "Documents") if (base / n).is_dir()]


def in_cloud(p):
    home = pathlib.Path.home()
    roots = CLOUD + icloud_desktop()
    cands = {os.path.abspath(os.path.expanduser(str(p))), str(real(p))}
    for q in cands:
        for c in roots:
            for r in {str(home / c), str(real(home / c))}:
                if (q.lower() + "/").startswith(r.lower().rstrip("/") + "/"):
                    return True
    return False


def placeholder(p):
    """True when reading p could download it: a cloud path or an online-only (dataless) file."""
    if in_cloud(p):
        return True
    try:
        return bool(getattr(os.stat(p), "st_flags", 0) & SF_DATALESS)
    except OSError:
        return False


# ---------- lock ----------

def norm_lines(body_text):
    out = []
    for c in criteria(body_text):
        out += [BOX.sub(r"\1[ ]\2", l) for l in c["raw"]]
    return out


def lock_sha(body_text, scripts, data):
    h = hashlib.sha256()
    for l in norm_lines(body_text):
        h.update((l + "\n").encode())
    for p in sorted(pathlib.Path(scripts).glob("measure-*.py")):
        h.update(f"script {p.name}\0{sha_file(p)}\n".encode())
    for d in sorted(data):
        h.update(f"data {d}\n".encode())
    return h.hexdigest()


def lock_state(body, scripts):
    """('unlocked', None) | ('ok', rec) | ('changed', why)."""
    text = pathlib.Path(body).read_text()
    locks = [(m.group(2), n, m.group(1)) for n, l in enumerate(text.splitlines()) if (m := LOCK.match(l.strip()))]
    if not locks:
        return "unlocked", None
    want = max(locks)[2]
    lf = pathlib.Path(scripts) / "lock"
    if not lf.is_file():
        return "changed", "the lock file is missing"
    rec = {"sha": None, "scripts": {}, "data": []}
    for l in lf.read_text().splitlines():
        k, _, v = l.partition(" ")
        if k == "sha":
            rec["sha"] = v
        elif k == "script":
            i, _, s = v.partition(" ")
            rec["scripts"][i] = s
        elif k == "data":
            rec["data"].append(v)
    if rec["sha"] != want:
        return "changed", "the lock file is not the newest lock line"
    if lock_sha(text, scripts, rec["data"]) != want:
        return "changed", "a criterion line or a measure script changed since the lock"
    return "ok", rec


def need_lock_ok(a):
    st, rec = lock_state(a.body, a.scripts)
    if st == "changed":
        print(f"CRITERIA-CHANGED ({rec}: stop)")
        return False, None
    return True, rec


def data_allowed(path, run, rec):
    return str(real(path)) in rec["data"] or inside(path, pathlib.Path(run) / "work")


def check_outs(run, rows, rec, scripts):
    """Every output behind the attempt lines used the locked scripts and allowed data."""
    bad = []
    for r in rows:
        if r["lock"] == "none" or rec is None:
            continue
        for p in sorted((pathlib.Path(run) / "criteria" / r["from"]).glob("*.out")):
            o = read_out(p)
            if o.get("SCRIPT-SHA") != rec["scripts"].get(p.stem):
                bad.append(f"ERROR-SCRIPT-NOT-LOCKED {p.stem} (attempt {r['n']})")
            if not data_allowed(o.get("DATA", ""), run, rec):
                bad.append(f"ERROR-DATA-NOT-LOCKED {p.stem} (attempt {r['n']})")
    return bad


def cmd_lock(a):
    text = pathlib.Path(a.body).read_text()
    cs = criteria(text)
    if not cs:
        print("CRITERIA-BAD none (no P<k>- line in ## Done when)")
        return 1
    sc = pathlib.Path(a.scripts)
    miss = [c["id"] for c in cs if c["kind"] in ("check", "later") and not (sc / f"measure-{c['id']}.py").is_file()]
    if miss or not a.by.strip():
        print(f"CRITERIA-BAD {' '.join(miss)} how (no script)" if miss else "CRITERIA-BAD approver (say who approved)")
        return 1
    data = sorted({str(real(d)) for d in a.data or []})
    if any(c["kind"] in ("check", "later") for c in cs) and not data:
        print("CRITERIA-BAD data (name each original file with --data)")
        return 1
    stale = []
    used = {r["from"] for r in epoch_rows(a.attempts)}
    for p in sorted(q for u in used for q in (pathlib.Path(a.run) / "criteria" / u).glob("*.out")):
        o, s = read_out(p), sc / f"measure-{p.stem}.py"
        if s.is_file() and o.get("SCRIPT-SHA") != sha_file(s):
            stale.append(f"{p.parent.name}/{p.stem}")
    if stale:
        print(f"CRITERIA-BAD baseline (measured with another script version: {' '.join(stale)}; measure again)")
        return 1
    sha = lock_sha(text, sc, data)
    lines = [f"sha {sha}"] + [f"script {p.stem[len('measure-'):]} {sha_file(p)}" for p in sorted(sc.glob("measure-*.py"))] + [f"data {d}" for d in data]
    (sc / "lock").write_text("\n".join(lines) + "\n")
    print(f"Internal: criteria-sha {sha} (sha256), locked {now()}, approved by {a.by.strip()}")
    print("CRITERIA-LOCKED")
    return 0


def cmd_lockcheck(a):
    st, rec = lock_state(a.body, a.scripts)
    if st == "unlocked":
        print("CRITERIA-UNLOCKED (no criteria-sha line: no fixing)")
        return 1
    if st == "changed":
        print(f"CRITERIA-CHANGED ({rec}: stop)")
        return 1
    if a.run and a.attempts:
        bad = check_outs(a.run, epoch_rows(a.attempts), rec, a.scripts)
        if bad:
            print("\n".join(bad))
            return 1
    print("CRITERIA-LOCK-OK")
    return 0


# ---------- shape ----------

def cmd_shape(a):
    text = pathlib.Path(a.body).read_text()
    cs, bad = criteria(text), []
    if not cs:
        bad.append("CRITERIA-BAD none (no P<k>- line in ## Done when)")
    seen_id, seen_name = set(), set()
    for c in cs:
        i = c["id"]
        if i in seen_id:
            bad.append(f"CRITERIA-BAD {i} id (used twice)")
        seen_id.add(i)
        if c["kind"] not in ("check", "later", "owner"):
            bad.append(f"CRITERIA-BAD {i} kind")
            continue
        if "name" not in c:
            bad.append(f"CRITERIA-BAD {i} fields (want: <plain name>: <definition>; pass: ...; how: ...; who: ...)")
            continue
        if not NAME.match(c["name"]):
            bad.append(f"CRITERIA-BAD {i} name (letters, digits, spaces and hyphens, starting with a letter)")
        elif c["name"].lower() in seen_name:
            bad.append(f"CRITERIA-BAD {i} name (used twice)")
        seen_name.add(c["name"].lower())
        if not c["defn"].strip():
            bad.append(f"CRITERIA-BAD {i} definition")
        if c["kind"] in ("check", "later"):
            if not c["how"].startswith(f"measure-{i}.py"):
                bad.append(f"CRITERIA-BAD {i} how (want measure-{i}.py)")
            if target(c["pass"]) is None:
                bad.append(f"CRITERIA-VAGUE {i} (pass line outside the grammar: ask the owner to rewrite it)")
        if c["kind"] == "check" and c["who"].strip() != "Superfix":
            bad.append(f"CRITERIA-BAD {i} who (want Superfix)")
        if c["kind"] == "later" and not re.fullmatch(r"re-measure on \d{4}-\d{2}-\d{2}", c["who"].strip()):
            bad.append(f"CRITERIA-BAD {i} who (want re-measure on YYYY-MM-DD)")
        if c["kind"] == "owner":
            n = re.search(r"all (\d+) items", c["pass"])
            if c["how"].strip() != "checklist" or c["who"].strip() != "owner sign-off":
                bad.append(f"CRITERIA-BAD {i} how or who (want checklist; owner sign-off)")
            if len(c["list"]) < 2 or (n and int(n.group(1)) != len(c["list"])):
                bad.append(f"CRITERIA-BAD {i} checklist ({len(c['list'])} items)")
        if re.search(r"\b\d{1,2}/\d{1,2}/\d{2,4}\b", c["rest"]):
            bad.append(f"CRITERIA-BAD {i} date (a date like 03/04 is a numbered question, never in the line)")
    for k in sorted({c["p"] for c in cs if c["ck"] == "C"}):
        has_k = any(c["p"] == k and c["ck"] == "K" for c in cs)
        none = re.search(rf"(?m)^P{k}: You chose no 'must not get worse' check", text)
        if not has_k and not none:
            bad.append(f"CRITERIA-NO-KEEP P{k}")
    print("\n".join(bad) if bad else f"CRITERIA-SHAPE-OK {len(cs)}")
    return 1 if bad else 0


# ---------- attempts file ----------

def all_lines(p):
    return pathlib.Path(p).read_text().splitlines() if pathlib.Path(p).exists() else []


def parse_row(l):
    f = l.split()
    if len(f) >= 9 and f[0].isdigit() and f[3] == "data-sha" and f[5] == "from" and f[7] == "lock":
        return {"n": int(f[0]), "sha": f[4], "from": f[6], "lock": f[8],
                "v": {k: float(v) for k, _, v in (x.partition("=") for x in f[9:])}}
    return None


def epoch_rows(p):
    """Attempt lines of the CURRENT epoch only (old epochs stay in the file for audit)."""
    rows = []
    for l in all_lines(p):
        if l.startswith("epoch "):
            rows = []
        elif (r := parse_row(l)):
            rows.append(r)
    return rows


def epochs(p):
    return sum(1 for l in all_lines(p) if l.startswith("epoch "))


def combined(shas):
    u = sorted(set(shas))
    return u[0] if len(u) == 1 else hashlib.sha256("\n".join(u).encode()).hexdigest()


def baseline_of(attempts_path, i):
    rows = epoch_rows(attempts_path) if attempts_path else []
    return rows[0]["v"].get(i) if rows else None


# ---------- measure ----------

PROFILE = '(version 1)(allow default)(deny network*)(deny file-write*)(allow file-write* (subpath "{tmp}") (literal "/dev/null"))'


def records(path):
    try:
        with open(path, newline="", encoding="utf-8", errors="replace") as f:
            return [tuple(r) for r in csv.reader(f)]
    except csv.Error:
        return [tuple([l]) for l in pathlib.Path(path).read_text(errors="replace").splitlines()]


def cmd_measure(a):
    run, i = real(a.run), a.id
    script, data, scripts = real(a.script), real(a.data), real(a.scripts)   # resolved before any cd
    if not (run / "key").is_file():
        print(f"NO-RUN-FOLDER {run}")
        return 1
    if not re.fullmatch(r"[A-Za-z0-9_-]{1,40}", a.out):
        print("ERROR out (letters, digits, - and _ only)")
        return 1
    out = run / "criteria" / a.out
    rec = {"DATA": str(data), "SCRIPT": str(script)}

    def finish(result, why=""):
        out.mkdir(parents=True, exist_ok=True)
        rec["RESULT"] = "ERROR" if result.startswith("ERROR") else result
        (out / f"{i}.out").write_text("".join(f"{k} {v}\n" for k, v in rec.items()))
        if result.startswith("ERROR"):
            print(f"{result} {i} {why}".rstrip())
            return 1
        print(f"{result} {i} {rec['MEASURE']} items {rec['ITEMS']}")
        if a.expect:
            print("EXPECTED" if a.expect == result else f"UNEXPECTED {i} wanted {a.expect} got {result}")
        return 0

    c = next((c for c in criteria(pathlib.Path(a.body).read_text()) if c["id"] == i and c.get("name")), None)
    if not c or c["kind"] not in ("check", "later"):
        return finish("ERROR", "no check or later criterion with this id in ## Done when")
    if script.parent != scripts or script.name != f"measure-{i}.py":
        return finish("ERROR-SCRIPT-NOT-LOCKED", f"(the script must be {scripts}/measure-{i}.py)")
    ok, lk = need_lock_ok(a)
    if not ok:
        return 1
    if placeholder(data) and not a.asked:
        print(f"ASK-FIRST {data} (a cloud or online-only file: reading it can download it; ask the owner, then add --asked)")
        return 1
    try:
        rec["DATA-SHA"], rec["SCRIPT-SHA"] = sha_file(data), sha_file(script)
    except OSError:
        return finish("ERROR", "cannot read the data file or the script")
    if lk:
        if rec["SCRIPT-SHA"] != lk["scripts"].get(i):
            return finish("ERROR-SCRIPT-NOT-LOCKED", "(its sha is not the locked one)")
        if not data_allowed(data, run, lk):
            return finish("ERROR-DATA-NOT-LOCKED", "(only a locked original or a file in the run folder's work/)")
    if a.neg_of:
        neg_of = real(a.neg_of)
        others = {sha_file(neg_of)} | {sha_file(d) for d in (lk["data"] if lk else []) if os.path.isfile(d)}
        if rec["DATA-SHA"] in others:
            return finish("ERROR-NEG-NOT-DISTINCT", "(the negative copy equals the change or an original)")
        added = collections.Counter(records(data)) - collections.Counter(records(neg_of))
        removed = collections.Counter(records(neg_of)) - collections.Counter(records(data))
        if (sum(added.values()), sum(removed.values())) not in ((1, 0), (0, 1), (1, 1)):
            return finish("ERROR-NEG-NOT-ONE-DEFECT", f"(want one row put back, removed or changed; found +{sum(added.values())} -{sum(removed.values())})")
        if not a.defect or not SAFE_TEXT.match(a.defect) or not a.attempts:
            return finish("ERROR", "a negative control needs --defect <plain words, no row values> and --attempts")
    sbx = shutil.which("sandbox-exec") or ("/usr/bin/sandbox-exec" if os.path.exists("/usr/bin/sandbox-exec") else None)
    if os.environ.get("SUPERFIX_TEST_NO_SANDBOX") == "1":   # tests only: can make the sandbox look missing, never skip it
        sbx = None
    if not sbx and not a.unsandboxed_ok:
        print(f"SANDBOX-MISSING {i} (not run; ask the owner the sandbox question, no recommended answer)")
        return 1
    tmp = real(tempfile.mkdtemp(prefix="crit-"))
    try:
        cmd = [sys.executable, "-I", "-B", str(script), str(data)]
        if sbx:
            cmd = [sbx, "-p", PROFILE.format(tmp=tmp)] + cmd
        env = {"PATH": "/usr/bin:/bin", "HOME": str(tmp), "TMPDIR": str(tmp), "LANG": "en_US.UTF-8"}
        r = subprocess.run(cmd, cwd=tmp, env=env, capture_output=True, text=True, timeout=a.timeout, stdin=subprocess.DEVNULL)
    except subprocess.TimeoutExpired:
        return finish("ERROR", f"timeout after {a.timeout} s")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    if r.returncode:
        return finish("ERROR", f"exit {r.returncode}")
    got, word = {}, None
    for l in (l.strip() for l in r.stdout.splitlines()):
        if not l:
            continue
        k, _, v = l.partition(" ")
        if k in ("MEASURE", "ITEMS", "DATA-SHA") and k not in got:
            got[k] = v
        elif l in ("PASS", "FAIL") and word is None:
            word = l
        else:
            return finish("ERROR", "unexpected or doubled output line (a script prints only MEASURE and ITEMS)")
    m = re.fullmatch(re.escape(i) + r" (" + NUM + ")", got.get("MEASURE", ""))
    if not m:
        return finish("ERROR", "missing or wrong MEASURE line")
    if "DATA-SHA" in got and got["DATA-SHA"] != rec["DATA-SHA"]:
        return finish("ERROR", "DATA-SHA is not the sha256 of the file given")
    items = got.get("ITEMS")
    if items is None:
        return finish("ERROR", "missing ITEMS line")
    nums = [] if items == "none" else items.replace(",", " ").split()
    if not all(n.isdigit() for n in nums) or [int(n) for n in nums] != sorted({int(n) for n in nums}):
        return finish("ERROR", "ITEMS must be none or row numbers in ascending order")
    nrec = len(records(data))
    if nums and (int(nums[0]) < 1 or int(nums[-1]) > nrec):
        return finish("ERROR-ITEMS-OUT-OF-RANGE", f"(the file has {nrec} rows, header included)")
    v = float(m.group(1))
    base = baseline_of(a.attempts, i)
    t = target(c["pass"], v if base is None else base)
    if t is None:
        return finish("ERROR", "the pass line is outside the grammar (shape check: CRITERIA-VAGUE)")
    res = "PASS" if distance(t, v) == 0 else "FAIL"
    if word and word != res:
        return finish("ERROR-VERDICT-DISAGREES", f"(script said {word}, the pass line gives {res})")
    rec["MEASURE"], rec["ITEMS"], rec["TARGET"] = m.group(1), " ".join(nums) or "none", f"{t[0]} {fmt(t[1])}" + (f" {fmt(t[2])}" if t[2] is not None else "")
    code = finish(res)
    if a.neg_of:
        with open(a.attempts, "a") as f:
            f.write(f"neg {now()} {i} data-sha {rec['DATA-SHA']} defect {a.defect}\n")
        print("NEG-RECORDED")
    return code


def cmd_attempt(a):
    run = real(a.run)
    if not (run / "key").is_file():
        print(f"NO-RUN-FOLDER {run}")
        return 1
    ok, lk = need_lock_ok(a)
    if not ok:
        return 1
    outs = sorted((run / "criteria" / a.from_).glob("*.out"))
    if not outs:
        print(f"ATTEMPT-REFUSED no output files in {run / 'criteria' / a.from_}")
        return 1
    recs = {p.stem: read_out(p) for p in outs}
    err = [i for i, r in recs.items() if r.get("RESULT") not in ("PASS", "FAIL")]
    if err:
        print(f"ATTEMPT-REFUSED {' '.join(err)} ERROR")
        return 1
    if lk:
        bad = [f"ERROR-SCRIPT-NOT-LOCKED {i}" for i, r in recs.items() if r.get("SCRIPT-SHA") != lk["scripts"].get(i)]
        bad += [f"ERROR-DATA-NOT-LOCKED {i}" for i, r in recs.items() if not data_allowed(r.get("DATA", ""), run, lk)]
        if bad:
            print("\n".join(bad))
            return 1
    lock = lk["sha"] if lk else "none"
    rows = epoch_rows(a.attempts)
    if rows and lock != "none" and any(r["lock"] not in ("none", lock) for r in rows) and not a.new_epoch:
        print("ATTEMPT-REFUSED the criteria were amended: measure a new baseline and add --new-epoch")
        return 1
    vals = {i: float(recs[i]["MEASURE"]) for i in recs}
    sha = combined(r["DATA-SHA"] for r in recs.values())
    if rows and not a.new_epoch and rows[-1]["sha"] == sha and rows[-1]["v"] == vals:
        print(f"ATTEMPT-SAME {rows[-1]['n']} (the same file and values as the newest line; nothing written)")
        return 0
    p = pathlib.Path(a.attempts)
    p.parent.mkdir(parents=True, exist_ok=True)
    with open(p, "a") as f:
        if a.new_epoch or not all_lines(p):
            f.write(f"epoch {epochs(p) + 1} {now()} lock {lock}\n")
            rows = []
        n = rows[-1]["n"] + 1 if rows else 0
        f.write(f"{n} {now()} data-sha {sha} from {a.from_} lock {lock} " + " ".join(f"{i}={recs[i]['MEASURE']}" for i in sorted(recs)) + "\n")
    print(f"ATTEMPT-SAVED {n} (epoch {epochs(p)})")
    return 0


def cmd_progress(a):
    ok, lk = need_lock_ok(a)
    if not ok:
        return 1
    rows = epoch_rows(a.attempts)
    bad = check_outs(a.run, rows, lk, a.scripts)
    if bad:
        print("\n".join(bad))
        return 1
    cs = {c["id"]: c for c in criteria(pathlib.Path(a.body).read_text()) if c.get("name") and c["kind"] == "check"}
    if len(rows) < 2:
        print("PROGRESS-NONE (only the baseline so far)")
        return 0
    base = rows[0]["v"]
    tg = {i: target(c["pass"], base.get(i)) for i, c in cs.items()}

    def step(prev, new):
        worse, better = [], []
        for i, c in cs.items():
            if i not in prev["v"]:
                continue
            if i not in new["v"]:
                worse.append(i)
                continue
            d0, d1 = distance(tg[i], prev["v"][i]), distance(tg[i], new["v"][i])
            if d1 > d0:
                worse.append(i)
            elif d1 < d0 and c["ck"] == "C":
                better.append(i)
        return worse, better

    flags = []
    for prev, new in zip(rows, rows[1:]):
        worse, better = step(prev, new)
        flags.append((new["n"], not worse and bool(better), worse))
    n, moved, worse = flags[-1]
    if cs and all(i in rows[-1]["v"] and distance(tg[i], rows[-1]["v"][i]) == 0 for i in cs):
        print(f"CHECKS-PASS {n}")
        return 0
    print(f"MOVED {n}" if moved else f"NO-PROGRESS {n}" + (f" (worse: {', '.join(cs[i]['name'] for i in worse)})" if worse else " (no failing check improved)"))
    code = 0
    if len(flags) >= 2 and not flags[-1][1] and not flags[-2][1]:
        first, last = rows[-3], rows[-1]
        cid = next((i for i, c in cs.items() if c["ck"] == "C" and i in first["v"] and i in last["v"]
                    and distance(tg[i], first["v"][i]) > 0), None)
        w = sorted({i for f in flags[-2:] for i in f[2]})
        part = f"{cs[cid]['name']} went from {fmt(first['v'][cid])} to {fmt(last['v'].get(cid, first['v'][cid]))}" if cid else "no failing check improved"
        part += f" and {' and '.join(cs[i]['name'] for i in w)} got worse" if w else ""
        print("STOP-NO-PROGRESS")
        print(f'"Two tries did not get closer: {part}. Work kept on <branch or copy>. Reply 1 to re-diagnose (about 20 minutes) or 2 to stop."')
        code = 1
    if n >= a.cap:
        print(f"STOP-CAP {n} of {a.cap} attempts")
        code = 1
    return code


# ---------- comment check ----------

def strip_fences(lines):
    out, f = [], False
    for l in lines:
        if l.startswith("`" * 3):
            f = not f
            continue
        if not f:
            out.append(l)
    return out


PII = [
    ("e-mail", re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")),
    ("url", re.compile(r"[A-Za-z][A-Za-z0-9+.-]*://|www\.")),
    ("long-digit-run", re.compile(r"(?<![0-9a-f])\d{9,}(?![0-9a-f])")),
]
PHONE = re.compile(r"\+?\(?\d[\d ()-]{6,}\d")
EXAMPLES = re.compile(r"^rows? \d+(?:(?:, \d+)*(?:,? and \d+))?$")


def pii(lines):
    hits = []
    for n, l in enumerate(lines, 1):
        for what, rx in PII:
            if rx.search(l):
                hits.append(f"CRITERIA-PII {what} (criteria line {n})")
        for m in PHONE.finditer(re.sub(r"\d{4}-\d{2}-\d{2}", "DATE", l)):
            s = m.group(0).strip()
            if sum(ch.isdigit() for ch in s) >= 8 and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", s):
                hits.append(f"CRITERIA-PII phone-number (criteria line {n})")
    return hits


def cmd_comment(a):
    lines = strip_fences(pathlib.Path(a.comment).read_text().splitlines())
    seps = [n for n, l in enumerate(lines) if l.strip() == "---"]
    plain = lines[:seps[0]] if seps else lines
    ai = lines[seps[-1] + 1:] if (a.kind == "decision" and seps) else lines
    cs = [c for c in criteria(pathlib.Path(a.body).read_text()) if c.get("name")]
    ok, lk = need_lock_ok(a)
    if not ok:
        return 1
    rows = epoch_rows(a.attempts)
    bad = check_outs(a.run, rows, lk, a.scripts)
    if not rows and any(c["kind"] in ("check", "later") for c in cs):
        print("CRITERIA-MISSING attempts (run the attempt command on the baseline first)")
        return 1
    rows = rows or [{"n": 0, "sha": "", "from": "none", "lock": "none", "v": {}}]
    base, new = rows[0], rows[-1]
    run = pathlib.Path(a.run)
    outs = {p.stem: read_out(p) for p in (run / "criteria" / new["from"]).glob("*.out")}
    bouts = {p.stem: read_out(p) for p in (run / "criteria" / base["from"]).glob("*.out")}

    def last(i):
        return next((r for r in reversed(rows) if i in r["v"]), new)

    for i, v in new["v"].items():
        mv = num(outs.get(i, {}).get("MEASURE", ""))
        if mv != v:
            bad.append(f"CRITERIA-VALUE-MISMATCH {i} attempts {fmt(v)} measured {outs.get(i, {}).get('MEASURE', 'none')}")
    if outs and combined(r.get("DATA-SHA", "") for r in outs.values()) != new["sha"]:
        bad.append("CRITERIA-VALUE-MISMATCH data-sha attempts and output files differ")
    if a.kind == "decision":
        cl = [l for l in ai if l.startswith("Criteria: ")]
        if len(cl) != 1:
            bad.append("CRITERIA-MISSING Criteria:")
        else:
            m = re.match(r"^Criteria: (PROPOSED|APPROVED) (\d+)$", cl[0])
            got = int(m.group(2)) if m else 0
            if got != len(cs):
                bad.append(f"CRITERIA-COUNT {got}/{len(cs)}")
    crit_text = []
    ck = [l for l in lines if l.startswith("Criteria check: ")]
    if len(ck) != 1:
        bad.append("CRITERIA-MISSING Criteria check:")
    else:
        crit_text.append(ck[0])
        ent = {}
        for e in ck[0][len("Criteria check: "):].split(", "):
            m = re.match(r"^(.+?) (PASS|FAIL|ERROR|LATER \d{4}-\d{2}-\d{2}|OWNER)(?: \((" + NUM + r")(?: -> (" + NUM + r"))?\))?$", e.strip())
            if m:
                ent[m.group(1).lower()] = m.groups()[1:]
        miss = [c["name"] for c in cs if c["name"].lower() not in ent]
        if miss:
            bad.append(f"CRITERIA-IDS-MISSING {', '.join(miss)}")
        for c in cs:
            e = ent.get(c["name"].lower())
            if not e or c["kind"] == "owner":
                continue
            res, x, y = e
            row = last(c["id"])
            if c["kind"] == "check" and c["id"] in row["v"]:
                want = verdict(c, row["v"][c["id"]], base["v"].get(c["id"]))
                if res != want:
                    bad.append(f"CRITERIA-VALUE-MISMATCH {c['name']} comment {res} computed {want}")
            pairs = [(x, base), (y, row)] if y is not None else [(x, row)]
            for s, r in pairs:
                if s is not None and num(s) != r["v"].get(c["id"]):
                    bad.append(f"CRITERIA-VALUE-MISMATCH {c['name']} comment {s} measured {fmt(r['v'][c['id']]) if c['id'] in r['v'] else 'none'}")
    if a.kind == "decision":
        for c in cs:
            pl = [l for l in plain if l.lower().startswith(c["name"].lower() + ". today: ")]
            if len(pl) != 1:
                bad.append(f"CRITERIA-MISSING plain line for {c['name']}")
                continue
            crit_text.append(pl[0])
            if c["kind"] == "owner":
                continue
            m = re.fullmatch(re.escape(c["name"]) + r"\. Today: (" + NUM + r")(?: \(([^()]*)\))?\. Must be (.+)\.", pl[0], re.I)
            if not m:
                bad.append(f"CRITERIA-PLAIN-BAD {c['name']} (want: <plain name>. Today: <number> (rows N, N and N). Must be <pass line>.)")
                continue
            if m.group(2) is not None and not EXAMPLES.match(m.group(2)):
                bad.append(f"CRITERIA-PLAIN-BAD {c['name']} (the bracket may hold only: rows N, N and N)")
                continue
            if m.group(3).strip() != c["pass"].strip():
                bad.append(f"CRITERIA-PLAIN-BAD {c['name']} (Must be ... is not the locked pass line)")
            if num(m.group(1)) != base["v"].get(c["id"]):
                bad.append(f"CRITERIA-VALUE-MISMATCH {c['name']} comment {m.group(1)} measured {fmt(base['v'][c['id']]) if c['id'] in base['v'] else 'none'}")
            shown = [int(x) for x in re.findall(r"\d+", m.group(2) or "")]
            want = [int(x) for x in bouts.get(c["id"], {}).get("ITEMS", "none").split() if x.isdigit()][:3]
            if shown != want:
                bad.append(f"CRITERIA-VALUE-MISMATCH {c['name']} comment rows {shown or 'none'} measured rows {want or 'none'}")
    if a.kind == "final":
        for c in cs:
            tr = [l for l in lines if re.match(r"^\|\s*" + re.escape(c["name"]) + r"\s*\|", l, re.I)]
            if len(tr) != 1:
                bad.append(f"CRITERIA-MISSING table row for {c['name']}")
                continue
            crit_text.append(tr[0])
            cells = [x.strip() for x in tr[0].strip().strip("|").split("|")]
            if len(cells) != 5:
                bad.append(f"TABLE-CELL-UNCHECKED {c['name']} (want 5 cells: check, before, after, must be, result)")
                continue
            _, before, after, must, result = cells
            if c["kind"] == "owner":
                if (before, after, result) != ("OWNER", "OWNER", "OWNER"):
                    bad.append(f"TABLE-CELL-UNCHECKED {c['name']} (an owner row reads OWNER in before, after and result)")
                continue
            if must != c["pass"].strip():
                bad.append(f"TABLE-CELL-UNCHECKED {c['name']} must be (not the locked pass line)")
            r = last(c["id"])
            for s, rr, label in ((before, base, "before"), (after, r, "after")):
                if c["kind"] == "later" and label == "after" and re.fullmatch(r"LATER \d{4}-\d{2}-\d{2}", s):
                    continue
                if num(s) is None:
                    bad.append(f"TABLE-CELL-UNCHECKED {c['name']} {label} ({'a number' if c['kind'] == 'check' else 'a number, or LATER YYYY-MM-DD after'})")
                elif num(s) != rr["v"].get(c["id"]):
                    bad.append(f"CRITERIA-VALUE-MISMATCH {c['name']} comment {s} measured {fmt(rr['v'][c['id']]) if c['id'] in rr['v'] else 'none'}")
            want = verdict(c, r["v"][c["id"]], base["v"].get(c["id"])) if c["id"] in r["v"] else None
            if not (result == want or (c["kind"] == "later" and result == "LATER")):
                bad.append(f"TABLE-CELL-UNCHECKED {c['name']} result (computed {want or 'none'})")
    bad += pii(crit_text)
    print("\n".join(dict.fromkeys(bad)) if bad else "CRITERIA-OK")
    return 1 if bad else 0


def cmd_signoff(a):
    cs = [c for c in criteria(pathlib.Path(a.body).read_text()) if c["kind"] == "owner"]
    if not cs:
        print("SIGNOFF-NONE (no owner criterion)")
        return 0
    with open(a.attempts, "a") as f:
        for c in cs:
            k = sum(1 for l in c["list"] if re.match(r"^\s+- \[[xX]\]", l))
            f.write(f"signoff {now()} {c['id']} {k}/{len(c['list'])}\n")
            print(f"SIGNOFF {c['id']} {k} of {len(c['list'])} ticked")
    print("SIGNOFF-RECORDED (ticks are a record only; the owner's reply \"signed off\" passes it)")
    return 0


# ---------- paths, copies, visibility ----------

def cmd_where(a):
    print(f"PATH-CLOUD {a.path}" if in_cloud(a.path) else f"PATH-LOCAL {a.path}")
    return 0


def cmd_copy(a):
    run, src = real(a.run), real(a.src)
    if not (run / "key").is_file():
        print(f"NO-RUN-FOLDER {run}")
        return 1
    if in_cloud(run):
        print(f"PATH-CLOUD {run} (the run folder must not sync)")
        return 1
    if placeholder(a.src) and not a.asked:
        print(f"ASK-FIRST {src} (a cloud or online-only file: reading it can download it; ask the owner, then add --asked)")
        return 1
    if not src.is_file():
        print(f"COPY-REFUSED {src} (not a file)")
        return 1
    work = run / "work"
    work.mkdir(mode=0o700, exist_ok=True)
    dest = work / (a.name or src.name)
    if dest.exists() or "/" in (a.name or ""):
        print(f"COPY-EXISTS {dest}" if dest.exists() else "COPY-REFUSED name")
        return 1
    shutil.copy2(src, dest)
    os.chmod(dest, 0o600)
    s = sha_file(src)
    (work / f"{dest.name}.orig").write_text(f"{s} {src}\n")
    print(f"COPY-READY {dest} sha {s}")
    return 0


def cmd_finish(a):
    run = real(a.run)
    work = run / "work"
    if not (run / "key").is_file():
        print(f"NO-RUN-FOLDER {run}")
        return 1
    if not work.is_dir():
        print("WORK-NONE")
        return 0
    changed = False
    for o in sorted(work.glob("*.orig")):
        s, _, p = o.read_text().strip().partition(" ")
        if placeholder(p) and not a.asked:
            print(f"ASK-FIRST {p} (hashing a cloud or online-only original can download it; ask, then add --asked)")
            return 1
        same = pathlib.Path(p).is_file() and sha_file(p) == s
        changed |= not same
        print(f"ORIGINAL-UNCHANGED {p}" if same else f"ORIGINAL-CHANGED {p}")
    if changed:
        print(f"WORK-KEPT {work} (an original changed during the run: tell the owner, ask before deleting)")
        return 1
    shutil.rmtree(work)
    print("WORK-DELETED")
    return 0


def cmd_visibility(a):
    if not re.fullmatch(r"[A-Za-z0-9-]+/[A-Za-z0-9._-]+", a.repo):
        print("VISIBILITY-PUBLIC (unknown: bad repo name; treated as public)")
        return 0
    try:
        r = subprocess.run(["gh", "repo", "view", a.repo, "--json", "visibility,isFork,isPrivate"], capture_output=True, text=True, timeout=60)
        j = json.loads(r.stdout) if r.returncode == 0 else None
    except (OSError, subprocess.TimeoutExpired, ValueError):
        j = None
    if not isinstance(j, dict):
        print("VISIBILITY-PUBLIC (unknown: could not read it; treated as public)")
    elif j.get("visibility") == "PRIVATE" and j.get("isPrivate") is True:
        print("VISIBILITY-PRIVATE" + (" (a fork)" if j.get("isFork") else ""))
    else:
        print(f"VISIBILITY-PUBLIC ({str(j.get('visibility', 'unknown')).lower()}" + (", a fork" if j.get("isFork") else "") + ")")
    return 0


# ---------- index and reminder ----------

def index_path():
    return pathlib.Path.home() / ".superfix" / "journal" / "INDEX.md"


def cmd_index(a):
    if not SAFE_TEXT.match(a.job) or (a.op == "add" and not SAFE_TEXT.match(a.waits or "")):
        print("INDEX-REFUSED (no |, quotes, $, backticks, backslashes or control characters in --job or --waits)")
        return 1
    p = index_path()
    p.parent.mkdir(parents=True, exist_ok=True)
    lockdir = p.parent / "INDEX.md.lock"
    for _ in range(100):
        try:
            os.mkdir(lockdir)
            break
        except FileExistsError:
            time.sleep(0.1)
    else:
        print(f"INDEX-BUSY {lockdir} (another run holds it; remove the folder if no run is active)")
        return 1
    try:
        old = p.read_text().splitlines() if p.exists() else []
        keep = [l for l in old if not l.startswith(f"- {a.job} | ")]
        if a.op == "add":
            keep.append(f"- {a.job} | {now()[:10]} | {a.waits}")
        elif len(keep) == len(old):
            print(f"INDEX-NOT-LISTED {a.job}")
            return 0
        p.write_text("".join(l + "\n" for l in keep))
        print(f"INDEX-{'ADDED' if a.op == 'add' else 'REMOVED'} {p}")
        return 0
    finally:
        os.rmdir(lockdir)


def cmd_remind(a):
    if not NAME.match(a.name) or not SAFE_TEXT.match(a.where) or not re.fullmatch(r"\d{4}-\d{2}-\d{2}", a.date):
        print("REMINDER-REFUSED (a plain name, a link or path without quotes, $ or backticks, and YYYY-MM-DD)")
        return 1
    datetime.date.fromisoformat(a.date)
    cmd = ["gws", "tasks", "tasks", "insert", "--params", json.dumps({"tasklist": "@default"}),
           "--json", json.dumps({"title": f"Superfix: re-check {a.name} ({a.where})", "due": f"{a.date}T00:00:00.000Z"})]
    if a.dry_run:
        cmd.append("--dry-run")
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except (OSError, subprocess.TimeoutExpired):
        print("REMINDER-FAILED (gws did not run: give the owner the ready-to-paste line)")
        return 1
    ok = r.returncode == 0
    print(("REMINDER-DRY-RUN" if a.dry_run else "REMINDER-CREATED") if ok else "REMINDER-FAILED (give the owner the ready-to-paste line)")
    return 0 if ok else 1


# ---------- send check (tests: S13) ----------

READ_VERBS = ("get", "list", "read", "search", "query", "count", "find", "explain", "describe", "check", "summarise",
              "aggregate", "diagnose", "recall", "preview", "analyze", "recommend", "lint", "guide", "fetch")
ARTIFACT_READ = {"read", "list", "list_types", "describe_type", "quickstart", "comments", "status", "list_files",
                 "read_file", "list_assets", "read_asset", "read_db"}
NAME_WORDS = ("send", "reply", "forward", "share", "campaign", "sms", "invite", "publish", "create_event", "update_event",
              "add_comment", "create_comment", "create_task", "manage_drive_access", "set_drive_file_permissions",
              "copy_file", "create_file", "update_file", "update_values", "append_values", "upload_file")
CLOUD_RX = r"(CloudStorage|shared-drives|Dropbox|Mobile Documents|Google Drive|OneDrive|com~apple~CloudDocs)"
BASH_RX = [
    ("gws write", r"\bgws\b(?!.*--dry-run).*\b(send|insert|create|update|patch|delete|modify|trash|import|copy|move|batchUpdate|append)\b"),
    ("osascript send", r"\bosascript\b.*\bsend\b"),
    ("tw write", r"\btw\b\s+(?!get\b|list\b|show\b|view\b|spec\b|help\b)\S+\s+(create|add|update|complete|delete|comment|move|log|close)"),
    ("curl or wget upload", r"\b(curl|wget)\b.*(\s-d\b|\s-d\S|--data|\s-F\b|--form|\s-T\b|--upload-file|--json|-X\s*['\"]?(POST|PUT|PATCH|DELETE)|--request\s+(POST|PUT|PATCH|DELETE)|--post-data|--post-file|--method)"),
    ("netcat", r"(^|[\s;|&(])(nc|ncat|netcat)\s"),
    ("copy to another machine", r"(^|[\s;|&(])(scp|sftp|rsync)\s"),
    ("gist", r"\bgh\s+gist\b"),
    ("cloud write", r"(\b(cp|mv|tee|ditto|install|ln|rsync)\b[^;&|]*" + CLOUD_RX + r")|(>>?\s*['\"]?[^;&|]*" + CLOUD_RX + r")|(python3?\b.*" + CLOUD_RX + r".*(open\(|write|copy|move))"),
    ("ditto", r"(^|[\s;|&(])ditto\s"),
]


def tool_uses(o):
    if isinstance(o, dict):
        if o.get("type") == "tool_use":
            yield o
        for v in o.values():
            yield from tool_uses(v)
    elif isinstance(o, list):
        for v in o:
            yield from tool_uses(v)


def cmd_sendcheck(a):
    hits, review = [], []
    for n, l in enumerate(pathlib.Path(a.log).read_text(errors="replace").splitlines(), 1):
        try:
            o = json.loads(l)
        except ValueError:
            continue
        for u in tool_uses(o):
            name, inp = str(u.get("name", "")), u.get("input") or {}
            low = name.lower()
            if name == "Artifact":
                if str(inp.get("action", "publish")) not in ARTIFACT_READ:
                    hits.append(f"SEND-HIT line {n} Artifact {inp.get('action', 'publish')}")
            elif low.startswith("mcp__"):
                verb = low.rsplit("__", 1)[-1]
                if any(w in verb for w in NAME_WORDS) or not verb.startswith(READ_VERBS):
                    hits.append(f"SEND-HIT line {n} {name}")
            elif name in ("Write", "Edit", "NotebookEdit", "MultiEdit"):
                p = str(inp.get("file_path") or inp.get("notebook_path") or "")
                if re.search(CLOUD_RX, p) or in_cloud(p):
                    hits.append(f"SEND-HIT line {n} {name} into a cloud folder")
            elif name == "Bash":
                c = str(inp.get("command", ""))
                for what, rx in BASH_RX:
                    if re.search(rx, c):
                        hits.append(f"SEND-HIT line {n} Bash {what}")
                if re.search(r"\bgit\s+push\b", c):
                    review.append(f"SEND-REVIEW line {n} git push (check that no data file was committed)")
    out = list(dict.fromkeys(hits + review))
    print("\n".join(out) if out else "SEND-CLEAN")
    return 1 if hits else 0


def main():
    ap = argparse.ArgumentParser()
    sp = ap.add_subparsers(dest="cmd", required=True)

    def p(name, f, *args):
        s = sp.add_parser(name)
        for x in args:
            s.add_argument(f"--{x}", required=True)
        s.set_defaults(f=f)
        return s
    p("shape", cmd_shape, "body")
    s = p("measure", cmd_measure, "run", "id", "script", "data", "out", "body", "scripts")
    s.add_argument("--attempts"); s.add_argument("--expect", choices=["PASS", "FAIL"]); s.add_argument("--asked", action="store_true")
    s.add_argument("--neg-of"); s.add_argument("--defect"); s.add_argument("--unsandboxed-ok", action="store_true")
    s.add_argument("--timeout", type=int, default=120)
    s = p("lock", cmd_lock, "body", "scripts", "by", "run", "attempts"); s.add_argument("--data", action="append")
    s = p("lockcheck", cmd_lockcheck, "body", "scripts"); s.add_argument("--run"); s.add_argument("--attempts")
    s = p("attempt", cmd_attempt, "run", "attempts", "body", "scripts"); s.add_argument("--from", dest="from_", required=True)
    s.add_argument("--new-epoch", action="store_true")
    s = p("progress", cmd_progress, "attempts", "body", "scripts", "run"); s.add_argument("--cap", type=int, default=5)
    s = p("comment", cmd_comment, "comment", "body", "attempts", "run", "scripts")
    s.add_argument("--kind", choices=["decision", "stop", "final"], required=True)
    p("signoff", cmd_signoff, "body", "attempts")
    s = sp.add_parser("where"); s.add_argument("path"); s.set_defaults(f=cmd_where)
    s = p("copy", cmd_copy, "run", "src"); s.add_argument("--asked", action="store_true"); s.add_argument("--name")
    s = p("finish", cmd_finish, "run"); s.add_argument("--asked", action="store_true")
    p("visibility", cmd_visibility, "repo")
    s = sp.add_parser("index"); s.add_argument("op", choices=["add", "remove"]); s.add_argument("--job", required=True)
    s.add_argument("--waits", default=""); s.set_defaults(f=cmd_index)
    s = p("remind", cmd_remind, "name", "where", "date"); s.add_argument("--dry-run", action="store_true")
    p("sendcheck", cmd_sendcheck, "log")
    a = ap.parse_args()
    os.umask(0o077)
    try:
        return a.f(a)
    except (OSError, ValueError, KeyError, IndexError) as e:
        print(f"ERROR {a.cmd} {type(e).__name__}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
# --- crit.py end ---
```
