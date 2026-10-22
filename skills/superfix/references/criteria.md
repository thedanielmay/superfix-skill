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
- The pass line follows this grammar exactly; anything else (two comparator phrases, a leading "no" with a comparator that is not a rule below, "under 3", "clearer") is `CRITERIA-VAGUE`, and the owner is asked to rewrite it:

| Pass line | Means |
|---|---|
| `0`, `none`, `zero`, `no`, `no <things> left` (the things are plain words with no comparator: `no more than three left` is VAGUE) | equal to 0 |
| `yes` | equal to 1 (a yes or no fact the script prints as 1 or 0) |
| `<N>`, `exactly <N>` | equal to N |
| `<N> or fewer`, `at most <N>`, `no more than <N>` | N or less |
| `fewer than <N>`, `less than <N>` | below N |
| `at least <N>`, `<N> or more`, `no fewer than <N>` | N or more |
| `between <A> and <B>` | A to B, both included |
| `<N>% fewer than today` (N from 1 to 99; `C` lines only, a `K` line with it is VAGUE) | at most floor(baseline x (100 - N) / 100), computed in exact integer and fraction arithmetic and rounded DOWN, so it is never easier than the words; the baseline is the first measure of the current epoch (section 14) |

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

Exact, after the problem questions and before the budget question, with no recommended answer and never in the Simple short form. The two questions are asked ONCE per issue, for all the criteria-mode problems together; only when the problems touch different people or different files, once per group of problems with the same people and files (live tests: three small problems with two questions each made 11 questions; together it is 7):

```
<n>. P1, P2 and P3 (<short names>): if every check above passes, would you consider these solved? (yes / no, and what is missing)
<n+1>. P1, P2 and P3: what must not get worse, for you or anyone affected (staff, customers)? My suggestions: <K lines in plain words, each with its problem>. (reply "those", add your own, or "none")
```

- One problem: `<n>. P<k> (problem <k>: <short name>): ... would you consider this solved? ...`. Groups: one pair per group, each naming its problems and who or what it touches (`P1 and P2 (... ; the members sheet)`, `P3 (...; staff who claim mileage)`).
- The answers apply to every problem in the group: a "yes" approves the `C` lines of each; "no, P2 ..." means rewrite P2's and ask again for P2 only. The lock records the approval per problem (`lock --approved P1,P2,P3`, section 12). The comment check asks each criteria-mode problem to be in exactly one of each question (`CRITERIA-QUESTIONS-MISSING P<k>`, `CRITERIA-QUESTIONS-TWICE P<k>`).

- An unclear definition (a date that reads two ways, which row wins) gets its own numbered question before these two.
- Meanings:
  - "yes" to the first approves the `C` lines; "no ..." means rewrite them and ask again; anything else means not approved yet.
  - "those" keeps the suggested `K` lines; added words become new `K` lines, shown back for a yes; "none" means no guard, recorded in ## Decision as `P<k>: You chose no 'must not get worse' check, so a fix could break something unnoticed.`
  - Only "yes" to the first plus an answer to the second approves the problems they name.
- "Keep executing" (or "keep going", "yes to all") does not approve them, because these questions have no recommended answer. Say once, in chat and in the decision comment: `Keep executing does not approve the checks for problem <k>; I am waiting for your answers to questions <a> and <b>.` The notice is APPENDED to the existing decision comment, never a new comment, so the comment counts in journal.md stay the same: record the decision comment's id when it is posted (the number after `#issuecomment-` in the URL `gh issue comment` prints) in `$HOME/.superfix/runs/<run-key>/decision-comment-id`, add the notice to the comment file, run the checks again, then `gh api -X PATCH repos/<owner>/<repo>/issues/comments/<id> -F body=@<comment file>`. Never `--edit-last` (it edits the newest comment by whoever is logged in). Ask again once more, at most; then park that problem with Status `Waiting for you: <n> questions` (the label rule applies). Code and Qik problems in the same issue go ahead on their own answers.
- Two more criteria questions, each with NO recommended answer (anything but an explicit yes is no), after the two above and before the budget question, only when they apply:
  - `<n>. The measure scripts cannot run in the macOS sandbox here (SANDBOX-MISSING), so nothing would stop a script reaching the network or writing files. Run them without it? (yes / no)` When it applies it is asked FIRST and alone (no baseline can be measured without it): stop on it; after an explicit yes, write `Internal: unsandboxed approved by <gh login, or the owner at the keyboard>, <YYYY-MM-DD HH:MM>` in ## Decision, then measure with `--unsandboxed-ok`. Every record and attempt line made that way is stamped (`SANDBOX off`, `sbx off`), and every criteria comment of that epoch carries the line `UNSANDBOXED: the measure scripts ran without the macOS sandbox, as you agreed.`
  - `<n>. Commit the changed <files> to <owner/repo>? GitHub keeps every pushed commit even if the PR is closed, and they become public if the repo is ever made public. Do these files hold names or contact details of customers or staff? (commit: yes / no, keep them on my Mac; names or contact details: yes / no)` (section 9). Asked only on a repo `visibility` reports PRIVATE.
- Order of the optional questions after the budget question: the diagram question (diagrams.md; never for an Everything else problem), the reminder question (section 16), the `assets` question, and the create-issue question always last.

### 5. The criteria tool (`crit.py`)

