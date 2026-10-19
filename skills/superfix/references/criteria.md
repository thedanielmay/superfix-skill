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
- "Keep executing" (or "keep going", "yes to all") does not approve them, because these questions have no recommended answer. Say once, in chat and in the decision comment: `Keep executing does not approve the checks for problem <k>; I am waiting for your answers to questions <a> and <b>.` The notice is APPENDED to the existing decision comment (the comment file gains it at the end, the checks run again, then `gh issue comment <N> --edit-last --body-file <file>`), never a new comment, so the comment counts in journal.md stay the same. Ask again once more, at most; then park that problem with Status `Waiting for you: <n> questions` (the label rule applies). Code and Qik problems in the same issue go ahead on their own answers.
- Two more criteria questions, each with NO recommended answer (anything but an explicit yes is no), after the two above and before the budget question, only when they apply:
  - `<n>. The measure scripts cannot run in the macOS sandbox here (SANDBOX-MISSING), so nothing would stop a script reaching the network or writing files. Run them without it? (yes / no)`
  - `<n>. Commit the changed <files> to <owner/repo>? GitHub keeps every pushed commit even if the PR is closed, and they become public if the repo is ever made public. Do these files hold names or contact details of customers or staff? (commit: yes / no, keep them on my Mac; names or contact details: yes / no)` (section 9). Asked only on a repo `visibility` reports PRIVATE.
- Order of the optional questions after the budget question: the diagram question (diagrams.md; never for an Everything else problem), the reminder question (section 16), the `assets` question, and the create-issue question always last.

### 5. The criteria tool (`crit.py`)

