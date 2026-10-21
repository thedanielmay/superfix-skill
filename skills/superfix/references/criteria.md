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

`crit.py` is written into the run folder from this file, by a command, never typed out by hand, like `shot.py` in evidence.md. `<skill dir>` is this skill's base directory, written out in full:

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; S="<criteria folder>"; if [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; elif [ -f "$S/lock" ]; then C="$S/crit.py"; L="$(sed -n 's/^crit //p' "$S/lock")"; if [ -f "$C" ] && [ "$(shasum -a 256 "$C" | cut -d' ' -f1)" = "$L" ]; then cp "$C" "$D/crit.py" && echo "CRIT-READY $D/crit.py (the locked tool)"; else echo "CRIT-SHA-MISMATCH (the criteria folder's crit.py is not the lock's crit line: stop)"; fi; else awk '/^# --- crit.py start ---$/{f=1} f{print} /^# --- crit.py end ---$/{f=0}' '<skill dir>/references/criteria.md' > "$D/crit.py" && grep -q '^# --- crit.py end ---$' "$D/crit.py" && echo "CRIT-READY $D/crit.py"; fi
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

Work copies live in `$HOME/.superfix/runs/<run-key>/work/` and are DELETED when the job ends (solved, abandoned or stopped for good), except the verified copies, which stay until taken or stop; a stop deletes everything; leftovers print `CLEANUP-INCOMPLETE` with exit 1; the run folder delete at the end of the run removes them too. A `later` job keeps only numbers, data shas, the scripts and the tool's records in the criteria folder, never the data.
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
- `finish` prints `ORIGINAL-UNCHANGED <path>` for each original, then `WORK-DELETED`; or `ORIGINAL-CHANGED <path>` or `WORK-METADATA-BAD <file>` (a record `copy` did not write; nothing is printed from it), then `WORK-KEPT` (stop, tell the owner, delete only after he answers); `ASK-FIRST` (hashing a cloud or online-only original can download it: ask, then `--asked`); or `WORK-NONE`.

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

The tool, exactly as the command in section 5 writes it:

```python
# --- crit.py start ---
# superfix 1.5.0 criteria mode. Written into the run folder from
# references/criteria.md. Standard library only; run it with python3 -I.
# Every command prints word lines; silence is never a pass. It never prints
# a data value, a measure script's own output or a line of the measured file.
# It is DETECTIVE, not preventive: it finds changed, missing or hand-made
# records, but a determined writer with file access can still forge them.
import argparse, collections, contextlib, csv, datetime, fractions, hashlib, io, json, os, pathlib, re, resource, secrets, shlex, shutil, signal, stat, subprocess, sys, tempfile, threading, time

LINE = re.compile(r"^- (P(\d+)-([CK])(\d+)) \[([a-z]+)\] (.*)$")
FIELDS = re.compile(r"^(?P<name>[^:]*): (?P<defn>.*); pass: (?P<pass>.*?); how: (?P<how>.*?); who: (?P<who>.*)$")
NAME = re.compile(r"^[A-Za-z][A-Za-z0-9 -]*[A-Za-z0-9]$")
LOCK = re.compile(r"^Internal: criteria-sha ([0-9a-f]{64}) \(sha256\), locked (\d{4}-\d{2}-\d{2} \d{2}:\d{2}), approved by (.+)$")
BOX = re.compile(r"^(\s+- )\[[ xX]\]( .*)$")
CLOUD = ["Library/CloudStorage", "shared-drives", "Dropbox", "Library/Mobile Documents", "Google Drive", "OneDrive"]
NUM = r"-?\d+(?:\.\d+)?"
MEASURE_NUM = r"-?(?:\d{1,9}|\d{1,8}\.\d|\d{1,7}\.\d\d)"   # posted, so it must stay a plain small number
SF_DATALESS = 0x40000000
SAFE_TEXT = re.compile(r"^[^|\x00-\x1f\x7f'\"`$\\]+$")
COPY_NAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$")
SBX = "/usr/bin/sandbox-exec"                                  # absolute, never looked up on PATH
COMPARATORS = {"more", "fewer", "less", "than", "least", "most", "over", "under", "below", "above", "between", "exactly", "and", "or", "at"}


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


def sha_text(s):
    return hashlib.sha256(s.encode()).hexdigest()


def inside(p, folder):
    return (str(real(p)).lower() + "/").startswith(str(real(folder)).lower().rstrip("/") + "/")


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


class Stop(Exception):
    pass


def body_text(a):
    """The issue body fetched by the tool itself (--issue), or the journal file (--body)."""
    if getattr(a, "issue", None):
        m = re.fullmatch(r"([A-Za-z0-9-]+/[A-Za-z0-9._-]+)#(\d+)", a.issue)
        if not m:
            raise Stop("BODY-UNREADABLE (want --issue <owner>/<repo>#<N>)")
        try:
            r = subprocess.run(["gh", "issue", "view", m.group(2), "--repo", m.group(1), "--json", "body", "-q", ".body"],
                               capture_output=True, text=True, timeout=60)
        except (OSError, subprocess.TimeoutExpired):
            raise Stop("BODY-UNREADABLE (gh did not run)")
        if r.returncode:
            raise Stop("BODY-UNREADABLE (gh issue view failed)")
        return r.stdout
    if not getattr(a, "body", None):
        raise Stop("BODY-UNREADABLE (give --issue <owner>/<repo>#<N>, or --body <journal file> in file mode)")
    return pathlib.Path(a.body).read_text()


# ---------- pass-line grammar ----------