`crit.py` is written into the run folder from `references/crit.py`, by a command, never typed out by hand, like `shot.py` in evidence.md. `<skill dir>` is this skill's base directory, written out in full:

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; S="<criteria folder>"; if [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; elif [ -f "$S/lock" ]; then C="$S/crit.py"; L="$(sed -n 's/^crit //p' "$S/lock")"; if [ -f "$C" ] && [ "$(shasum -a 256 "$C" | cut -d' ' -f1)" = "$L" ]; then cp "$C" "$D/crit.py" && echo "CRIT-READY $D/crit.py (the locked tool)"; else echo "CRIT-SHA-MISMATCH (the criteria folder's crit.py is not the lock's crit line: stop)"; fi; else cp '<skill dir>/references/crit.py' "$D/crit.py" && echo "CRIT-READY $D/crit.py"; fi
```

A locked job keeps the tool it was locked with: when the criteria folder's `lock` exists, the command above reuses its `crit.py`, and stops loudly otherwise. It never writes a newer tool over the folder's copy and never re-locks silently. The 1.5.0 copy is there because every attempt wrote it, so later tool changes stop breaking older jobs.

Every command below starts `python3 -I "$HOME/.superfix/runs/<run-key>/crit.py"`. The same arguments recur, always written out in full:
- `--run "$HOME/.superfix/runs/<run-key>"`: the run folder (redaction.md), deleted at the end of the run;
- `--scripts "<criteria folder>"`: `$HOME/.superfix/journal/<name>/criteria/<run-key>` (`<name>` as in journal.md's file-mode path: `<owner>-<repo>`, or the folder name without a remote). It holds the measure scripts, the `lock` file, the `attempts` file, the tool's own `records/` and the owner's `VERIFY.txt`, never data, so it outlives the run (a `later` re-check needs them);
- `--attempts "<criteria folder>/attempts"`;
- the body: `--issue '<owner>/<repo>#<N>'` when an issue exists (the tool fetches the body itself with `gh issue view --json body`, so it never trusts a file for it); `--body "<journal file>"` in file mode, where the journal file is the record and the tool stores its sha256 in each attempt line.

Every path argument is resolved to its real path before the tool changes folder. Words: `CRIT-READY`, then the words of each command below; `BODY-UNREADABLE` when the body cannot be read.

**The posted record.** Every tool write to the attempts file refreshes `<criteria folder>/head` (its line count and the first 8 hex of the newest line's sha256), and every criteria comment carries the public line `attempts: <n> lines, head <8 hex>` (the tool prints it after each write; the comment check compares it). On every later check the tool reads the newest such line already posted: from the issue's comments (`--issue`), from `--prev-comment <file>`, or from the journal file (`--body`), and prints `ATTEMPTS-TRUNCATED` when the file has fewer lines or another line at that place, and `ATTEMPTS-MISSING` when a lock exists but the attempts file, or its line for that lock, is gone.

**Honest limit: the tool is DETECTIVE, not preventive.** It finds changed, missing or hand-made records (a hash chain, run ids, record hashes), and it re-runs the locked scripts itself, but a model that can edit files can still forge a record by working the chain out. The owner's own check is one line: each attempt writes `<criteria folder>/VERIFY.txt`, a command that first prints the sha256 of the copy of the tool it runs (to compare with the posted `Internal: crit-sha` line; `CRIT-SHA-MISMATCH` when they differ), checks every script against the lock, then re-runs the scripts on the files named, which the owner may replace with his own copy (Superfix's work copies are deleted at the end): the same file gives `VERIFY-OK <n>` or `VERIFY-MISMATCH <id> attempts <a> now <b>`; another file gives `VERIFY-DIFFERENT-DATA <id>` with both numbers, for information, never a false alarm; a file that is gone gives `VERIFY-NO-FILE`. The decision comment and the final comment say where it is: `To check my numbers yourself, run the command in <criteria folder>/VERIFY.txt on your Mac.`

After `RUN-MOVED` (journal.md, the create-issue question), move the criteria folder to the issue key too, before the lock:

```bash
S="$HOME/.superfix/journal/<name>/criteria/<journal run-key>"; T="$HOME/.superfix/journal/<name>/criteria/<owner>+<repo>+<N>"; if [ ! -d "$S" ]; then echo "CRITERIA-FOLDER-NONE $S"; elif [ -e "$T" ]; then echo "REFUSED-EXISTS $T"; else mv "$S" "$T" && echo CRITERIA-FOLDER-MOVED; fi
```

### 6. Shape check (free, before the stop and after every amendment)

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" shape --issue '<owner>/<repo>#<N>'   # or --body "<journal file>"
```

It prints `CRITERIA-SHAPE-OK <n>`, or one line per problem: `CRITERIA-BAD <id> <field>` (kind, fields, name, definition, how, who, checklist, date, id), `CRITERIA-VAGUE <id>` (the pass line is outside the grammar in section 2), `CRITERIA-NO-KEEP P<k>` (a problem with `C` lines, no `K` line and no recorded "none"). Fix the lines and run it again; never post with a problem line.

### 7. Measure scripts

- One per `check` or `later` criterion, exactly `<criteria folder>/measure-<id>.py`, written under `umask 077` with a quoted heredoc. Standard library only; it reads only the file named as its one argument, writes nothing, uses no network.
- It prints only `MEASURE <id> <number>` and `ITEMS <row numbers in ascending order, or none>`. The number is posted, so it must be plain: an integer of up to 9 digits, or at most 2 decimals and 9 digits in all; anything else is `ERROR-MEASURE-FORMAT`. **The tool decides PASS or FAIL itself** from the number and the pass line; a script may also print `DATA-SHA <sha256>` and a `PASS` or `FAIL` line, but any that disagrees is an error, and any other line (a value, a name, a debug print) is an error that is never shown.
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

- Read data with the `csv` module, never by splitting on commas: a quoted field with a comma (`"Nguyen, Linh"`) breaks a split. Row numbers count records for `.csv` and `.tsv` files and lines for every other file.
- How the tool runs a script (`baseline`, `attempt`, `amend`, `measure`, `verify`): under `/usr/bin/sandbox-exec` only (never a `sandbox-exec` found on PATH), with a DENY-BY-DEFAULT profile (probed on this Mac): it may start only the Python binary (so `osascript`, `security`, `pbpaste`, `curl` or any child program cannot start), read only the script, the data file, a temporary folder it deletes afterwards, system library paths and the Python install, read metadata only on those paths and their parent folders (so it cannot list or stat the home folder), write only in that temporary folder, and use no network and no other service; with `python3 -I -B`, a cleaned environment, a 120 second limit, no shell, in its own process group, which is killed after a timeout AND after a normal exit.
- Residual, said plainly: the one thing a script sends out is its number and its row numbers. A `MEASURE` number of up to 9 digits can carry a few bits of a data value per attempt; the tool keeps that channel small (9 digits, at most 5 attempts per epoch) but cannot close it. The plain block shows only counts and row numbers, and the owner approves the definitions before anything runs.
- Errors, each a stop and never FAIL: `ERROR <id> <reason>` (a non-zero exit, a timeout, a missing or wrong `MEASURE` or `ITEMS` line, an unexpected line, `ITEMS` not ascending, a `DATA-SHA` that is not the file's), `ERROR-MEASURE-FORMAT`, `ERROR-VERDICT-DISAGREES`, `ERROR-ITEMS-OUT-OF-RANGE` (a row number above the file's row count, header included), `ERROR-SCRIPT-NOT-LOCKED` (not `measure-<id>.py` in the criteria folder, or after go not the locked sha), `ERROR-DATA-NOT-LOCKED` (after go, neither a locked original nor in a run folder's `work/`), `CRITERIA-CHANGED`, `SANDBOX-MISSING` (nothing ran: ask the sandbox question in section 4; only after a yes add `--unsandboxed-ok`), `ASK-FIRST <file>` (a cloud or online-only file: reading it can download it; ask the owner, then add `--asked`).
- Measuring for the record is `baseline` (before the stop), `attempt` (after go) and `amend` (after an amendment), section 14: the tool runs every script itself and writes the records. `measure` is only for run 1, the negative control (section 15) or a look; its output is never an attempt:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" measure --run "$HOME/.superfix/runs/<run-key>" --scripts "<criteria folder>" --issue '<owner>/<repo>#<N>' --attempts "<criteria folder>/attempts" --id <id> --script "<criteria folder>/measure-<id>.py" --data "<file>" --out <name> --expect <PASS or FAIL>
```

  It prints `PASS <id> <value> items <rows>` or `FAIL ...`, then `EXPECTED`, or `UNEXPECTED <id> wanted <a> got <b>` (a stop: it exits non-zero).
- Before the stop, the baseline is `baseline --label base` on the ORIGINAL (section 14): each `C` must print `FAIL` with `ITEMS` whose first 3 rows are the rows in the plain block (else the failure is for the wrong reason: fix the script); a `C` that passes does not detect the problem: rewrite it; each `K` must print `PASS`.
- Honest limit: a script that misreads the file quietly (no crash) is caught only when its `ITEMS` or its number differ from what the owner sees in the plain block.

### 8. Business figures

They follow redaction.md: a figure the owner calls private goes on the secrets list, and then blocks any post that holds it. The plain block and the pass lines use counts, and on a PUBLIC repo relative values ("20% fewer than today"), never amounts or row values.

### 9. Where the work happens

Work copies live in `$HOME/.superfix/runs/<run-key>/work/` and are DELETED when the job ends (solved, abandoned or stopped for good), except the verified copies, which stay until taken or stop; a stop deletes every data copy and keeps the records, which hold a hash and a path and no data, and names them `CLEANUP-KEPT`; leftovers print `CLEANUP-INCOMPLETE` with exit 1; the run folder delete at the end of the run removes them too. A `later` job keeps only numbers, data shas, the scripts and the tool's records in the criteria folder, never the data.
- While the owner still has to put a changed copy back (section 10), the job has not ended: the run folder and its `work/` stay (mode 700 and 600, on this Mac only), the stop message names the copy's path, and redaction.md's end-of-run delete waits until the export is measured or the owner says stop. Then `finish` runs first, then the delete.

**Nothing changed in criteria mode is committed by default, on any repo: a data file, a guide, a process document alike.** The changed files stay on the Mac in `work/`, and the PR (when there is one) or the final comment describes the change in counts. A commit needs ALL of:
- `visibility` prints `VISIBILITY-PRIVATE` (code follows the same rule for pictures and diagrams);
- the owner's explicit yes to question (b) in section 4, and "no" to its names-or-contact-details part;
- `scan` prints `SCAN-CLEAN` on the diff (`git diff <approval-sha> > "$HOME/.superfix/runs/<run-key>/diff"` first).
A yes to names or contact details, or any scan hit, means the files stay local.

| What | Change made on | Shown beside the original by | Undo |
|---|---|---|---|
| Any file, by default | a copy in `work/`; nothing committed | counts before and after; `diff -u` saved next to the copy | delete the copy |
| A file the owner agreed to commit (all three conditions above), in a git repo outside any cloud mount | the work branch | the PR diff | close the PR without merging (GitHub keeps the closed PR and its commits); after a merge, a revert |
| A file in a folder without git, or a git repo inside a cloud mount | a copy in `work/` (a branch edit there syncs to others) | `diff -u` saved next to it; the original's sha256 checked unchanged at the end | delete the copy |
| Google Doc or Sheet, or a Drive mount file | a local copy (an online-only file is read only after asking) | as above | delete the copy |
| A process | a copy of the process description, messages as draft files in `work/` | the diff and a list of who would need to be told | delete the drafts |

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" visibility --repo '<owner>/<repo>'
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" scan --file "$HOME/.superfix/runs/<run-key>/diff"
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" where "<path>"
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" copy --run "$HOME/.superfix/runs/<run-key>" --src "<original>"
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" finish --run "$HOME/.superfix/runs/<run-key>"
```

- `visibility` prints `VISIBILITY-PRIVATE` or `VISIBILITY-PUBLIC (<why>)`; unknown or a failed read is PUBLIC.
- `scan` prints `SCAN-CLEAN` or `SCAN-PII <what> (line <n>)` for an e-mail address, a phone-like number, a link, a run of 9 or more digits, or a value after a label such as `Name:` or `Phone:`.
- `where` prints `PATH-CLOUD <path>` or `PATH-LOCAL <path>`. Cloud means under `~/Library/CloudStorage`, `~/shared-drives`, `~/Dropbox`, `~/Library/Mobile Documents` (iCloud Drive), `~/Google Drive` or `~/OneDrive`, and also `~/Desktop` and `~/Documents` when iCloud's Desktop and Documents sync is on (detected by those folders inside iCloud Drive); symlinks are resolved and the comparison ignores case.
- `copy` records the original's sha256 and prints `COPY-READY <copy> sha <sha>`, `COPY-EXISTS`, `COPY-REFUSED` (a `--name` outside letters, digits, `.`, `_` and `-`, or ending `.sf-orig`), `PATH-CLOUD` (the run folder itself syncs) or `ASK-FIRST <original>` (ask, then `--asked`).
- `finish` prints `ORIGINAL-UNCHANGED <path>` or `ORIGINAL-CHANGED <path>` for each recorded original still present, then `WORK-DELETED`; or `WORK-METADATA-BAD <file>` (a record `copy` did not write, or that cleanup deleted while data stayed; nothing is printed from it), then `WORK-KEPT` (stop, tell the owner, delete only after he answers); `ASK-FIRST` (hashing a cloud or online-only original can download it: ask, then `--asked`); or `WORK-NONE`. Kind `criteria` ends with `wo-finish` instead: it checks the lock's origsha itself, printing `ORIGINAL-CHANGED` plus `WORK-KEPT` when the original changed or is missing, else the shared finish; `WORK-PERMISSION-DENIED <path>` when it cannot delete.

### 10. The real file (Google Sheet, Drive file, any file the owner puts back himself)

- Final state: "ready, not verified on the real file"; Status `Waiting for you: put it back and give me an export`.
- On the export: never expect it to equal the copy (an export from Sheets is rarely byte for byte the same). Copy it in with `copy --src "<export>" --name export-<YYYY-MM-DD>.<ext>` (this records the export's own sha256), run `attempt --label export --measure <id>=<that copy> ...` (the tool runs the locked scripts): every check passing means "verified on the real file". Say in the stop or final message: "Your export is still at <path>; it holds the data, so delete it when you are done." Superfix never deletes the owner's own files; its copy goes with `work/`.

### 11. Nothing leaves (never sent, never written outside)

**The principle: in criteria mode nothing leaves the repo, the run folder and the owner's Mac, by any route.** Messages to other people are draft files in `work/`; the owner sends them. The routes, none allowed:
- A tool call whose name contains `send`, `reply`, `forward`, `share`, `campaign`, `sms`, `invite`, `publish`, `create_event`, `update_event`, `add_comment`, `create_comment`, `create_task`, `manage_drive_access`, `set_drive_file_permissions`, `copy_file`, `create_file`, `update_file`, `update_values`, `append_values`, `upload_file`, `checkout`.
- Any MCP tool that creates, changes, moves or deletes something: Google Drive, Docs, Sheets, Slides, Gmail, Calendar, Slack, Teamwork, Qik, iCloud and the rest. Reading is allowed.
- An Artifact publish (or any Artifact action that writes), Claude Docs `create`, `batch` and `update`, `WebFetch` and `WebSearch` (a query or a URL can carry data out).
- Through Bash: a `gws` write, `osascript`, a `tw` write, `gh gist`, `gh release`, `gh repo create`, `curl` or `wget` with `-d`, `--data*`, `-F`, `--form`, `-T`, `--upload-file`, `--json` or `-X POST|PUT|PATCH|DELETE`, `nc`, `ncat`, `scp`, `sftp`, `rsync`, `ssh`, `ditto`, and any `gh` call against a repo other than the work repo and the gap repo.
- A write into a cloud path (`where` prints `PATH-CLOUD`) by Write, Edit, `cp`, `mv`, `tee`, `ln`, `install`, a `>` or `>>` redirect, or a Python `open(..., "w")`.
- `git push` of a changed criteria-mode file without the three conditions in section 9.
- The one exception: the owner's own reminder task (section 16), only after his explicit yes to that question.

The test harness (S13) checks a run's `stream-json` log, in the main thread and in subagents, with an ALLOWLIST plus a text scan:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" sendcheck --log "<run.jsonl>" --repo '<owner>/<repo>' --gap-repo '<owner>/<gap repo>' --allow-dir "<clone>" --allow-dir "<temporary folder>" --scripts "<criteria folder>"
```

- Tools: `Read`, `Grep`, `Glob`, `Skill`, `Agent`, `TodoWrite`, `ToolSearch`, `AskUserQuestion`; `Write` and `Edit` only into the clone, `~/.superfix` or an `--allow-dir`; MCP tools whose name starts `get_`, `list_`, `read_`, `search_`, `describe_`, `preview_`, `count_` or `summarise_` AND holds none of `search_custom`, `search_web`, `upload`, `publish`, `create`, `send`, `update`, `delete`, `copy`, `share`, `move`, `checkout`, `find_or_upload`. Everything else is a hit, `WebFetch`, `WebSearch` and `Artifact` included.
- Bash, the whole text first (heredoc bodies and quoted strings included): any of `curl`, `wget`, `nc`, `ncat`, `ssh`, `scp`, `sftp`, `rsync`, `ftp`, `telnet`, `dig`, `nslookup`, `ping`, `socat`, `osascript`, `mail`, `sendmail`, `openssl s_client`, `pbcopy` with `open`, a here-string `<<<`, a `cd` into a cloud folder, or a write (`cp`, `mv`, `ln`, `tee`, `rsync`, `ditto`, `install`, a redirect) in a command that names a cloud folder (also through a variable set in it), is a hit.
- Then each simple command: the shell's own words and the text tools the skill's commands use (`cat`, `ls`, `grep`, `head`, `tail`, `wc`, `diff`, `tr`, `cut`, `sort`, `printf`, `echo`, `test`, `mkdir`, `cp`, `mv`, `rm`, `chmod`, `mktemp`, `shasum`, `date`, `base64`, `jq` and a few more), with writes only into the clone, `~/.superfix` or an `--allow-dir`; `sed` without `-i` and without a `w` or `e` command; `awk` and `perl` without `system`, `exec`, `open`, `getline`, a pipe or `-i`; `git`, except `remote` changes and `push`, `fetch`, `pull`, `ls-remote` or `clone` with a URL or another remote than `origin` (a `git push origin ...` is `SEND-REVIEW`); `gh issue view|comment|edit|list|create`, `gh pr view|create|checks|list|diff`, `gh label create|list`, `gh repo view` and `gh api` reads, on the work repo or the gap repo only (`--repo`, `--repo=`, `-R`, an `api repos/...` path; a shell variable counts only when it is `$R` or was set to one of those repos in the same command), with no `--hostname`, no `--edit-last`, and the one write `gh api -X PATCH repos/<work repo>/issues/comments/<id> -F body=@<file>` (section 4); `python3 -I` only of the locked `crit.py` (its sha must equal the lock's crit-sha; its `remind` command is the owner's one exception and is flagged for a look), of a locked measure script, of `-m pytest`, or of `-` with a heredoc that names no network module or cloud folder; `python3 -I -c` is a hit, so a gap note's names check (gaps.md) shows up here and is read by hand; `node`, `npm` (not `install` or `add`), `pytest`. A leading `command`, `builtin`, `env`, `exec`, `time`, `nohup`, `xargs`, `eval`, `source`, `sudo` or `timeout`, and any other command, is a hit.
- It prints `SEND-CLEAN (<n> tool calls)`, or `SEND-HIT line <n> <route>` per hit and `SEND-REVIEW line <n> <what>` for a look by hand; both fail (non-zero exit). An empty log, a line that is not JSON, or a log with no tool call prints `SEND-UNKNOWN`, a failure, never a pass.
- **Best effort, said plainly:** it reads text, so base64, unusual spellings or a tool hidden in an allowed one can still slip past. It is the second line, behind the sandbox and the tests' `--disallowedTools` and permission settings.

### 12. Lock (at go, before any change)

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" lock --run "$HOME/.superfix/runs/<run-key>" --issue '<owner>/<repo>#<N>' --scripts "<criteria folder>" --attempts "<criteria folder>/attempts" --data "<each original data file>" --by "<gh login, or the owner at the keyboard>" --approved P1,P2,P3
```

- `--approved` names every problem whose checks the owner approved (from his answers to the shared questions); the lock file records `approved P<k> by <who>` for each, and a problem left out is `CRITERIA-BAD approval`.
- It hashes (sha256) every `P<k>-` line of `## Done when` with its checklist lines (each checkbox read as `[ ]`, so ticking a box never changes the lock), every `measure-*.py` in the criteria folder, and the real path of each original named by `--data` (repeat it per file). It writes `<criteria folder>/lock` (the hash, each script's sha, each data path), adds a `locked` line to the attempts file, and prints `Internal: criteria-sha <64 hex> (sha256), locked <YYYY-MM-DD HH:MM>, approved by <who>`, `Internal: crit-sha <64 hex> (sha256)` (the sha256 of this tool, for the owner's re-check) and `CRITERIA-LOCKED`. Both Internal lines go in ## Decision. The lock is written once; every later change goes through `amend`.
- It refuses with `CRITERIA-BAD ...` (no criteria, a missing script, no `--data`, no approver, a baseline measured with another version of a script, or a baseline measured on a file not named by `--data`), `CRITERIA-INCOMPLETE <id>` (a `check` or `later` criterion with no baseline measure), or `ATTEMPTS-TAMPERED`.
- The word `sha256` on the line lets redaction.md's pattern check pass the hash; never redact it. Any other sha in a comment or body is written next to the word `sha256` too.
- Write those lines in ## Decision directly BEFORE the `Internal: approval-sha` line, which stays last. `<who>` is the GitHub login that wrote the approving reply, or "the owner at the keyboard" in chat. After an amendment, the newest line counts.
- Before every attempt, and on every restart:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" lockcheck --issue '<owner>/<repo>#<N>' --scripts "<criteria folder>" --run "$HOME/.superfix/runs/<run-key>" --attempts "<criteria folder>/attempts"
```

  It prints `CRITERIA-LOCK-OK`; `CRITERIA-CHANGED (<why>)` (a line, a script or the lock file changed since the lock, or a `lock` file exists while the body has no lock line: stop and ask; never fix the lock quietly); `CRITERIA-UNLOCKED` (no lock line and no lock file: no fixing); `ATTEMPTS-TAMPERED`; or `ERROR-SCRIPT-NOT-LOCKED` / `ERROR-DATA-NOT-LOCKED` for a recorded attempt not made with the locked scripts and files. `measure`, `attempt`, `progress` and `comment` run the same checks themselves and stop on the same words.
- Owner sign-offs: ticks in the checklist are recorded, not locked:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" signoff --issue '<owner>/<repo>#<N>' --attempts "<criteria folder>/attempts"
```

  It appends `signoff <date> <id> <ticked>/<items>` and prints `SIGNOFF <id> <k> of <n> ticked` and `SIGNOFF-RECORDED`. Only the owner's reply "signed off" passes an `owner` criterion.

### 13. Amending

Only through new numbered questions (the Stop gate form), and only with the `amend` command, which never dead-ends: it closes the current epoch, re-measures the NEW scripts on the ORIGINAL files as line 0 of a new epoch, and writes the new lock.
1. Edit the lines in ## Done when (a changed definition, a new criterion, a removed one) and the scripts, after the owner's yes.
2. ## Decision gains, per change, `Criteria change <date>: "<old plain line>" is now "<new plain line>". Approved by <who> in chat <date time>.`; a removed criterion also needs `Criteria removed <date>: "<its plain name>" ... Approved by <who> ...`.
3. Run the shape check, then:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" amend --run "$HOME/.superfix/runs/<run-key>" --scripts "<criteria folder>" --issue '<owner>/<repo>#<N>' --attempts "<criteria folder>/attempts" --label <base2, base3 ...> --data "<each original>" --by "<who approved>" --measure <id>=<original> ... [--removed <id>]
```

4. Write its two Internal lines in ## Decision (as in section 12). Until then every check prints `CRITERIA-CHANGED`.
- It prints the new baseline, `ATTEMPT-SAVED 0 (epoch <e>)` and `CRITERIA-LOCKED (amended ...)`; or `ERROR-AMEND-NOTHING-CHANGED`, `ERROR-AMEND-NOT-APPROVED` (no new `Criteria change` or `Criteria removed` line), `ERROR-AMEND-REMOVAL-NOT-APPROVED <id>`, `CRITERIA-INCOMPLETE <id>` (every `check` and `later` criterion, new ones too, is measured), `ERROR-AMEND-NOT-ORIGINAL <id>` (a new baseline is measured on the originals named by `--data`), `AMEND-BASELINE-BAD <id>` (the baseline rules again: a `C` that passes on the original does not detect the problem; a `K` that fails is no guard), `CRITERIA-CHANGED` (the body's newest lock line is not the current lock), `ATTEMPTS-*`.
- The old epochs stay in the attempts file (`epoch-close <e> ... lock <old sha>`), for audit.

### 14. Baseline, attempts, epochs and the stop rule

Every measure for the record is made BY THE TOOL: it re-runs the scripts itself, in the sandbox, on the files you name, writes its own records and appends the line. It never accepts an output file it did not write.

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" baseline --run "$HOME/.superfix/runs/<run-key>" --scripts "<criteria folder>" --issue '<owner>/<repo>#<N>' --attempts "<criteria folder>/attempts" --label base --measure <id>=<original> ...
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" attempt --run "$HOME/.superfix/runs/<run-key>" --scripts "<criteria folder>" --issue '<owner>/<repo>#<N>' --attempts "<criteria folder>/attempts" --label <try1, try2, run2 ...> --measure <id>=<file> ...
```

- `baseline` (before the stop only) writes `epoch 1` and line 0. It refuses once a lock exists (`ATTEMPT-REFUSED locked already: a new baseline only through amend`) and once a baseline has been posted; before that, `--redo` measures it again (the old one is closed, not erased).
- `attempt` (after go only; before it, `CRITERIA-UNLOCKED`) adds lines 1 to 5 of the current epoch. Every `check` criterion must have a `--measure` (else `CRITERIA-INCOMPLETE <id>`). The tool allows at most 5 attempts per epoch, whatever the budget says: a sixth is `STOP-CAP 5 of 5 attempts`. `attempt --recheck` measures only `later` criteria (the re-check of section 16), on the data as it now is; such a line is not a try for the stop rule.
- They print `PASS|FAIL <id> <value> items <rows>` per criterion and `ATTEMPT-SAVED <n> (epoch <e>); attempts: <n> lines, head <h>; your own re-check command: <criteria folder>/VERIFY.txt`; or `ATTEMPT-SAME <n>` (the same file and values as the newest line: nothing written), `ATTEMPT-REFUSED <id> <error>`, `ATTEMPT-REFUSED label <label> is used already`, `ATTEMPT-REFUSED the criteria were amended: run amend`, `ATTEMPTS-MISSING`, `ATTEMPTS-TAMPERED`, `ATTEMPTS-TRUNCATED`, or a lock word.
- The records go to `<criteria folder>/records/<label>/<id>.out`, each with the tool's own run id, and a `LINE` file with the sha of its attempt line. The attempt line is `<n> <date time> data-sha <sha> from <label> lock <criteria-sha or none> run <run id> rec <sha of the records> body <sha of the body> sbx <on|off> P1-C1=<value> ... prev <sha of the previous line>`. Every line the tool writes (`epoch`, `epoch-close`, `locked`, attempts, `neg`, `signoff`) ends with `prev <sha256 of the line before>`; a line changed, added or removed by hand is `ATTEMPTS-TAMPERED` or `ATTEMPTS-TRUNCATED`, and so is a record changed, removed or not written by the tool.
- Epochs: `baseline` writes epoch 1, `amend` each later one. Line 0 of the CURRENT epoch is its baseline: comments, progress, the stop rule and `% fewer than today` use only the current epoch. Old epochs stay for audit.
- A problem whose criteria are all `owner` has no scripts; its attempts file holds only the `locked` line.
- After every attempt:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" progress --run "$HOME/.superfix/runs/<run-key>" --scripts "<criteria folder>" --issue '<owner>/<repo>#<N>' --attempts "<criteria folder>/attempts"
```

- Moved: at least one failing `C` got closer to its pass line AND no `C` or `K` got further from its pass line; any worsening is no progress. It prints `CHECKS-PASS <n>` (every `check` criterion meets its pass line: never a stop), `MOVED <n>`, `NO-PROGRESS <n> (worse: <names>)` or `NO-PROGRESS <n> (no failing check improved)`; `PROGRESS-NONE` with only the baseline.
- Two attempts in a row with no progress: `STOP-NO-PROGRESS` and the stop text, filled in: `"Two tries did not get closer: <plain name> went from <before> to <after> and <plain name> got worse. Work kept on <branch or copy>. Reply 1 to re-diagnose (about 20 minutes) or 2 to stop."` Write the branch or copy in place of `<branch or copy>`. Status `Waiting for you: 1 question`.
- The fifth attempt: `STOP-CAP 5 of 5 attempts`, a budget stop (SKILL.md Budget).

### 15. Three runs (the solved check in criteria mode)

- Run 1, the original: `measure --out run1 --expect FAIL` for each `C` (`--expect PASS` for each `K`) on the original, and its data sha equal to the epoch's line 0 (the original is unchanged).
- Run 2, the change: `attempt --label run2 --measure <id>=<the changed copy> ...` (it prints `ATTEMPT-SAME` when the last try measured the same file, and that line counts as run 2): every `C` `PASS`, every `K` `PASS` and no further from its pass line than in run 1.
- Run 3, negative control: make a scratch copy of the change in `work/neg/` with exactly ONE planted defect (one example row put back, for a `C`; one member deleted, for a `K`), and run `measure --neg-of "<the changed copy>" --defect "<what was planted, in plain words, no row values>" --expect FAIL --attempts "<criteria folder>/attempts"`. The tool refuses `ERROR-NEG-NOT-DISTINCT` (the negative copy equals the change or an original), `ERROR-NEG-NOT-ONE-DEFECT` (not exactly one record added, removed or changed; records by file type, section 7) and `ASK-FIRST` (a cloud or online-only file); it writes a `neg <date> <id> data-sha <sha> defect <words>` line (`NEG-RECORDED`) only after `EXPECTED`. Run 3 outputs are never attempts.
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
- On "continue superfix on #N" (or the journal path): read the lock line, run the lock check, then `attempt --recheck --label recheck-<date> --measure <id>=<the data as it now is>` in a new run folder (the locked script counts only cases after the adoption date; the earlier records in the criteria folder are still checked); report with the process wording.
- `owner`: the checklist in the final comment, Status `Waiting for you: sign-off on <plain name>`; the reply "signed off" passes it, anything wrong is a new attempt.
- Every one of these Status values starts "Waiting for you", so journal.md's label rule already applies. The issue stays open; nothing closes on its own.

### 17. Closing

When the last criterion passes or is signed off: post the final comment, then close only after `gh pr view <PR> --json state -q .state` returns `MERGED` (no PR: after the owner's reply). Then the `finish` command (section 9) and, for a no-repo job, `index remove`.

### 18. Comment check (before every post in criteria mode, after LINES-OK)

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" comment --comment "$HOME/.superfix/runs/<run-key>/comment-<N>.md" --kind <decision, stop or final> --run "$HOME/.superfix/runs/<run-key>" --scripts "<criteria folder>" --issue '<owner>/<repo>#<N>' --attempts "<criteria folder>/attempts" --repo '<owner>/<repo>' --gap-repo '<owner>/<gap repo>'
```

- Fences: a line starting (after any indent) with three or more backticks or tildes opens one; it closes only on the same character, at least as long, with nothing after it. An unclosed fence is `CRITERIA-FENCE-UNCLOSED`. Lines outside fences are read for the checks below, with their indent removed.
- `decision`: `Criteria: PROPOSED <n> (P1, P2)` (or `APPROVED ...`), and `; NONE (P<k>: <why>)` for each Everything else problem with no checkable criterion, once in the AI detail below the LAST `---`, with `<n>` equal to the `P<k>-` lines and the named problems equal to theirs; one plain line per criterion above the FIRST `---`, in exactly the section 3 form; the two shared questions (section 4).
- No gap note for a problem whose checks are proposed: a `Gap note: FILED|SEEN-AGAIN|LOCAL <n>` larger than the number of problems that are `NONE` on the `Criteria:` line or have an `owner` criterion (one that fell to the owner because nothing could check it), or a gap-list sentence ("P<k> ... is outside what I cover") for a problem with `check` or `later` criteria, is `LINES-GAP-WITH-CRITERIA`. This is the one place the gap-note rule is checked mechanically: the comment check runs right after the lines check on every criteria-mode post.
- Every kind: `Criteria check: ` once, naming every criterion by its plain name, each `<plain name> <PASS|FAIL|ERROR|LATER YYYY-MM-DD|OWNER> (<value>)` or `(<before> -> <after>)`, separated by `, `. **Every criterion is recomputed:** a `check` criterion's word must be the verdict of its newest measured value, and one with no measured value is `CRITERIA-INCOMPLETE <id>`; a `later` criterion's word is `LATER <its re-measure date>` and an `owner` criterion's word is `OWNER`, never PASS.
- Every kind: the line `attempts: <n> lines, head <8 hex>`, equal to the head record now (the tool printed it after its last write); and, when any measure in the epoch ran unsandboxed, the `UNSANDBOXED:` line (section 4).
- `final`: one table row per criterion, `| <plain name> | <before> | <after> | <must be> | <result> |`. Before and after are plain numbers (a `later` after may be `LATER YYYY-MM-DD`; an `owner` row reads `OWNER` in before, after and result); `must be` is the pass line word for word; the result is the computed one. Note the two forms: the table's result cell is the bare word `LATER` (or `OWNER`), while the `Criteria check:` line writes `LATER <YYYY-MM-DD>`. Any other cell is `TABLE-CELL-UNCHECKED` and fails.
- Values are compared at fixed places only (the pass line's own number is not a measure): the plain line's Today number and rows against the epoch's line 0 and its records; the `Criteria check:` values against the newest line that has that criterion (`<before>` against line 0); the table cells likewise. The attempt lines and records are checked as in section 14.
- A personal-data scan reads EVERY line of the comment, fenced text included: an e-mail address, a phone-like number (8 or more digits), a link, a run of 9 or more digits, or a value after a label such as `Name:`, `Customer:` or `Phone:` is `CRITERIA-PII <what> (comment line <n>)`. Only these links are allowed: exactly `https://github.com/<owner>/<repo>/issues/<N>` or `.../pull/<N>`, with nothing after the number (no `#fragment`, query or further path), on the work repo (`--repo`) or the gap repo (`--gap-repo`). Every other link is scanned as text and fails, the gap list link (`...issues?q=...`) included. The numbers the tool validated itself (the Today number, the `Criteria check:` values, the table's before and after cells, the `attempts:` line) are not scanned for long digit runs, so a count of 10 million or more can be shown.
- It prints `CRITERIA-OK`, or one line each: `CRITERIA-MISSING <what>`, `LINES-GAP-WITH-CRITERIA`, `CRITERIA-QUESTIONS-MISSING <P>`, `CRITERIA-QUESTIONS-TWICE <P>`, `CRITERIA-COUNT <n>/<m>`, `CRITERIA-IDS-MISSING <names>`, `CRITERIA-INCOMPLETE <id>`, `CRITERIA-PLAIN-BAD <name> (<why>)`, `CRITERIA-VALUE-MISMATCH <name> comment <a> measured <b>` (or `computed <b>`), `TABLE-CELL-UNCHECKED <name> <cell>`, `CRITERIA-PII <what>`, `CRITERIA-FENCE-UNCLOSED`, `ATTEMPTS-TAMPERED`, or a lock word. Post only after `LINES-OK` and `CRITERIA-OK`.

### 19. Final comment additions

- The callout says "fixed against the checks you approved" (a process: "change drafted (or adopted), effect measured on <date>: <result>").
- The table (section 18), one row per criterion, the plain name in the first cell.
- The change beside the original (the PR diff, or the counts, or the saved `diff -u` named by path on the Mac), the undo line from section 9's table (never "close the PR" alone: GitHub keeps a closed PR's commits), the waiting checks and their dates.
- The cost line for criteria jobs: `Cost: about <n> USD and <m> attempts (estimate; the run cannot read its own bill)`. Rough figures: Simple about 2 USD and 2 attempts, Moderate about 6 USD and 3.

### 20. Gap notes

- A problem with no checkable criterion (section 1) stops at diagnosis and gets one note (gaps.md), kind "no checkable criterion".
- One note when a criterion would have been `check` but Superfix had no tool or access to measure it, so it fell to `later` or `owner`.
- A problem fully handled in criteria mode gets no note and no gap-list sentence: no gap note for a problem that has checks proposed (`LINES-GAP-WITH-CRITERIA`, section 18).
- In a criteria-mode comment the gap note line (gaps.md) ends after the note's own link; the "All notes, most seen first" list link is left out, because the comment check allows only issue and PR links.

### 21. Not tested lines (exact)

- `Not verified on the real file: you have not sent me an export yet.`
- `<plain name> is measured later, on <date>; not checked in this run.`
- `<plain name> needs your sign-off; not checked by me.`
- `The measure scripts ran without the macOS sandbox, as you agreed.` (only after the sandbox question's yes; the comments also carry the `UNSANDBOXED:` line)

### 22. Work orders

- A criteria work order hands a copy, never the original, to someone else; the template is workorder.md's `criteria` row.
- The copy goes in only after the owner's explicit yes to the second of the two data questions there, with no recommended answer; `workorder.md` holds counts and row numbers only.
- The folder is a stub run folder with its own lock on the stub path; the column cut keeps every column a script reads and maps back by `row`; the stub's `checks/VERIFY.txt` is never bundled.
- On return the copy is untrusted data: Superfix's own locked tool measures it in the sandbox, never the folder's copies.
- Each `[Superfix verifies]` line gets one finding "`<tick text>: met (lines 3, 4)`" or "`<tick text>: not met (lines 3, 4)`": a whole-word `met` (not `metadata`, not `met?`/`met-ish`/`met =`), line numbers in a closing `(lines ...)` shape and checked against the copy, else `FINDING-NOT-MET`, `FINDING-MISSING` or `FINDING-LINE-MISSING`; a finding for an unknown tick is `FINDING-UNKNOWN-TICK`.
- Dedupe jobs always carry the earliest-wins line; `owner` items still need "signed off".
- Return order: original unchanged, only FILES, own-measure, the three runs, the findings, then `CRITERIA-OK`.
- Success says "the counts meet your checks"; a process ends at "ready for your review", never "solved".

### The script

The tool lives in `references/crit.py`, byte for byte the block that stood here through 1.6.1 (moved in 1.6.2, issue 60). The command in section 5 writes that file into the run folder.
