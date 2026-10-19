# Criteria mode

New in 1.5.0 ([superfix-skill#54](https://github.com/thedanielmay/superfix-skill/issues/54)). SKILL.md (Criteria mode) says when to read this file: in full, before the stop, whenever any problem's Coverage line is "Everything else". A code-only or Qik-only run never reads it and writes `Criteria: NONE (no Everything else problem)`. Every rule of `references/redaction.md`, `references/journal.md` and `references/gaps.md` still holds; this file adds the criteria rules. Every command below writes each value out literally, because the shell keeps no variables between calls, and prints word lines: silence is never a pass.

### 1. Scope

- Data and document clean-ups (a CSV or sheet export, a guide, a list), checked against the owner's own rules, written as criteria and approved by him before any change.
- A process (how refunds, onboarding or approvals work): Superfix may draft or change the process document and sets a `later` criterion. It reports "change drafted (or adopted), effect measured on <date>: <result>", never "solved".
- Roadmap issues [superfix-skill#35](https://github.com/thedanielmay/superfix-skill/issues/35), [superfix-skill#36](https://github.com/thedanielmay/superfix-skill/issues/36) and [superfix-skill#37](https://github.com/thedanielmay/superfix-skill/issues/37) are optional helpers; their output can be a `how:`. A library of recurring criteria is LATER, not in 1.5.0.
- Criteria mode never applies to Code or Qik problems. They keep their own path, solved check and rules.

### 2. Criterion lines in ## Done when

One line per criterion. The id (`P1-C1`) is internal; every message to the owner uses the plain name.

```
- P1-C1 [check] duplicate members: rows whose email, with spaces trimmed and case ignored, matches an earlier row; the earliest joined date wins and keeps its own fee; pass: 0; how: measure-P1-C1.py; who: Superfix
- P1-K1 [check] distinct members: by email with spaces trimmed and case ignored; pass: 112 (today's count); how: measure-P1-K1.py; who: Superfix
- P2-C1 [later] refund time: median days from refund request to payment, over refunds requested after the change was adopted; pass: 3 or fewer over at least 20 refunds; how: measure-P2-C1.py on the refunds log; who: re-measure on 2026-11-16
- P3-C1 [owner] mileage claim: a new staff member can claim mileage from the guide alone; pass: you tick all 3 items below; how: checklist; who: owner sign-off
  - [ ] the guide gives the mileage rate in cents per km
  - [ ] every "see step" points at a step that exists
  - [ ] a claim can be filled in without asking anyone
```

- Shape: `- P<k>-<C|K><n> [<kind>] <plain name>: <definition>; pass: <pass line>; how: <how>; who: <who>`. `C` lines say when the problem is gone; `K` lines say what must not get worse.
- The plain name is letters, digits, spaces and hyphens, starting with a letter, and unique in the issue (it is used in comma-separated lines and must never look like a numbered question).
- Kinds:
  - `check`: measured now by a script; `how: measure-<id>.py`; `who: Superfix`.
  - `later`: a baseline now and a dated re-measure; `how: measure-<id>.py ...`; `who: re-measure on <YYYY-MM-DD>`.
  - `owner`: a checklist of at least 2 items, indented `  - [ ] ` lines under it, then the owner's sign-off; `how: checklist`; `who: owner sign-off`. "all <n> items" must match the number of items.
- Every definition the measure depends on is in the line: what counts as a duplicate, which row wins, how a date or a fee is read. A date that could be read two ways (`03/04/2025`: March or April) is a numbered question, never a guess, and never written into the line.
- Worked numbers for the K example (testbed fixture): 120 rows, minus 6 exact copies, minus 1 row whose email differs only in case, minus 1 row whose email has a trailing space = 112. Without trimming the count is 113, which is why the definition is written out.
- The owner's own words stay on the existing line `The owner's description no longer holds: "<words>"`: context only, never a pass (see 15, Checks met but the description still holds).

### 3. The plain block (above the `---`)

Per criterion, one line in plain words, before the numbered questions:

`<plain name>. Today: <number> (<up to 3 examples>). Must be <pass line>.`

For example: `Duplicate members. Today: 8 (rows 14, 15 and 62 repeat an earlier member's email). Must be 0.`

- Examples are row numbers and the field, never the personal value itself ("rows 14, 15 and 62 share an email with an earlier row"), so nothing personal is posted. Row numbers are as the sheet shows them: the header is row 1, the first data row is row 2.
- The examples are the FIRST 3 row numbers of the baseline script's `ITEMS` line (the script lists every row, in ascending order). The comment check compares them.
- An `owner` criterion's line says what is true today in words ("Today: the guide has no mileage rate.") and lists the checklist below it.
- Approval covers this line and its examples.
- For guides and processes, one plain line above the questions: "Does anyone else use this (staff, customers)? Tell me if they should see the change first."
- A pass line in vague words ("clearer", "better", "faster", "easier", "improved", "nicer"): propose a rewrite with a number, a yes or no fact, or a checklist, and show it here.

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
- The reminder question for a `later` criterion (section 16) goes after the budget question and before the `assets` and create-issue questions (the create-issue question stays last).

### 5. The criteria tool (`crit.py`)

`crit.py` is written into the run folder from this file, by a command, never typed out by hand, like `shot.py` in evidence.md. `<skill dir>` is this skill's base directory, written out in full:

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; if [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; else awk '/^# --- crit.py start ---$/{f=1} f{print} /^# --- crit.py end ---$/{f=0}' '<skill dir>/references/criteria.md' > "$D/crit.py" && grep -q '^# --- crit.py end ---$' "$D/crit.py" && echo "CRIT-READY $D/crit.py"; fi
```

Every command below runs it as `python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" <command> ...`. Paths used here:
- the run folder `$HOME/.superfix/runs/<run-key>` (redaction.md), deleted at the end of the run;
- the criteria folder `$HOME/.superfix/journal/<name>/criteria/<run-key>/` (`<name>` as in journal.md's file-mode path: `<owner>-<repo>`, or the folder name without a remote). It holds the measure scripts and the `attempts` file, never data, so it may outlive the run (a `later` re-check needs the locked scripts);
- the body file: the issue body read fresh (`gh issue view <N> --json body -q .body > "$HOME/.superfix/runs/<run-key>/body-now.md"`), or the journal file in file mode.

Words: `CRIT-READY`, then the words of each command below.

After `RUN-MOVED` (journal.md, the create-issue question), move the criteria folder to the issue key too, before the lock:

```bash
S="$HOME/.superfix/journal/<name>/criteria/<journal run-key>"; T="$HOME/.superfix/journal/<name>/criteria/<owner>+<repo>+<N>"; if [ ! -d "$S" ]; then echo "CRITERIA-FOLDER-NONE $S"; elif [ -e "$T" ]; then echo "REFUSED-EXISTS $T"; else mv "$S" "$T" && echo CRITERIA-FOLDER-MOVED; fi
```

### 6. Shape check (free, before the stop and after every amendment)

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" shape --body "<body file>"
```

It prints `CRITERIA-SHAPE-OK <n>`, or one line per problem: `CRITERIA-BAD <id> <field>` (kind, fields, name, definition, how, who, checklist, date, id), `CRITERIA-VAGUE <id>` (the pass line of a `check` or `later` criterion holds no number and no yes or no fact), `CRITERIA-NO-KEEP P<k>` (a problem with `C` lines, no `K` line and no recorded "none"). Fix the lines and run it again; never post with a problem line.

### 7. Measure scripts

- One per `check` or `later` criterion: `$HOME/.superfix/journal/<name>/criteria/<run-key>/measure-<id>.py`, written under `umask 077` with a quoted heredoc. Standard library only; it reads only the file named as its one argument, writes nothing, uses no network, and never prints a data value.
- Output, in this order: `MEASURE <id> <number>`, `ITEMS <row numbers in ascending order, or none>`, `DATA-SHA <sha256 of the file it read>`, then `PASS` or `FAIL` as the last line.
- Template:

```python
import csv, hashlib, sys
path = sys.argv[1]
data = open(path, "rb").read()
rows = list(csv.DictReader(open(path, newline="", encoding="utf-8")))
seen, items = set(), []
for n, r in enumerate(rows, start=2):        # the header is row 1
    k = r["email"].strip().lower()
    if k in seen:
        items.append(n)
    seen.add(k)
print("MEASURE P1-C1", len(items))
print("ITEMS", " ".join(map(str, items)) or "none")
print("DATA-SHA", hashlib.sha256(data).hexdigest())
print("PASS" if len(items) == 0 else "FAIL")
```

- Read data with the `csv` module, never by splitting on commas: a quoted field with a comma (`"Nguyen, Linh"`) breaks a split.
- Run every script through the tool, never directly; `<out>` names the output folder (`base`, `try1`, `run1`, `run2`, `neg-P1-C1` ...):

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" measure --run "$HOME/.superfix/runs/<run-key>" --id <id> --script "<criteria folder>/measure-<id>.py" --data "<file>" --out <out> --expect <PASS or FAIL>
```

- It runs the script with `python3 -I`, a 120 second limit and no shell, and computes the file's sha256 itself. It writes `<run folder>/criteria/<out>/<id>.out` and prints `PASS <id> <value> items <rows>` or `FAIL ...`, then `EXPECTED` or `UNEXPECTED <id> wanted <a> got <b>`; or `ERROR <id> <reason>` for a non-zero exit, a timeout, a missing or doubled `MEASURE`, `ITEMS` or `DATA-SHA` line, a `DATA-SHA` that is not the sha256 of the file given, `ITEMS` not in ascending order, or a last line that is not `PASS` or `FAIL`. **A crash is ERROR, never FAIL.** It never prints the script's own error text, which could quote a row.
- Before the stop, on the ORIGINAL, `--out base`: each `C` must print `FAIL` with `ITEMS` whose first 3 rows are the examples in the plain block (else the failure is for the wrong reason: fix the script); a `C` that passes does not detect the problem: rewrite it; each `K` must print `PASS`. Then write the baseline attempt (section 14).
- Honest limit: a script that misreads the file quietly (no crash) is caught only when its `ITEMS` or its number differ from what the owner sees in the plain block.

### 8. Business figures

They follow redaction.md: a figure the owner calls private goes on the secrets list, and then blocks any post that holds it. On a PUBLIC repo the plain block and the pass lines use relative values ("20% fewer than today") and counts, never amounts or row values.

### 9. Where the work happens

Work copies live in `$HOME/.superfix/runs/<run-key>/work/` and are DELETED when the job ends (solved, abandoned or stopped for good); the run folder delete at the end of the run removes them too. A `later` job keeps only numbers, data shas and the scripts in the criteria folder, never the data.
- While the owner still has to put a changed copy back (section 10), the job has not ended: the run folder and its `work/` stay (mode 700 and 600, on this Mac only), the stop message names the copy's path, and redaction.md's end-of-run delete waits until the export is measured or the owner says stop. Then `finish` runs first, then the delete.

| What | Change made on | Shown beside the original by | Undo |
|---|---|---|---|
| File in a PRIVATE git repo | the work branch | the PR diff | close the PR |
| File in a PUBLIC git repo holding personal or financial data | a copy in `work/`; nothing committed; the PR (or comment) describes the change in counts | counts before and after | delete the copy |
| File in a folder without git | a copy in `work/` | `diff -u` saved next to it; the original's sha256 checked unchanged at the end | delete the copy |
| Google Doc or Sheet, or a Drive mount file | a local copy (an online-only mount file is read only after asking) | as above | delete the copy |
| A process | a copy of the process description, messages as draft files in `work/` | the diff and a list of who would need to be told | delete the drafts |

- A git repo that itself sits in a cloud mount is treated like a folder without git: copy in `work/`, no branch edit, because a branch edit there syncs to others. Check any path first:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" where "<path>"
```

  It prints `PATH-CLOUD <path>` (under `~/Library/CloudStorage`, `~/shared-drives`, `~/Dropbox`, `~/Library/Mobile Documents`, `~/Google Drive` or `~/OneDrive`, symlinks followed) or `PATH-LOCAL <path>`.
- Make the copy with the tool, which records the original's sha256:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" copy --run "$HOME/.superfix/runs/<run-key>" --src "<original>"
```

  It prints `COPY-READY <copy> sha <sha>`, `COPY-EXISTS`, `COPY-REFUSED`, `PATH-CLOUD` (the run folder itself syncs) or `ASK-FIRST <original>` (a cloud file: reading it can download it; ask the owner, then add `--asked`).
- At the end of the job:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" finish --run "$HOME/.superfix/runs/<run-key>"
```

  It prints `ORIGINAL-UNCHANGED <path>` for each original, then `WORK-DELETED`; or `ORIGINAL-CHANGED <path>` and `WORK-KEPT` (stop, tell the owner what changed, delete only after he answers); or `WORK-NONE`.
- On a PUBLIC repo, never commit personal or financial data: not the file, not a diff of it, not a row value in a PR body or comment.

### 10. The real file (Google Sheet, Drive file, any file the owner puts back himself)

- Final state: "ready, not verified on the real file"; Status `Waiting for you: put it back and give me an export`.
- On the export: compare `shasum -a 256 "<export>" "<run folder>/work/<copy>"`. The same sha: run the locked scripts on the export; pass means verified. A different sha: stop and say "the live file is not the same as my copy (it changed after <date>, or the put-back differs)", record both shas in the journal, and ask whether to measure the export as it is (that counts as a new attempt).

### 11. Never sent, never written outside

In criteria mode:
- No tool call whose name contains `send`, `reply`, `forward`, `share`, `campaign`, `sms`, `invite`, `publish`, `create_event`, `update_event`, `add_comment`, `create_comment`, `create_task`, `manage_drive_access`, `set_drive_file_permissions`, `copy_file`, `create_file`, `update_file`, `update_values`, `append_values`, `upload_file`, or any Gmail, Calendar, Slack, Drive, Docs or Sheets write. No MCP tool that creates, changes, moves or deletes a file or a record anywhere (a Drive, Docs, Sheets, Qik or Teamwork write is a write).
- Through Bash: no `gws` write, no `osascript` with `send`, no `tw` write, no `curl` with `-X POST`, `PUT`, `PATCH` or `-d`, no `gh` call against a repo other than the work repo and the gap repo.
- No Write, Edit, `cp` or `mv` into `~/Library/CloudStorage`, `~/shared-drives`, `~/Dropbox`, `~/Library/Mobile Documents` or any folder that syncs (`where` above prints `PATH-CLOUD`).
- Messages to other people (the team, a customer) are draft files in `work/`, named in the final comment; the owner sends them.
- The one exception: the owner's own reminder task (section 16), only after his explicit yes to that question.

### 12. Lock (at go, before any change)

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" lock --body "<body file>" --scripts "<criteria folder>" --by "<gh login, or the owner at the keyboard>"
```

- It hashes (sha256) every `P<k>-` line of `## Done when` with its checklist lines, and every `measure-*.py` in the criteria folder, and prints `Internal: criteria-sha <64 hex> (sha256), locked <YYYY-MM-DD HH:MM>, approved by <who>` and `CRITERIA-LOCKED` (the word `sha256` on the line lets redaction.md's pattern check pass the hash; never redact it); or `CRITERIA-BAD ...` (no criteria, a missing script, no approver).
- Write that line in ## Decision directly BEFORE the `Internal: approval-sha` line, which stays last. `<who>` is the GitHub login that wrote the approving reply, or "the owner at the keyboard" in chat. After an amendment, the newest line counts.
- Before every attempt, and on every restart:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" lockcheck --body "<body file>" --scripts "<criteria folder>"
```

  It prints `CRITERIA-LOCK-OK`, `CRITERIA-CHANGED` (a line or a script changed since the lock: stop and ask; never fix the lock quietly) or `CRITERIA-UNLOCKED` (no lock line: no fixing).

### 13. Amending

Only through new numbered questions (the Stop gate form). ## Decision gains `Criteria change <date>: "<old plain line>" is now "<new plain line>". Approved by <who> in chat <date time>.` and a new lock line. Then the shape check, a new baseline (`--out base2`, a new attempt line) and the lock check.

### 14. Attempts and the stop rule

The attempts file is `<criteria folder>/attempts`, one line per measured version, written only by the tool from the output files (never typed):

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" attempt --run "$HOME/.superfix/runs/<run-key>" --attempts "<criteria folder>/attempts" --from <out>
```

- It prints `ATTEMPT-SAVED <n>` and appends `<n> <YYYY-MM-DD HH:MM> data-sha <sha> from <out> P1-C1=<value> P1-K1=<value> ...`; or `ATTEMPT-SAME <n>` (the same file and values as the newest line: nothing written, so a version is never counted twice), `ATTEMPT-REFUSED <ids> ERROR` (an output is ERROR) or `ATTEMPT-REFUSED no output files`. Line 0 is the baseline (`--from base`). A problem whose criteria are all `owner` has no scripts and no attempts file. `data-sha` is the measured file's sha256, or, when several files were measured, the sha256 of their shas.
- After every attempt after the baseline:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" progress --attempts "<criteria folder>/attempts" --body "<body file>" --cap <attempts cap, default 5>
```

- Moved: at least one failing `C` got closer to its pass line AND no `C` or `K` got further from its pass line; any worsening is no progress. It prints `CHECKS-PASS <n>` (every `check` criterion meets its pass line: never a stop), `MOVED <n>`, `NO-PROGRESS <n> (worse: <names>)` or `NO-PROGRESS <n> (no failing check improved)`; `PROGRESS-NONE` with only the baseline.
- Two attempts in a row with no progress: `STOP-NO-PROGRESS` and the stop text, filled in: `"Two tries did not get closer: <plain name> went from <before> to <after> and <plain name> got worse. Work kept on <branch or copy>. Reply 1 to re-diagnose (about 20 minutes) or 2 to stop."` Write the branch or copy in place of `<branch or copy>`. Status `Waiting for you: 1 question`.
- The attempts cap reached: `STOP-CAP <n> of <cap> attempts`; a budget stop (SKILL.md Budget).

### 15. Three runs (the solved check in criteria mode)

- Run 1, the original: measure the original again (`--out run1`): every `C` `FAIL`, every `K` `PASS`, and the original's data sha equal to line 0's (the original is unchanged).
- Run 2, the change (`--out run2`, then the attempt command `--from run2`, which prints `ATTEMPT-SAME` when run 2 measured the same file as the last try): every `C` `PASS`, every `K` `PASS` and no further from its pass line than in run 1.
- Run 3, negative control: put one known defect back into a scratch copy of the change (one of the example rows, in `work/neg/`) and measure it with `--out neg-<id> --expect FAIL`: that `C` must `FAIL`. For each `K`, break the guarded thing in another scratch copy (delete one member) and expect `FAIL`. Run 3 outputs are never attempts.
- Any `ERROR` or `UNEXPECTED`, or a run 3 that passes: stop and ask, because locked criteria are never rewritten quietly.
- `later` and `owner` criteria are listed as waiting, never counted as passes.
- Checks met but the description still holds: when every check passes and the owner's description in ## Done when still seems true, say `All checks pass, but you said "<words>" and that still seems true, because <reason>.` Do not say solved; the issue stays open.
- A process is never "solved": "change drafted (or adopted), effect measured on <date>: <result>".

### 16. Later and owner

- `later`: Status `Waiting for you: re-check on <date>`. The PR body says `Refs #<N>`, not `Closes`, and "Adopted, effect not measured yet. <plain name> is due on <date>."
- The reminder question, at the stop, with NO recommended answer (anything but an explicit yes to it is no, like the create-issue question; "keep executing" never creates a task):

```
<n>. P<k>: add a reminder for <date> to re-check <plain name>? It would be one task in your own task list. (yes / no; I create nothing unless you say yes to this question)
```

  - Yes, with `gws`: at the end of the run, one task, the date in the form the API stores correctly (`YYYY-MM-DDT00:00:00.000Z` with the intended local date; a local offset stores the day before):

```bash
gws tasks tasks insert --params '{"tasklist":"@default"}' --json '{"title":"Superfix: re-check <plain name> (<issue link or journal path>)","due":"<YYYY-MM-DD>T00:00:00.000Z"}'
```

  - Yes, without `gws`: one ready-to-paste line in the final comment: `Reminder for <date>: re-check <plain name> with "continue superfix on <issue link or journal path>".`
- No-repo jobs (file-mode journal): one line in `$HOME/.superfix/journal/INDEX.md` per waiting job, removed when the job ends:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" index add --job "<journal file path>" --waits "<what it waits for, for example re-check on 2026-11-16>"
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" index remove --job "<journal file path>"
```

  They print `INDEX-ADDED <index>`, `INDEX-REMOVED <index>`, `INDEX-NOT-LISTED <job>` or `INDEX-REFUSED`. Every stop message for such a job prints the job's path and the index path.
- On "continue superfix on #N" (or the journal path): read the lock line, run the lock check, then the locked script on the data as it now is, counting only cases after the adoption date; write the attempt; report with the process wording.
- `owner`: the checklist in the final comment, Status `Waiting for you: sign-off on <plain name>`; the reply "signed off" passes it, anything wrong is a new attempt.
- Every one of these Status values starts "Waiting for you", so journal.md's label rule already applies. The issue stays open; nothing closes on its own.

### 17. Closing

When the last criterion passes or is signed off: post the final comment, then close only after `gh pr view <PR> --json state -q .state` returns `MERGED` (no PR: after the owner's reply). Then the `finish` command (section 9) and, for a no-repo job, `index remove`.

### 18. Comment check (before every post in criteria mode, after LINES-OK)

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" comment --comment "$HOME/.superfix/runs/<run-key>/comment-<N>.md" --kind <decision, stop or final> --body "<body file>" --attempts "<criteria folder>/attempts" --run "$HOME/.superfix/runs/<run-key>"
```

- Lines inside code fences never count. `decision`: `Criteria: PROPOSED <n>` (or `APPROVED <n>`) once in the AI detail below the LAST `---`, with `<n>` equal to the `P<k>-` lines; one plain line per criterion above the FIRST `---`.
- Every kind: `Criteria check: ` once, naming every criterion by its plain name, each `<plain name> <PASS|FAIL|ERROR|LATER YYYY-MM-DD|OWNER> (<value>)` or `(<before> -> <after>)`, separated by `, `.
- Values are compared at fixed places only, never "every number" (the pass line's own number is not a measure): the plain line's Today number and its examples against line 0 and its output files; the `Criteria check:` value against the newest attempt line (`<before>` against line 0); the result word of a `check` criterion against the newest output; the final table's before and after cells against line 0 and the newest line; and the newest line's values and data sha against its output files.
- A sha written in a comment or body is written next to the word `sha256` (`sha256 <64 hex>`), so redaction.md's pattern check passes it.
- A problem whose criteria are all `owner` needs no attempts file; its lines are still checked.
- It prints `CRITERIA-OK`, or one line each: `CRITERIA-MISSING <what>`, `CRITERIA-COUNT <n>/<m>`, `CRITERIA-IDS-MISSING <names>`, `CRITERIA-VALUE-MISMATCH <name> comment <a> measured <b>`. Post only after `LINES-OK` and `CRITERIA-OK`.

### 19. Final comment additions

- The callout says "fixed against the checks you approved" (a process: "change drafted (or adopted), effect measured on <date>: <result>").
- A table: `| check | before | after | must be | result |`, one row per criterion, the plain name in the first cell.
- The change beside the original (the PR diff, or the counts, or the saved `diff -u` named by path on the Mac), the undo line from section 9, the waiting checks and their dates.
- The cost line for criteria jobs: `Cost: about <n> USD and <m> attempts (estimate; the run cannot read its own bill)`. Rough figures: Simple about 2 USD and 2 attempts, Moderate about 6 USD and 3.

### 20. Gap notes

One note (gaps.md) when a criterion would have been `check` but Superfix had no tool or access to measure it, so it fell to `later` or `owner`. A problem fully handled in criteria mode gets no note.

### 21. Not tested lines (exact)

- `Not verified on the real file: you have not sent me an export yet.`
- `<plain name> is measured later, on <date>; not checked in this run.`
- `<plain name> needs your sign-off; not checked by me.`

### The script

The tool, exactly as the command in section 5 writes it:

```python
# --- crit.py start ---
# superfix 1.5.0 criteria mode. Written into the run folder from
# references/criteria.md. Standard library only; run it with python3 -I.
# Every command prints word lines; silence is never a pass. It never prints
# a data value, a measure script's error text or a line of the measured file.
import argparse, datetime, hashlib, os, pathlib, re, shutil, subprocess, sys

LINE = re.compile(r"^- (P(\d+)-([CK])(\d+)) \[([a-z]+)\] (.*)$")
FIELDS = re.compile(r"^(?P<name>[^:]*): (?P<defn>.*); pass: (?P<pass>.*?); how: (?P<how>.*?); who: (?P<who>.*)$")
NAME = re.compile(r"^[A-Za-z][A-Za-z0-9 -]*[A-Za-z0-9]$")
LOCK = re.compile(r"^Internal: criteria-sha ([0-9a-f]{64}) \(sha256\), locked (\d{4}-\d{2}-\d{2} \d{2}:\d{2}), approved by (.+)$")
CLOUD = ["Library/CloudStorage", "shared-drives", "Dropbox", "Library/Mobile Documents", "Google Drive", "OneDrive"]
NUM = r"-?\d+(?:\.\d+)?"


def now():
    return datetime.datetime.now().strftime("%Y-%m-%d %H:%M")


def sha_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 16), b""):
            h.update(b)
    return h.hexdigest()


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
            if re.match(r"^\s+- \[[ x]\] \S", l):
                cur["list"].append(l)
        else:
            cur = None
    return crit


def target(p):
    """(op, number) from a pass field, or None."""
    s = p.lower()
    if re.fullmatch(r"\s*yes\b.*", s):
        return ("eq", 1.0)
    if re.fullmatch(r"\s*no\b.*", s):
        return ("eq", 0.0)
    m = re.search(r"(at most |under |below |at least |over )?(" + NUM + r")%?( or fewer| or less| or more)?", s)
    if not m:
        return None
    op = "eq"
    if (m.group(1) or "").strip() in ("at most", "under", "below") or m.group(3) in (" or fewer", " or less"):
        op = "le"
    if (m.group(1) or "").strip() in ("at least", "over") or m.group(3) == " or more":
        op = "ge"
    return (op, float(m.group(2)))


def distance(t, v):
    op, n = t
    return abs(v - n) if op == "eq" else max(0.0, v - n) if op == "le" else max(0.0, n - v)


def num(s):
    return float(s) if re.fullmatch(NUM, s) else None


def fmt(v):
    return str(int(v)) if v == int(v) else str(v)


def read_out(p):
    d = {}
    for l in pathlib.Path(p).read_text().splitlines():
        k, _, v = l.partition(" ")
        d[k] = v
    return d


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
        if not NAME.match(c["name"]) or re.match(r"^\d", c["name"]):
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
                bad.append(f"CRITERIA-VAGUE {i}")
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


def cmd_measure(a):
    run, i = pathlib.Path(a.run), a.id
    if not (run / "key").is_file():
        print(f"NO-RUN-FOLDER {run}")
        return 1
    out = run / "criteria" / a.out
    out.mkdir(parents=True, exist_ok=True)
    rec = {"DATA": str(pathlib.Path(a.data).resolve()), "SCRIPT": str(pathlib.Path(a.script).resolve())}

    def finish(result, why=""):
        rec["RESULT"] = result
        (out / f"{i}.out").write_text("".join(f"{k} {v}\n" for k, v in rec.items()))
        if result == "ERROR":
            print(f"ERROR {i} {why}")
        else:
            print(f"{result} {i} {rec['MEASURE']} items {rec['ITEMS']}")
            if a.expect:
                print("EXPECTED" if a.expect == result else f"UNEXPECTED {i} wanted {a.expect} got {result}")
        return 0 if result != "ERROR" else 1

    try:
        rec["DATA-SHA"], rec["SCRIPT-SHA"] = sha_file(a.data), sha_file(a.script)
    except OSError:
        return finish("ERROR", "cannot read the data file or the script")
    try:
        r = subprocess.run([sys.executable, "-I", a.script, a.data], cwd=out, capture_output=True,
                           text=True, timeout=a.timeout, stdin=subprocess.DEVNULL)
    except subprocess.TimeoutExpired:
        return finish("ERROR", f"timeout after {a.timeout} s")
    if r.returncode:
        return finish("ERROR", f"exit {r.returncode}")
    lines = [l.strip() for l in r.stdout.splitlines() if l.strip()]
    got = {}
    for l in lines[:-1]:
        k, _, v = l.partition(" ")
        if k in ("MEASURE", "ITEMS", "DATA-SHA"):
            if k in got:
                return finish("ERROR", f"{k} printed twice")
            got[k] = v
    if not lines or lines[-1] not in ("PASS", "FAIL"):
        return finish("ERROR", "last line is not PASS or FAIL")
    m = re.fullmatch(re.escape(i) + r" (" + NUM + ")", got.get("MEASURE", ""))
    if not m:
        return finish("ERROR", "missing or wrong MEASURE line")
    if got.get("DATA-SHA") != rec["DATA-SHA"]:
        return finish("ERROR", "missing DATA-SHA, or not the sha256 of the file given")
    items = got.get("ITEMS")
    if items is None:
        return finish("ERROR", "missing ITEMS line")
    nums = [] if items == "none" else items.replace(",", " ").split()
    if not all(n.isdigit() for n in nums) or [int(n) for n in nums] != sorted({int(n) for n in nums}):
        return finish("ERROR", "ITEMS must be none or row numbers in ascending order")
    rec["MEASURE"], rec["ITEMS"] = m.group(1), " ".join(nums) or "none"
    return finish(lines[-1])


def lock_sha(body_text, scripts):
    h = hashlib.sha256()
    for c in criteria(body_text):
        h.update(("\n".join(c["raw"]) + "\n").encode())
    for p in sorted(pathlib.Path(scripts).glob("measure-*.py")):
        h.update(f"{p.name}\0{sha_file(p)}\n".encode())
    return h.hexdigest()


def cmd_lock(a):
    text = pathlib.Path(a.body).read_text()
    cs = criteria(text)
    if not cs:
        print("CRITERIA-BAD none (no P<k>- line in ## Done when)")
        return 1
    miss = [c["id"] for c in cs if c["kind"] in ("check", "later")
            and not (pathlib.Path(a.scripts) / f"measure-{c['id']}.py").is_file()]
    if miss or not a.by.strip():
        print(f"CRITERIA-BAD {' '.join(miss)} how (no script)" if miss else "CRITERIA-BAD approver (say who approved)")
        return 1
    print(f"Internal: criteria-sha {lock_sha(text, a.scripts)} (sha256), locked {now()}, approved by {a.by.strip()}")
    print("CRITERIA-LOCKED")
    return 0


def cmd_lockcheck(a):
    text = pathlib.Path(a.body).read_text()
    locks = [(m.group(2), n, m.group(1)) for n, l in enumerate(text.splitlines()) if (m := LOCK.match(l.strip()))]
    if not locks:
        print("CRITERIA-UNLOCKED (no criteria-sha line: no fixing)")
        return 1
    if lock_sha(text, a.scripts) == max(locks)[2]:
        print("CRITERIA-LOCK-OK")
        return 0
    print("CRITERIA-CHANGED (a criterion line or a measure script changed since the lock: stop)")
    return 1


def attempts(p):
    rows = []
    for l in pathlib.Path(p).read_text().splitlines() if pathlib.Path(p).exists() else []:
        f = l.split()
        if len(f) >= 7 and f[3] == "data-sha" and f[5] == "from":
            rows.append({"n": int(f[0]), "sha": f[4], "from": f[6],
                         "v": {k: float(v) for k, _, v in (x.partition("=") for x in f[7:])}})
    return rows


def combined(shas):
    u = sorted(set(shas))
    return u[0] if len(u) == 1 else hashlib.sha256("\n".join(u).encode()).hexdigest()


def cmd_attempt(a):
    run = pathlib.Path(a.run)
    if not (run / "key").is_file():
        print(f"NO-RUN-FOLDER {run}")
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
    old = attempts(a.attempts)
    n = old[-1]["n"] + 1 if old else 0
    vals = " ".join(f"{i}={recs[i]['MEASURE']}" for i in sorted(recs))
    sha = combined(r["DATA-SHA"] for r in recs.values())
    if old and old[-1]["sha"] == sha and old[-1]["v"] == {i: float(recs[i]["MEASURE"]) for i in recs}:
        print(f"ATTEMPT-SAME {old[-1]['n']} (the same file and values as the newest line; nothing written)")
        return 0
    p = pathlib.Path(a.attempts)
    p.parent.mkdir(parents=True, exist_ok=True)
    with open(p, "a") as f:
        f.write(f"{n} {now()} data-sha {sha} from {a.from_} {vals}\n")
    print(f"ATTEMPT-SAVED {n}")
    return 0


def cmd_progress(a):
    cs = {c["id"]: c for c in criteria(pathlib.Path(a.body).read_text()) if c.get("name") and c["kind"] == "check"}
    rows = attempts(a.attempts)
    if len(rows) < 2:
        print("PROGRESS-NONE (only the baseline so far)")
        return 0

    def step(prev, new):
        worse, better = [], []
        for i, c in cs.items():
            t = target(c["pass"])
            if i not in prev["v"]:
                continue
            if i not in new["v"]:
                worse.append(i)
                continue
            d0, d1 = distance(t, prev["v"][i]), distance(t, new["v"][i])
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
    if cs and all(i in rows[-1]["v"] and distance(target(c["pass"]), rows[-1]["v"][i]) == 0 for i, c in cs.items()):
        print(f"CHECKS-PASS {n}")
        return 0
    print(f"MOVED {n}" if moved else f"NO-PROGRESS {n}" + (f" (worse: {', '.join(cs[i]['name'] for i in worse)})" if worse else " (no failing check improved)"))
    code = 0
    if len(flags) >= 2 and not flags[-1][1] and not flags[-2][1]:
        first, last = rows[-3], rows[-1]
        cid = next((i for i, c in cs.items() if c["ck"] == "C" and i in first["v"] and i in last["v"]
                    and distance(target(c["pass"]), first["v"][i]) > 0), None)
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


def strip_fences(lines):
    out, f = [], False
    for l in lines:
        if l.startswith("`" * 3):
            f = not f
            continue
        if not f:
            out.append(l)
    return out


def cmd_comment(a):
    lines = strip_fences(pathlib.Path(a.comment).read_text().splitlines())
    seps = [n for n, l in enumerate(lines) if l.strip() == "---"]
    plain = lines[:seps[0]] if seps else lines
    ai = lines[seps[-1] + 1:] if (a.kind == "decision" and seps) else lines
    cs = [c for c in criteria(pathlib.Path(a.body).read_text()) if c.get("name")]
    rows = attempts(a.attempts)
    bad = []
    if not rows and any(c["kind"] in ("check", "later") for c in cs):
        print("CRITERIA-MISSING attempts (run the attempt command on the baseline first)")
        return 1
    rows = rows or [{"n": 0, "sha": "", "from": "none", "v": {}}]
    base, new = rows[0], rows[-1]
    run = pathlib.Path(a.run)
    outs = {p.stem: read_out(p) for p in (run / "criteria" / new["from"]).glob("*.out")}
    bouts = {p.stem: read_out(p) for p in (run / "criteria" / base["from"]).glob("*.out")}
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
    ck = [l for l in lines if l.startswith("Criteria check: ")]
    if len(ck) != 1:
        bad.append("CRITERIA-MISSING Criteria check:")
    else:
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
            if c["kind"] == "check" and c["id"] in outs and res != outs[c["id"]].get("RESULT"):
                bad.append(f"CRITERIA-VALUE-MISMATCH {c['name']} comment {res} measured {outs[c['id']].get('RESULT')}")
            last = next((r for r in reversed(rows) if c["id"] in r["v"]), new)
            pairs = [(x, base), (y, last)] if y is not None else [(x, last)]
            for s, row in pairs:
                if s is not None and num(s) != row["v"].get(c["id"]):
                    bad.append(f"CRITERIA-VALUE-MISMATCH {c['name']} comment {s} measured {fmt(row['v'][c['id']]) if c['id'] in row['v'] else 'none'}")
    if a.kind == "decision":
        for c in cs:
            pl = [l for l in plain if l.lower().startswith(c["name"].lower() + ". today: ")]
            if len(pl) != 1:
                bad.append(f"CRITERIA-MISSING plain line for {c['name']}")
                continue
            if c["kind"] == "owner":
                continue
            m = re.match(r"^.*?\. today: (" + NUM + r")[^.(]*?(?:\s*\(([^)]*)\))?(?:\.|$)", pl[0], re.I)
            if not m or num(m.group(1)) != base["v"].get(c["id"]):
                bad.append(f"CRITERIA-VALUE-MISMATCH {c['name']} comment {m.group(1) if m else 'none'} measured {fmt(base['v'][c['id']]) if c['id'] in base['v'] else 'none'}")
            shown = [int(x) for x in re.findall(r"\d+", m.group(2) or "")] if m else []
            want = [int(x) for x in bouts.get(c["id"], {}).get("ITEMS", "none").split() if x.isdigit()][:3]
            if shown != want:
                bad.append(f"CRITERIA-VALUE-MISMATCH {c['name']} comment rows {shown or 'none'} measured rows {want or 'none'}")
    if a.kind == "final":
        for c in cs:
            tr = [l for l in lines if re.match(r"^\|\s*" + re.escape(c["name"]) + r"\s*\|", l, re.I)]
            if len(tr) != 1:
                bad.append(f"CRITERIA-MISSING table row for {c['name']}")
                continue
            cells = [x.strip() for x in tr[0].strip().strip("|").split("|")]
            last = next((r for r in reversed(rows) if c["id"] in r["v"]), new)
            for s, row in ((cells[1] if len(cells) > 1 else "", base), (cells[2] if len(cells) > 2 else "", last)):
                if c["kind"] != "owner" and num(s) is not None and num(s) != row["v"].get(c["id"]):
                    bad.append(f"CRITERIA-VALUE-MISMATCH {c['name']} comment {s} measured {fmt(row['v'][c['id']]) if c['id'] in row['v'] else 'none'}")
    print("\n".join(dict.fromkeys(bad)) if bad else "CRITERIA-OK")
    return 1 if bad else 0


def in_cloud(p):
    home = pathlib.Path.home()
    for q in {pathlib.Path(os.path.abspath(os.path.expanduser(p))), pathlib.Path(p).expanduser().resolve()}:
        for c in CLOUD:
            try:
                q.relative_to(home / c)
                return True
            except ValueError:
                pass
    return False


def cmd_where(a):
    print(f"PATH-CLOUD {a.path}" if in_cloud(a.path) else f"PATH-LOCAL {a.path}")
    return 0


def cmd_copy(a):
    run, src = pathlib.Path(a.run), pathlib.Path(a.src)
    if not (run / "key").is_file():
        print(f"NO-RUN-FOLDER {run}")
        return 1
    if in_cloud(run):
        print(f"PATH-CLOUD {run} (the run folder must not sync)")
        return 1
    if in_cloud(src) and not a.asked:
        print(f"ASK-FIRST {src} (a cloud file: reading it can download it; ask the owner, then add --asked)")
        return 1
    if not src.is_file():
        print(f"COPY-REFUSED {src} (not a file)")
        return 1
    work = run / "work"
    work.mkdir(mode=0o700, exist_ok=True)
    dest = work / src.name
    if dest.exists():
        print(f"COPY-EXISTS {dest}")
        return 1
    shutil.copy2(src, dest)
    os.chmod(dest, 0o600)
    s = sha_file(src)
    (work / f"{src.name}.orig").write_text(f"{s} {src.resolve()}\n")
    print(f"COPY-READY {dest} sha {s}")
    return 0


def cmd_finish(a):
    run = pathlib.Path(a.run)
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
        same = pathlib.Path(p).is_file() and sha_file(p) == s
        changed |= not same
        print(f"ORIGINAL-UNCHANGED {p}" if same else f"ORIGINAL-CHANGED {p}")
    if changed:
        print(f"WORK-KEPT {work} (an original changed during the run: tell the owner, ask before deleting)")
        return 1
    shutil.rmtree(work)
    print("WORK-DELETED")
    return 0


def index_path():
    return pathlib.Path.home() / ".superfix" / "journal" / "INDEX.md"


def cmd_index(a):
    p = index_path()
    old = p.read_text().splitlines() if p.exists() else []
    keep = [l for l in old if not l.startswith(f"- {a.job} | ")]
    if a.op == "add":
        if "|" in a.waits or "\n" in a.waits:
            print("INDEX-REFUSED (no | or line break in the waiting text)")
            return 1
        keep.append(f"- {a.job} | {now()[:10]} | {a.waits}")
    elif len(keep) == len(old):
        print(f"INDEX-NOT-LISTED {a.job}")
        return 0
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text("".join(l + "\n" for l in keep))
    print(f"INDEX-{'ADDED' if a.op == 'add' else 'REMOVED'} {p}")
    return 0


def main():
    ap = argparse.ArgumentParser()
    sp = ap.add_subparsers(dest="cmd", required=True)
    s = sp.add_parser("shape"); s.add_argument("--body", required=True); s.set_defaults(f=cmd_shape)
    s = sp.add_parser("measure"); s.add_argument("--run", required=True); s.add_argument("--id", required=True)
    s.add_argument("--script", required=True); s.add_argument("--data", required=True)
    s.add_argument("--out", required=True); s.add_argument("--expect", choices=["PASS", "FAIL"])
    s.add_argument("--timeout", type=int, default=120); s.set_defaults(f=cmd_measure)
    s = sp.add_parser("lock"); s.add_argument("--body", required=True); s.add_argument("--scripts", required=True)
    s.add_argument("--by", required=True); s.set_defaults(f=cmd_lock)
    s = sp.add_parser("lockcheck"); s.add_argument("--body", required=True); s.add_argument("--scripts", required=True)
    s.set_defaults(f=cmd_lockcheck)
    s = sp.add_parser("attempt"); s.add_argument("--run", required=True); s.add_argument("--attempts", required=True)
    s.add_argument("--from", dest="from_", required=True); s.set_defaults(f=cmd_attempt)
    s = sp.add_parser("progress"); s.add_argument("--attempts", required=True); s.add_argument("--body", required=True)
    s.add_argument("--cap", type=int, default=5); s.set_defaults(f=cmd_progress)
    s = sp.add_parser("comment"); s.add_argument("--comment", required=True)
    s.add_argument("--kind", choices=["decision", "stop", "final"], required=True)
    s.add_argument("--body", required=True); s.add_argument("--attempts", required=True)
    s.add_argument("--run", required=True); s.set_defaults(f=cmd_comment)
    s = sp.add_parser("where"); s.add_argument("path"); s.set_defaults(f=cmd_where)
    s = sp.add_parser("copy"); s.add_argument("--run", required=True); s.add_argument("--src", required=True)
    s.add_argument("--asked", action="store_true"); s.set_defaults(f=cmd_copy)
    s = sp.add_parser("finish"); s.add_argument("--run", required=True); s.set_defaults(f=cmd_finish)
    s = sp.add_parser("index"); s.add_argument("op", choices=["add", "remove"]); s.add_argument("--job", required=True)
    s.add_argument("--waits", default=""); s.set_defaults(f=cmd_index)
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