def target(p, baseline=None, ck="C"):
    """(op, a, b) or None (VAGUE). baseline is the epoch's first value, as a string."""
    s = re.sub(r"\s*\([^)0-9]*\)\s*$", "", p.strip().lower())
    n = NUM
    m = re.fullmatch(r"no ([a-z][a-z -]*) left", s)
    if m:
        return ("eq", 0.0, None) if not COMPARATORS & set(m.group(1).split()) else None
    rules = [
        (r"0|none|zero|no", lambda m: ("eq", 0.0, None)),
        (r"yes", lambda m: ("eq", 1.0, None)),
        (rf"({n}) or fewer|at most ({n})|no more than ({n})", lambda m: ("le", float(next(g for g in m.groups() if g)), None)),
        (rf"(?:fewer|less) than ({n})", lambda m: ("lt", float(m.group(1)), None)),
        (rf"at least ({n})|({n}) or more|no fewer than ({n})", lambda m: ("ge", float(next(g for g in m.groups() if g)), None)),
        (r"(\d{1,2})% fewer than today", lambda m: ("pct", int(m.group(1)), None)),
        (rf"between ({n}) and ({n})", lambda m: ("range", float(m.group(1)), float(m.group(2)))),
        (rf"(?:exactly )?({n})", lambda m: ("eq", float(m.group(1)), None)),
    ]
    for rx, f in rules:
        m = re.fullmatch(rx, s)
        if not m:
            continue
        t = f(m)
        if t[0] == "range" and t[1] > t[2]:
            return None
        if t[0] == "pct":
            if ck != "C" or not 1 <= t[1] <= 99:
                return None          # a K line guards today's value; "% fewer" makes no sense there
            if baseline is None:
                return t
            # integer arithmetic: floor(b * (100 - n) / 100), never easier than the words
            return ("le", float(fractions.Fraction(str(baseline)) * (100 - t[1]) // 100), None)
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
    t = target(c["pass"], baseline, c["ck"])
    if t is None or t[0] == "pct":
        return None
    return "PASS" if distance(t, v) == 0 else "FAIL"


def num(s):
    return float(s) if re.fullmatch(NUM, s or "") and len(s) < 30 else None


def fmt(v):
    return str(int(v)) if v == int(v) else str(v)


def read_out(p):
    d = {}
    for l in pathlib.Path(p).read_text().splitlines():
        k, _, v = l.partition(" ")
        d[k] = v
    return d


# ---------- cloud ----------

def icloud_desktop():
    base = pathlib.Path.home() / "Library/Mobile Documents/com~apple~CloudDocs"
    return [n for n in ("Desktop", "Documents") if (base / n).is_dir()]


def in_cloud(p):
    home = pathlib.Path.home()
    cands = {os.path.abspath(os.path.expanduser(str(p))), str(real(p))}
    for q in cands:
        for c in CLOUD + icloud_desktop():
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


# ---------- records by file type ----------

def records(path):
    """.csv and .tsv are read as records; any other file as lines."""
    suf = pathlib.Path(path).suffix.lower()
    if suf in (".csv", ".tsv"):
        try:
            with open(path, newline="", encoding="utf-8", errors="replace") as f:
                return [tuple(r) for r in csv.reader(f, delimiter="\t" if suf == ".tsv" else ",")]
        except csv.Error:
            pass
    return [(l,) for l in pathlib.Path(path).read_text(encoding="utf-8", errors="replace").splitlines()]


# ---------- shape ----------

def cmd_shape(a):
    text = body_text(a)
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
            if target(c["pass"], None, c["ck"]) is None:
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


# ---------- attempts file: a hash chain, a head record, the posted head ----------

MAX_ATTEMPTS = 5                    # per epoch, after the baseline; fixed in the tool, not by the caller
HEAD_RX = re.compile(r"^attempts: (\d+) lines, head ([0-9a-f]{8}|none)$")
UNSBX_RX = re.compile(r"^Internal: unsandboxed approved by (.+), (\d{4}-\d{2}-\d{2} \d{2}:\d{2})$")
CRIT_RX = re.compile(r"^Internal: crit-sha ([0-9a-f]{64}) \(sha256\)$")


def all_lines(p):
    return pathlib.Path(p).read_text().splitlines() if p and pathlib.Path(p).exists() else []


def head_of(lines):
    return (len(lines), sha_text(lines[-1])[:8] if lines else "none")


def head_file(p):
    return pathlib.Path(p).parent / "head"


def append_line(p, text):
    lines = all_lines(p)
    prev = sha_text(lines[-1]) if lines else "none"
    pathlib.Path(p).parent.mkdir(parents=True, exist_ok=True)
    with open(p, "a") as f:
        f.write(f"{text} prev {prev}\n")
    n, h = head_of(all_lines(p))
    head_file(p).write_text(f"lines {n} head {h}\n")           # every tool write refreshes the head record


def posted_head(a):
    """The newest `attempts: <n> lines, head <h>` line already posted: --prev-comment, the issue's comments, or the journal file."""
    texts = []
    if getattr(a, "prev_comment", None):
        texts.append(pathlib.Path(a.prev_comment).read_text())
    elif getattr(a, "issue", None):
        m = re.fullmatch(r"([A-Za-z0-9-]+/[A-Za-z0-9._-]+)#(\d+)", a.issue)
        try:
            r = subprocess.run(["gh", "api", f"repos/{m.group(1)}/issues/{m.group(2)}/comments", "--paginate", "-q", ".[].body"],
                               capture_output=True, text=True, timeout=60)
        except (OSError, subprocess.TimeoutExpired):
            raise Stop("BODY-UNREADABLE (the posted comments could not be read)")
        if r.returncode:
            raise Stop("BODY-UNREADABLE (the posted comments could not be read)")
        texts.append(r.stdout)
    elif getattr(a, "body", None) and pathlib.Path(a.body).exists():
        texts.append(pathlib.Path(a.body).read_text())
    found = None
    for t in texts:
        for l in t.splitlines():
            m = HEAD_RX.match(l.strip())
            if m:
                found = (int(m.group(1)), m.group(2))
    return found


def check_file(a, need=True):
    """Missing, truncated or hand-edited attempts file: raises Stop with the word."""
    p, lf = a.attempts, pathlib.Path(a.scripts) / "lock"
    lines = all_lines(p)
    if lf.exists():
        sha = next((l[4:] for l in lf.read_text().splitlines() if l.startswith("sha ")), None)
        if not lines or not any(l.startswith("locked ") and l.split()[3] == sha for l in lines if len(l.split()) > 3) \
                and not any(l.startswith("epoch ") and len(l.split()) > 5 and l.split()[5] == sha for l in lines):
            raise Stop("ATTEMPTS-MISSING (a lock exists but the attempts file, or its line for that lock, is gone: stop)")
    for n, l in enumerate(lines):
        want = sha_text(lines[n - 1]) if n else "none"
        if not l.endswith(f" prev {want}"):
            raise Stop(f"ATTEMPTS-TAMPERED line {n + 1} (the chain is broken: a line was changed, added or removed by hand)")
    hf = head_file(p)
    if lines or hf.exists():
        m = re.fullmatch(r"lines (\d+) head ([0-9a-f]{8}|none)\n?", hf.read_text() if hf.exists() else "")
        if not m or (int(m.group(1)), m.group(2)) != head_of(lines):
            raise Stop("ATTEMPTS-TRUNCATED (the attempts file does not match its head record: lines were removed or added by hand)")
    ph = posted_head(a) if need else None
    if ph and ph[0]:
        if len(lines) < ph[0] or sha_text(lines[ph[0] - 1])[:8] != ph[1]:
            raise Stop(f"ATTEMPTS-TRUNCATED (the posted record says {ph[0]} lines, head {ph[1]}; the file does not hold that line)")


def parse_row(l):
    f = l.split()
    if len(f) >= 19 and f[0].isdigit() and f[3] == "data-sha" and f[5] == "from" and f[7] == "lock" and f[9] == "run" \
            and f[11] == "rec" and f[13] == "body" and f[15] == "sbx" and f[-2] == "prev":
        raw = dict(x.split("=", 1) for x in f[17:-2])
        return {"n": int(f[0]), "sha": f[4], "from": f[6], "lock": f[8], "run": f[10], "rec": f[12], "sbx": f[16], "line": l,
                "raw": raw, "v": {k: float(v) for k, v in raw.items()}}
    return None


def epoch_lines(p):
    out = []
    for l in all_lines(p):
        if l.startswith("epoch "):
            out = []
        out.append(l)
    return out


def epoch_rows(p):
    """Attempt lines of the CURRENT epoch only (old epochs stay in the file for audit)."""
    return [r for l in epoch_lines(p) if (r := parse_row(l))]


def epoch_locks(p):
    s = set()
    for l in epoch_lines(p):
        f = l.split()
        if f and f[0] == "epoch" and len(f) > 5 and f[5] != "none":
            s.add(f[5])
        elif f and f[0] == "locked" and len(f) > 3:
            s.add(f[3])
        elif (r := parse_row(l)) and r["lock"] != "none":
            s.add(r["lock"])
    return s


def epochs(p):
    return sum(1 for l in all_lines(p) if l.startswith("epoch "))


def combined(shas):
    u = sorted(set(shas))
    return u[0] if len(u) == 1 else sha_text("\n".join(u))


def rec_dir(scripts, label):
    """The tool's own records: in the criteria folder (no data values), so a later re-check still finds them."""
    return pathlib.Path(scripts) / "records" / label


def rec_hash(folder):
    return sha_text("".join(p.name + "\n" + p.read_text() for p in sorted(pathlib.Path(folder).glob("*.out"))))


def check_rows(scripts, rows, lk=None):
    """Every attempt line's records exist, are the tool's own (run id, hash, line sha) and match the line."""
    bad = []
    for r in rows:
        d = rec_dir(scripts, r["from"])
        outs = {p.stem: read_out(p) for p in d.glob("*.out")}
        if not d.is_dir() or rec_hash(d) != r["rec"] or set(outs) != set(r["v"]) \
                or not (d / "LINE").is_file() or (d / "LINE").read_text().strip() != sha_text(r["line"]) \
                or any(o.get("RUN") != r["run"] or o.get("MEASURE") != r["raw"].get(i) for i, o in outs.items()) \
                or combined(o.get("DATA-SHA", "") for o in outs.values()) != r["sha"]:
            bad.append(f"ATTEMPTS-TAMPERED attempt {r['n']} (its records are missing, changed or not written by the tool)")
            continue
        if lk and r["lock"] == lk["sha"]:
            for i, o in outs.items():
                if o.get("SCRIPT-SHA") != lk["scripts"].get(i):
                    bad.append(f"ERROR-SCRIPT-NOT-LOCKED {i} (attempt {r['n']})")
                if not data_allowed(o.get("DATA", ""), None, lk):
                    bad.append(f"ERROR-DATA-NOT-LOCKED {i} (attempt {r['n']})")
    return bad


# ---------- lock ----------

def norm_lines(text):
    out = []
    for c in criteria(text):
        out += [BOX.sub(r"\1[ ]\2", l) for l in c["raw"]]
    return out


def lock_sha(text, scripts, data):
    h = hashlib.sha256()
    for l in norm_lines(text):
        h.update((l + "\n").encode())
    for p in sorted(pathlib.Path(scripts).glob("measure-*.py")):
        h.update(f"script {p.name}\0{sha_file(p)}\n".encode())
    for d in sorted(data):
        h.update(f"data {d}\n".encode())
    return h.hexdigest()


def read_lock(scripts):
    rec = {"sha": None, "scripts": {}, "data": [], "crit": None, "names": {}, "changes": 0}
    for l in (pathlib.Path(scripts) / "lock").read_text().splitlines():
        k, _, v = l.partition(" ")
        if k == "sha":
            rec["sha"] = v
        elif k == "script":
            i, _, s = v.partition(" ")
            rec["scripts"][i] = s
        elif k == "data":
            rec["data"].append(v)
        elif k == "crit":
            rec["crit"] = v
        elif k == "criterion":
            i, _, n = v.partition(" ")
            rec["names"][i] = n
        elif k == "changes":
            rec["changes"] = int(v)
    return rec


def lock_state(text, scripts):
    """('unlocked', None) | ('ok', rec); raises Stop on a changed lock."""
    locks = [(m.group(2), n, m.group(1)) for n, l in enumerate(text.splitlines()) if (m := LOCK.match(l.strip()))]
    lf = pathlib.Path(scripts) / "lock"
    if not locks:
        if lf.exists():
            raise Stop("CRITERIA-CHANGED (a lock file exists but the body has no lock line: stop)")
        return "unlocked", None
    want = max(locks)[2]
    if not lf.is_file():
        raise Stop("CRITERIA-CHANGED (the lock file is missing: stop)")
    rec = read_lock(scripts)
    if rec["sha"] != want:
        raise Stop("CRITERIA-CHANGED (the lock file is not the newest lock line: stop)")
    if lock_sha(text, scripts, rec["data"]) != want:
        raise Stop("CRITERIA-CHANGED (a criterion line or a measure script changed since the lock: stop)")
    return "ok", rec


def data_allowed(path, run, rec):
    """A locked original, or a copy in a run folder's work/ (this run's, or an earlier run's for a record)."""
    if str(real(path)) in rec["data"]:
        return True
    if run is not None:
        return inside(path, pathlib.Path(run) / "work")
    runs = str(real(pathlib.Path.home() / ".superfix" / "runs")).lower()
    return bool(re.match(re.escape(runs) + r"/[^/]+/work/", str(real(path)).lower()))


def need_ids(cs, baseline):
    """Every check criterion, and at a baseline every later criterion too."""
    return [c["id"] for c in cs if c.get("name") and (c["kind"] == "check" or (baseline and c["kind"] == "later"))]


def change_lines(text):
    return sum(1 for l in section(text, "Decision") if re.match(r"^Criteria (change|removed) \d{4}-\d{2}-\d{2}: .*Approved by .+", l.strip()))


def write_lock(text, sc, data, by):
    sha = lock_sha(text, sc, data)
    cs = [c for c in criteria(text) if c.get("name")]
    lines = ([f"sha {sha}", f"crit {sha_file(__file__)}", f"changes {change_lines(text)}"]
             + [f"script {p.stem[len('measure-'):]} {sha_file(p)}" for p in sorted(sc.glob("measure-*.py"))]
             + [f"data {d}" for d in data] + [f"criterion {c['id']} {c['name']}" for c in cs])
    (sc / "lock").write_text("\n".join(lines) + "\n")
    return sha


def print_lock(sha, by):
    print(f"Internal: criteria-sha {sha} (sha256), locked {now()}, approved by {by}")
    print(f"Internal: crit-sha {sha_file(__file__)} (sha256)")


def lock_inputs(a, text, cs):
    sc = pathlib.Path(a.scripts)
    miss = [c["id"] for c in cs if c["kind"] in ("check", "later") and not (sc / f"measure-{c['id']}.py").is_file()]
    if miss or not a.by.strip():
        raise Stop(f"CRITERIA-BAD {' '.join(miss)} how (no script)" if miss else "CRITERIA-BAD approver (say who approved)")
    data = sorted({str(real(d)) for d in a.data or []})
    if any(c["kind"] in ("check", "later") for c in cs) and not data:
        raise Stop("CRITERIA-BAD data (name each original file with --data)")
    return sc, data


def cmd_lock(a):
    text = body_text(a)
    cs = criteria(text)
    if not cs:
        print("CRITERIA-BAD none (no P<k>- line in ## Done when)")
        return 1
    if (pathlib.Path(a.scripts) / "lock").exists():
        print("CRITERIA-BAD locked already (use amend for a change)")
        return 1
    sc, data = lock_inputs(a, text, cs)
    check_file(a)
    rows = epoch_rows(a.attempts)
    bad = check_rows(a.scripts, rows)
    ids = need_ids(cs, True)
    bad += [f"CRITERIA-INCOMPLETE {i} (no baseline measure)" for i in ids if not rows or i not in rows[0]["v"]]
    for r in rows[:1]:
        for p in sorted(rec_dir(a.scripts, r["from"]).glob("*.out")):
            o, s = read_out(p), sc / f"measure-{p.stem}.py"
            if s.is_file() and o.get("SCRIPT-SHA") != sha_file(s):
                bad.append(f"CRITERIA-BAD baseline (measured with another script version: {p.stem}; measure again)")
            if o.get("DATA") not in data:
                bad.append(f"CRITERIA-BAD baseline data ({p.stem} was measured on a file not named by --data)")
    if bad:
        print("\n".join(dict.fromkeys(bad)))
        return 1
    probs = sorted({c["p"] for c in cs if c.get("name")})
    appr = sorted({int(x) for v in (a.approved or []) for x in re.findall(r"P?(\d+)", v)}) if a.approved != ["all"] else probs
    if a.approved is None or [k for k in probs if k not in appr]:
        print(f"CRITERIA-BAD approval (name every problem the owner approved: --approved P1,P2,...; missing {', '.join('P%d' % k for k in probs if k not in appr)})")
        return 1
    sha = write_lock(text, sc, data, a.by.strip())
    with open(sc / "lock", "a") as f:
        f.write("".join(f"approved P{k} by {a.by.strip()}\n" for k in probs))
    if all_lines(a.attempts) or ids:
        append_line(a.attempts, f"locked {now()} {sha}")
    print_lock(sha, a.by.strip())
    print("CRITERIA-LOCKED (write both Internal lines in ## Decision, directly before Internal: approval-sha)")
    return 0


def cmd_lockcheck(a):
    st, rec = lock_state(body_text(a), a.scripts)
    if st == "unlocked":
        print("CRITERIA-UNLOCKED (no criteria-sha line: no fixing)")
        return 1
    check_file(a)
    bad = check_rows(a.scripts, epoch_rows(a.attempts), rec)
    if bad:
        print("\n".join(bad))
        return 1
    print("CRITERIA-LOCK-OK")
    return 0


# ---------- running one script ----------

def profile(tmp, reads, execs=(), read_dirs=()):
    """Deny by default (probed on macOS 27): exec only of Python, reads only of the named files, the
    temporary folder, system paths and the Python install, metadata only on those paths' parents.
    1.6.0 (work orders): execs are the other programs allowed to start (bash, the tools check.sh calls,
    node) and read_dirs whole folders to read (the worktree, node's install); with execs, also fork,
    the execs' own files and sysctl-read (node aborts without it; probed). With neither, the 1.5.0 profile."""
    q = lambda s: '"' + str(s).replace("\\", "\\\\").replace('"', '\\"') + '"'
    py = real(sys.executable)
    fw = py.parents[3] if "Frameworks" in str(py) else py.parent.parent
    sysr = ["/System", "/usr/lib", "/usr/share", "/private/var/db/dyld", "/private/var/db/timezone", "/Library/Apple",
            "/opt/homebrew", "/dev", "/private/var/select", real(sys.base_prefix), real(sys.prefix), fw] + [real(d) for d in read_dirs]
    reads = list(reads) + [real(e) for e in execs]
    allowed = [str(x) for x in sysr] + [str(r) for r in reads] + [str(tmp)]
    anc = sorted({str(x) for p in allowed for x in pathlib.Path(p).parents} | {"/"})
    return ("(version 1)(deny default)"
            f"(allow process-exec (literal {q(py)}) (subpath {q(fw)})" + "".join(f" (literal {q(real(e))})" for e in execs) + ")"
            + ("(allow process-fork)(allow sysctl-read)" if execs else "")
            # /bin/bash 3.2 writes here-documents to /tmp/sh-thd-<n> whatever TMPDIR says (T4 run v1-3: held.sh's heredocs printed nothing)
            + ("(allow file-read* file-write* (regex #\"^/private/tmp/sh-thd-[0-9]+$\"))(allow file-read-metadata (literal \"/tmp\") (literal \"/private/tmp\"))(allow file-write* (literal \"/private/tmp\"))" if execs else "")
            + "(allow file-read-metadata " + " ".join(f"(literal {q(x)})" for x in anc) + ")"
            "(allow file-read* (literal \"/\") " + " ".join(f"(subpath {q(r)})" for r in sysr)
            + " " + " ".join(f"(literal {q(r)})" for r in reads) + f" (subpath {q(tmp)}))"
            f"(allow file-write* (subpath {q(tmp)}) (literal \"/dev/null\"))")


SANDBOX_TOOLS = ["/bin/bash", "/bin/sh", "/bin/cat", "/usr/bin/tr", "/usr/bin/cut", "/usr/bin/sed", "/usr/bin/grep", "/usr/bin/head",
                 "/usr/bin/tail", "/usr/bin/sort", "/usr/bin/wc", "/usr/bin/awk", "/usr/bin/env", "/usr/bin/printf"]


OUT_CAP = 16 * 2**20                     # bytes read back from one run
FSIZE_CAP = 256 * 2**20                  # the largest file the code may write (RLIMIT_FSIZE)


def run_capped(cmd, cwd, env, timeout, stderr_out=True):
    """Run cmd in its own process group. Its output comes back through a pipe, read up to OUT_CAP: a file the code
    could reach (the old tmp/.o) could be rewritten after the checks printed (review of 1.6.0). Returns
    (rc, why, text); why is None, "timeout", "overflow" or "held-open" (something kept the pipe open after the kill)."""
    lim = lambda: resource.setrlimit(resource.RLIMIT_FSIZE, (FSIZE_CAP, FSIZE_CAP))
    p = subprocess.Popen(cmd, cwd=cwd, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT if stderr_out else subprocess.DEVNULL,
                         stdin=subprocess.DEVNULL, start_new_session=True, preexec_fn=lim)
    buf, over = bytearray(), []

    def rd():
        for chunk in iter(lambda: p.stdout.read1(65536), b""):
            if len(buf) + len(chunk) > OUT_CAP:
                over.append(1)
            buf.extend(chunk[:max(0, OUT_CAP - len(buf))])
    th = threading.Thread(target=rd, daemon=True)
    th.start()
    why = None
    try:
        p.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        why = "timeout"
    finally:
        try:
            os.killpg(p.pid, signal.SIGKILL)       # the whole group: children too, after a timeout AND after a normal exit
        except (ProcessLookupError, PermissionError):
            pass
        p.wait()
    th.join(5)
    why = why or ("held-open" if th.is_alive() else "overflow" if over else None)
    return p.returncode, why, buf.decode(errors="replace")


def sandbox_run(cwd, argv, timeout=300):
    """1.6.0 work orders: run someone else's code (check.sh, the suite) in the widened profile: no network, writes
    only in a temporary folder, reads of the worktree, system paths and node. Returns (rc, why, text); why
    "missing" or "no-node" means nothing ran."""
    cwd = real(cwd)
    node = shutil.which("node", path=os.environ.get("PATH"))
    if not os.path.exists(SBX) or os.environ.get("SUPERFIX_TEST_NO_SANDBOX") == "1":
        return None, "missing", ""
    if not node:
        return None, "no-node", ""
    nreal = real(node)
    tmp = real(tempfile.mkdtemp(prefix="wo-", dir="/private/tmp" if os.path.isdir("/private/tmp") else None))
    prof = profile(tmp, [real(x) for x in argv if os.path.isfile(x)], SANDBOX_TOOLS + [nreal], [cwd, nreal.parent.parent])
    env = {"PATH": f"{nreal.parent}:/usr/bin:/bin", "HOME": str(tmp), "TMPDIR": str(tmp), "LANG": "en_US.UTF-8"}
    try:
        return run_capped([SBX, "-p", prof] + list(argv), cwd, env, timeout)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def cmd_sandbox(a):
    rc, why, out = sandbox_run(a.cwd, a.argv[1:] if a.argv[:1] == ["--"] else a.argv, a.timeout)
    if why == "missing":
        print("SANDBOX-MISSING (nothing ran; ask the owner the criteria-mode sandbox question first)")
        return 1
    if why == "no-node":
        print("SANDBOX-NO-NODE (node is not on PATH)")
        return 1
    sys.stdout.write(out if not out or out.endswith("\n") else out + "\n")
    print(f"SANDBOX-EXIT {why or rc}")
    return 0


def unsandboxed_approved(text):
    return any(UNSBX_RX.match(l.strip()) for l in section(text, "Decision"))


def run_script(c, script, data, baseline, timeout, unsandboxed_ok, own_verdict=True):
    """Run one measure script. Returns (word, info): word PASS/FAIL, or an ERROR word with a reason."""
    i = c["id"]
    sbx = SBX if os.path.exists(SBX) and os.environ.get("SUPERFIX_TEST_NO_SANDBOX") != "1" else None
    if not sbx and not unsandboxed_ok:
        return "SANDBOX-MISSING", "not run; ask the owner the sandbox question, no recommended answer, and record his yes"
    tmp = real(tempfile.mkdtemp(prefix="crit-", dir="/private/tmp" if os.path.isdir("/private/tmp") else None))
    try:
        cmd = [str(real(sys.executable)), "-I", "-B", str(script), str(data)]
        if sbx:
            cmd = [sbx, "-p", profile(tmp, [script, data])] + cmd
        env = {"PATH": "/usr/bin:/bin", "HOME": str(tmp), "TMPDIR": str(tmp), "LANG": "en_US.UTF-8"}
        rc, why, stdout = run_capped(cmd, tmp, env, timeout, stderr_out=False)
        if why == "timeout":
            return "ERROR", f"timeout after {timeout} s"
        if why:
            return "ERROR", f"output {why}"
        if rc:
            return "ERROR", f"exit {rc}"
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    got, word = {}, None
    for l in (l.strip() for l in stdout.splitlines()):
        if not l:
            continue
        k, _, v = l.partition(" ")
        if k in ("MEASURE", "ITEMS", "DATA-SHA") and k not in got:
            got[k] = v
        elif l in ("PASS", "FAIL") and word is None:
            word = l
        else:
            return "ERROR", "unexpected or doubled output line (a script prints only MEASURE and ITEMS)"
    m = re.fullmatch(re.escape(i) + r" (\S+)", got.get("MEASURE", ""))
    if not m:
        return "ERROR", "missing or wrong MEASURE line"
    if not re.fullmatch(MEASURE_NUM, m.group(1)):
        return "ERROR-MEASURE-FORMAT", "(a plain number: up to 9 digits, at most 2 after the point)"
    dsha = sha_file(data)
    if "DATA-SHA" in got and got["DATA-SHA"] != dsha:
        return "ERROR", "DATA-SHA is not the sha256 of the file given"
    items = got.get("ITEMS")
    if items is None:
        return "ERROR", "missing ITEMS line"
    nums = [] if items == "none" else items.replace(",", " ").split()
    if not all(n.isdigit() and len(n) <= 9 for n in nums) or [int(n) for n in nums] != sorted({int(n) for n in nums}):
        return "ERROR", "ITEMS must be none or row numbers in ascending order"
    nrec = len(records(data))
    if nums and (int(nums[0]) < 1 or int(nums[-1]) > nrec):
        return "ERROR-ITEMS-OUT-OF-RANGE", f"(the file has {nrec} rows, header included)"
    v = float(m.group(1))
    t = target(c["pass"], m.group(1) if baseline is None else baseline, c["ck"])
    if t is None:
        return "ERROR", "the pass line is outside the grammar (shape check: CRITERIA-VAGUE)"
    res = "PASS" if distance(t, v) == 0 else "FAIL"
    if own_verdict and word and word != res:
        return "ERROR-VERDICT-DISAGREES", f"(script said {word}, the pass line gives {res})"
    return res, {"DATA": str(data), "SCRIPT": str(script), "DATA-SHA": dsha, "SCRIPT-SHA": sha_file(script),
                 "MEASURE": m.group(1), "ITEMS": " ".join(nums) or "none", "SANDBOX": "on" if sbx else "off",
                 "TARGET": f"{t[0]} {fmt(t[1])}" + (f" {fmt(t[2])}" if t[2] is not None else ""), "RESULT": res}


def baseline_raw(attempts, i):
    rows = epoch_rows(attempts) if attempts else []
    return rows[0]["raw"].get(i) if rows else None


def parse_measures(items):
    out = {}
    for x in items or []:
        i, sep, p = x.partition("=")
        if not sep or not re.fullmatch(r"P\d+-[CK]\d+", i):
            raise Stop(f"ERROR measure (want --measure <id>=<file>, got {x[:40]})")
        out[i] = real(p)
    return out


def script_checks(a, c, script, data, lk, run):
    """The script and data rules shared by measure, baseline, attempt and amend. Returns an error line or None."""
    i = c["id"]
    if script.parent != real(a.scripts) or script.name != f"measure-{i}.py":
        return f"ERROR-SCRIPT-NOT-LOCKED {i} (the script must be {real(a.scripts)}/measure-{i}.py)"
    if lk and sha_file(script) != lk["scripts"].get(i):
        return f"ERROR-SCRIPT-NOT-LOCKED {i} (its sha is not the locked one)"
    if lk and not data_allowed(data, run, lk):
        return f"ERROR-DATA-NOT-LOCKED {i} (only a locked original or a file in the run folder's work/)"
    if placeholder(data) and not a.asked:
        return f"ASK-FIRST {data} (a cloud or online-only file: reading it can download it; ask the owner, then add --asked)"
    if not data.is_file():
        return f"ERROR {i} cannot read the data file"
    return None


def sbx_ok(a, text):
    if getattr(a, "unsandboxed_ok", False) and not unsandboxed_approved(text):
        raise Stop("SANDBOX-MISSING (--unsandboxed-ok needs the owner's yes recorded in ## Decision: Internal: unsandboxed approved by <who>, <YYYY-MM-DD HH:MM>)")
    return getattr(a, "unsandboxed_ok", False)


def measure_all(a, cs, ms, lk, run, text, baseline_vals):
    recs = {}
    for i, data in sorted(ms.items()):
        script = real(a.scripts) / f"measure-{i}.py"
        err = script_checks(a, cs[i], script, data, lk, run)
        if err:
            raise Stop(err)
        res, info = run_script(cs[i], script, data, baseline_vals.get(i) if baseline_vals else None, a.timeout, sbx_ok(a, text))
        if res not in ("PASS", "FAIL"):
            raise Stop(f"ATTEMPT-REFUSED {i} {res} {info}")
        recs[i] = info
    return recs


def write_row(a, recs, lock, n, label, text):
    d = rec_dir(a.scripts, label)
    rid = secrets.token_hex(8)
    d.mkdir(parents=True)
    for i, info in recs.items():
        (d / f"{i}.out").write_text("".join(f"{k} {v}\n" for k, v in info.items()) + f"RUN {rid}\n")
    sha = combined(r["DATA-SHA"] for r in recs.values())
    sbx = "on" if all(r["SANDBOX"] == "on" for r in recs.values()) else "off"
    append_line(a.attempts, f"{n} {now()} data-sha {sha} from {label} lock {lock} run {rid} rec {rec_hash(d)} body {sha_text(text)} sbx {sbx} "
                + " ".join(f"{i}={recs[i]['MEASURE']}" for i in sorted(recs)))
    (d / "LINE").write_text(sha_text(all_lines(a.attempts)[-1]) + "\n")   # so a hand edit of the newest line is caught too
    for i in sorted(recs):
        print(f"{recs[i]['RESULT']} {i} {recs[i]['MEASURE']} items {recs[i]['ITEMS']}" + (" UNSANDBOXED" if recs[i]["SANDBOX"] == "off" else ""))
    write_verify(a, n, recs)
    n_l, h = head_of(all_lines(a.attempts))
    print(f"ATTEMPT-SAVED {n} (epoch {epochs(a.attempts)}); attempts: {n_l} lines, head {h}; your own re-check command: {real(a.scripts) / 'VERIFY.txt'}")


def write_verify(a, n, recs):
    sc = real(a.scripts)
    if real(__file__) != real(sc / "crit.py"):
        shutil.copy2(__file__, sc / "crit.py")
    crit = read_lock(sc)["crit"] if (sc / "lock").exists() else sha_file(__file__)
    verify = f"shasum -a 256 {shlex.quote(str(sc / 'crit.py'))}; python3 -I {shlex.quote(str(sc / 'crit.py'))} verify --scripts {shlex.quote(str(sc))} --attempts {shlex.quote(str(real(a.attempts)))} --line {n} --crit-sha {crit} " \
             + " ".join(f"--measure {shlex.quote(i + '=' + recs[i]['DATA'])}" for i in sorted(recs))
    (sc / "VERIFY.txt").write_text("# The first line printed is the sha256 of the tool; it must equal the crit-sha line in the issue.\n"
                                   "# Replace a file path with your own copy of the data if mine is gone.\n" + verify + "\n")


def setup(a):
    run = real(a.run)
    if not (run / "key").is_file():
        raise Stop(f"NO-RUN-FOLDER {run}")
    if not re.fullmatch(r"[A-Za-z0-9_-]{1,40}", a.label):
        raise Stop("ERROR label (letters, digits, - and _ only)")
    if rec_dir(a.scripts, a.label).exists():
        raise Stop(f"ATTEMPT-REFUSED label {a.label} is used already")
    return run


# ---------- measure (run 1, the negative control, a look; never an attempt) ----------

def cmd_measure(a):
    run, i = real(a.run), a.id
    script, data = real(a.script), real(a.data)                    # resolved before any cd
    if not (run / "key").is_file():
        print(f"NO-RUN-FOLDER {run}")
        return 1
    if not re.fullmatch(r"[A-Za-z0-9_-]{1,40}", a.out):
        print("ERROR out (letters, digits, - and _ only)")
        return 1
    text = body_text(a)
    c = next((c for c in criteria(text) if c["id"] == i and c.get("name")), None)
    if not c or c["kind"] not in ("check", "later"):
        print(f"ERROR {i} no check or later criterion with this id in ## Done when")
        return 1
    _, lk = lock_state(text, a.scripts)
    if a.attempts:
        check_file(a, need=False)
    err = script_checks(a, c, script, data, lk, run)
    if err:
        print(err)
        return 1
    if a.neg_of:
        neg_of = real(a.neg_of)
        if placeholder(neg_of) and not a.asked:
            print(f"ASK-FIRST {neg_of} (hashing a cloud or online-only file can download it; ask, then add --asked)")
            return 1
        if not a.defect or not SAFE_TEXT.match(a.defect) or not a.attempts or a.expect != "FAIL":
            print(f"ERROR {i} a negative control needs --defect <plain words, no row values>, --attempts and --expect FAIL")
            return 1
        others = {sha_file(neg_of)} | {sha_file(d) for d in (lk["data"] if lk else []) if os.path.isfile(d)}
        if sha_file(data) in others:
            print(f"ERROR-NEG-NOT-DISTINCT {i} (the negative copy equals the change or an original)")
            return 1
        added = collections.Counter(records(data)) - collections.Counter(records(neg_of))
        removed = collections.Counter(records(neg_of)) - collections.Counter(records(data))
        if (sum(added.values()), sum(removed.values())) not in ((1, 0), (0, 1), (1, 1)):
            print(f"ERROR-NEG-NOT-ONE-DEFECT {i} (want one row put back, removed or changed; found +{sum(added.values())} -{sum(removed.values())})")
            return 1
    res, info = run_script(c, script, data, baseline_raw(a.attempts, i), a.timeout, sbx_ok(a, text))
    if res not in ("PASS", "FAIL"):
        print(f"{res} {i} {info}".rstrip())
        return 1
    out = run / "criteria" / "measure" / a.out
    out.mkdir(parents=True, exist_ok=True)
    (out / f"{i}.out").write_text("".join(f"{k} {v}\n" for k, v in info.items()))
    print(f"{res} {i} {info['MEASURE']} items {info['ITEMS']}" + (" UNSANDBOXED" if info["SANDBOX"] == "off" else ""))
    if a.expect:
        if a.expect != res:
            print(f"UNEXPECTED {i} wanted {a.expect} got {res}")
            return 1
        print("EXPECTED")
    if a.neg_of:
        append_line(a.attempts, f"neg {now()} {i} data-sha {info['DATA-SHA']} defect {a.defect}")
        print("NEG-RECORDED")
    return 0


# ---------- baseline (epoch 1, before the stop), attempt (after go), amend (a new epoch) ----------

def cmd_baseline(a):
    run = setup(a)
    text = body_text(a)
    if (pathlib.Path(a.scripts) / "lock").exists():
        print("ATTEMPT-REFUSED locked already: a new baseline only through amend")
        return 1
    if all_lines(a.attempts):
        if posted_head(a):
            print("ATTEMPT-REFUSED a baseline was posted already: a new baseline only through amend, after go")
            return 1
        if not a.redo:
            print("ATTEMPT-REFUSED a baseline exists (nothing posted yet): add --redo to measure it again")
            return 1
        check_file(a, need=False)
        append_line(a.attempts, f"epoch-close {epochs(a.attempts)} {now()} lock none redo")
    cs = {c["id"]: c for c in criteria(text) if c.get("name")}
    ms = parse_measures(a.measure)
    miss = [i for i in need_ids(cs.values(), True) if i not in ms]
    unknown = [i for i in ms if i not in cs or cs[i]["kind"] not in ("check", "later")]
    if miss or unknown:
        print("\n".join([f"CRITERIA-INCOMPLETE {i} (measure every check and later criterion at a baseline)" for i in miss]
                        + [f"ERROR measure {i} (no check or later criterion with this id)" for i in unknown]))
        return 1
    recs = measure_all(a, cs, ms, None, run, text, None)
    append_line(a.attempts, f"epoch {epochs(a.attempts) + 1} {now()} lock none")
    write_row(a, recs, "none", 0, a.label, text)
    return 0


def cmd_attempt(a):
    run = setup(a)
    text = body_text(a)
    st, lk = lock_state(text, a.scripts)
    if st == "unlocked":
        print("CRITERIA-UNLOCKED (no criteria-sha line: no fixing, so no attempt)")
        return 1
    check_file(a)
    rows = epoch_rows(a.attempts)
    if not rows:
        print("ATTEMPTS-MISSING (no baseline in this epoch: baseline before the stop, amend after an amendment)")
        return 1
    bad = check_rows(a.scripts, rows, lk)
    if bad:
        print("\n".join(bad))
        return 1
    if epoch_locks(a.attempts) - {lk["sha"]}:
        print("ATTEMPT-REFUSED the criteria were amended: run amend, which measures the new baseline")
        return 1
    n = rows[-1]["n"] + 1
    if n > MAX_ATTEMPTS:
        print(f"STOP-CAP {MAX_ATTEMPTS} of {MAX_ATTEMPTS} attempts (fixed per epoch: stop and ask)")
        return 1
    cs = {c["id"]: c for c in criteria(text) if c.get("name")}
    ms = parse_measures(a.measure)
    if a.recheck:   # a later re-check: only later criteria, on the data as it is now (the check criteria were met earlier)
        miss = [] if ms else ["(none given)"]
        unknown = [i for i in ms if i not in cs or cs[i]["kind"] != "later"]
    else:
        miss = [i for i in need_ids(cs.values(), False) if i not in ms]
        unknown = [i for i in ms if i not in cs or cs[i]["kind"] not in ("check", "later")]
    if miss or unknown:
        print("\n".join([f"CRITERIA-INCOMPLETE {i} (measure every check criterion; --recheck measures later criteria only)" for i in miss]
                        + [f"ERROR measure {i} (not a {'later' if a.recheck else 'check or later'} criterion)" for i in unknown]))
        return 1
    recs = measure_all(a, cs, ms, lk, run, text, rows[0]["raw"])
    vals = {i: float(r["MEASURE"]) for i, r in recs.items()}
    if rows[-1]["sha"] == combined(r["DATA-SHA"] for r in recs.values()) and rows[-1]["v"] == vals:
        print(f"ATTEMPT-SAME {rows[-1]['n']} (the same file and values as the newest line; nothing written)")
        return 0
    write_row(a, recs, lk["sha"], n, a.label, text)
    return 0


def cmd_amend(a):
    """An approved amendment: new or changed lines and scripts, a removed criterion. Closes the epoch,
    re-measures the NEW scripts on the ORIGINAL files as line 0 of a new epoch, and writes the new lock."""
    run = setup(a)
    text = body_text(a)
    sc = pathlib.Path(a.scripts)
    if not (sc / "lock").exists():
        print("CRITERIA-UNLOCKED (nothing to amend: lock first)")
        return 1
    old = read_lock(sc)
    locks = [(m.group(2), n, m.group(1)) for n, l in enumerate(text.splitlines()) if (m := LOCK.match(l.strip()))]
    if not locks or max(locks)[2] != old["sha"]:
        print("CRITERIA-CHANGED (the newest lock line in the body is not the current lock: stop)")
        return 1
    check_file(a)
    cs = {c["id"]: c for c in criteria(text) if c.get("name")}
    sc, data = lock_inputs(a, text, list(cs.values()))
    new = lock_sha(text, sc, data)
    if new == old["sha"]:
        print("ERROR-AMEND-NOTHING-CHANGED (the lines, scripts and files are the same as the lock)")
        return 1
    if change_lines(text) <= old["changes"]:
        print("ERROR-AMEND-NOT-APPROVED (## Decision needs a new line: Criteria change <date>: \"<old>\" is now \"<new>\". Approved by <who> ...)")
        return 1
    removed = [i for i in old["names"] if i not in cs]
    for i in removed:
        if i not in (a.removed or []) or not any(re.match(rf"^Criteria removed \d{{4}}-\d{{2}}-\d{{2}}: .*{re.escape(old['names'][i])}.*Approved by .+", l.strip(), re.I) for l in section(text, "Decision")):
            print(f"ERROR-AMEND-REMOVAL-NOT-APPROVED {i} (needs --removed {i} and a line: Criteria removed <date>: \"{old['names'][i]}\" ... Approved by <who>)")
            return 1
    ms = parse_measures(a.measure)
    miss = [i for i in need_ids(cs.values(), True) if i not in ms]
    notorig = [i for i, p in ms.items() if str(p) not in data]
    if miss or notorig:
        print("\n".join([f"CRITERIA-INCOMPLETE {i} (the new baseline measures every check and later criterion)" for i in miss]
                        + [f"ERROR-AMEND-NOT-ORIGINAL {i} (a new baseline is measured on the original files named by --data)" for i in notorig]))
        return 1
    tmp_lock = {"sha": new, "scripts": {p.stem[len("measure-"):]: sha_file(p) for p in sc.glob("measure-*.py")}, "data": data}
    recs = measure_all(a, cs, ms, tmp_lock, run, text, None)
    badb = [f"AMEND-BASELINE-BAD {i} ({'a C criterion passes on the original, so it does not detect the problem' if cs[i]['ck'] == 'C' else 'a K criterion fails on the original'})"
            for i, r in recs.items() if cs[i]["kind"] == "check" and ((cs[i]["ck"] == "C") == (r["RESULT"] == "PASS"))]
    if badb:
        print("\n".join(badb))
        return 1
    e = epochs(a.attempts)
    append_line(a.attempts, f"epoch-close {e} {now()} lock {old['sha']}")
    write_lock(text, sc, data, a.by.strip())
    append_line(a.attempts, f"epoch {e + 1} {now()} lock {new}")
    write_row(a, recs, new, 0, a.label, text)
    print_lock(new, a.by.strip())
    print("CRITERIA-LOCKED (amended: write both Internal lines in ## Decision, directly before Internal: approval-sha)")
    return 0


def cmd_verify(a):
    """The owner's own re-check. It never needs Superfix's work copies: give it your own file."""
    me = sha_file(__file__)
    print(f"CRIT-SHA {me}")
    bad = []
    if me != a.crit_sha:
        bad.append(f"CRIT-SHA-MISMATCH (this tool is {me[:12]}, the issue's crit-sha line says {a.crit_sha[:12]})")
    lk = read_lock(a.scripts) if (pathlib.Path(a.scripts) / "lock").exists() else None
    if lk:
        if lk["crit"] and lk["crit"] != a.crit_sha:
            bad.append("CRIT-SHA-MISMATCH (the lock file names another tool)")
        for p in sorted(pathlib.Path(a.scripts).glob("measure-*.py")):
            if lk["scripts"].get(p.stem[len("measure-"):]) != sha_file(p):
                bad.append(f"ERROR-SCRIPT-NOT-LOCKED {p.stem[len('measure-'):]} (its sha is not the locked one)")
    rows = [r for r in epoch_rows(a.attempts) if r["n"] == a.line]      # the current epoch
    row = rows[-1] if rows else None
    if not row:
        print("\n".join(bad + [f"VERIFY-NO-LINE {a.line}"]))
        return 1
    recs = {p.stem: read_out(p) for p in rec_dir(a.scripts, row["from"]).glob("*.out")}
    info_lines = []
    for i, data in parse_measures(a.measure).items():
        if not data.is_file():
            info_lines.append(f"VERIFY-NO-FILE {i} {data} (give your own copy of the data: --measure {i}=<your file>)")
            continue
        script = real(a.scripts) / f"measure-{i}.py"
        res, info = run_script({"id": i, "pass": "0", "ck": "C"}, script, data, None, 120, False, own_verdict=False)
        got = info["MEASURE"] if res in ("PASS", "FAIL") else res
        if res in ("PASS", "FAIL") and info["DATA-SHA"] != recs.get(i, {}).get("DATA-SHA"):
            info_lines.append(f"VERIFY-DIFFERENT-DATA {i} (not the file I measured; for information: mine gave {row['raw'].get(i, 'none')}, yours gives {got})")
        elif got != row["raw"].get(i):
            bad.append(f"VERIFY-MISMATCH {i} attempts {row['raw'].get(i, 'none')} now {got}")
    out = bad + info_lines
    print("\n".join(out) if out else "")
    if not bad:
        print(f"VERIFY-OK {a.line} (the scripts give the same numbers as the attempts file{'' if not info_lines else ' where the file is the same'})")
    return 1 if bad else 0


def cmd_progress(a):
    text = body_text(a)
    _, lk = lock_state(text, a.scripts)
    check_file(a)
    rows = epoch_rows(a.attempts)
    bad = check_rows(a.scripts, rows, lk)
    if bad:
        print("\n".join(bad))
        return 1
    cs = {c["id"]: c for c in criteria(text) if c.get("name") and c["kind"] == "check"}
    rows = [r for r in rows if all(i in r["v"] for i in cs)] or rows[:1]   # re-check lines (later only) are not tries
    if len(rows) < 2:
        print("PROGRESS-NONE (only the baseline so far)")
        return 0
    tg = {i: target(c["pass"], rows[0]["raw"].get(i), c["ck"]) for i, c in cs.items()}

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
    if n >= MAX_ATTEMPTS:
        print(f"STOP-CAP {n} of {MAX_ATTEMPTS} attempts")
        code = 1
    return code


# ---------- comment check ----------

FENCE = re.compile(r"^(`{3,}|~{3,})(.*)$")


def unfence(lines):
    """(lines outside fences, ok). A closing fence is the same character, at least as long, nothing after it."""
    out, open_ = [], None
    for l in lines:
        s = l.strip()
        m = FENCE.match(s)
        if open_ is None and m:
            open_ = m.group(1)
            continue
        if open_ is not None:
            if m and m.group(1)[0] == open_[0] and len(m.group(1)) >= len(open_) and not m.group(2).strip():
                open_ = None
            continue
        out.append(s)
    return out, open_ is None


PII = [
    ("e-mail", re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")),
    ("url", re.compile(r"[A-Za-z][A-Za-z0-9+.-]*://|www\.")),
    ("long-digit-run", re.compile(r"(?<![0-9a-fA-F])\d{9,}(?![0-9a-fA-F])")),
    ("name-after-label", re.compile(r"(?i)\b(name|customer|client|contact|member|staff|employee|patient|e-?mail|phone|mobile|address|dob|birthday)\s*:\s*\S")),
]
PHONE = re.compile(r"\+?\(?\d[\d ()-]{6,}\d")
EXAMPLES = re.compile(r"^rows? \d+(?:(?:, \d+)*(?:,? and \d+))?$")
LINK = re.compile(r"https://github\.com/([A-Za-z0-9-]+/[A-Za-z0-9._-]+)/(?:issues|pull)/\d+(?![\w/#?&=.%:-])")


def pii(lines, repos=()):
    hits = []
    for n, l in enumerate(lines, 1):
        l = LINK.sub(lambda m: "LINK" if m.group(1).lower() in repos else m.group(0), l)   # only the run's own issue and PR links
        for what, rx in PII:
            if rx.search(l):
                hits.append(f"CRITERIA-PII {what} (comment line {n})")
        for m in PHONE.finditer(re.sub(r"\d{4}-\d{2}-\d{2}( \d{2}:\d{2})?", "DATE", l)):
            s = m.group(0).strip()
            if sum(ch.isdigit() for ch in s) >= 8:
                hits.append(f"CRITERIA-PII phone-number (comment line {n})")
    return hits


def blank_slots(l, names):
    """The numbers the tool validated itself (Today, the Criteria check values, the table's before and after) are not scanned."""
    s = l.strip()
    if HEAD_RX.match(s):
        return "attempts: N"
    for nm in names:
        if s.lower().startswith(nm + ". today: "):
            return re.sub(r"(?i)(\. today: )" + NUM, r"\1N", s, count=1)
        if re.match(r"^\|\s*" + re.escape(nm) + r"\s*\|", s, re.I):
            cells = s.strip("|").split("|")
            return "|".join(c if k not in (1, 2) else re.sub(r"^\s*" + NUM + r"\s*$", " N ", c) for k, c in enumerate(cells))
    if s.startswith("Criteria check: "):
        return re.sub(r"\((" + NUM + r")(?: -> (" + NUM + r"))?\)", "(N)", s)
    return s


def cmd_scan(a):
    hits = pii(pathlib.Path(a.file).read_text(errors="replace").splitlines())
    print("\n".join(h.replace("CRITERIA-PII", "SCAN-PII").replace("comment line", "line") for h in hits) if hits else "SCAN-CLEAN")
    return 1 if hits else 0


def cmd_comment(a):
    raw_lines = pathlib.Path(a.comment).read_text().splitlines()
    lines, closed = unfence(raw_lines)
    bad = [] if closed else ["CRITERIA-FENCE-UNCLOSED (a code fence is never closed)"]
    seps = [n for n, l in enumerate(lines) if l == "---"]
    plain = lines[:seps[0]] if seps else lines
    ai = lines[seps[-1] + 1:] if (a.kind == "decision" and seps) else lines
    text = body_text(a)
    cs = [c for c in criteria(text) if c.get("name")]
    _, lk = lock_state(text, a.scripts)
    if any(c["kind"] in ("check", "later") for c in cs) or all_lines(a.attempts):
        check_file(a)
    rows = epoch_rows(a.attempts)
    bad += check_rows(a.scripts, rows, lk)
    if not rows and any(c["kind"] in ("check", "later") for c in cs):
        print("CRITERIA-MISSING attempts (run the baseline command first)")
        return 1
    hl = [l for l in lines if HEAD_RX.match(l)]
    want_head = "attempts: %d lines, head %s" % head_of(all_lines(a.attempts))
    if len(hl) != 1:
        bad.append(f"CRITERIA-MISSING attempts line (want: {want_head})")
    elif hl[0] != want_head:
        bad.append(f"CRITERIA-VALUE-MISMATCH attempts comment {hl[0][10:]} file {want_head[10:]}")
    rows = rows or [{"n": 0, "sha": "", "from": "none", "lock": "none", "raw": {}, "v": {}, "sbx": "on"}]
    if any(r["sbx"] == "off" for r in rows) and not any(l.startswith("UNSANDBOXED: ") for l in lines):
        bad.append("CRITERIA-MISSING UNSANDBOXED: line (a measure in this epoch ran without the sandbox)")
    base, new = rows[0], rows[-1]
    brecs = {p.stem: read_out(p) for p in rec_dir(a.scripts, base["from"]).glob("*.out")}
    for c in cs:
        if c["kind"] == "check" and not any(c["id"] in r["v"] for r in rows):
            bad.append(f"CRITERIA-INCOMPLETE {c['id']} (no measure in this epoch)")
        if c["kind"] == "later" and c["id"] not in base["v"]:
            bad.append(f"CRITERIA-INCOMPLETE {c['id']} (no baseline measure)")

    def last(i):
        return next((r for r in reversed(rows) if i in r["v"]), new)

    none_ps = set()
    if a.kind == "decision":
        cl = [l for l in ai if l.startswith("Criteria: ")]
        if len(cl) != 1:
            bad.append("CRITERIA-MISSING Criteria:")
        else:
            m = re.match(r"^Criteria: (PROPOSED|APPROVED) (\d+)(?: \((P\d+(?:, P\d+)*)\))?((?:; NONE \(P\d+[^)]*\))*)$", cl[0])
            got = int(m.group(2)) if m else 0
            if got != len(cs):
                bad.append(f"CRITERIA-COUNT {got}/{len(cs)}")
            if m and m.group(3) and {int(x) for x in re.findall(r"\d+", m.group(3))} != {c["p"] for c in cs}:
                bad.append("CRITERIA-MISSING the Criteria: line names other problems than ## Done when")
            none_ps = {int(x) for x in re.findall(r"NONE \(P(\d+)", m.group(4) or "")} if m else set()
        # F1 (live tests): no gap note for a problem whose checks are proposed
        allowed_ps = (none_ps if cl else set()) | {c["p"] for c in cs if c["kind"] == "owner"}
        checkable_ps = {c["p"] for c in cs if c["kind"] in ("check", "later")} - allowed_ps
        g = sum(int(m2.group(2)) for l in ai if (m2 := re.match(r"^Gap note: (FILED|SEEN-AGAIN|LOCAL) (\d+)", l)))
        if g > len(allowed_ps):
            bad.append(f"LINES-GAP-WITH-CRITERIA (Gap note: {g}, but only {len(allowed_ps)} problem(s) have no checkable criterion or a criterion that fell to OWNER)")
        # F2 (live tests): the two criteria questions, once per problem, asked for a group of problems together
        qs = {"solved": collections.Counter(), "worse": collections.Counter()}
        for l in plain:
            mq = re.match(r"^\d+\. (P\d+(?:(?:, P\d+)*(?:,? and P\d+))?)\b(.*)$", l)
            if not mq:
                continue
            ps = [int(x) for x in re.findall(r"P(\d+)", mq.group(1))]
            key = "solved" if re.search(r"would you consider (this|these|them|it) solved", mq.group(2)) else "worse" if "what must not get worse" in mq.group(2) else None
            if key:
                qs[key].update(ps)
        for k in sorted({c["p"] for c in cs if c["kind"] in ("check", "later", "owner")}):
            for key, word in (("solved", "would you consider ... solved"), ("worse", "what must not get worse")):
                if qs[key][k] == 0:
                    bad.append(f"CRITERIA-QUESTIONS-MISSING P{k} ({word})")
                elif qs[key][k] > 1:
                    bad.append(f"CRITERIA-QUESTIONS-TWICE P{k} ({word}: ask it once, for the group)")
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
            if not e:
                continue
            res, x, y = e
            if c["kind"] == "owner":
                if res != "OWNER":
                    bad.append(f"CRITERIA-VALUE-MISMATCH {c['name']} comment {res} computed OWNER")
                continue
            if c["kind"] == "later" and res != f"LATER {c['who'].strip()[len('re-measure on '):]}":
                bad.append(f"CRITERIA-VALUE-MISMATCH {c['name']} comment {res} computed LATER {c['who'].strip()[len('re-measure on '):]}")
            row = last(c["id"])
            if c["kind"] == "check" and c["id"] in row["v"]:
                want = verdict(c, row["v"][c["id"]], base["raw"].get(c["id"]))
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
            want = [int(x) for x in brecs.get(c["id"], {}).get("ITEMS", "none").split() if x.isdigit()][:3]
            if shown != want:
                bad.append(f"CRITERIA-VALUE-MISMATCH {c['name']} comment rows {shown or 'none'} measured rows {want or 'none'}")
    if a.kind == "final":
        for c in cs:
            tr = [l for l in lines if re.match(r"^\|\s*" + re.escape(c["name"]) + r"\s*\|", l, re.I)]
            if len(tr) != 1:
                bad.append(f"CRITERIA-MISSING table row for {c['name']}")
                continue
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
            want = verdict(c, r["v"][c["id"]], base["raw"].get(c["id"])) if c["id"] in r["v"] else None
            if not ((c["kind"] == "check" and result == want) or (c["kind"] == "later" and result == "LATER")):
                bad.append(f"TABLE-CELL-UNCHECKED {c['name']} result (computed {want if c['kind'] == 'check' else 'LATER'})")
    for l in lines:     # every kind: a gap-list sentence for a problem with checks proposed
        mg = re.match(r"^P(\d+) \(problem \d+: [^)]*\) is outside what I cover", l)
        if mg and int(mg.group(1)) in {c["p"] for c in cs if c["kind"] in ("check", "later")} - {c["p"] for c in cs if c["kind"] == "owner"}:
            bad.append(f"LINES-GAP-WITH-CRITERIA P{mg.group(1)} (no gap note and no gap-list sentence for a problem that has checks proposed)")
    names = [c["name"].lower() for c in cs]
    bad += pii([blank_slots(l, names) for l in raw_lines], {r.lower() for r in [a.repo] + (a.gap_repo or [])})   # every line, fenced text included
    print("\n".join(dict.fromkeys(bad)) if bad else "CRITERIA-OK")
    return 1 if bad else 0


def cmd_signoff(a):
    cs = [c for c in criteria(body_text(a)) if c["kind"] == "owner"]
    if not cs:
        print("SIGNOFF-NONE (no owner criterion)")
        return 0
    check_file(a, need=False)
    for c in cs:
        k = sum(1 for l in c["list"] if re.match(r"^\s+- \[[xX]\]", l))
        append_line(a.attempts, f"signoff {now()} {c['id']} {k}/{len(c['list'])}")
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
    name = a.name or src.name
    if not COPY_NAME.match(name) or name.endswith(".sf-orig"):
        print("COPY-REFUSED name (letters, digits, . _ -, not ending .sf-orig)")
        return 1
    if placeholder(a.src) and not a.asked:
        print(f"ASK-FIRST {src} (a cloud or online-only file: reading it can download it; ask the owner, then add --asked)")
        return 1
    if not src.is_file():
        print(f"COPY-REFUSED {src} (not a file)")
        return 1
    work = run / "work"
    work.mkdir(mode=0o700, exist_ok=True)
    dest = work / name
    if dest.exists():
        print(f"COPY-EXISTS {dest}")
        return 1
    shutil.copy2(src, dest)
    os.chmod(dest, 0o600)
    s = sha_file(src)
    (work / f"{name}.sf-orig").write_text(f"{s} {src}\n")
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
    for o in sorted(work.glob("*.sf-orig")):
        t = o.read_text()
        m = re.fullmatch(r"([0-9a-f]{64}) (/[^\n]+)\n", t)
        if not m or not (work / o.name[:-len(".sf-orig")]).exists():
            print(f"WORK-METADATA-BAD {o.name} (not written by copy; nothing printed from it)")
            changed = True
            continue
        s, p = m.groups()
        if placeholder(p) and not a.asked:
            print(f"ASK-FIRST {p} (hashing a cloud or online-only original can download it; ask, then add --asked)")
            return 1
        same = pathlib.Path(p).is_file() and sha_file(p) == s
        changed |= not same
        print(f"ORIGINAL-UNCHANGED {p}" if same else f"ORIGINAL-CHANGED {p}")
    if changed:
        print(f"WORK-KEPT {work} (an original changed, or a record is not the tool's: tell the owner, ask before deleting)")
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


# ---------- work orders (1.6.0, references/workorder.md): someone else makes a code change ----------

WO_REQUIRED = ["WORK-ORDER", "CHECKS-KIND", "REPO", "BASE", "BRANCH", "FILES", "LIMITS", "CHECKS-SHA", "BASELINE", "DELIVER"]
WO_KINDS = {"code", "criteria"}          # 1.6.1 added "criteria"
WO_REQUIRED_CRITERIA = ["WORK-ORDER", "CHECKS-KIND", "SOURCE", "BASE", "FILES", "LIMITS", "CHECKS-SHA", "BASELINE", "DELIVER"]
WO_LIMIT = 5
R_CALL = re.compile(r'\br ([CKH]\d+) \$\? (' + r'"(?:[^"\\]|\\.)*"' + "|'[^']*'" + ') ')   # r <id> $? <expected> <got>


def wo_head(text):
    return {k: v for l in text.splitlines() for k, _, v in [l.partition(": ")] if k in WO_REQUIRED}


def wo_block(text):
    """The CHECKS block, exactly as Step 0 extracts it (the lines between # BEGIN CHECKS and # END CHECKS)."""
    m = re.search(r"(?ms)^# BEGIN CHECKS\n(.*?)^# END CHECKS$", text)
    return m.group(1) if m else None


def wo_files(text):
    """FILES as [(path, is_new)]: a path marked ' (new)' does not exist at BASE."""
    return [(f[:-6].strip(), True) if f.endswith(" (new)") else (f, False)
            for f in (x.strip() for x in wo_head(text).get("FILES", "").split(",")) if f]


def git(clone, *args):
    r = subprocess.run(["git", "-C", str(clone), *args], capture_output=True, text=True)
    return r.returncode, r.stdout.strip()


def woc_split_finding(line):
    """Split a findings line on the LAST whole-word ': met' / ': not met' verdict
    -> (name, verdict, rest) or None.

    The verdict is a whole word (": metadata" and ": methodology" do not match)
    followed by something other than ?, - or = (": met?", ": met-ish" and
    ": met = false" do not match). Splitting on the last match lets a tick text
    contain a colon: only the final verdict counts.
    """
    ms = list(WOC_VERDICT_RX.finditer(line))
    if not ms:
        return None
    m = ms[-1]
    return line[:m.start()].strip(), ("not met" if m.group(1) else "met"), line[m.end():]


def woc_tick(text):
    """Tick lines under ## Done when: [(marker, name, must)] for '- [ ] [marker] name: must be value'."""
    m = re.search(r"(?ms)^## Done when.*?(?=^## )", text)
    out = []
    for l in (m.group(0) if m else text).splitlines():
        m2 = re.fullmatch(r"- \[ \] \[([^\]]+)\] (.+)", l.strip())
        if m2:
            out.append((m2.group(1),) + woc_split_must(m2.group(2)))
    return out


def woc_split_must(rest):
    """'name: must be value' or bare judgment text (a [Superfix verifies] line has no must-be)."""
    m = re.fullmatch(r"([^:]+): must be (.+)", rest.strip())
    return (m.group(1), m.group(2)) if m else (rest.strip(), "")


WOC_APPROVED_RX = re.compile(r"^- (?:(P\d+-[CK]\d+) )?\[([^\]]+)\] (.+)$")
WOC_VERDICT_RX = re.compile(r":\s*(not\s+)?met\b(?!\?|-|\s*=)", re.IGNORECASE)


def woc_approved(folder, name="checks/done-when.md"):
    """Approved lines in done-when.md: {(marker, name, must): id}, plus the two Internal lines."""
    d = pathlib.Path(folder) / name
    if not d.is_file():
        return None
    out = {}
    for l in d.read_text().splitlines():
        m = WOC_APPROVED_RX.match(l.strip())
        if m and m.group(1):
            out[(m.group(2),) + woc_split_must(m.group(3))] = m.group(1)
    return out


def woc_body(a):
    """The locked body (--body file, else --issue fetched by the tool itself), or None."""
    b = getattr(a, "body", None)
    if b and pathlib.Path(b).is_file():
        try:
            return pathlib.Path(b).read_text()
        except OSError:
            return None
    if getattr(a, "issue", None):
        try:
            return body_text(a)
        except (Stop, OSError, ValueError):
            return None
    return None


def woc_norm_pass(p):
    """A pass line without its trailing today-note, for comparing tick must-bes with body pass lines."""
    return re.sub(r"\s*\([^)]*\)\s*$", "", p).strip()


def woc_body_passes(text):
    """{criterion id: normalized pass line} from the locked body's check and later criteria."""
    out = {}
    for c in criteria(text):
        if c.get("name") and c.get("kind") in ("check", "later") and c.get("pass"):
            out[c["id"]] = woc_norm_pass(c["pass"])
    return out


def woc_fidelity(appr, body_passes):
    """Every done-when script/later line carries its locked body's pass line, and covers it."""
    bad = []
    ids = sorted(i for i in appr.values() if i)
    for (marker, name, must), i in sorted(appr.items(), key=lambda kv: (kv[1] or "")):
        if i is None or (marker != "script" and not marker.startswith("later")):
            continue
        if body_passes.get(i) is None or woc_norm_pass(must) != body_passes[i]:
            bad.append(f"WORKORDER-TICKLIST {i} (not the locked body's pass line)")
    for i in sorted(body_passes):
        if i not in ids:
            bad.append(f"WORKORDER-TICKLIST {i} (an approved criterion is missing from the tick list)")
    return bad


def woc_block_files(text):
    """The CHECKS block as {name: sha} for '<sha>  checks/<name>' lines, or None."""
    blk = wo_block(text)
    if blk is None:
        return None
    rows = [l.split("  ", 1) for l in blk.splitlines() if l.strip()]
    if any(len(r) != 2 or not re.fullmatch(r"[0-9a-f]{64}", r[0]) or not r[1].startswith("checks/") for r in rows):
        return None
    return {r[1][len("checks/"):]: r[0] for r in rows}


def woc_scan_data(text):
    """pii hits on workorder.md without the CHECKS block and the BASE:/CHECKS-SHA: lines (their shas hold digit runs)."""
    blk = wo_block(text)
    body = text.replace("# BEGIN CHECKS\n" + blk + "# END CHECKS", "") if blk else text
    kept = [l for l in body.splitlines() if not l.startswith(("BASE: ", "CHECKS-SHA:"))]
    return pii(kept)


def woc_baseline_want(text):
    return dict(re.findall(r"(P\d+-[CK]\d+) ([A-Z]+)", wo_head(text).get("BASELINE", "")))


def woc_files_entries(t):
    """FILES entries: exactly one work/<file>, plus optional work/drafts/ for a process job."""
    return [f.strip() for f in (wo_head(t).get("FILES", "") or "").split(",") if f.strip()]


def woc_drafts_ok(t):
    return any(f.rstrip("/") == "work/drafts" for f in woc_files_entries(t))


def woc_proc_job(text):
    """A process or guide job: its criteria include an owner or later kind (processes set a
    later criterion, section 1 Scope). Pure check jobs are data clean-ups: no drafts."""
    try:
        return any(c.get("kind") in ("owner", "later") for c in criteria(text))
    except (AttributeError, TypeError):
        return False


def woc_copy_file(t, folder):
    """The FILES data file: exactly one work/<file> entry (plus optional work/drafts/); its folder-side path or None."""
    fs = woc_files_entries(t)
    plain = [f for f in fs if f.rstrip("/") != "work/drafts"]
    if len(plain) != 1 or len(fs) > 2 or "/" in plain[0][len("work/"):] or not plain[0].startswith("work/"):
        return None
    return pathlib.Path(folder) / plain[0]


def woc_folder_is_criteria(path):
    p = pathlib.Path(real(path)) / "workorder.md"
    return p.is_file() and wo_head(p.read_text()).get("CHECKS-KIND") == "criteria"


def woc_run_is_criteria(D):
    p = pathlib.Path(D) / "workorder" / "folder" / "workorder.md"
    return p.is_file() and wo_head(p.read_text()).get("CHECKS-KIND") == "criteria"


def woc_need_clone(a, cmd):
    """Code-kind commands need --clone: an argparse-style error, never a traceback downstream."""
    if getattr(a, "clone", None) is None:
        print(f"usage: crit.py {cmd} --run RUN --clone CLONE ...")
        print(f"crit.py {cmd}: error: the following arguments are required: --clone")
        return 2
    return 0


WOC_DATAYES_RX = re.compile(r"^Data yes:\s*(\S+)\s*\(.*?\)\s*:\s*(\S+)\s*$", re.IGNORECASE)


def woc_data_yes(text, base):
    """Last `Data yes:` line for this file in ## Decision: True only on an explicit yes."""
    ans = None
    for l in section(text, "Decision"):
        m = WOC_DATAYES_RX.match(l.strip())
        if m and m.group(1) == base:
            ans = m.group(2).lower() == "yes"
    return ans is True


def woc_base_name(t):
    """FILES data-file basename for the data-yes record, or None."""
    fs = [f for f in woc_files_entries(t) if f.rstrip("/") != "work/drafts"]
    if not fs or not fs[0].startswith("work/") or "/" in fs[0][len("work/"):]:
        return None
    return pathlib.Path(fs[0]).name


def woc_check(a, t):
    """WORKORDER for kind criteria: the tick list, the bundled files, the copy, the scan, the data yes, the stub lock."""
    lines, bad = t.splitlines(), []
    for k in WO_REQUIRED_CRITERIA:
        n = sum(1 for l in lines if l.startswith(k + ": "))
        if n != 1:
            bad.append(f"WORKORDER-MISSING {k} (found {n} times)")
    h = wo_head(t)
    rep = t.find("\n## Report")
    for n, l in enumerate(t[:rep if rep >= 0 else len(t)].splitlines(), 1):
        if re.search(r"<[^<>\s][^<>]*>", re.sub(r"<(word|n|k|why)>", "", l)) and not l.lstrip().startswith(("#", "- [ ]")):
            bad.append(f"WORKORDER-NOT-FRESH line {n} (a placeholder outside ## Report)")
        if re.search(r"^\s*- \[[xX]\]", l):
            bad.append(f"WORKORDER-NOT-FRESH line {n} (a ticked box)")
    if not re.search(r"(?m)^- \[ \] ", t):
        bad.append("WORKORDER-NOT-FRESH (no unticked step)")
    F = real(pathlib.Path(a.wo).parent)
    appr = woc_approved(F)
    ticks = woc_tick(t)
    if appr is None:
        bad.append("WORKORDER-CHECKS-SHA (checks/done-when.md is missing from the folder)")
    else:
        have = sorted(appr.get(k, "?") or "?" for k in ticks)
        want = sorted(i for i in appr.values() if i)
        for i in sorted(set(want) - set(have)):
            bad.append(f"WORKORDER-TICKLIST {i} (an approved criterion is missing from the tick list)")
        for k in ticks:
            if ticks.count(k) > 1:
                bad.append(f"WORKORDER-TICKLIST {appr.get(k) or k[1]} (a ticked line is doubled)")
            elif k not in appr and k[0] == "script":
                bad.append(f"WORKORDER-TICKLIST {k[1]} (no approved line matches this tick word for word)")
        text = woc_body(a)
        if text is not None:
            bad.extend(woc_fidelity(appr, woc_body_passes(text)))
    files = woc_block_files(t)
    if files is None or sha_text(wo_block(t) + ("" if wo_block(t).endswith("\n") else "\n")) != h.get("CHECKS-SHA", "").split()[0]:
        bad.append("WORKORDER-CHECKS-SHA (the CHECKS block and CHECKS-SHA differ)")
    else:
        for name, sha in files.items():
            if not (F / "checks" / name).is_file() or sha_file(F / "checks" / name) != sha:
                bad.append("WORKORDER-CHECKS-SHA (a bundled file differs from its CHECKS line)")
                break
    for name in ("crit.py", "lock", "attempts", "done-when.md"):
        if files is not None and name not in files:
            bad.append(f"WORKORDER-CHECKS-SHA (checks/{name} is not bundled)")
    cp = woc_copy_file(t, F)
    if cp is None or not cp.is_file() or sha_file(cp) != h.get("BASE", "").split()[0]:
        bad.append("WORKORDER-NO-COPY (work/<file> is missing, FILES names more than one file, or its sha256 is not BASE)")
    hits = woc_scan_data(t)
    if hits:
        bad.append(f"WORKORDER-DATA ({hits[0]})")
    dw = F / "checks" / "done-when.md"
    if dw.is_file():
        hits = pii([l for l in dw.read_text(errors="replace").splitlines() if not l.startswith("Internal: ")])
        if hits:
            bad.append(f"WORKORDER-DATA ({hits[0]})")
    text = woc_body(a)
    base = woc_base_name(t) or "the file"
    if text is None:
        bad.append("WORKORDER-NO-YES (no body given: pass --body or --issue so the Data yes line can be checked)")
    elif not woc_data_yes(text, base):
        bad.append(f"WORKORDER-NO-YES (no Data yes line for {base} in ## Decision)")
    try:
        rec = read_lock(F / "checks")
        if any(not inside(pathlib.Path(p), F) for p in rec["data"]):
            bad.append("WORKORDER-LOCK-PATH (the folder lock names a path outside the stub)")
    except (OSError, ValueError, KeyError, IndexError):
        bad.append("WORKORDER-CHECKS-SHA (the folder lock cannot be read)")
    else:
        if sha_file(F / "checks" / "crit.py") != rec["crit"]:
            bad.append("WORKORDER-CRIT-SHA (checks/crit.py is not the locked tool)")
    print("\n".join(dict.fromkeys(bad)) if bad else "WORKORDER-OK")
    return 1 if bad else 0


def woc_run_measures(script_dir, done_name, copy_path, timeout=300, passes=None):
    """Each [script] approval measured on the copy with the bundled scripts: {id: (word, value)}."""
    appr = woc_approved(script_dir, done_name) or {}
    out = {}
    for (marker, _name, must), i in sorted(((k, v) for k, v in appr.items()), key=lambda kv: kv[1] or ""):
        if not marker.startswith("script"):
            continue
        sc = pathlib.Path(script_dir) / f"measure-{i}.py"
        if copy_path is None or not sc.is_file():
            out[i] = ("ERROR", "?")
            continue
        p = passes.get(i, woc_norm_pass(must)) if passes else woc_norm_pass(must)
        w, info = run_script({"id": i, "pass": p, "ck": i.split("-")[1][0]},
                             sc, copy_path, None, timeout, False)
        out[i] = (w, info.get("MEASURE", "?") if isinstance(info, dict) else "?")
    return out


def woc_baseline(a):
    """BASELINE for kind criteria: the bundled measures on the untouched copy give the BASELINE words."""
    F = real(a.folder)
    t = (F / "workorder.md").read_text()
    want = woc_baseline_want(t)
    text = woc_body(a)
    cp = woc_copy_file(t, F)
    got = woc_run_measures(F / "checks", "done-when.md", cp if cp is not None and cp.is_file() else None,
                           passes=woc_body_passes(text) if text is not None else None)
    if any(w == "SANDBOX-MISSING" for w, _ in got.values()):
        print("SANDBOX-MISSING (nothing ran; ask the owner the criteria-mode sandbox question first)")
        return 1
    bad = [f"{i} (no script result)" for i in want if i not in got]
    bad += [i for i in want if i in got and got[i][0] != want[i]]
    bad += [f"{i} (not in BASELINE)" for i in got if i not in want]
    print("BASELINE-OK" if not bad else "BASELINE-MISMATCH " + ", ".join(sorted(set(bad))))
    return 1 if bad else 0


def woc_lock_state(D):
    """Parse D/workorder/lock: ({name: sha} for '  ' lines, origsha, origpath) or None."""
    p = pathlib.Path(D) / "workorder" / "lock"
    if not p.is_file():
        return None
    files, orig, opath = {}, None, None
    for l in p.read_text().splitlines():
        if l.startswith("origsha "):
            orig = l[len("origsha "):]
        elif l.startswith("origpath "):
            opath = l[len("origpath "):]
        elif "  " in l:
            s, n = l.split("  ", 1)
            files[n] = s
    return files, orig, opath


def woc_returns(D):
    p = pathlib.Path(D) / "workorder" / "returns.json"
    return json.loads(p.read_text()) if p.exists() else []


def woc_save_return(D, **kv):
    rs = woc_returns(D)
    rs.append({"n": len(rs) + 1, **kv})
    (pathlib.Path(D) / "workorder" / "returns.json").write_text(json.dumps(rs, indent=1) + "\n")
    return len(rs)


def woc_head(t):
    """Header lines for kind criteria (wo_head only keeps the code kind's keys)."""
    return {k: v for l in t.splitlines() for k, _, v in [l.partition(": ")] if k in WO_REQUIRED_CRITERIA}


def woc_orig_record(t, D):
    """(origsha, origpath) from the .sf-orig record matching SOURCE's basename, or None."""
    src = (woc_head(t).get("SOURCE", "") or "").split()
    if not src:
        return None
    cand = pathlib.Path(D) / "work" / (pathlib.Path(src[0]).name + ".sf-orig")
    if not cand.is_file():
        return None
    try:
        sha, sep, path = cand.read_text().strip().partition(" ")
    except OSError:
        return None
    if not sep or not re.fullmatch(r"[0-9a-f]{64}", sha) or not path:
        return None
    return sha, path


def woc_ours(D):
    """Our locked stub: (folder, headers, {name: sha}, origsha, origpath), or None after NO-LOCK/OURS-CHANGED."""
    F = pathlib.Path(D) / "workorder" / "folder"
    st = woc_lock_state(D)
    if st is None:
        print("RETURN-NO-LOCK (the run folder is gone: say so, use the ## Decision shas, ask for any password again)")
        return None
    files, origsha, origpath = st
    if any(not (F / n[len("folder/"):]).exists() or sha_file(F / n[len("folder/"):]) != s
           for n, s in files.items() if n.startswith("folder/")):
        print("RETURN-OURS-CHANGED (our locked copies and their lock do not agree: stop)")
        return None
    return F, wo_head((F / "workorder.md").read_text()), files, origsha, origpath


def woc_copy_folder(F, dest, t):
    """Copy only the documented layout: key, workorder.md, work/, and the bundled checks (never VERIFY.txt or records)."""
    for n in ["key", "workorder.md"] + [f"checks/{n}" for n in sorted(woc_block_files(t))]:
        (dest / n).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(F / n, dest / n)
    shutil.copytree(F / "work", dest / "work", symlinks=False, dirs_exist_ok=True)


def woc_lock_modes(dest):
    """Owner-only modes: 700 on every directory, 600 on every file (copytree keeps the stub's 755/644)."""
    dest = pathlib.Path(dest)
    for r, ds, fs in os.walk(dest):
        for d in ds:
            try:
                os.chmod(os.path.join(r, d), 0o700)
            except OSError:
                pass
        for f in fs:
            try:
                os.chmod(os.path.join(r, f), 0o600)
            except OSError:
                pass
    try:
        os.chmod(dest, 0o700)
    except OSError:
        pass


def woc_symlink_hit(dest):
    """A link on ~/superfix-workorders, the destination, or any parent between: the path or None.
    Only the tree at and below the base is walked: parents above it (macOS /private/tmp) are not ours."""
    base = pathlib.Path.home() / "superfix-workorders"
    if os.path.islink(base):
        return str(base)
    d = pathlib.Path(dest)
    try:
        d.relative_to(base)
    except ValueError:
        return None
    p = d
    while p != base:
        if os.path.islink(p):
            return str(p)
        p = p.parent
    return None


def woc_lock(a):
    """Lock a criteria folder: WORKORDER and BASELINE again, default path only, then copy the folder."""
    D, F = pathlib.Path(a.run), real(a.folder)
    t = (F / "workorder.md").read_text()
    h = wo_head(t)
    if woc_check(argparse.Namespace(wo=str(F / "workorder.md"), run=a.run, body=getattr(a, "body", None),
                                    issue=getattr(a, "issue", None)), t) \
            or woc_baseline(argparse.Namespace(folder=str(F), body=getattr(a, "body", None),
                                               issue=getattr(a, "issue", None))):
        print("WORKORDER-LOCK-REFUSED (WORKORDER and BASELINE must both be OK)")
        return 1
    want = real(pathlib.Path.home() / "superfix-workorders" / h["WORK-ORDER"])
    if real(a.dest) != want:
        print(f"WORKORDER-PATH {a.dest} (criteria work orders go only to the default path)")
        return 1
    if in_cloud(real(a.dest)):
        print(f"PATH-CLOUD {a.dest} (a synced folder: criteria work orders go only to a local default path)")
        return 1
    hit = woc_symlink_hit(a.dest)
    if hit is not None:
        print(f"WORKORDER-SYMLINK {hit} (a link in the work-order path: use a plain local folder)")
        return 1
    dest = wo_dest(a.dest)
    if dest is None:
        return 1
    W = D / "workorder"
    rec = woc_orig_record(t, D)
    if rec is None:
        print("WORKORDER-LOCK-REFUSED (no .sf-orig record for the SOURCE file: copy the original with crit.py copy under its own name)")
        return 1
    origsha, origpath = rec
    names = ["workorder.md"] + [f"checks/{n}" for n in sorted(woc_block_files(t))]
    (W / "lock").write_text("".join(f"{sha_file(F / n)}  folder/{n}\n" for n in names)
                            + f"origsha {origsha}\norigpath {origpath}\n")
    woc_copy_folder(F, dest, t)
    woc_lock_modes(dest)
    ws = sha_file(F / "workorder.md")
    if sha_file(dest / "workorder.md") != ws:
        print("WORKORDER-COPY-FAILED")
        return 1
    print(f"Internal: workorder-sha {ws} (sha256)")
    print(f"Internal: checks-sha {h['CHECKS-SHA'].split()[0]} (sha256)")
    print(f"Give this line to the executor separately: WORKORDER-SHA {ws} (sha256)")
    print(f"WORKORDER-LOCKED {dest / 'workorder.md'}")
    return 0


def woc_symlinks(RF):
    return sorted(os.path.relpath(os.path.join(r, n), RF) for r, ds, fs in os.walk(RF) for n in ds + fs
                  if stat.S_ISLNK((s := os.lstat(os.path.join(r, n))).st_mode) or (stat.S_ISREG(s.st_mode) and s.st_nlink > 1))


def woc_return(a):
    """RETURN for kind criteria: our lock, the original, only FILES, then the copy for Superfix's own tools."""
    D, RF = pathlib.Path(a.run), real(a.folder)
    o = woc_ours(D)
    if o is None:
        return 1
    F, _h, files, origsha, origpath = o
    ours = (F / "workorder.md").read_text()
    links = woc_symlinks(RF)
    if links:
        print("RETURN-SYMLINK " + " ".join(links) + " (a link in the returned folder: nothing read or committed; ask for a plain copy)")
        return 1
    cp = woc_copy_file(ours, F)
    if cp is None:
        print("WORKORDER-NO-COPY (FILES must name exactly one work/<file>, plus optional work/drafts/)")
        return 1
    base = cp.name
    if origpath is None or not pathlib.Path(origpath).is_file() or sha_file(origpath) != origsha:
        print("RETURN-ORIGINAL-MOVED (the recorded original is gone or changed: a fresh baseline through amend)")
        return 1
    got = RF / "work" / base
    if not got.is_file():
        print("RETURN-NO-COPY (work/<file> is missing from the returned folder)")
        return 1
    text = woc_body(a)
    if text is None or not woc_drafts_ok(ours):
        drafts = False
    else:
        # the drafts gate reads the body's criteria from the run's real criteria
        # folder (the same reference verify and sendback use): only the locked
        # body counts, so a swapped --body cannot smuggle an owner criterion in
        at, sc = getattr(a, "attempts", None), getattr(a, "scripts", None)
        if not at or not sc:
            print("RETURN-NEEDS-CRITERIA (wo-return needs --attempts and --scripts for the run's real criteria folder)")
            return 1
        try:
            st, _ = lock_state(text, sc)
        except Stop as e:
            print(str(e))
            return 1
        if st != "ok":
            print("RETURN-NEEDS-CRITERIA (that criteria folder holds no lock for this body: pass the run's real criteria folder)")
            return 1
        drafts = woc_proc_job(text)

    def allowed(rel):
        if rel in ("workorder.md", "report.md", "sendback.md", "key", f"work/{base}"):
            return True
        if re.fullmatch(r"RETURNED-\d+\.md", rel):
            return True
        return rel.startswith("work/drafts/") and drafts

    over = sorted(str(p.relative_to(RF)) for p in RF.rglob("*") if p.is_file()
                  and not allowed(str(p.relative_to(RF))) and not str(p.relative_to(RF)).startswith("checks/"))
    for n, sh in sorted(files.items()):
        if not n.startswith("folder/checks/"):
            continue
        q = RF / n[len("folder/"):]
        if not q.is_file() or sha_file(q) != sh:
            over.append("CHECKS-CHANGED (a bundled file differs: Superfix measures only with its own copies)")
            break
    if (RF / "checks").is_dir():
        for q in sorted((RF / "checks").rglob("*")):
            if q.is_dir():
                continue
            rel = "folder/" + str(q.relative_to(RF))
            if rel == "folder/checks/files.sha256":
                continue
            if rel not in files or sha_file(q) != files[rel]:
                over.append("CHECKS-CHANGED (a bundled file differs: Superfix measures only with its own copies)")
                break
    if over:
        print("RETURN-FILES-OVER " + " ".join(sorted(set(over))))
        return 1
    rs = woc_returns(D)
    if len(rs) + 1 > WO_LIMIT:
        print(f"RETURN-CAP {len(rs) + 1} of {WO_LIMIT} attempts used (over the limit: stop)")
        return 1
    dst = D / "work" / f"wo{len(rs) + 1}-{base}"
    shutil.copy2(got, dst)
    n = woc_save_return(D, copy=str(dst), sha=sha_file(dst))
    print(f"RETURN-CRITERIA-COPIED wo{n} {sha_file(dst)} attempts {n}")
    print(f"next: lockcheck, attempt --label wo{n} and progress with your own locked crit.py, then the section 15 three runs")
    return 0


def woc_verify(a):
    """VERIFY for kind criteria: verdicts from Superfix's own recorded attempt, then the findings line numbers."""
    D = pathlib.Path(a.run)
    rs = woc_returns(D)
    r = next((r for r in rs if f"wo{r['n']}" == a.head), None)
    if r is None:
        print(f"VERIFY-NO-RETURN {a.head} (no recorded return or attempt under that label)")
        return 1
    text = woc_body(a)
    at, sc = getattr(a, "attempts", None), getattr(a, "scripts", None)
    if not at or not sc or text is None:
        print(f"VERIFY-NO-ATTEMPT {a.head} (Superfix's own attempt must be recorded first: lockcheck, attempt --label {a.head}, progress)")
        return 1
    try:
        _, lk = lock_state(text, sc)
    except Stop as e:
        print(str(e))
        return 1
    rows = epoch_rows(at)
    row = next((x for x in rows if x["from"] == a.head), None)
    flat = False
    if row is None:
        # ATTEMPT-SAME records nothing: carry the newest values forward so the
        # flat return still counts (same values feed verdicts and progress).
        if not rows:
            print(f"VERIFY-NO-ATTEMPT {a.head} (no recorded attempt under that label: lockcheck, attempt --label {a.head}, progress)")
            return 1
        row = rows[-1]
        flat = True
    bad = check_rows(sc, rows, lk)
    if bad:
        print("\n".join(bad))
        return 1
    try:
        csha = sha_file(r["copy"])
    except OSError:
        csha = None
    if csha != row["sha"]:
        print(f"VERIFY-SHA-MISMATCH {a.head} (the recorded attempt measured a different file: re-run attempt --label {a.head} on the returned copy)")
        return 1
    cs = {c["id"]: c for c in criteria(text) if c.get("name") and c.get("kind") == "check"}
    base = rows[0]["raw"] if rows else {}
    ids = [i for i in row["v"] if i in cs]
    if not ids:
        print(f"VERIFY-NO-RETURN {a.head} (the recorded attempt holds no check verdict)")
        return 1
    out, failing = [], []
    if flat:
        out.append(f"FLAT {a.head} (carried values from attempt {row['n']})")
    for i in sorted(ids):
        tg = target(cs[i]["pass"], base.get(i), cs[i]["ck"])
        w = "PASS" if tg is not None and distance(tg, row["v"][i]) == 0 else "FAIL"
        out.append(f"{i} {w} {fmt(row['v'][i])}")
        if w != "PASS":
            failing.append(i)
    copy = pathlib.Path(r["copy"])
    ours = (D / "workorder" / "folder" / "workorder.md").read_text()
    sv = sorted({k[1] for k in woc_tick(ours) if k[0].lower().startswith("superfix verifies")})
    if a.findings:
        try:
            nrec = len(records(copy))
        except OSError:
            nrec = 0
        flines = pathlib.Path(a.findings).read_text().splitlines()
        for name in sv:
            parsed = []
            named = []
            for l in flines:
                sp = woc_split_finding(l)
                if sp is not None and sp[0] == name:
                    parsed.append((l,) + sp[1:])
                elif l.startswith(name + ":"):
                    named.append(l)
            if len(parsed) != 1:
                # a whole-word "met" anywhere else, or any negation, refuses the finding
                if any(re.search(r"\b(unmet|isn'?t|not|no|never|fail(?:ed)?|n't)\b", l, re.IGNORECASE) for l in named):
                    out.append(f"FINDING-NOT-MET {name} (sent back while attempts remain)")
                else:
                    out.append(f"FINDING-MISSING {name} (needs exactly one finding)")
                failing.append("findings")
                continue
            _line, verdict, rest = parsed[0]
            if verdict == "not met" or re.search(r"\b(unmet|isn'?t|not|no|never|fail(?:ed)?|n't)\b", rest, re.IGNORECASE):
                out.append(f"FINDING-NOT-MET {name} (sent back while attempts remain)")
                failing.append("findings")
                continue
            g = re.search(r"\(\s*lines?\b([^)]*)\)", rest, re.IGNORECASE)
            nums = [int(x) for x in re.findall(r"\d+", g.group(1))] if g else []
            if not nums or any(x < 1 or x > nrec for x in nums):
                out.append(f"FINDING-LINE-MISSING {nums} (the copy has {nrec} records or lines)")
                failing.append("findings")
        for l in flines:
            sp = woc_split_finding(l)
            if sp is not None and sp[0] not in sv:
                out.append(f"FINDING-UNKNOWN-TICK {sp[0]} (no such [Superfix verifies] line)")
                failing.append("findings")
    elif sv:
        for name in sv:
            out.append(f"FINDING-MISSING {name} (needs exactly one finding)")
        failing.append("findings")
    r["failing"] = len(failing)
    r["values"] = {i: row["v"][i] for i in sorted(ids)}
    r["lock"] = row["lock"]
    r["flat"] = flat
    r["lines"] = [l for l in out if " FAIL" in l or l.startswith(("FINDING-", "VERIFY-"))]
    (D / "workorder" / "returns.json").write_text(json.dumps(rs, indent=1) + "\n")
    if not failing:
        _, ok = woc_cleanup_full(D)
        print("\n".join(out + ["VERIFY-PASS (then the section 15 three runs)"]))
        return 0 if ok else 1
    print("\n".join(out + ["VERIFY-FAIL"]))
    return 1


def woc_round_dirs(work_id):
    """The round-1 <id>/ folder plus the ~/superfix-workorders/<id>-r<n>/ send-back rounds."""
    base = pathlib.Path.home() / "superfix-workorders"
    ds = [base / work_id] + sorted(base.glob(work_id + "-r[0-9]*"))
    return [d for d in ds if d.is_dir()]


def woc_cleanup_rounds(work_id):
    """Delete work/ inside every send-back round folder: personal data must not linger past an ending.
    Returns [work/ paths still present]."""
    left = []
    for d in woc_round_dirs(work_id):
        shutil.rmtree(d / "work", ignore_errors=True)
        if (d / "work").exists():
            left.append(str(d / "work"))
    return left


def woc_cleanup_full(D, keep=True):
    """Every ending: the rounds work/ folders, the stub work/ copy, and the run work/
    data files. With keep (a pass) the verified copies stay until taken or stop;
    without it (stop, later, finish) everything goes. A .sf-orig record whose data
    file is gone goes with it, so finish finds no orphan record. Records (lock,
    returns.json, attempts) stay for audit. Prints CLEANUP-INCOMPLETE with leftover
    paths when anything remains. Returns (work-order id, clean)."""
    D = pathlib.Path(D)
    try:
        wid = wo_head((D / "workorder" / "folder" / "workorder.md").read_text()).get("WORK-ORDER", "")
    except OSError:
        wid = ""
    left = woc_cleanup_rounds(wid) if wid else []
    fw = D / "workorder" / "folder" / "work"
    if fw.exists():
        shutil.rmtree(fw, ignore_errors=True)
        if fw.exists():
            left.append(str(fw))
    if keep:
        keep = {r.get("copy") for r in woc_returns(D) if r.get("failing") == 0}
        keep = {str(real(pathlib.Path(k))) for k in keep if k}
    else:
        keep = set()
    w = D / "work"
    if w.is_dir():
        for dirpath, dirnames, filenames in os.walk(w, followlinks=False, onerror=lambda e: left.append(str(getattr(e, "filename", dirpath)))):
            for dn in list(dirnames):
                full = pathlib.Path(dirpath) / dn
                try:
                    if not full.is_symlink():
                        os.chmod(full, 0o700)
                except OSError:
                    pass
                if full.is_symlink():
                    try:
                        full.unlink()
                    except OSError:
                        left.append(str(full))
                    else:
                        dirnames.remove(dn)
            for fn in sorted(filenames):
                p = pathlib.Path(dirpath) / fn
                try:
                    if not p.is_symlink():
                        os.chmod(p, 0o600)
                except OSError:
                    pass
                if p.suffix == ".sf-orig":
                    continue
                if p.is_symlink() or (p.is_file() and str(real(p)) not in keep):
                    try:
                        p.unlink()
                    except OSError:
                        left.append(str(p))
        for p in sorted(w.rglob("*.sf-orig")):
            data = p.parent / p.name[:-len(".sf-orig")]
            if p.is_symlink() or not data.exists():
                try:
                    p.unlink()
                except OSError:
                    left.append(str(p))
    left = sorted(set(left))
    if left:
        print(f"CLEANUP-INCOMPLETE {' '.join(left)} (personal data may remain: delete these by hand)")
    return wid, not left


def cmd_wo_cleanup(a):
    """CLEANUP: the model runs this on a stop, a later, or finish (the pass, cap and
    no-progress paths run the same cleanup themselves)."""
    D = pathlib.Path(a.run)
    if not woc_run_is_criteria(D):
        print("CLEANUP-NOT-CRITERIA (a code run has no criteria folders: finish covers its work/)")
        return 1
    wid, ok = woc_cleanup_full(D, keep=False)
    if not wid:
        print("CLEANUP-NO-WORKORDER (no stub workorder.md in the run folder)")
        return 1
    if not ok:
        return 1
    print(f"CLEANUP-OK {wid} (rounds, stub and run copies deleted; records kept)")
    return 0


def woc_sendback(a):
    """Send a criteria folder back: the same locked stub, the returned copy back in work/, Superfix's own FAIL lines."""
    D = pathlib.Path(a.run)
    o = woc_ours(D)
    if o is None:
        return 1
    F, h, *_ = o
    rs = woc_returns(D)
    if not rs or "failing" not in rs[-1]:
        print("SENDBACK-NOT-VERIFIED (run wo-return and wo-verify on the returned work first)")
        return 1
    last = rs[-1]
    if last["failing"] == 0:
        woc_cleanup_full(D)
        print("SENDBACK-NOTHING (the last return passed every check)")
        return 1
    want = real(pathlib.Path.home() / "superfix-workorders" / f"{h['WORK-ORDER']}-r{len(rs) + 1}")
    if real(a.dest) != want:
        print(f"WORKORDER-PATH {a.dest} (criteria send-backs go only to the default path)")
        return 1
    if in_cloud(real(a.dest)):
        print(f"PATH-CLOUD {a.dest} (a synced folder: criteria work orders go only to a local default path)")
        return 1
    hit = woc_symlink_hit(a.dest)
    if hit is not None:
        print(f"WORKORDER-SYMLINK {hit} (a link in the work-order path: use a plain local folder)")
        return 1
    text = woc_body(a)
    base = woc_base_name((F / "workorder.md").read_text()) or "the file"
    if text is None:
        print("WORKORDER-NO-YES (no body given: pass --body or --issue so the Data yes line can be checked)")
        return 1
    if not woc_data_yes(text, base):
        print(f"WORKORDER-NO-YES (no Data yes line for {base} in ## Decision)")
        return 1
    at, sc = getattr(a, "attempts", None), getattr(a, "scripts", None)
    if not at or not sc or woc_body(a) is None:
        print("SENDBACK-NOT-VERIFIED (Superfix's own attempt and progress must be recorded first)")
        return 1
    ns = argparse.Namespace(attempts=at, scripts=sc, body=getattr(a, "body", None), issue=getattr(a, "issue", None))
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            cmd_progress(ns)
    except Stop as e:
        print(str(e))
        return 1
    out = buf.getvalue()
    print(out, end="")
    if "STOP-NO-PROGRESS" in out:
        print("NO-PROGRESS (two returns in a row did not move, from Superfix's own runs: offer 2 or 3)")
        woc_cleanup_full(D)
        return 1
    if "STOP-CAP" in out:
        print("RETURN-CAP (no send-back left: offer 2 or 3)")
        woc_cleanup_full(D)
        return 1
    if "PROGRESS-NONE" in out:
        print("SENDBACK-NOT-VERIFIED (Superfix's own attempt and progress must be recorded first)")
        return 1
    hist = [(r.get("values"), r.get("lock")) for r in rs
            if "failing" in r and isinstance(r.get("values"), dict)]

    def _same(x, y):
        return x[1] == y[1] and x[0] is not None and x[0] == y[0]

    flat_pairs = [_same(hist[k - 1], hist[k]) for k in range(1, len(hist))]
    if len(flat_pairs) >= 2 and flat_pairs[-1] and flat_pairs[-2]:
        print("NO-PROGRESS (two returns in a row did not move, from Superfix's own runs: offer 2 or 3)")
        woc_cleanup_full(D)
        return 1
    dest = wo_dest(a.dest)
    if dest is None:
        return 1
    base = woc_copy_file((F / "workorder.md").read_text(), F).name
    woc_copy_folder(F, dest, (F / "workorder.md").read_text())
    shutil.copy2(last["copy"], dest / "work" / base)
    (dest / "sendback.md").write_text(f"# Sent back: round {len(rs) + 1}, {last['n']} of {WO_LIMIT} attempts used\n"
                                      "Superfix's own runs at your last copy:\n```\n"
                                      + "\n".join(last.get("lines", [])) + "\n```\n")
    woc_lock_modes(dest)
    print(f"SENDBACK-READY {dest} (round {len(rs) + 1}; {last['n']} of {WO_LIMIT} attempts used)")
    return 0


def cmd_wo_check(a):
    """WORKORDER: is this work order complete, fresh, and its CHECKS the locked ones?"""
    t = pathlib.Path(a.wo).read_text()
    if wo_head(t).get("CHECKS-KIND") == "criteria":
        return woc_check(a, t)
    lines, bad = t.splitlines(), []
    for k in WO_REQUIRED:
        n = sum(1 for l in lines if l.startswith(k + ": "))
        if n != 1:
            bad.append(f"WORKORDER-MISSING {k} (found {n} times)")
    h = wo_head(t)
    if h.get("CHECKS-KIND") and h["CHECKS-KIND"] not in WO_KINDS:
        print(f"WORKORDER-KIND {h['CHECKS-KIND']}")
        return 1
    rep = t.find("\n## Report")
    for n, l in enumerate(t[:rep if rep >= 0 else len(t)].splitlines(), 1):
        if re.search(r"<[^<>\s][^<>]*>", re.sub(r"<(word|n|k|why)>", "", l)) and not l.lstrip().startswith(("#", "r(){", "o=", "t=")):
            bad.append(f"WORKORDER-NOT-FRESH line {n} (a placeholder outside ## Report)")
        if re.search(r"^\s*- \[[xX]\]", l):
            bad.append(f"WORKORDER-NOT-FRESH line {n} (a ticked box)")
    if not re.search(r"(?m)^- \[ \] ", t):
        bad.append("WORKORDER-NOT-FRESH (no unticked step)")
    blk = wo_block(t)
    locked = pathlib.Path(a.check).read_text() if a.check else None
    if blk is None or sha_text(blk) != h.get("CHECKS-SHA") or (locked is not None and sha_text(locked) != h.get("CHECKS-SHA")):
        bad.append("WORKORDER-CHECKS-SHA (the CHECKS block, CHECKS-SHA and the locked check.sh differ)")
    steps = re.search(r"(?ms)^## Checklist.*?(?=^## )", t)
    steps = steps.group(0) if steps else ""
    ids = []
    for m in R_CALL.finditer(blk or ""):
        i, exp = m.group(1), m.group(2)[1:-1]
        ids.append(i)
        if exp not in steps:
            bad.append(f"WORKORDER-EXPECTED-NOT-IN-STEPS {i}")
    base_ids = re.findall(r"([CK]\d+) (?:PASS|FAIL)", h.get("BASELINE", ""))
    for i in ids:
        if i not in base_ids:
            bad.append(f"WORKORDER-NOT-IN-BASELINE {i}")
    for m in re.finditer(r"(?m)^B=([0-9a-f]{40});", t):
        if m.group(1) != h.get("BASE"):
            bad.append("WORKORDER-STEP0 (Step 0's base is not BASE)")
    if h.get("CHECKS-SHA") and h["CHECKS-SHA"] not in t.split("## Step 0", 1)[-1].split("## Checklist", 1)[0]:
        bad.append("WORKORDER-STEP0 (Step 0 does not check CHECKS-SHA)")
    if a.clone and h.get("BASE"):
        for f, new in wo_files(t):
            there = git(a.clone, "cat-file", "-e", f"{h['BASE']}:{f}")[0] == 0
            if new and there:
                bad.append(f"WORKORDER-NEW-EXISTS {f} (marked (new) but it is at BASE)")
            if not new and not there:
                bad.append(f"WORKORDER-FILE-NOT-AT-BASE {f} (mark it (new), or fix the name)")
    print("\n".join(dict.fromkeys(bad)) if bad else "WORKORDER-OK")
    return 1 if bad else 0


def wo_ids(D):
    """The ids each locked script must print: check.sh's from the BASELINE line, held.sh's from its own r calls (never from output)."""
    W = pathlib.Path(D) / "workorder"
    base = re.findall(r"([CK]\d+) (?:PASS|FAIL)", wo_head((W / "workorder.md").read_text()).get("BASELINE", ""))
    held = [m.group(1) for m in R_CALL.finditer((W / "held.sh").read_text())] if (W / "held.sh").exists() else []
    return {"check.sh": base, "held.sh": held}


def wo_run_checks(D, wt, timeout=300):
    """check.sh and held.sh in the sandbox, passed as text (bash -c), so no run-folder path is in argv and the code under
    test cannot read held.sh. A missing held.sh, or a copy that differs from its lock, stops the run loudly."""
    W, runs = pathlib.Path(D) / "workorder", {}
    lock = {n: s for s, n in (l.split("  ", 1) for l in (W / "lock").read_text().splitlines() if "  " in l)} if (W / "lock").exists() else {}
    for f in ("check.sh", "held.sh"):
        if not (W / f).is_file():
            raise Stop(f"VERIFY-FAIL {f} is missing from the run folder (nothing passes without it)")
        if f in lock and sha_file(W / f) != lock[f]:
            raise Stop(f"RETURN-OURS-CHANGED ({f} differs from its lock: stop)")
        runs[f] = sandbox_run(wt, ["/bin/bash", "-c", (W / f).read_text()], timeout)
    return runs


def check_words(run, ids):
    """One run of a locked script: exactly one CHECK line per expected id, no other id, exit 0.
    Returns ({id: PASS or FAIL}, [problems], [raw CHECK lines])."""
    rc, why, out = run
    got, bad, raw = {}, [], []
    if why or rc != 0:
        bad.append(f"run {why or 'exit ' + str(rc)}")
    for m in dict.fromkeys(re.findall(r"(?m)(\S+): command not found$|^(.*?): ?Operation not permitted$", out)):
        bad.append(f"sandbox refused {m[0] or m[1][-60:]} (the script needs a tool or path the sandbox lacks: rewrite it)")
    for l in out.splitlines():
        m = re.fullmatch(r"CHECK (\S+) (?:(PASS)|(FAIL)(?: .*)?)", l)
        if not m:
            continue
        raw.append(l)
        i = m.group(1)
        if i not in ids:
            bad.append(f"{i} (not expected)")
        elif i in got:
            bad.append(f"{i} (twice)")
        else:
            got[i] = m.group(2) or m.group(3)
    bad += [f"{i} (missing)" for i in ids if i not in got]
    if not ids:
        bad.append("no ids to check")
    return got, bad, raw


def worktree(clone, sha):
    wt = real(tempfile.mkdtemp(prefix="wo-wt-", dir="/private/tmp" if os.path.isdir("/private/tmp") else None)) / "wt"
    rc, _ = git(clone, "worktree", "add", "-q", "--detach", str(wt), sha)
    if rc:
        raise Stop(f"WORKTREE-FAILED {sha[:12]}")
    return wt


def drop_worktree(clone, wt):
    git(clone, "worktree", "remove", "--force", str(wt)); git(clone, "worktree", "prune")
    shutil.rmtree(wt.parent, ignore_errors=True)


def cmd_wo_baseline(a):
    """BASELINE: solved-check run 1 at the base: the locked check.sh in the sandbox gives exactly BASELINE, every held-back check FAILs."""
    if getattr(a, "folder", None) and woc_folder_is_criteria(a.folder):
        return woc_baseline(a)
    rc = woc_need_clone(a, "wo-baseline")
    if rc:
        return rc
    D = pathlib.Path(a.run)
    h = wo_head((D / "workorder/workorder.md").read_text())
    ids = wo_ids(D)
    wt = worktree(a.clone, h["BASE"])
    try:
        runs = wo_run_checks(D, wt)
    finally:
        drop_worktree(a.clone, wt)
    if any(r[1] == "missing" for r in runs.values()):
        print("SANDBOX-MISSING (nothing ran; ask the owner the criteria-mode sandbox question first)")
        return 1
    want = dict(re.findall(r"([CK]\d+) (PASS|FAIL)", h["BASELINE"]))
    got, bad, _ = check_words(runs["check.sh"], ids["check.sh"])
    bad = [i for i in want if i in got and got[i] != want[i]] + bad
    hg, hb, _ = check_words(runs["held.sh"], ids["held.sh"])
    bad += [f"held.sh {x}" for x in hb] + [f"{i} (a held-back check passes at the base)" for i, v in hg.items() if v == "PASS"]
    print("BASELINE-OK" if not bad else "BASELINE-MISMATCH " + ", ".join(bad))
    return 1 if bad else 0


def decision_shas(text):
    # the " (sha256)" suffix is optional: T4 run v1-16 copied the lines without it and got RETURN-OURS-CHANGED
    w = re.findall(r"(?m)^Internal: workorder-sha ([0-9a-f]{64})\b", text)
    c = re.findall(r"(?m)^Internal: checks-sha ([0-9a-f]{64})\b", text)
    return (w[-1] if w else None, c[-1] if c else None)


def wo_dest(dest):
    """A work order folder is new or empty and outside ~/.superfix (the run folders, held.sh and crit.py live there)."""
    d = real(dest)
    sf = real(pathlib.Path.home() / ".superfix")
    if d == sf or sf in d.parents:
        print(f"WORKORDER-DEST-INSIDE-SUPERFIX {d} (an executor there sits beside held.sh and the lock; use ~/superfix-workorders/<id>/)")
        return None
    d.mkdir(parents=True, exist_ok=True)
    if any(d.iterdir()):
        print(f"WORKORDER-DEST-NOT-EMPTY {d} (use a new folder)")
        return None
    return d


def cmd_wo_lock(a):
    """WORKORDER and BASELINE again, then lock the run folder's copies (shasum format), copy workorder.md to the destination, print the sha lines."""
    if getattr(a, "folder", None) and woc_folder_is_criteria(a.folder):
        return woc_lock(a)
    rc = woc_need_clone(a, "wo-lock")
    if rc:
        return rc
    W = pathlib.Path(a.run) / "workorder"
    files = [f for f in ("workorder.md", "check.sh", "held.sh") if (W / f).exists()]
    if files != ["workorder.md", "check.sh", "held.sh"]:
        print("WORKORDER-LOCK-REFUSED (the run folder's workorder/ needs workorder.md, check.sh and held.sh)")
        return 1
    if in_cloud(a.dest) and not a.asked:
        print(f"PATH-CLOUD {a.dest} (a synced folder needs the owner's explicit yes, then add --asked)")
        return 1
    if cmd_wo_check(argparse.Namespace(wo=str(W / "workorder.md"), check=str(W / "check.sh"), clone=a.clone, run=a.run)) \
            or cmd_wo_baseline(argparse.Namespace(run=a.run, clone=a.clone)):
        print("WORKORDER-LOCK-REFUSED (WORKORDER and BASELINE must both be OK)")
        return 1
    dest = wo_dest(a.dest)
    if dest is None:
        return 1
    (W / "lock").write_text("".join(f"{sha_file(W / f)}  {f}\n" for f in files))
    shutil.copy2(W / "workorder.md", dest / "workorder.md")
    ws, cs = sha_file(W / "workorder.md"), sha_file(W / "check.sh")
    if sha_file(dest / "workorder.md") != ws:
        print("WORKORDER-COPY-FAILED")
        return 1
    print(f"Internal: workorder-sha {ws} (sha256)")
    print(f"Internal: checks-sha {cs} (sha256)")
    print(f"Give this line to the executor separately: WORKORDER-SHA {ws} (sha256)")
    print(f"WORKORDER-LOCKED {dest / 'workorder.md'}")
    return 0


def rounds(D):
    p = pathlib.Path(D) / "workorder" / "rounds.json"
    return json.loads(p.read_text()) if p.exists() else []


def save_round(D, H, **kv):
    """One entry per returned H, in order: its attempts (wo-return, wo-files) and Superfix's own failing count (wo-verify)."""
    rs = rounds(D)
    r = next((r for r in rs if r["H"] == H), None)
    if r is None:
        rs.append(r := {"H": H})
    r.update(kv)
    (pathlib.Path(D) / "workorder" / "rounds.json").write_text(json.dumps(rs, indent=1) + "\n")


def wo_shared(a):
    """The shared return steps: our locked copies, their lock and the newest ## Decision shas agree; the kind has a row;
    the returned folder holds no symlink or hard link (a link to ~/.config would be committed and echoed). None on a stop."""
    D, F = pathlib.Path(a.run), real(a.folder)
    ws, cs = decision_shas(body_text(a))
    W = D / "workorder"
    if not (W / "lock").exists():
        print("RETURN-NO-LOCK (the run folder is gone: say so, use the ## Decision shas, ask for any password again)")
        return None
    lock = {n: s for s, n in (l.split("  ", 1) for l in (W / "lock").read_text().splitlines() if "  " in l)}
    if not ws or not cs or lock.get("workorder.md") != ws or lock.get("check.sh") != cs \
            or any(not (W / n).exists() or sha_file(W / n) != s for n, s in lock.items()):
        print("RETURN-OURS-CHANGED (our locked copies, their lock and the newest ## Decision shas do not agree: stop)")
        return None
    t = (W / "workorder.md").read_text()
    h = wo_head(t)
    if h.get("CHECKS-KIND") not in WO_KINDS:
        print(f"RETURN-KIND-UNKNOWN {h.get('CHECKS-KIND')}")
        return None
    links = sorted(os.path.relpath(os.path.join(r, n), F) for r, ds, fs in os.walk(F) for n in ds + fs
                   if stat.S_ISLNK((s := os.lstat(os.path.join(r, n))).st_mode) or (stat.S_ISREG(s.st_mode) and s.st_nlink > 1))
    if links:
        print("RETURN-SYMLINK " + " ".join(links) + " (a link in the returned folder: nothing read or committed; ask for a plain copy)")
        return None
    return D, F, t, h


def wo_attempts(a, D, B, H):
    """Attempts = the larger of the git count and the last recorded return's attempts plus one; the next H must build on
    the last recorded H (a squash or a restart at BASE resets the git count). Returns (n, words, stop)."""
    rs = [r for r in rounds(D) if r["H"] != H]
    if rs and git(a.clone, "merge-base", "--is-ancestor", rs[-1]["H"], H)[0]:
        return 0, [f"RETURN-NOT-BUILT-ON {rs[-1]['H']} (round {len(rs) + 1} must carry on from the last returned work; a squash or a restart is refused)"], True
    rc, n = git(a.clone, "rev-list", "--count", f"{B}..{H}")
    n = max(int(n or 0), rs[-1].get("attempts", len(rs)) + 1 if rs else 1)
    if n > WO_LIMIT:
        return n, [f"RETURN-CAP {n} of {WO_LIMIT} attempts used (over the limit: stop)"], True
    return n, [f"RETURN-CAP {n} of {WO_LIMIT} attempts used (no send-back left)"] if n == WO_LIMIT else [], False


def cmd_wo_return(a):
    """RETURN: the shared steps, then the code step: one resolved H, built on the last returned H, attempts counted."""
    if getattr(a, "run", None) and woc_run_is_criteria(pathlib.Path(a.run)):
        if getattr(a, "folder", None):
            rf = pathlib.Path(real(a.folder)) / "workorder.md"
            if rf.is_file():
                try:
                    kind = wo_head(rf.read_text()).get("CHECKS-KIND")
                except (OSError, UnicodeDecodeError):
                    kind = None
            else:
                kind = "criteria"
            if kind != "criteria":
                print("RETURN-OURS-CHANGED (the returned workorder.md is unreadable or its kind differs from our lock: stop)")
                return 1
        return woc_return(a)
    if getattr(a, "folder", None) and woc_folder_is_criteria(a.folder):
        if getattr(a, "run", None) and not woc_run_is_criteria(pathlib.Path(a.run)):
            print("RETURN-OURS-CHANGED (the returned folder says criteria but our run is not a criteria run: stop)")
            return 1
        return woc_return(a)
    rc = woc_need_clone(a, "wo-return")
    if rc:
        return rc
    s = wo_shared(a)
    if s is None:
        return 1
    D, F, t, h = s
    B, BR = h["BASE"], h["BRANCH"]
    if a.patch:
        wt = worktree(a.clone, B)
        rc, _ = git(wt, "apply", "--index", str(real(a.patch)))
        rc2, _ = git(wt, "-c", "user.name=superfix", "-c", "user.email=superfix@localhost", "commit", "-q", "-m", "returned as a patch")
        rc3, H = git(wt, "rev-parse", "HEAD")
        drop_worktree(a.clone, wt)
        if rc or rc2:
            print("RETURN-PATCH-FAILED")
            return 1
    else:
        src = str(F / "return.bundle") if (F / "return.bundle").exists() else None
        if not src and not a.remote_branch:
            print("RETURN-NO-WORK (no return.bundle: if changed files came back, use wo-files)")
            return 1
        if src:
            rc, _ = git(a.clone, "bundle", "verify", src)
            if rc:
                print("RETURN-BUNDLE-BAD")
                return 1
        rc, _ = git(a.clone, "fetch", "-q", src or "origin", f"+refs/heads/{BR}:refs/wo/{BR}")
        if rc:
            print(f"RETURN-NO-BRANCH {BR}")
            return 1
        rc, H = git(a.clone, "rev-parse", f"refs/wo/{BR}")
    rc, mb = git(a.clone, "merge-base", B, H)
    if mb != B:
        print("RETURN-WRONG-BASE (the work does not start at BASE)")
        return 1
    words = []
    if not a.remote_branch:
        try:
            r = subprocess.run(["git", "-C", str(a.clone), "ls-remote", "origin", f"refs/heads/{BR}"], capture_output=True, text=True,
                               timeout=60, env={**os.environ, "GIT_TERMINAL_PROMPT": "0"})
            words.append(f"RETURN-PUSHED {BR} {r.stdout.split()[0]} (DELIVER said do not push: tell the owner)" if r.returncode == 0 and r.stdout.strip()
                         else "RETURN-REMOTE-UNCHECKED (git ls-remote origin failed: say so)" if r.returncode else None)
        except subprocess.TimeoutExpired:
            words.append("RETURN-REMOTE-UNCHECKED (git ls-remote origin timed out: say so)")
    n, aw, stop = wo_attempts(a, D, B, H)
    words = [w for w in words if w] + aw
    if stop:
        print("\n".join(words))
        return 1
    save_round(D, H, attempts=n)
    rc, ch = git(a.clone, "diff", "--name-only", f"{B}...{H}")
    over = sorted(set(ch.split()) - {f for f, _ in wo_files(t)})
    if over:
        words.append("RETURN-FILES-OVER " + " ".join(over))
    print("\n".join(words + [f"RETURN-{'OK' if not over else 'CHECKED'} H {H} attempts {n}"]))
    return 1 if over else 0


def tap_names(wt, timeout=300):
    """node --test in the sandbox: {name: (skipped or todo, failed)}, indented subtests included; None if the run broke."""
    rc, why, out = sandbox_run(wt, ["/bin/bash", "-c", "node --test --test-reporter=tap"], timeout)
    if why or not re.search(r"(?m)^# tests \d+$", out):
        return None
    return {m.group(2): (bool(m.group(3)), bool(m.group(1)))
            for m in re.finditer(r"(?m)^\s*(not )?ok \d+ - (.+?)( # (?:SKIP|TODO)\b.*)?$", out)}


def cmd_wo_verify(a):
    """Superfix's own runs at H: the locked check.sh, the held-back checks, the test names and the suite, in the sandbox.
    Records Superfix's failing count for H (the send-back and NO-PROGRESS read it)."""
    D = pathlib.Path(a.run)
    if woc_run_is_criteria(D):
        return woc_verify(a)
    rc = woc_need_clone(a, "wo-verify")
    if rc:
        return rc
    h = wo_head((D / "workorder/workorder.md").read_text())
    ids = wo_ids(D)
    base = worktree(a.clone, h["BASE"])
    try:
        names_base = tap_names(base, a.timeout)
    finally:
        drop_worktree(a.clone, base)
    wt = worktree(a.clone, a.head)
    try:
        runs = wo_run_checks(D, wt, a.timeout)
        names_h = tap_names(wt, a.timeout)
    finally:
        drop_worktree(a.clone, wt)
    if any(r[1] == "missing" for r in runs.values()):
        print("SANDBOX-MISSING (nothing ran)\nVERIFY-FAIL")
        return 1
    cg, cb, craw = check_words(runs["check.sh"], ids["check.sh"])
    hg, hb, hraw = check_words(runs["held.sh"], ids["held.sh"])
    out = craw + hraw + [f"VERIFY-PROBLEM {f}: " + ", ".join(b) for f, b in (("check.sh", cb), ("held.sh", hb)) if b]
    failing = [i for k in ("check.sh", "held.sh") for i in ids[k] if {**cg, **hg}.get(i) != "PASS"]
    if names_base is None or names_h is None:
        out.append("VERIFY-PROBLEM node --test did not finish (no test names to compare)")
        failing.append("suite")
    else:
        gone = sorted(n for n in names_base if n not in names_h or names_h[n][0])
        new = sorted(n for n, (sk, bad) in names_h.items() if bad and not sk and not names_base.get(n, (0, 0))[1])
        out.append("TESTNAMES-OK" if not gone else "RETURN-TESTS-DROPPED " + ", ".join(gone))
        out.append("SUITE-OK (no test fails at H that passed at BASE)" if not new else "SUITE-NEW-FAILURES " + ", ".join(new))
        failing += gone + new
    ok = not cb and not hb and not failing
    keep = [l if not l.startswith("CHECK H") or l.endswith(" PASS") else " ".join(l.split()[:3]) + " (held back)" for l in out]
    save_round(D, a.head, failing=len(failing), lines=[l for l in keep if " FAIL" in l or l.startswith(("VERIFY-PROBLEM", "RETURN-", "SUITE-NEW"))])
    print("\n".join(out + ["VERIFY-PASS (then wo-solved: runs 1 and 3)" if ok else "VERIFY-FAIL"]))
    return 0 if ok else 1


def cmd_wo_solved(a):
    """SKILL.md's solved check runs 1 and 3 at H, in the sandbox: run 1 is BASE with H's test files, run 3 is H with its
    non-test changes reverted (outside the sandbox). Each must give exactly one CHECK FAIL per C, PASS per K, exit 0:
    a crash or a timeout is never 'failed as expected'."""
    D = pathlib.Path(a.run)
    if woc_run_is_criteria(D):
        print("WO-SOLVED-NOT-FOR-CRITERIA (a criteria return has no commit: run the section 15 three runs with your own 1.5.0 commands)")
        return 1
    rc = woc_need_clone(a, "wo-solved")
    if rc:
        return rc
    h = wo_head((D / "workorder/workorder.md").read_text())
    B, ids, bad = h["BASE"], wo_ids(D), []
    tests = ["--", "test", "tests", ":(glob)**/*.test.*"]
    for run, sha in (("RUN1", B), ("RUN3", a.head)):
        wt = worktree(a.clone, sha)
        try:
            if run == "RUN1":
                rc, names = git(a.clone, "diff", "--name-only", "--diff-filter=d", f"{B}..{a.head}", *tests)
                if names:
                    git(wt, "checkout", a.head, "--", *names.split())
            else:
                d = subprocess.run(["git", "-C", str(wt), "diff", f"{B}..{a.head}", "--", ".", ":!test", ":!tests", ":!*.test.*"], capture_output=True)
                if d.stdout and subprocess.run(["git", "-C", str(wt), "apply", "-R"], input=d.stdout, capture_output=True).returncode:
                    raise Stop(f"SOLVED-{run}-BROKEN (the revert did not apply)")
            got, probs, _ = check_words(wo_run_checks(D, wt, a.timeout)["check.sh"], ids["check.sh"])
        finally:
            drop_worktree(a.clone, wt)
        wrong = [i for i in ids["check.sh"] if i in got and got[i] != ("FAIL" if i[0] == "C" else "PASS")]
        if probs:
            bad.append(f"SOLVED-{run}-BROKEN " + ", ".join(probs))
        if wrong:
            bad.append(f"SOLVED-{run}-PASSES " + ", ".join(wrong) + " (a check that passes here does not detect the problem: fix the check)")
    print("\n".join(bad) if bad else "SOLVED-OK (run 1 and run 3 fail as they should)")
    return 1 if bad else 0


def cmd_wo_sendback(a):
    """Send it back: a fresh folder with the same locked workorder.md (its sha stays valid), the last returned work as
    return.bundle (Step 0 carries on from it) and Superfix's own failure lines (held-back ones by id only). Refused at the
    cap, with no progress, or before Superfix's own runs."""
    D = pathlib.Path(a.run)
    if woc_run_is_criteria(D):
        return woc_sendback(a)
    rc = woc_need_clone(a, "wo-sendback")
    if rc:
        return rc
    W, rs = D / "workorder", rounds(D)
    if not rs or "failing" not in rs[-1] or "attempts" not in rs[-1]:
        print("SENDBACK-NOT-VERIFIED (run wo-return and wo-verify on the returned work first)")
        return 1
    last = rs[-1]
    f = [r["failing"] for r in rs if "failing" in r]
    if last["failing"] == 0:
        print("SENDBACK-NOTHING (the last return passed every check)")
        return 1
    if last["attempts"] >= WO_LIMIT:
        print(f"RETURN-CAP {last['attempts']} of {WO_LIMIT} attempts used (no send-back left: offer 2 or 3)")
        return 1
    if len(f) >= 2 and f[-1] >= f[-2]:
        print(f"NO-PROGRESS (failing {f[-2]} then {f[-1]}, from Superfix's own runs: offer 2 or 3)")
        return 1
    lock = {n: s for s, n in (l.split("  ", 1) for l in (W / "lock").read_text().splitlines() if "  " in l)}
    if sha_file(W / "workorder.md") != lock.get("workorder.md"):
        print("RETURN-OURS-CHANGED (workorder.md differs from its lock: stop)")
        return 1
    dest = wo_dest(a.dest)
    if dest is None:
        return 1
    h = wo_head((W / "workorder.md").read_text())
    shutil.copy2(W / "workorder.md", dest / "workorder.md")
    git(a.clone, "update-ref", f"refs/heads/{h['BRANCH']}", last["H"])
    rc, _ = git(a.clone, "bundle", "create", str(dest / "return.bundle"), f"{h['BASE']}..{h['BRANCH']}")
    if rc:
        print("SENDBACK-BUNDLE-FAILED")
        return 1
    (dest / "sendback.md").write_text(f"# Sent back: round {len(rs) + 1}, {last['attempts']} of {WO_LIMIT} attempts used\n"
                                      "Superfix's own runs at your last commit (held-back checks by id only):\n```\n"
                                      + "\n".join(last.get("lines", [])) + "\n```\n")
    print(f"SENDBACK-READY {dest} (round {len(rs) + 1}; {last['attempts']} of {WO_LIMIT} attempts used)")
    return 0


def cmd_wo_files(a):
    """The files row: after the shared steps, changed FILES that came back as plain files are committed as one attempt on
    the last returned H (BASE in round 1); anything else is named and ignored."""
    if getattr(a, "folder", None) and woc_folder_is_criteria(a.folder):
        print("RETURN-NO-WORK (kind criteria carries work/<file> inside the folder; use wo-return)")
        return 1
    rc = woc_need_clone(a, "wo-files")
    if rc:
        return rc
    s = wo_shared(a)
    if s is None:
        return 1
    D, F, t, h = s
    files = [f for f, _ in wo_files(t)]
    got = [f for f in files if (F / f).is_file()]
    other = sorted(str(p.relative_to(F)) for p in F.rglob("*") if p.is_file() and str(p.relative_to(F)) not in files
                   and p.name not in ("workorder.md", "check.sh", "return.bundle", "report.md", "sendback.md"))
    if not got:
        print("RETURN-NO-WORK (no FILES came back)")
        return 1
    rs = rounds(D)
    wt = worktree(a.clone, rs[-1]["H"] if rs else h["BASE"])
    for f in got:
        (wt / f).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(F / f, wt / f, follow_symlinks=False)
    git(wt, "add", "--", *got)
    git(wt, "-c", "user.name=superfix", "-c", "user.email=superfix@localhost", "commit", "-q", "--allow-empty", "-m", f"round {len(rs) + 1}: returned as files")
    rc2, H = git(wt, "rev-parse", "HEAD")
    drop_worktree(a.clone, wt)
    n, words, stop = wo_attempts(a, D, h["BASE"], H)
    if stop:
        print("\n".join(words))
        return 1
    save_round(D, H, attempts=n)
    git(a.clone, "update-ref", f"refs/wo/{h['BRANCH']}", H)
    print("\n".join(([f"RETURN-IGNORED {' '.join(other)}"] if other else []) + words + [f"RETURN-FILES {len(got)} H {H} attempts {n}"]))
    return 0


# ---------- send check (tests: S13): an ALLOWLIST plus a text scan; best-effort ----------

TOOL_OK = {"Read", "Grep", "Glob", "LS", "Skill", "Agent", "Task", "TodoWrite", "ToolSearch", "AskUserQuestion", "SubagentHandback"}
WRITE_TOOLS = {"Write", "Edit", "MultiEdit", "NotebookEdit"}
MCP_PREFIX = ("get_", "list_", "read_", "search_", "describe_", "preview_", "count_", "summarise_")
MCP_DENY = re.compile(r"search_custom|search_web|websearch|webfetch|artifact|upload|publish|create|send|update|delete|copy|share|move|checkout|find_or_upload", re.I)
TEXT_TOOLS = {"cat", "ls", "grep", "egrep", "fgrep", "sed", "head", "tail", "wc", "diff", "mkdir", "cp", "echo", "printf", "test", "[",
              "true", "false", "cd", "umask", "chmod", "mktemp", "tr", "cut", "sort", "uniq", "awk", "perl", "shasum", "date", "base64",
              "rm", "mv", "touch", "find", "tee", "jq", "basename", "dirname", "realpath", "stat", "file", "sleep", "pwd", "export", "exit",
              "node", "npm", "pytest", "git", "gh", "python3", "python", "rmdir", "type", "read", "set", "unset", "local", "return", "break", "continue"}
PREFIXES = {"command", "builtin", "env", "exec", "time", "nohup", "xargs", "eval", "source", ".", "sudo", "nice", "timeout", "caffeinate"}
NETWORDS = re.compile(r"(?<![\w.~/-])(curl|wget|nc|ncat|netcat|ssh|scp|sftp|rsync|ftp|telnet|dig|nslookup|host|ping|socat|osascript|sendmail|mailx)(?![\w-])"
                      r"|(?<![\w-])mail(?![\w-])|openssl\s+s_client|pbcopy[^\n]*\bopen\b|\bopen\b[^\n]*pbcopy")
NET_HINT = re.compile(r"\b(socket|urllib|http\.client|requests|smtplib|ftplib|telnetlib|subprocess|os\.system|os\.popen|webbrowser|asyncio|__import__)\b")
KEYWORDS = {"if", "then", "else", "elif", "fi", "for", "do", "done", "while", "until", "case", "esac", "in", "!", "{", "}", "function"}
CLOUD_PATH = re.compile(r"(?i)Library/CloudStorage|Library/Mobile Documents|com~apple~CloudDocs|(~|\$HOME|\$\{HOME\}|/Users/[^/\s'\"]+)/(shared-drives|Dropbox|Google Drive|OneDrive)(/|\b)")
WRITE_CMDS = {"cp", "mv", "ln", "tee", "rsync", "ditto", "install", "touch", "mkdir", "rm", "rmdir"}


def heredocs(c):
    """(command text without heredoc bodies, [bodies])."""
    out, bodies, end, cur = [], [], None, []
    for l in c.split("\n"):
        if end is not None:
            if l.strip() == end:
                bodies.append("\n".join(cur)); end, cur = None, []
            else:
                cur.append(l)
            continue
        m = re.search(r"<<-?\s*['\"]?([A-Za-z_][A-Za-z0-9_]*)['\"]?", l)
        out.append(l)
        if m and "<<<" not in l:
            end = m.group(1)
    if end is not None:
        bodies.append("\n".join(cur))
    return "\n".join(out), bodies


def segments(c):
    """Simple commands, split on ; | & && || ( ) and newlines, quotes respected (shlex), with $( and ` as breaks."""
    c = c.replace("$(", " ( ").replace("`", " ; ").replace("\n", " ; ")
    try:
        lx = shlex.shlex(c, posix=True, punctuation_chars=";&|()")
        lx.whitespace_split = True
        toks = list(lx)
    except ValueError:
        toks = c.split()
    cur = []
    for t in toks + [";"]:
        if t and set(t) <= set(";&|()"):
            while cur and (re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", cur[0]) or cur[0] in KEYWORDS):
                cur = cur[1:]
            if cur:
                yield cur
            cur = []
        else:
            cur.append(t)


def path_ok(p, dirs):
    if CLOUD_PATH.search(p):
        return False
    if p.startswith(("$", "~/.superfix", "/dev/null")) or not p.startswith(("/", "~")):
        return True
    return any(inside(p, d) for d in dirs) and not in_cloud(p)


def var_repos(c, repos):
    """Shell variables set in the same command to the work repo or the gap repo; $R is the skill's own name for the work repo."""
    ok = {"R"}
    for m in re.finditer(r"(?:^|[\s;])([A-Za-z_][A-Za-z0-9_]*)=['\"]?([A-Za-z0-9-]+/[A-Za-z0-9._-]+)['\"]?(?=[\s;]|$)", c):
        if m.group(2).lower() in repos:
            ok.add(m.group(1))
    return ok


def repo_ok(v, repos, okvars):
    m = re.fullmatch(r"\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?", v)
    return v.lower() in repos or bool(m and m.group(1) in okvars)


def gh_ok(t, repos, okvars):
    for k, x in enumerate(t):
        if x == "--hostname" or x.startswith("--hostname="):
            return False, "gh --hostname"
        v = x.split("=", 1)[1] if x.startswith(("--repo=", "-R=")) else (t[k + 1] if x in ("--repo", "-R") and k + 1 < len(t) else None)
        if v is not None and not repo_ok(v, repos, okvars):
            return False, "gh against another repo"
    sub = [x for x in t[1:] if not x.startswith("-")][:2]
    if not sub:
        return False, "gh without a subcommand"
    allowed = {("issue", "view"), ("issue", "comment"), ("issue", "edit"), ("issue", "list"), ("issue", "create"),
               ("pr", "view"), ("pr", "create"), ("pr", "checks"), ("pr", "list"), ("pr", "diff"),
               ("label", "create"), ("label", "list"), ("repo", "view")}
    if sub[0] == "api":
        valued = {"-X", "--method", "-F", "-f", "--field", "--raw-field", "-H", "--header", "-q", "--jq", "-t", "--template", "--input", "-p", "--preview", "--cache"}
        rest, path, skip = t[t.index("api") + 1:], "", False
        for x in rest:
            if skip:
                skip = False
                continue
            if x in valued:
                skip = True
                continue
            if not x.startswith("-"):
                path = x
                break
        m = re.match(r"^/?repos/([^/]+/[^/?]+)(/.*)?$", path)
        if m and not (m.group(1).lower() in repos or re.fullmatch(r"\$\{?R\}?|\$\{?[A-Za-z_]\w*\}?", m.group(1)) and repo_ok(m.group(1), repos, okvars)):
            return False, "gh api against another repo"
        meth = [t[k + 1].upper() for k, x in enumerate(t[:-1]) if x in ("-X", "--method")]
        fields = [x for x in t if x in ("-f", "-F", "--field", "--raw-field", "--input") or (x.startswith(("-f", "-F")) and len(x) > 2)]
        if meth == ["PATCH"]:
            # the one write: the decision comment, edited by its id on the work repo (journal.md)
            if m and re.fullmatch(r"/issues/comments/\d+", m.group(2) or "") and [x for x in t if x.startswith("body=@")] and fields in (["-F"], ["--field"]):
                return True, ""
            return False, "gh api PATCH other than the decision comment's body"
        if meth and meth != ["GET"]:
            return False, "gh api with a write method"
        if fields:
            return False, "gh api with fields (a write)"
        return True, ""
    if tuple(sub[:2]) not in allowed:
        return False, f"gh {' '.join(sub[:2])}"
    if sub[:2] == ["issue", "comment"] and any(x == "--edit-last" for x in t):
        return False, "gh issue comment --edit-last (edit by comment id)"
    return True, ""


def python_ok(t, locked):
    rest = t[1:]
    if rest[:1] != ["-I"]:
        return False
    if len(rest) > 1 and rest[1] == "-":
        return True                                  # its heredoc body gets the text scan
    if len(rest) > 2 and rest[1] == "-m" and rest[2] in ("pytest", "unittest"):
        return True
    if len(rest) > 1 and not rest[1].startswith("-"):
        p = rest[1].replace("${HOME}", str(pathlib.Path.home())).replace("$HOME", str(pathlib.Path.home()))
        if re.search(r"/\.superfix/(runs/[^/]+|journal/[^/]+/criteria/[^/]+)/crit\.py$", p):
            if locked.get("crit") and os.path.exists(p) and sha_file(p) != locked["crit"]:
                return False
            return not (len(rest) > 2 and rest[2] == "remind")
        mm = re.search(r"/measure-(P\d+-[CK]\d+)\.py$", p)
        if mm and locked.get("scripts") and os.path.exists(p) and sha_file(p) == locked["scripts"].get(mm.group(1)):
            return True
    return False


def bash_hits(c, repos, dirs, locked):
    hits, review = [], []
    body, docs = heredocs(c)
    if NETWORDS.search(c):                                   # the WHOLE text: heredoc bodies and quoted strings too
        hits.append(f"network or send word {NETWORDS.search(c).group(0).split()[0]}")
    if "<<<" in c:
        hits.append("here-string <<<")
    if re.search(r"\bcd\s+['\"]?[^;&|\n]*", body) and any(CLOUD_PATH.search(x) for x in re.findall(r"\bcd\s+([^;&|\n]+)", body)):
        hits.append("cd into a cloud folder")
    if CLOUD_PATH.search(c) and (re.search(r"(?<![<0-9&])>>?", body) or any(t and os.path.basename(t[0]) in WRITE_CMDS for t in segments(body))):
        hits.append("write that names a cloud folder")
    okvars = var_repos(c, repos)
    py_dash = False
    for t in segments(body):
        cmd = os.path.basename(t[0])
        if t[0] in PREFIXES or cmd in PREFIXES:
            hits.append(f"prefix {t[0]} hides the command")
            continue
        if cmd not in TEXT_TOOLS:
            hits.append(f"unknown or network command {cmd}")
            continue
        if cmd == "gh":
            ok, why = gh_ok(t, repos, okvars)
            if not ok:
                hits.append(why)
        elif cmd == "git":
            sub = next((x for x in t[1:] if not x.startswith("-") and x not in ("-C",)), "")
            args = t[t.index(sub) + 1:] if sub in t else []
            if sub == "remote" and args[:1] != ["-v"] and args:
                hits.append("git remote change")
            elif sub in ("push", "fetch", "pull", "ls-remote", "clone"):
                if any("://" in x or re.match(r"^[\w.-]+@[\w.-]+:", x) or x.startswith(("/", "~", "../")) for x in args) \
                        or any(x for x in args if not x.startswith("-") and x != "origin" and sub != "push") \
                        or (sub == "push" and [x for x in args if not x.startswith("-")][:1] not in (["origin"], [])):
                    hits.append(f"git {sub} to another remote or a URL")
                elif sub == "push":
                    review.append("git push (check that no data file was committed)")
        elif cmd in ("python3", "python"):
            if not python_ok(t, locked):
                hits.append("python running something other than the locked crit.py or a locked script")
            elif len(t) > 2 and t[2] == "-":
                py_dash = True
        elif cmd in ("npm",) and any(x in ("install", "add", "i") for x in t[1:]):
            hits.append("npm install")
        elif cmd == "sed":
            if any(x.startswith("-i") or x == "--in-place" for x in t):
                hits.append("sed -i")
            elif any(re.search(r"(^|[;{}\n]\s*)\d*[we](\s|$)|/[gpiIM0-9]*[we](\s|;|$)", x) for x in t[1:] if not x.startswith("-")):
                hits.append("sed with a w or e command")
        elif cmd in ("awk", "perl"):
            prog = " ".join(t[1:])
            if re.search(r"\b(system|exec|open|getline|qx|fork|socket)\b|\|", prog) or any(x.startswith("-i") for x in t):
                hits.append(f"{cmd} running commands, opening files or editing in place")
        elif cmd == "find" and any(x in ("-exec", "-execdir", "-delete", "-ok", "-fprint") for x in t):
            hits.append("find with -exec or -delete")
        elif cmd in WRITE_CMDS:
            for x in t[1:]:
                if not x.startswith("-") and not path_ok(x, dirs):
                    hits.append(f"{cmd} outside the repo and the run folder")
                    break
    if py_dash:
        for d in docs:
            if NET_HINT.search(d) or NETWORDS.search(d) or CLOUD_PATH.search(d):
                hits.append("python heredoc that names a network module or a cloud folder")
    for m in re.finditer(r"(?<![<0-9&])>>?\s*(['\"]?)([^\s'\";&|]+)\1", body):
        if not path_ok(m.group(2), dirs) and not m.group(2).startswith("&"):
            hits.append("redirect outside the repo and the run folder")
    return hits, review


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
    repos = {r.lower() for r in [a.repo] + (a.gap_repo or [])}
    dirs = [real(d) for d in (a.allow_dir or [])] + [real(pathlib.Path.home() / ".superfix")]
    locked = read_lock(a.scripts) if a.scripts and (pathlib.Path(a.scripts) / "lock").exists() else {}
    hits, review, seen = [], [], 0
    lines = [l for l in pathlib.Path(a.log).read_text(errors="replace").splitlines() if l.strip()] if pathlib.Path(a.log).exists() else []
    for n, l in enumerate(lines, 1):
        try:
            o = json.loads(l)
        except ValueError:
            print(f"SEND-UNKNOWN (line {n} is not JSON: the log cannot be checked)")
            return 1
        for u in tool_uses(o):
            seen += 1
            name, inp = str(u.get("name", "")), u.get("input") or {}
            if name in TOOL_OK:
                continue
            if name in WRITE_TOOLS:
                p = str(inp.get("file_path") or inp.get("notebook_path") or "")
                if not path_ok(p, dirs):
                    hits.append(f"SEND-HIT line {n} {name} outside the repo and the run folder")
            elif name == "Bash":
                h, r = bash_hits(str(inp.get("command", "")), repos, dirs, locked)
                hits += [f"SEND-HIT line {n} Bash {x}" for x in h]
                review += [f"SEND-REVIEW line {n} {x}" for x in r]
            elif name.startswith("mcp__") and name.rsplit("__", 1)[-1].startswith(MCP_PREFIX) and not MCP_DENY.search(name.rsplit("__", 1)[-1]):
                continue
            else:
                hits.append(f"SEND-HIT line {n} {name}")
    if not lines or not seen:
        print("SEND-UNKNOWN (an empty log, or no tool calls in it: nothing was checked)")
        return 1
    out = list(dict.fromkeys(hits + review))
    print("\n".join(out) if out else f"SEND-CLEAN ({seen} tool calls)")
    return 1 if out else 0


def main():
    ap = argparse.ArgumentParser()
    sp = ap.add_subparsers(dest="cmd", required=True)

    def p(name, f, *args, body=False):
        s = sp.add_parser(name)
        for x in args:
            s.add_argument(f"--{x}", required=True)
        if body:
            s.add_argument("--body"); s.add_argument("--issue"); s.add_argument("--prev-comment")
        s.set_defaults(f=f)
        return s

    def run_args(s):
        s.add_argument("--measure", action="append"); s.add_argument("--asked", action="store_true")
        s.add_argument("--unsandboxed-ok", action="store_true"); s.add_argument("--timeout", type=int, default=120)
    p("shape", cmd_shape, body=True)
    s = p("measure", cmd_measure, "run", "id", "script", "data", "out", "scripts", body=True)
    s.add_argument("--attempts"); s.add_argument("--expect", choices=["PASS", "FAIL"]); s.add_argument("--asked", action="store_true")
    s.add_argument("--neg-of"); s.add_argument("--defect"); s.add_argument("--unsandboxed-ok", action="store_true")
    s.add_argument("--timeout", type=int, default=120)
    s = p("lock", cmd_lock, "scripts", "by", "run", "attempts", body=True); s.add_argument("--data", action="append"); s.add_argument("--approved", action="append")
    s = p("lockcheck", cmd_lockcheck, "scripts", "attempts", body=True); s.add_argument("--run")
    s = p("baseline", cmd_baseline, "run", "attempts", "scripts", "label", body=True); run_args(s); s.add_argument("--redo", action="store_true")
    s = p("attempt", cmd_attempt, "run", "attempts", "scripts", "label", body=True); run_args(s); s.add_argument("--recheck", action="store_true")
    s = p("amend", cmd_amend, "run", "attempts", "scripts", "label", "by", body=True); run_args(s)
    s.add_argument("--data", action="append"); s.add_argument("--removed", action="append")
    s = p("verify", cmd_verify, "scripts", "attempts", "crit-sha"); s.add_argument("--line", type=int, required=True)
    s.add_argument("--measure", action="append")
    p("progress", cmd_progress, "attempts", "scripts", "run", body=True)
    s = p("comment", cmd_comment, "comment", "attempts", "run", "scripts", "repo", body=True)
    s.add_argument("--kind", choices=["decision", "stop", "final"], required=True); s.add_argument("--gap-repo", action="append")
    p("signoff", cmd_signoff, "attempts", "scripts", body=True)
    p("scan", cmd_scan, "file")
    s = sp.add_parser("where"); s.add_argument("path"); s.set_defaults(f=cmd_where)
    s = p("copy", cmd_copy, "run", "src"); s.add_argument("--asked", action="store_true"); s.add_argument("--name")
    s = p("finish", cmd_finish, "run"); s.add_argument("--asked", action="store_true")
    p("visibility", cmd_visibility, "repo")
    s = sp.add_parser("index"); s.add_argument("op", choices=["add", "remove"]); s.add_argument("--job", required=True)
    s.add_argument("--waits", default=""); s.set_defaults(f=cmd_index)
    s = p("remind", cmd_remind, "name", "where", "date"); s.add_argument("--dry-run", action="store_true")
    s = p("wo-check", cmd_wo_check, "wo", body=True); s.add_argument("--check"); s.add_argument("--clone"); s.add_argument("--run")
    s = p("wo-baseline", cmd_wo_baseline, "run", body=True); s.add_argument("--clone"); s.add_argument("--folder")
    s = p("wo-lock", cmd_wo_lock, "run", "dest", body=True); s.add_argument("--clone"); s.add_argument("--folder"); s.add_argument("--asked", action="store_true")
    s = p("wo-return", cmd_wo_return, "run", "folder", body=True); s.add_argument("--clone"); s.add_argument("--patch"); s.add_argument("--remote-branch", action="store_true"); s.add_argument("--attempts"); s.add_argument("--scripts")
    for name, f in (("wo-verify", cmd_wo_verify), ("wo-solved", cmd_wo_solved)):
        s = p(name, f, "run", "head", body=True); s.add_argument("--clone"); s.add_argument("--timeout", type=int, default=300)
        if name == "wo-verify":
            s.add_argument("--findings"); s.add_argument("--attempts"); s.add_argument("--scripts")
    s = p("wo-files", cmd_wo_files, "run", "folder", body=True); s.add_argument("--clone")
    s = p("wo-cleanup", cmd_wo_cleanup, "run")
    s = p("wo-sendback", cmd_wo_sendback, "run", "dest", body=True); s.add_argument("--clone"); s.add_argument("--attempts"); s.add_argument("--scripts")
    s = p("sandbox", cmd_sandbox, "cwd"); s.add_argument("--timeout", type=int, default=300); s.add_argument("argv", nargs=argparse.REMAINDER)
    s = p("sendcheck", cmd_sendcheck, "log", "repo"); s.add_argument("--gap-repo", action="append"); s.add_argument("--allow-dir", action="append")
    s.add_argument("--scripts")
    a = ap.parse_args()
    os.umask(0o077)
    try:
        return a.f(a)
    except Stop as e:
        print(str(e))
        return 1
    except (OSError, ValueError, KeyError, IndexError, OverflowError) as e:
        print(f"ERROR {a.cmd} {type(e).__name__}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
# --- crit.py end ---
```
