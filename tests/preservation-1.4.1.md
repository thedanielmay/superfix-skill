# Preservation justifications for 1.4.1

One line per v1.4.0 line that is removed, changed or moved: `- <old place> :: <exact old line> :: <reason>`. `<old place>` is `<file> > <nearest heading>` exactly as `tests/preservation-check.py` prints it. A MOVED line also names its new place in the reason. Every change in 1.4.1 is the labels, diagrams, private gap notes and aligned crops release ([superfix-skill#51](https://github.com/thedanielmay/superfix-skill/issues/51)). 1.4.1 is add-only: new lines go next to old ones, so this list should stay empty.

Check: `python3 tests/preservation-check.py "$PWD" --tag v1.4.0` must print `0 unjustified` and exit 0.

## Justifications

- skills/superfix/SKILL.md > Coverage check (before type and tier) :: | Code | files in this repo, a test, a stack trace, CLI or page output from this repo | diagnose and fix | :: review 1 of 1.4.1 (coordinator decision 6): "files in this repo" also caught a README or guide whose problem is the writing, so such a problem was called Code and got no gap note. Same place, same row; the trigger list now reads "source, tests, build or config files in this repo, a stack trace, CLI or page output from this repo".
- skills/superfix/SKILL.md > Coverage check (before type and tier) :: | Everything else | documents, process, sheets, business, anything not above | diagnose only, low confidence | :: review 1 of 1.4.1 (coordinator decision 6): the other half of the same fix. Same place, same row; it now names prose files inside the repo (README, ONBOARDING.md, guides) when the problem is the writing, not code. Nothing else in the row changed.

## Deviations from the plan (builder, 19 Oct 2026)

Each is the safest reading of the plan, or a fix for something its wording would have broken. Found while building and probing on testbed tags `seed-1.4` and `seed-1.4.1`.

**Diagrams depend on probe T1b, which the coordinator runs.** Everything for diagrams (Route B) is written: `references/diagrams.md`, the `diagram` and `diagram-verify` subcommands in `shot.py`, SKILL.md C5, C8 and the `Diagram:` field. If T1b fails (Route C), those lines are removed again and `Diagram:` is dropped from the field list; nothing else depends on them.

Process
- **One comment for T0 and T1a.** The T0 summary is folded into the single T1a comment on [superfix-skill#51](https://github.com/thedanielmay/superfix-skill/issues/51) (the issue was already assigned to Daniel). T11's check output is a second, short comment.
- **Render and crop probes ran after T4 and T5**, because they need the new `shot.py` code; their results are in the same T1a comment.
- **No create call against cli/cli.** A create is a write call even when it would fail. Only the read-only label lookup ran there. `LABEL-CREATE-FAILED` was shown with an invalid colour on the testbed and on a repo that does not exist.
- **Testbed `main`** was at `seed` (684ec2b) before the probes; after them it was reset to `seed-1.4.1` (5d68ec3), as the coordinator asked (the plan said `seed`).
- **`GAP-REPO-OK`** was shown only under a scratch HOME with a test config; the real `~/.superfix/config` has no `gap_repo_no_apps=` line and was not changed. `GAP-REPO-SHARED` was not provoked (it would mean inviting a real person). `GAP-REPO-HOOKS` was shown with a throwaway inactive webhook on the testbed, deleted again.

Labels (journal.md)
- **GitHub search does find the marker inside the HTML comment** (after about 5 minutes); the plan assumed it would not. It also matches issues that merely mention the words. journal.md and README say so.
- **Extra words:** `LABELS-READ-FAILED` (the read-back could not run, so an empty read is never silence) and `LABELS-SKIPPED could-not-list-files`. The remove command keeps the label list in a variable first, so a failed read prints `LABEL-REMOVE-FAILED` rather than `LABEL-NOT-PRESENT`.
- **Body heredoc:** the `**Labels:**` line has a blank line before it, so GitHub shows it on its own line. The rule line below the comment-trigger table sits after the blank line that ends the table (GitHub would read a line directly under a table as another row). The plan comment template gains a `Labels:` line.
- The final comment's `Labels:` reads `superfix:awaiting-decision (ready for your review)` (the mock's wording); journal.md says why.

Diagrams (diagrams.md, shot.py)
- **Asked only when there is an issue on a PRIVATE repo.** On a public repo or without an issue nothing could be posted, so the question would mislead; the field says `NONE (public repo)`.
- **Source check:** besides `<name>.norm.txt` it writes `<name>.flat.txt` (all spaces removed), used for the exact-string check only, so a secret split across two `<tspan>` lines is caught. The pattern check never runs on it (joined words with digits make 32-character runs). The pattern check adds e-mail addresses, as the picture upload command does. The interpreter is the BROWSER-SCRIPT one (`<python> -I`), not a hard-coded `/usr/bin/python3`. The exact-string result is reported first.
- **Render:** refuses an HTML file outside the run's `diagrams/` folder; any request other than `file:` and the two Google Fonts hosts prints `UNREACHABLE remote-asset`; `foreignObject` prints `UNREACHABLE foreign-object`; the Geist font must have loaded (`ERROR fonts`), because the no-fallback rule exists to keep the fonts; the first `<svg>` is shot as an element.
- **Dry `assets` check** prints a new word, `ASSETS-WOULD-CREATE`, in place of creating.
- **The brief** tells the subagent the default style was chosen on purpose, so it skips the skill's onboarding and style gate (the gate fires on the shipped default tokens). After the subagent returns, `CLONE-CLEAN` or `CLONE-CHANGED` checks the clone.
- **Kept diagrams** go to `~/.superfix/journal/<owner>-<repo>/diagrams/<run-key>/`. New words: `DIAGRAM-SKILL`, `DIAGRAM-SKILL-MISSING`, `STYLE-SET`, `STYLE-WRITTEN`, `CLONE-CLEAN`, `CLONE-CHANGED`.

Gap notes (gaps.md)
- **Order:** note check, then the repo check, then (only after `GAP-REPO-OK`) the source link, then the standard redaction.md checks, then create. The extended check flags the `repo#number` link itself, so it must run before the link is added.
- **The extended check flags any URL** (not only one with a query string), `~/` paths and `www.`; the `owner/repo` pattern flags any `word/word`, so gaps.md tells the writer to avoid `/`. A third block means no note at all. New words: `GAP-NOTE-CLEAN`, `GAP-NOTE-BLOCKED`, `GAP-LOCAL-EXISTS`, `GAP-FILE-FAILED`, `GAP-CANDIDATES`, `GAP-NO-MATCH`, `GAP-SEARCH-FAILED`, `GAP-OPEN`.
- `GAP-REPO-REFUSED` means the gap repo is the work repo. `GAP-REPO-SHARED` and `GAP-REPO-HOOKS` also cover a list that could not be read (fail closed). A `gap_repo_no_apps=` date in the future counts as unchecked.

Aligned crops (shot.py)
- If a retake cannot scroll back to the stored position (the page got shorter), it centres again and prints `CROP-DIFFERENT`.
- `pair` also pads `CROP-DIFFERENT` halves (centred) so both halves are the same size; the plan's 1.4.0 behaviour would leave them unequal. The 2x OCR copies are not padded (they are never posted, and OCR reads unequal halves). Temporary padded files are named `*.pad.raw.png`, so the 1.4.0 picture count ignores them. The after record stores `offset`.

SKILL.md and placement
- **20 blank lines directly after headings removed** (after the `##` headings Model & Effort Policy, Input Handling, Phase 0, GitHub Issue as Work Journal, Phase 1, and every `###` heading from Coverage check to Execute sequences). C2 and C5 each carry one blank separator line, so 26 lines were added. SKILL.md is 436 lines.
- **briefs.md (C14):** the plan's anchor line is the middle of a sentence, so the new line goes after the end of that sentence (`the Status line: return those results to the caller, which posts them.`).
- **Commit trailer** names Sonnet 5.5 as the coordinator asked; the builder ran on Opus.

## Review 1 (19 Oct 2026)

Changes made on the coordinator's 14 decisions, each tested locally with a fake HOME (read-only calls to the testbed only; nothing created on GitHub, `thedanielmay/superfix-gaps` not touched):
- **Gap note names (1):** the note check also blocks the work repo's owner, repo name and run key (any case, also with `-` and `_` as spaces or left out; 5 or more letters anywhere, shorter as whole words) and the issue number as a word of its own (not inside a version such as `1.4.1`). New reason word `GAP-NOTE-BLOCKED names`. The reviewer's title (`... Alison Fiske khub onboarding`, work repo `thedanielmay/khub`) and a body with `thedanielmay+khub+51` are blocked. `Seen again` (repo and local) is written by the command: the date and an 8-character hash of the run key, never the run key; the local note also carries the hash, not the run key. Known limit: a client name that is not part of the repo name (here "Alison Fiske") is not known to the check; only the writing rule covers it.
- **Attestation (2):** `gap_repo_no_apps=<owner>/<repo> <YYYY-MM-DD>`; it must name the chosen repo. `SUPERFIX_GAP_REPO` is treated as untrusted and counts only with a matching line. The old date-only form is `GAP-REPO-APPS-UNCHECKED`. README says how to write it.
- **Diagram subagent (3, 4):** it writes only into its own `mktemp -d` folder under `~/.superfix/tmp`; the main thread records `SECRETS-SHA` and `CLONE-STATE` (commit, branch, status hash) before, compares both after (`DIAGRAM-RUN-FOLDER-CHANGED`, `CLONE-CHANGED`), deletes nothing on a change, and only then copies the two files in (`CLONE-CLEAN DIAGRAMS-COPIED <n>`).
- **Lines check (5):** `LINES-OK`, `LINES-MISSING <which>`, `LABELS-MISMATCH`, `LABELS-READ-FAILED`, comparing the `Labels:` value with a fresh read-back. The final value is the read-back plus the fixed suffix ` (ready for your review)`.
- **Coverage rows (6):** the two SKILL.md rows are changed in place (justified above); SKILL.md stays 436 lines.
- **Renderer (7):** `file:` is let through only for the diagram file itself; a linked or `@import`ed stylesheet or a CSS `url()` image prints `UNREACHABLE local-file`. An external `<use href>` was not fetched at all by Chromium in the probe, so it cannot leak.
- **Diagram text (8):** `/Users/`, `~/` and URLs with a query string are checked on the shown text (`<name>.text.txt`), not the source, which always holds the Google Fonts address.
- **Gap repo workflows (9):** `GAP-REPO-WORKFLOWS`, with the strict word list (adds `issues`, `label`).
- **Webhooks and quotes (10, 11):** the label check prints `LABELS-SKIPPED hooks` for any webhook; quotes and YAML anchors are removed before the workflow scan, which catches `'on': &trig [...]` and `on: &a {...}` that the 1.4.0-style pattern missed.
- **Local fallback (12):** the local file never holds a `Source:` line.
- **Gap link (13):** `GAP-LINK-OK` only for a PRIVATE work repo whose collaborators are only the owner; otherwise no gap repo name or link.
- **Kind (14):** written by quoted heredoc to `gap-<k>-kind.txt`, checked (`GAP-KIND-OK`, `GAP-KIND-BAD`), read with `"$(cat ...)"` and `grep -F -f`; `$(touch x)`, a backtick and a quote are refused and nothing ran.
- **Found while fixing:** the invisible-character class in the Python of `diagrams.md` and `gaps.md` had been written as literal invisible characters (and in diagrams.md one range was malformed); both now use ASCII `\u` escapes.