`crit.py` is written into the run folder from this file, by a command, never typed out by hand, like `shot.py` in evidence.md. `<skill dir>` is this skill's base directory, written out in full:

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; if [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; else awk '/^# --- crit.py start ---$/{f=1} f{print} /^# --- crit.py end ---$/{f=0}' '<skill dir>/references/criteria.md' > "$D/crit.py" && grep -q '^# --- crit.py end ---$' "$D/crit.py" && echo "CRIT-READY $D/crit.py"; fi
```

Every command below starts `python3 -I "$HOME/.superfix/runs/<run-key>/crit.py"`. The same arguments recur, always written out in full:
- `--run "$HOME/.superfix/runs/<run-key>"`: the run folder (redaction.md), deleted at the end of the run;
- `--scripts "<criteria folder>"`: `$HOME/.superfix/journal/<name>/criteria/<run-key>` (`<name>` as in journal.md's file-mode path: `<owner>-<repo>`, or the folder name without a remote). It holds the measure scripts, the `lock` file, the `attempts` file, the tool's own `records/` and the owner's `VERIFY.txt`, never data, so it outlives the run (a `later` re-check needs them);
- `--attempts "<criteria folder>/attempts"`;
- the body: `--issue '<owner>/<repo>#<N>'` when an issue exists (the tool fetches the body itself with `gh issue view --json body`, so it never trusts a file for it); `--body "<journal file>"` in file mode, where the journal file is the record and the tool stores its sha256 in each attempt line.

Every path argument is resolved to its real path before the tool changes folder. Words: `CRIT-READY`, then the words of each command below; `BODY-UNREADABLE` when the body cannot be read.

**Honest limit: the tool is DETECTIVE, not preventive.** It finds changed, missing or hand-made records (a hash chain, run ids, record hashes), and it re-runs the locked scripts itself, but a model that can edit files can still forge a record by working the chain out. The owner's own check is one line: each attempt writes `<criteria folder>/VERIFY.txt`, a command that re-runs the locked scripts on the same files and compares the numbers (`VERIFY-OK <n>` or `VERIFY-MISMATCH <id> attempts <a> now <b>`). The decision comment and the final comment say where it is: `To check my numbers yourself, run the command in <criteria folder>/VERIFY.txt on your Mac.`

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
- How the tool runs a script (`attempt`, `measure`, `verify`): under `/usr/bin/sandbox-exec` only (never a `sandbox-exec` found on PATH), with a profile that denies the network, denies every file write outside a temporary folder it deletes afterwards, and denies every file read except the script, the data file, that folder, system paths and the Python install (and explicitly `~/.ssh`, `~/.superfix`, `~/Library/Keychains`, `~/.config`, `~/.gnupg`, `~/.aws`, shell profiles and histories, `~/.gitconfig`, `~/.netrc`); with `python3 -I -B`, a cleaned environment, a 120 second limit, no shell, in its own process group, which is killed after a timeout AND after a normal exit (so a child it started cannot live on).
- Errors, each a stop and never FAIL: `ERROR <id> <reason>` (a non-zero exit, a timeout, a missing or wrong `MEASURE` or `ITEMS` line, an unexpected line, `ITEMS` not ascending, a `DATA-SHA` that is not the file's), `ERROR-MEASURE-FORMAT`, `ERROR-VERDICT-DISAGREES`, `ERROR-ITEMS-OUT-OF-RANGE` (a row number above the file's row count, header included), `ERROR-SCRIPT-NOT-LOCKED` (not `measure-<id>.py` in the criteria folder, or after go not the locked sha), `ERROR-DATA-NOT-LOCKED` (after go, neither a locked original nor in a run folder's `work/`), `CRITERIA-CHANGED`, `SANDBOX-MISSING` (nothing ran: ask the sandbox question in section 4; only after a yes add `--unsandboxed-ok`), `ASK-FIRST <file>` (a cloud or online-only file: reading it can download it; ask the owner, then add `--asked`).
- Measuring for an attempt is the `attempt` command (section 14): the tool runs every script itself and writes the records. `measure` is only for run 1, the negative control (section 15) or a look; its output is never an attempt:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" measure --run "$HOME/.superfix/runs/<run-key>" --scripts "<criteria folder>" --issue '<owner>/<repo>#<N>' --attempts "<criteria folder>/attempts" --id <id> --script "<criteria folder>/measure-<id>.py" --data "<file>" --out <name> --expect <PASS or FAIL>
```

  It prints `PASS <id> <value> items <rows>` or `FAIL ...`, then `EXPECTED`, or `UNEXPECTED <id> wanted <a> got <b>` (a stop: it exits non-zero).
- Before the stop, the baseline is `attempt --label base` on the ORIGINAL (section 14): each `C` must print `FAIL` with `ITEMS` whose first 3 rows are the rows in the plain block (else the failure is for the wrong reason: fix the script); a `C` that passes does not detect the problem: rewrite it; each `K` must print `PASS`.
- Honest limit: a script that misreads the file quietly (no crash) is caught only when its `ITEMS` or its number differ from what the owner sees in the plain block.

### 8. Business figures

They follow redaction.md: a figure the owner calls private goes on the secrets list, and then blocks any post that holds it. The plain block and the pass lines use counts, and on a PUBLIC repo relative values ("20% fewer than today"), never amounts or row values.

### 9. Where the work happens

Work copies live in `$HOME/.superfix/runs/<run-key>/work/` and are DELETED when the job ends (solved, abandoned or stopped for good); the run folder delete at the end of the run removes them too. A `later` job keeps only numbers, data shas, the scripts and the tool's records in the criteria folder, never the data.
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

The test harness (S13) checks a run's `stream-json` log, in the main thread and in subagents, with an ALLOWLIST:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" sendcheck --log "<run.jsonl>" --repo '<owner>/<repo>' --gap-repo '<owner>/<gap repo>' --allow-dir "<clone>" --allow-dir "<temporary folder>"
```

- Allowed tools: `Read`, `Grep`, `Glob`, `Skill`, `Agent`, `TodoWrite`, `ToolSearch`, `AskUserQuestion`; `Write` and `Edit` only into the clone, `~/.superfix` or an `--allow-dir`; MCP tools whose name starts `get_`, `list_`, `read_`, `search_`, `describe_`, `preview_`, `count_` or `summarise_` (and holds no `checkout`, `share`, `send`, `upload` or `publish`). Everything else is a hit, including `WebFetch`, `WebSearch`, `Artifact` and `find_or_upload_image`.
- Allowed Bash: `git`; `gh issue view|comment|edit|list|create`, `gh pr view|create|checks|list|diff`, `gh label create|list`, `gh repo view` and `gh api` reads, only on the work repo and the gap repo (a `-X` other than GET, a field flag, another repo, `gist`, `release` or `repo create` is a hit); `python3 -I` of `crit.py`, of `-c` code with no network module, or `-m pytest`; `node`, `npm test|run|ci|install`, `pytest`; the shell's own words and the text tools the skill's commands use (`cat`, `ls`, `grep`, `sed`, `head`, `tail`, `wc`, `diff`, `awk`, `perl`, `tr`, `cut`, `sort`, `printf`, `echo`, `test`, `mkdir`, `cp`, `mv`, `rm`, `chmod`, `mktemp`, `shasum`, `date`, `base64`, `jq` and a few more), with `cp`, `mv`, `rm`, `mkdir`, `touch`, `tee`, `sed -i` and redirects only into the clone, `~/.superfix` or an `--allow-dir`. Any other command is a hit (`unknown or network command <name>`).
- It prints `SEND-CLEAN (<n> tool calls)`, or `SEND-HIT line <n> <route>` per hit, plus `SEND-REVIEW line <n> git push` (a push to check by hand). An empty log, a line that is not JSON, or a log with no tool call prints `SEND-UNKNOWN`, which is a failure, never a pass.
- **Best effort:** the Bash match reads text, so base64, unusual spellings or a tool hidden in an allowed one (`perl`, `node`) can slip past. It is the second line, behind the sandbox and the tests' `--disallowedTools` and permission settings.

### 12. Lock (at go, before any change)

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" lock --run "$HOME/.superfix/runs/<run-key>" --issue '<owner>/<repo>#<N>' --scripts "<criteria folder>" --attempts "<criteria folder>/attempts" --data "<each original data file>" --by "<gh login, or the owner at the keyboard>"
```

- It hashes (sha256) every `P<k>-` line of `## Done when` with its checklist lines (each checkbox read as `[ ]`, so ticking a box never changes the lock), every `measure-*.py` in the criteria folder, and the real path of each original named by `--data` (repeat it per file). It writes `<criteria folder>/lock` (the hash, each script's sha, each data path), adds a `locked` line to the attempts file, and prints `Internal: criteria-sha <64 hex> (sha256), locked <YYYY-MM-DD HH:MM>, approved by <who>` and `CRITERIA-LOCKED`.
- It refuses with `CRITERIA-BAD ...` (no criteria, a missing script, no `--data`, no approver, a baseline measured with another version of a script, or a baseline measured on a file not named by `--data`), `CRITERIA-INCOMPLETE <id>` (a `check` or `later` criterion with no baseline measure), or `ATTEMPTS-TAMPERED`.
- The word `sha256` on the line lets redaction.md's pattern check pass the hash; never redact it. Any other sha in a comment or body is written next to the word `sha256` too.
- Write that line in ## Decision directly BEFORE the `Internal: approval-sha` line, which stays last. `<who>` is the GitHub login that wrote the approving reply, or "the owner at the keyboard" in chat. After an amendment, the newest line counts.
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

Only through new numbered questions (the Stop gate form). ## Decision gains `Criteria change <date>: "<old plain line>" is now "<new plain line>". Approved by <who> in chat <date time>.` and a new lock line. Then the shape check, a new lock (`lock`, which adds a `locked` line), and a new baseline: `attempt --label base2 --new-epoch` (section 14). Without `--new-epoch`, `attempt` refuses under the new lock (`ATTEMPT-REFUSED the criteria were amended`); `--new-epoch` without an amendment (the current epoch has no other lock than the current one) is `ERROR-EPOCH-WITHOUT-AMENDMENT`.

### 14. Attempts, epochs and the stop rule

An attempt is measured BY THE TOOL: it re-runs every locked script itself, in the sandbox, on the files you name, writes its own records and appends the line. It never accepts an output file it did not write.

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" attempt --run "$HOME/.superfix/runs/<run-key>" --scripts "<criteria folder>" --issue '<owner>/<repo>#<N>' --attempts "<criteria folder>/attempts" --label <base, try1, try2, run2 ...> --measure <id>=<file> --measure <id>=<file> ...
```

- Every `check` criterion must have a `--measure`, and at a baseline (the first attempt, or `--new-epoch`) every `later` criterion too; else `CRITERIA-INCOMPLETE <id>`. Each label is used once.
- It prints `PASS|FAIL <id> <value> items <rows>` per criterion and `ATTEMPT-SAVED <n> (epoch <e>); your own re-check command: <criteria folder>/VERIFY.txt`; or `ATTEMPT-SAME <n>` (the same file and values as the newest line: nothing written, so a version is never counted twice), `ATTEMPT-REFUSED <id> <error>`, `ATTEMPT-REFUSED label <label> is used already`, `ATTEMPT-REFUSED the criteria were amended ...`, `ERROR-EPOCH-WITHOUT-AMENDMENT`, `ATTEMPTS-TAMPERED`, or a lock word.
- The records go to `<criteria folder>/records/<label>/<id>.out`, each with the tool's own run id. The attempt line is `<n> <date time> data-sha <sha> from <label> lock <criteria-sha or none> run <run id> rec <sha of the records> body <sha of the body> P1-C1=<value> ... prev <sha of the previous line>`. Every line the tool writes (`epoch`, `locked`, attempts, `neg`, `signoff`) ends with `prev <sha256 of the line before>`, so a line changed, added or removed by hand breaks the chain: `ATTEMPTS-TAMPERED`. A record changed, removed or not written by the tool is `ATTEMPTS-TAMPERED` too.
- Epochs: the first attempt writes `epoch 1`; `--new-epoch` writes the next epoch line, only after an amendment. Line 0 of the CURRENT epoch is its baseline: comments, progress, the stop rule and `% fewer than today` use only the current epoch. Old epochs stay in the file for audit.
- A problem whose criteria are all `owner` has no scripts and no attempts file.
- After every attempt after the baseline:

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" progress --run "$HOME/.superfix/runs/<run-key>" --scripts "<criteria folder>" --issue '<owner>/<repo>#<N>' --attempts "<criteria folder>/attempts" --cap <attempts cap, default 5>
```

- Moved: at least one failing `C` got closer to its pass line AND no `C` or `K` got further from its pass line; any worsening is no progress. It prints `CHECKS-PASS <n>` (every `check` criterion meets its pass line: never a stop), `MOVED <n>`, `NO-PROGRESS <n> (worse: <names>)` or `NO-PROGRESS <n> (no failing check improved)`; `PROGRESS-NONE` with only the baseline.
- Two attempts in a row with no progress: `STOP-NO-PROGRESS` and the stop text, filled in: `"Two tries did not get closer: <plain name> went from <before> to <after> and <plain name> got worse. Work kept on <branch or copy>. Reply 1 to re-diagnose (about 20 minutes) or 2 to stop."` Write the branch or copy in place of `<branch or copy>`. Status `Waiting for you: 1 question`.
- The attempts cap reached: `STOP-CAP <n> of <cap> attempts`; a budget stop (SKILL.md Budget).
- The owner's re-check: `VERIFY.txt` holds `python3 -I "<criteria folder>/crit.py" verify --scripts ... --attempts ... --line <n> --measure <id>=<file> ...`, which re-runs the scripts and prints `VERIFY-OK <n>` or `VERIFY-MISMATCH <id> attempts <a> now <b>`.

### 15. Three runs (the solved check in criteria mode)

- Run 1, the original: `measure --out run1 --expect FAIL` for each `C` (`--expect PASS` for each `K`) on the original, and its data sha equal to the epoch's line 0 (the original is unchanged).
- Run 2, the change: `attempt --label run2 --measure <id>=<the changed copy> ...` (it prints `ATTEMPT-SAME` when the last try measured the same file): every `C` `PASS`, every `K` `PASS` and no further from its pass line than in run 1.
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
- On "continue superfix on #N" (or the journal path): read the lock line, run the lock check, then `attempt --label recheck-<date> --measure <id>=<the data as it now is>` (the locked script counts only cases after the adoption date); report with the process wording.
- `owner`: the checklist in the final comment, Status `Waiting for you: sign-off on <plain name>`; the reply "signed off" passes it, anything wrong is a new attempt.
- Every one of these Status values starts "Waiting for you", so journal.md's label rule already applies. The issue stays open; nothing closes on its own.

### 17. Closing

When the last criterion passes or is signed off: post the final comment, then close only after `gh pr view <PR> --json state -q .state` returns `MERGED` (no PR: after the owner's reply). Then the `finish` command (section 9) and, for a no-repo job, `index remove`.

### 18. Comment check (before every post in criteria mode, after LINES-OK)

```bash
python3 -I "$HOME/.superfix/runs/<run-key>/crit.py" comment --comment "$HOME/.superfix/runs/<run-key>/comment-<N>.md" --kind <decision, stop or final> --run "$HOME/.superfix/runs/<run-key>" --scripts "<criteria folder>" --issue '<owner>/<repo>#<N>' --attempts "<criteria folder>/attempts"
```

- Fences: a line starting (after any indent) with three or more backticks or tildes opens one; it closes only on the same character, at least as long, with nothing after it. An unclosed fence is `CRITERIA-FENCE-UNCLOSED`. Lines outside fences are read for the checks below, with their indent removed.
- `decision`: `Criteria: PROPOSED <n>` (or `APPROVED <n>`) once in the AI detail below the LAST `---`, with `<n>` equal to the `P<k>-` lines; one plain line per criterion above the FIRST `---`, in exactly the section 3 form.
- Every kind: `Criteria check: ` once, naming every criterion by its plain name, each `<plain name> <PASS|FAIL|ERROR|LATER YYYY-MM-DD|OWNER> (<value>)` or `(<before> -> <after>)`, separated by `, `. **Every criterion is recomputed:** a `check` criterion's word must be the verdict of its newest measured value, and one with no measured value is `CRITERIA-INCOMPLETE <id>`; a `later` criterion's word is `LATER <its re-measure date>` and an `owner` criterion's word is `OWNER`, never PASS.
- `final`: one table row per criterion, `| <plain name> | <before> | <after> | <must be> | <result> |`. Before and after are plain numbers (a `later` after may be `LATER YYYY-MM-DD`; an `owner` row reads `OWNER` in before, after and result); `must be` is the pass line word for word; the result is the computed one. Any other cell is `TABLE-CELL-UNCHECKED` and fails.
- Values are compared at fixed places only (the pass line's own number is not a measure): the plain line's Today number and rows against the epoch's line 0 and its records; the `Criteria check:` values against the newest line that has that criterion (`<before>` against line 0); the table cells likewise. The attempt lines and records are checked as in section 14.
- A personal-data scan reads EVERY line of the comment, fenced text included: an e-mail address, a phone-like number (8 or more digits), a link, a run of 9 or more digits, or a value after a label such as `Name:`, `Customer:` or `Phone:` is `CRITERIA-PII <what> (comment line <n>)`. Only these links are allowed, wherever they appear in a line: `https://github.com/<owner>/<repo>/issues/<N>`, `.../pull/<N>` and the gap list link (`.../issues?q=is%3Aopen+sort%3Acomments-desc`).
- It prints `CRITERIA-OK`, or one line each: `CRITERIA-MISSING <what>`, `CRITERIA-COUNT <n>/<m>`, `CRITERIA-IDS-MISSING <names>`, `CRITERIA-INCOMPLETE <id>`, `CRITERIA-PLAIN-BAD <name> (<why>)`, `CRITERIA-VALUE-MISMATCH <name> comment <a> measured <b>` (or `computed <b>`), `TABLE-CELL-UNCHECKED <name> <cell>`, `CRITERIA-PII <what>`, `CRITERIA-FENCE-UNCLOSED`, `ATTEMPTS-TAMPERED`, or a lock word. Post only after `LINES-OK` and `CRITERIA-OK`.

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
# It is DETECTIVE, not preventive: it finds changed, missing or hand-made
# records, but a determined writer with file access can still forge them.
import argparse, collections, csv, datetime, fractions, hashlib, json, os, pathlib, re, secrets, shlex, shutil, signal, subprocess, sys, tempfile, time

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


# ---------- attempts file: a hash chain ----------

def all_lines(p):
    return pathlib.Path(p).read_text().splitlines() if p and pathlib.Path(p).exists() else []


def append_line(p, text):
    lines = all_lines(p)
    prev = sha_text(lines[-1]) if lines else "none"
    pathlib.Path(p).parent.mkdir(parents=True, exist_ok=True)
    with open(p, "a") as f:
        f.write(f"{text} prev {prev}\n")


def chain_ok(p):
    lines = all_lines(p)
    for n, l in enumerate(lines):
        want = sha_text(lines[n - 1]) if n else "none"
        if not l.endswith(f" prev {want}"):
            raise Stop(f"ATTEMPTS-TAMPERED line {n + 1} (the chain is broken: a line was changed, added or removed by hand)")


def parse_row(l):
    f = l.split()
    if len(f) >= 17 and f[0].isdigit() and f[3] == "data-sha" and f[5] == "from" and f[7] == "lock" and f[9] == "run" \
            and f[11] == "rec" and f[13] == "body" and f[-2] == "prev":
        raw = dict(x.split("=", 1) for x in f[15:-2])
        return {"n": int(f[0]), "sha": f[4], "from": f[6], "lock": f[8], "run": f[10], "rec": f[12], "line": l,
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
    """Every attempt line's records exist, are the tool's own (run id, hash) and match the line."""
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


def cmd_lock(a):
    text = body_text(a)
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
    chain_ok(a.attempts)
    rows = epoch_rows(a.attempts)
    bad = check_rows(a.scripts, rows)
    if rows:
        bad += [f"CRITERIA-INCOMPLETE {i} (no baseline measure)" for i in need_ids(cs, True) if i not in rows[0]["v"]]
    elif need_ids(cs, True):
        bad += [f"CRITERIA-INCOMPLETE {i} (no baseline measure)" for i in need_ids(cs, True)]
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
    sha = lock_sha(text, sc, data)
    lines = [f"sha {sha}"] + [f"script {p.stem[len('measure-'):]} {sha_file(p)}" for p in sorted(sc.glob("measure-*.py"))] + [f"data {d}" for d in data]
    (sc / "lock").write_text("\n".join(lines) + "\n")
    append_line(a.attempts, f"locked {now()} {sha}")
    print(f"Internal: criteria-sha {sha} (sha256), locked {now()}, approved by {a.by.strip()}")
    print("CRITERIA-LOCKED")
    return 0


def cmd_lockcheck(a):
    st, rec = lock_state(body_text(a), a.scripts)
    if st == "unlocked":
        print("CRITERIA-UNLOCKED (no criteria-sha line: no fixing)")
        return 1
    if a.run and a.attempts:
        chain_ok(a.attempts)
        bad = check_rows(a.scripts, epoch_rows(a.attempts), rec)
        if bad:
            print("\n".join(bad))
            return 1
    print("CRITERIA-LOCK-OK")
    return 0


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


# ---------- running one script ----------

def profile(tmp, reads):
    q = lambda s: '"' + str(s).replace("\\", "\\\\").replace('"', '\\"') + '"'
    home = pathlib.Path.home()
    py = real(sys.executable)
    sysreads = ["/System", "/usr/lib", "/usr/share", "/bin", "/usr/bin", "/dev", "/private/var/db", "/private/var/select",
                "/private/etc", "/Library/Apple", "/opt/homebrew", "/usr/local",
                real(sys.base_prefix), real(sys.prefix), py.parent.parent]
    # later rules win: deny all reads, allow system paths, deny the sensitive home folders, THEN allow the named files
    return ("(version 1)(allow default)(deny network*)"
            "(deny file-read*)(allow file-read-metadata)(allow file-read* (literal \"/\"))"
            "(allow file-read* " + " ".join(f"(subpath {q(r)})" for r in sysreads) + ")"
            + "".join(f"(deny file-read* (subpath {q(home / d)}))" for d in (".ssh", ".superfix", "Library/Keychains", ".config", ".gnupg", ".aws", ".docker", ".kube"))
            + "".join(f"(deny file-read* (literal {q(home / f)}))" for f in (".zshrc", ".zprofile", ".bashrc", ".bash_profile", ".netrc", ".bash_history", ".zsh_history", ".gitconfig", ".git-credentials"))
            + "(allow file-read* " + " ".join(f"(literal {q(r)})" for r in reads) + f" (subpath {q(tmp)}))"
            f"(deny file-write*)(allow file-write* (subpath {q(tmp)}) (literal \"/dev/null\"))")


def run_script(c, script, data, baseline, timeout, unsandboxed_ok, own_verdict=True):
    """Run one measure script. Returns (word, info): word PASS/FAIL, or an ERROR word with a reason."""
    i = c["id"]
    sbx = SBX if os.path.exists(SBX) and os.environ.get("SUPERFIX_TEST_NO_SANDBOX") != "1" else None
    if not sbx and not unsandboxed_ok:
        return "SANDBOX-MISSING", "not run; ask the owner the sandbox question, no recommended answer"
    tmp = real(tempfile.mkdtemp(prefix="crit-", dir="/private/tmp" if os.path.isdir("/private/tmp") else None))
    try:
        cmd = [str(real(sys.executable)), "-I", "-B", str(script), str(data)]
        if sbx:
            cmd = [sbx, "-p", profile(tmp, [script, data])] + cmd
        env = {"PATH": "/usr/bin:/bin", "HOME": str(tmp), "TMPDIR": str(tmp), "LANG": "en_US.UTF-8"}
        with open(tmp / ".o", "w") as o, open(os.devnull, "w") as e:
            p = subprocess.Popen(cmd, cwd=tmp, env=env, stdout=o, stderr=e, stdin=subprocess.DEVNULL, start_new_session=True)
            try:
                p.wait(timeout=timeout)
                timed_out = False
            except subprocess.TimeoutExpired:
                timed_out = True
            finally:
                try:
                    os.killpg(p.pid, signal.SIGKILL)       # the whole group: children too, after a timeout AND after a normal exit
                except (ProcessLookupError, PermissionError):
                    pass
                p.wait()
        if timed_out:
            return "ERROR", f"timeout after {timeout} s"
        if p.returncode:
            return "ERROR", f"exit {p.returncode}"
        stdout = (tmp / ".o").read_text(errors="replace")
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
                 "MEASURE": m.group(1), "ITEMS": " ".join(nums) or "none",
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
    """The script and data rules shared by measure and attempt. Returns an error line or None."""
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
        chain_ok(a.attempts)
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
    res, info = run_script(c, script, data, baseline_raw(a.attempts, i), a.timeout, a.unsandboxed_ok)
    if res not in ("PASS", "FAIL"):
        print(f"{res} {i} {info}".rstrip())
        return 1
    out = run / "criteria" / "measure" / a.out
    out.mkdir(parents=True, exist_ok=True)
    (out / f"{i}.out").write_text("".join(f"{k} {v}\n" for k, v in info.items()))
    print(f"{res} {i} {info['MEASURE']} items {info['ITEMS']}")
    if a.expect:
        if a.expect != res:
            print(f"UNEXPECTED {i} wanted {a.expect} got {res}")
            return 1
        print("EXPECTED")
    if a.neg_of:
        append_line(a.attempts, f"neg {now()} {i} data-sha {info['DATA-SHA']} defect {a.defect}")
        print("NEG-RECORDED")
    return 0


# ---------- attempt: the tool measures, writes the records and the line ----------

def cmd_attempt(a):
    run = real(a.run)
    if not (run / "key").is_file():
        print(f"NO-RUN-FOLDER {run}")
        return 1
    if not re.fullmatch(r"[A-Za-z0-9_-]{1,40}", a.label):
        print("ERROR label (letters, digits, - and _ only)")
        return 1
    text = body_text(a)
    _, lk = lock_state(text, a.scripts)
    chain_ok(a.attempts)
    rows = epoch_rows(a.attempts)
    bad = check_rows(a.scripts, rows, lk)
    if bad:
        print("\n".join(bad))
        return 1
    L = lk["sha"] if lk else "none"
    locks = epoch_locks(a.attempts)
    if a.new_epoch:
        if L == "none" or not (locks - {L}):
            print("ERROR-EPOCH-WITHOUT-AMENDMENT (a new epoch needs a new lock after an amendment)")
            return 1
    elif L != "none" and (locks - {L}):
        print("ATTEMPT-REFUSED the criteria were amended: measure a new baseline with --new-epoch")
        return 1
    cs = {c["id"]: c for c in criteria(text) if c.get("name")}
    ms = parse_measures(a.measure)
    baseline = a.new_epoch or not rows
    miss = [i for i in need_ids(cs.values(), baseline) if i not in ms]
    unknown = [i for i in ms if i not in cs or cs[i]["kind"] not in ("check", "later")]
    if miss or unknown:
        print("\n".join([f"CRITERIA-INCOMPLETE {i} (measure every check criterion{', and every later one at a baseline' if baseline else ''})" for i in miss]
                        + [f"ERROR measure {i} (no check or later criterion with this id)" for i in unknown]))
        return 1
    d = rec_dir(a.scripts, a.label)
    if d.exists():
        print(f"ATTEMPT-REFUSED label {a.label} is used already")
        return 1
    recs = {}
    for i, data in sorted(ms.items()):
        script = real(a.scripts) / f"measure-{i}.py"
        err = script_checks(a, cs[i], script, data, lk, run)
        if err:
            print(err)
            return 1
        res, info = run_script(cs[i], script, data, None if baseline else (rows[0]["raw"].get(i) if rows else None), a.timeout, a.unsandboxed_ok)
        if res not in ("PASS", "FAIL"):
            print(f"ATTEMPT-REFUSED {i} {res} {info}")
            return 1
        recs[i] = info
    vals = {i: float(r["MEASURE"]) for i, r in recs.items()}
    sha = combined(r["DATA-SHA"] for r in recs.values())
    if rows and not a.new_epoch and rows[-1]["sha"] == sha and rows[-1]["v"] == vals:
        print(f"ATTEMPT-SAME {rows[-1]['n']} (the same file and values as the newest line; nothing written)")
        return 0
    rid = secrets.token_hex(8)
    d.mkdir(parents=True)
    for i, info in recs.items():
        (d / f"{i}.out").write_text("".join(f"{k} {v}\n" for k, v in info.items()) + f"RUN {rid}\n")
    if a.new_epoch or not all_lines(a.attempts) or not any(l.startswith("epoch ") for l in all_lines(a.attempts)):
        append_line(a.attempts, f"epoch {epochs(a.attempts) + 1} {now()} lock {L}")
        rows = []
    n = rows[-1]["n"] + 1 if rows else 0
    append_line(a.attempts, f"{n} {now()} data-sha {sha} from {a.label} lock {L} run {rid} rec {rec_hash(d)} body {sha_text(text)} "
                + " ".join(f"{i}={recs[i]['MEASURE']}" for i in sorted(recs)))
    (d / "LINE").write_text(sha_text(all_lines(a.attempts)[-1]) + "\n")   # so a hand edit of the newest line is caught too
    for i in sorted(recs):
        print(f"{recs[i]['RESULT']} {i} {recs[i]['MEASURE']} items {recs[i]['ITEMS']}")
    # the owner's own re-check: the tool and a one-line command next to the locked scripts
    sc = real(a.scripts)
    if real(__file__) != real(sc / "crit.py"):
        shutil.copy2(__file__, sc / "crit.py")
    verify = f"python3 -I {shlex.quote(str(sc / 'crit.py'))} verify --scripts {shlex.quote(str(sc))} --attempts {shlex.quote(str(real(a.attempts)))} --line {n} " \
             + " ".join(f"--measure {shlex.quote(i + '=' + recs[i]['DATA'])}" for i in sorted(recs))
    (sc / "VERIFY.txt").write_text(verify + "\n")
    print(f"ATTEMPT-SAVED {n} (epoch {epochs(a.attempts)}); your own re-check command: {sc / 'VERIFY.txt'}")
    return 0


def cmd_verify(a):
    chain_ok(a.attempts)
    row = next((r for r in epoch_rows(a.attempts) if r["n"] == a.line), None)
    if not row:
        print(f"VERIFY-NO-LINE {a.line}")
        return 1
    bad = []
    for i, data in parse_measures(a.measure).items():
        c = {"id": i, "pass": "0", "ck": "C"}
        script = real(a.scripts) / f"measure-{i}.py"
        res, info = run_script(c, script, data, None, 120, False, own_verdict=False)   # verify compares numbers only
        got = info["MEASURE"] if res in ("PASS", "FAIL") else res
        if got != row["raw"].get(i):
            bad.append(f"VERIFY-MISMATCH {i} attempts {row['raw'].get(i, 'none')} now {got}")
    print("\n".join(bad) if bad else f"VERIFY-OK {a.line} (the scripts give the same numbers as the attempts file)")
    return 1 if bad else 0


def cmd_progress(a):
    text = body_text(a)
    _, lk = lock_state(text, a.scripts)
    chain_ok(a.attempts)
    rows = epoch_rows(a.attempts)
    bad = check_rows(a.scripts, rows, lk)
    if bad:
        print("\n".join(bad))
        return 1
    cs = {c["id"]: c for c in criteria(text) if c.get("name") and c["kind"] == "check"}
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
    if n >= a.cap:
        print(f"STOP-CAP {n} of {a.cap} attempts")
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
OK_LINK = re.compile(r"https://github\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+/(?:issues|pull)/\d+(?:#[A-Za-z0-9_-]+)?|https://github\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+/issues\?q=is%3Aopen\+sort%3Acomments-desc")


def pii(lines):
    hits = []
    for n, l in enumerate(lines, 1):
        l = OK_LINK.sub("LINK", l)
        for what, rx in PII:
            if rx.search(l):
                hits.append(f"CRITERIA-PII {what} (comment line {n})")
        for m in PHONE.finditer(re.sub(r"\d{4}-\d{2}-\d{2}( \d{2}:\d{2})?", "DATE", l)):
            s = m.group(0).strip()
            if sum(ch.isdigit() for ch in s) >= 8:
                hits.append(f"CRITERIA-PII phone-number (comment line {n})")
    return hits


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
    chain_ok(a.attempts)
    rows = epoch_rows(a.attempts)
    bad += check_rows(a.scripts, rows, lk)
    if not rows and any(c["kind"] in ("check", "later") for c in cs):
        print("CRITERIA-MISSING attempts (run the attempt command on the baseline first)")
        return 1
    rows = rows or [{"n": 0, "sha": "", "from": "none", "lock": "none", "raw": {}, "v": {}}]
    base, new = rows[0], rows[-1]
    brecs = {p.stem: read_out(p) for p in rec_dir(a.scripts, base["from"]).glob("*.out")}
    for c in cs:
        if c["kind"] == "check" and c["id"] not in new["v"]:
            bad.append(f"CRITERIA-INCOMPLETE {c['id']} (no measure in the newest attempt)")
        if c["kind"] == "later" and c["id"] not in base["v"]:
            bad.append(f"CRITERIA-INCOMPLETE {c['id']} (no baseline measure)")

    def last(i):
        return next((r for r in reversed(rows) if i in r["v"]), new)

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
    bad += pii([l.strip() for l in raw_lines])           # every line, fenced text included
    print("\n".join(dict.fromkeys(bad)) if bad else "CRITERIA-OK")
    return 1 if bad else 0


def cmd_signoff(a):
    cs = [c for c in criteria(body_text(a)) if c["kind"] == "owner"]
    if not cs:
        print("SIGNOFF-NONE (no owner criterion)")
        return 0
    chain_ok(a.attempts)
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


# ---------- send check (tests: S13), an ALLOWLIST, best-effort ----------

TOOL_OK = {"Read", "Grep", "Glob", "LS", "Skill", "Agent", "Task", "TodoWrite", "ToolSearch", "AskUserQuestion", "SubagentHandback"}
WRITE_TOOLS = {"Write", "Edit", "MultiEdit", "NotebookEdit"}
MCP_PREFIX = ("get_", "list_", "read_", "search_", "describe_", "preview_", "count_", "summarise_")
TEXT_TOOLS = {"cat", "ls", "grep", "egrep", "fgrep", "sed", "head", "tail", "wc", "diff", "mkdir", "cp", "echo", "printf", "test", "[",
              "true", "false", "cd", "umask", "chmod", "mktemp", "tr", "cut", "sort", "uniq", "awk", "perl", "shasum", "date", "base64",
              "rm", "mv", "touch", "find", "tee", "jq", "basename", "dirname", "realpath", "stat", "file", "sleep", "pwd", "export", "exit",
              "node", "npm", "pytest", "git", "gh", "python3", "python", "rmdir", "env", "command", "type", "which", "read", "set", "unset", "local"}
NET_HINT = re.compile(r"\b(socket|urllib|http\.client|requests|smtplib|ftplib|telnetlib|subprocess|os\.system|os\.popen|webbrowser|asyncio)\b")
KEYWORDS = {"if", "then", "else", "elif", "fi", "for", "do", "done", "while", "until", "case", "esac", "in", "!", "time", "{", "}", "function"}
CLOUD_RX = r"(CloudStorage|shared-drives|Dropbox|Mobile Documents|Google Drive|OneDrive|com~apple~CloudDocs)"


def strip_heredocs(c):
    out, end = [], None
    for l in c.split("\n"):
        if end is not None:
            if l.strip() == end:
                end = None
            continue
        m = re.search(r"<<-?\s*['\"]?([A-Za-z_][A-Za-z0-9_]*)['\"]?", l)
        out.append(l)
        if m:
            end = m.group(1)
    return "\n".join(out)


def segments(c):
    c = strip_heredocs(c).replace("$(", " ; ").replace("`", " ; ")
    for part in re.split(r"\|\||&&|[;|&\n(){}]", c):
        try:
            toks = shlex.split(part, comments=True)
        except ValueError:
            toks = part.split()
        while toks and (re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", toks[0]) or toks[0] in KEYWORDS):
            toks = toks[1:]
        if toks:
            yield toks


def path_ok(p, dirs):
    if p.startswith(("$", "~/.superfix", "/dev/null")) or not p.startswith(("/", "~")):
        return not re.search(CLOUD_RX, p)
    return any(inside(p, d) for d in dirs) and not in_cloud(p)


def gh_ok(t, repos):
    sub = [x for x in t[1:] if not x.startswith("-")][:2]
    rflag = next((t[k + 1] for k, x in enumerate(t[:-1]) if x in ("--repo", "-R")), None)
    if rflag is not None and "$" not in rflag and rflag.lower() not in repos:
        return False, "gh against another repo"
    if not sub:
        return False, "gh without a subcommand"
    allowed = {("issue", "view"), ("issue", "comment"), ("issue", "edit"), ("issue", "list"), ("issue", "create"),
               ("pr", "view"), ("pr", "create"), ("pr", "checks"), ("pr", "list"), ("pr", "diff"),
               ("label", "create"), ("label", "list"), ("repo", "view")}
    if sub[0] == "api":
        path = sub[1] if len(sub) > 1 else ""
        if any(x in ("-X", "--method") for x in t) and not any(t[k + 1].upper() == "GET" for k, x in enumerate(t[:-1]) if x in ("-X", "--method")):
            return False, "gh api with a write method"
        if any(x in ("-f", "-F", "--field", "--raw-field", "--input") or x.startswith(("-f", "-F")) and len(x) > 2 for x in t):
            return False, "gh api with fields (a write)"
        m = re.match(r"^/?repos/([^/]+/[^/?]+)", path)
        if m and "$" not in m.group(1) and m.group(1).lower() not in repos:
            return False, "gh api against another repo"
        return True, ""
    if tuple(sub[:2]) not in allowed:
        return False, f"gh {' '.join(sub[:2])}"
    return True, ""


def bash_hits(c, repos, dirs):
    hits, review = [], []
    for t in segments(c):
        cmd = os.path.basename(t[0])
        if cmd not in TEXT_TOOLS:
            hits.append(f"unknown or network command {cmd}")
            continue
        if cmd == "gh":
            ok, why = gh_ok(t, repos)
            if not ok:
                hits.append(why)
        elif cmd == "git":
            if "push" in t:
                review.append("git push (check that no data file was committed)")
        elif cmd in ("python3", "python"):
            rest = t[1:]
            if rest[:1] != ["-I"]:
                hits.append("python without -I")
            elif len(rest) > 1 and rest[1].endswith("/crit.py"):
                pass
            elif len(rest) > 2 and rest[1] == "-c" and not NET_HINT.search(rest[2]) \
                    and all(path_ok(x, dirs) for x in re.findall(r"(/[^'\"\s,)]+)", rest[2]) if "open" in rest[2]):
                pass
            elif len(rest) > 2 and rest[1] == "-m" and rest[2] in ("pytest", "unittest"):
                pass
            else:
                hits.append("python running something other than crit.py")
        elif cmd == "npm" and len(t) > 1 and t[1] not in ("test", "run", "ci", "install"):
            hits.append(f"npm {t[1]}")
        elif cmd == "find" and any(x in ("-exec", "-execdir", "-delete", "-ok") for x in t):
            hits.append("find with -exec or -delete")
        elif cmd == "env" and len(t) > 1 and not all("=" in x for x in t[1:]):
            hits.append("env running a command")
        elif cmd in ("cp", "mv", "rm", "mkdir", "touch", "tee", "rmdir") or (cmd == "sed" and any(x.startswith("-i") for x in t)):
            for x in t[1:]:
                if not x.startswith("-") and not path_ok(x, dirs):
                    hits.append(f"{cmd} outside the repo and the run folder")
                    break
    for m in re.finditer(r"(?<![<0-9&])>>?\s*(['\"]?)([^\s'\";&|]+)\1", strip_heredocs(c)):
        if not path_ok(m.group(2), dirs) and m.group(2) != "&1":
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
                h, r = bash_hits(str(inp.get("command", "")), repos, dirs)
                hits += [f"SEND-HIT line {n} Bash {x}" for x in h]
                review += [f"SEND-REVIEW line {n} {x}" for x in r]
            elif name.startswith("mcp__") and name.rsplit("__", 1)[-1].startswith(MCP_PREFIX) \
                    and not re.search(r"checkout|find_or_upload|share|send|upload|publish", name, re.I):
                continue
            else:
                hits.append(f"SEND-HIT line {n} {name}")
    if not lines or not seen:
        print("SEND-UNKNOWN (an empty log, or no tool calls in it: nothing was checked)")
        return 1
    out = list(dict.fromkeys(hits + review))
    print("\n".join(out) if out else f"SEND-CLEAN ({seen} tool calls)")
    return 1 if hits else 0


def main():
    ap = argparse.ArgumentParser()
    sp = ap.add_subparsers(dest="cmd", required=True)

    def p(name, f, *args, body=False):
        s = sp.add_parser(name)
        for x in args:
            s.add_argument(f"--{x}", required=True)
        if body:
            s.add_argument("--body"); s.add_argument("--issue")
        s.set_defaults(f=f)
        return s
    p("shape", cmd_shape, body=True)
    s = p("measure", cmd_measure, "run", "id", "script", "data", "out", "scripts", body=True)
    s.add_argument("--attempts"); s.add_argument("--expect", choices=["PASS", "FAIL"]); s.add_argument("--asked", action="store_true")
    s.add_argument("--neg-of"); s.add_argument("--defect"); s.add_argument("--unsandboxed-ok", action="store_true")
    s.add_argument("--timeout", type=int, default=120)
    s = p("lock", cmd_lock, "scripts", "by", "run", "attempts", body=True); s.add_argument("--data", action="append")
    s = p("lockcheck", cmd_lockcheck, "scripts", body=True); s.add_argument("--run"); s.add_argument("--attempts")
    s = p("attempt", cmd_attempt, "run", "attempts", "scripts", "label", body=True)
    s.add_argument("--measure", action="append"); s.add_argument("--new-epoch", action="store_true")
    s.add_argument("--asked", action="store_true"); s.add_argument("--unsandboxed-ok", action="store_true")
    s.add_argument("--timeout", type=int, default=120)
    s = p("verify", cmd_verify, "scripts", "attempts"); s.add_argument("--line", type=int, required=True)
    s.add_argument("--measure", action="append")
    s = p("progress", cmd_progress, "attempts", "scripts", "run", body=True); s.add_argument("--cap", type=int, default=5)
    s = p("comment", cmd_comment, "comment", "attempts", "run", "scripts", body=True)
    s.add_argument("--kind", choices=["decision", "stop", "final"], required=True)
    p("signoff", cmd_signoff, "attempts", body=True)
    p("scan", cmd_scan, "file")
    s = sp.add_parser("where"); s.add_argument("path"); s.set_defaults(f=cmd_where)
    s = p("copy", cmd_copy, "run", "src"); s.add_argument("--asked", action="store_true"); s.add_argument("--name")
    s = p("finish", cmd_finish, "run"); s.add_argument("--asked", action="store_true")
    p("visibility", cmd_visibility, "repo")
    s = sp.add_parser("index"); s.add_argument("op", choices=["add", "remove"]); s.add_argument("--job", required=True)
    s.add_argument("--waits", default=""); s.set_defaults(f=cmd_index)
    s = p("remind", cmd_remind, "name", "where", "date"); s.add_argument("--dry-run", action="store_true")
    s = p("sendcheck", cmd_sendcheck, "log", "repo"); s.add_argument("--gap-repo", action="append"); s.add_argument("--allow-dir", action="append")
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
