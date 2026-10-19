# Preservation justifications for 1.4.1

One line per v1.4.0 line that is removed, changed or moved: `- <old place> :: <exact old line> :: <reason>`. `<old place>` is `<file> > <nearest heading>` exactly as `tests/preservation-check.py` prints it. A MOVED line also names its new place in the reason. Every change in 1.4.1 is the labels, diagrams, private gap notes and aligned crops release ([superfix-skill#51](https://github.com/thedanielmay/superfix-skill/issues/51)). 1.4.1 is add-only: new lines go next to old ones, so this list should stay empty.

Check: `python3 tests/preservation-check.py "$PWD" --tag v1.4.0` must print `0 unjustified` and exit 0.

## Justifications

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
