# superfix-skill

Intelligent development orchestrator for Claude Code - takes a GitHub issue or freeform description and drives it end-to-end to an opened PR with CI green.

---

## Overview

`superfix` is a Claude Code skill that acts as the single front-door for all development work. You give it a GitHub issue number (`#42`) or describe what needs doing in plain English; it classifies the problem, assembles the right sub-skill set, and manages the full pipeline - exploration, planning, expert review, implementation, testing, code review, and PR - without requiring you to invoke individual skills manually or break the work into steps yourself.

It supersedes the older `change-pipeline` skill.

Since 1.3.0 it diagnoses first and stops for your approval before it fixes anything (see "Diagnose and stop" below).

The skill file is kept short. The long parts (the issue journal, the diagnosis method, agent briefs, redaction, evidence pictures, exploration by type, the execute sequences and review rules, the skill inventory) live in `skills/superfix/references/` and are read only when a step needs them.

---

## Documentation

Six pages under `docs/guide/` explain the whole system, in plain language first and technical detail after:

- [How a run works](docs/guide/how-a-run-works.md): Phase 0 to Phase 4, the Stop gate, where Superfix asks, and the issue as a work journal.
- [Modes](docs/guide/modes.md): code mode, criteria mode and work orders, what each produces and how each ends.
- [Gates and checks](docs/guide/gates-and-checks.md): every gate and check, what it blocks and the word it prints when it fails.
- [Work orders](docs/guide/work-orders.md): the hand-off folder, the checks and the return, in detail.
- [Settings file](docs/guide/settings-file.md): the seven keys in `.superfix/project.md`, the refusals and worked examples.
- [Versions](docs/guide/versions.md): one entry per tagged release from 1.1.0 to 1.6.5, taken from the GitHub release notes where one exists.

---

## When to use / Triggers

Invoke `superfix` (via `/superfix` in Claude Code) whenever you have:

- A GitHub issue number: `/superfix #42`, `/fix #42`, `/implement #42`
- A freeform description: `/superfix "the login button is broken on mobile"`
- No arguments - it will ask for an issue number or description

The skill triggers automatically on the keywords `superfix`, `issue #N`, `fix #N`, or `implement #N`.

Qik configuration and other non-code problems are reached only by typing `/superfix`. There is no automatic trigger for them.
Since 1.5.0 the skill description also names "clean up a document or data file against criteria the owner approves", so a plain request such as "fix the duplicates in data/members-export.csv" may trigger it on its own. Whether it does is test N8; until it passes, type `/superfix`.

---

## What it does

### Problem Profile (Phase 0)

Reads the full issue - body, labels, all comments - and classifies it:

| Classification | Types |
|----------------|-------|
| Problem type | `bug`, `performance`, `ux`, `architecture`, `security`, `feature` |
| Complexity tier | `Simple`, `Moderate`, `Complex` (provisional; confirmed after exploration) |

Before the type, it runs a coverage check (below). The Problem Profile is not posted on its own: it goes into the one decision message at the stop. The issue body stays a living spec, with a Status line on top and the reporter's text kept under `## Original report`. Without an issue, the same record goes in a local file at `~/.superfix/journal/`, outside the repo.

Repo settings (1.6.3): a repo can carry `.superfix/project.md` naming its base branch, PR base, checks, rules and do-not-edit folders, so a run does not repeat them every time. `references/project.py` reads it in Phase 0, refuses any key that would relax a safeguard and any checks command outside a narrow allowlist, and puts the applied settings in the `Settings:` line of the Profile for you to approve with everything else. Rules in `references/project.md`.

### Explore and diagnose (Phase 1)

Runs type-aware exploration before writing any code, inside a diagnosis method (`references/diagnose.md`): a check that fails on the reported symptom first, then 3 to 5 ranked guesses at the cause, each tested. "Confirmed" needs a test that tells the guesses apart. Before approval nothing is written except the journal and a scratch folder outside the repo. The exploration skills by type:

- **bug** - systematic debugging + execution path tracing
- **performance** - hot-path mapping + call graph + baseline measurement
- **ux** - component tree, design tokens, layout patterns
- **architecture** - full system mapping, dependency graph, structural analysis
- **security** - auth/data flow tracing + pre-plan security scan
- **feature** - quick lookup (Simple) or full explorer + architect (Moderate/Complex)

### Diagnose and stop

Every run stops after diagnosis, whatever its size, unless that run's request says "just fix it" (one Simple code problem, not security).

- The issue body gets `## Problems` (evidence), `## Options` (with a recommendation) and `## Done when` (your own description of the problem, which must stop being true).
- One decision message holds every question, numbered. Reply in one line, for example "1 yes, 2 option two". "Keep executing" means yes to every recommendation.
- Without an issue, inside a repo on GitHub, the same message asks whether to create one. It names the repo's visibility first.
- The message proposes a budget in plain words, for example "Up to 2 hours, touching these 3 files. I stop and ask if I go over."
- Your answer is written into `## Decision` in Superfix's own words, never pasted, so a password in a reply never reaches GitHub.

Coverage check: it says which kind of problem this is, and quotes the words that made it decide.

| Kind | Matches when the report mentions | What Superfix does |
|------|----------------------------------|--------------------|
| Code | files in the repo, a test, a stack trace, CLI or page output | diagnose and fix |
| Qik configuration | a Qik interface, section, form, role, workflow, definition, a qik.dev link | diagnose and fix in the draft only, marked provisional (not yet proven by a test); you always publish |
| Everything else | documents, process, sheets, business | diagnosis; since 1.5.0 data and document clean-ups are fixed on a copy against checks you approve (criteria mode, below); a process only gets a drafted change |

Passwords and tokens: it keeps a list of every credential given in the session and checks every comment, body edit, commit and PR against it before anything is posted (`references/redaction.md`). Name a 1Password item instead of typing a password.
Since 1.3.1 each run keeps that list and its scratch files in its own folder, `~/.superfix/runs/<owner>+<repo>+<issue number or journal file name>/` (all lowercase), and deletes only that folder at the end, so two runs on different issues never touch each other's list.

### Pictures of the problem and the fix (1.4.0, private repos only)

When a problem shows on a screen (a page, a rendered component), Superfix takes a picture of it with a red numbered box round the problem, and after the fix a picture with a green box. The rules and the script are in `references/evidence.md`.

- **Where they appear:** under each problem in the issue description; the first picture of each problem below the questions in the decision comment; one side-by-side Before and After picture per problem in the final comment.
- **Private repos only.** Pictures are uploaded to a standing release named `assets` in the repo, as in `thedanielmay/pullstruder`. On a public repo nothing is uploaded: the pictures stay on your Mac in `~/.superfix/journal/<owner>-<repo>/pictures/<run-key>/`, and the decision comment names that folder.
- **The GitHub mobile app does not show these pictures; the website does.** So every caption says the whole thing in words, and every comment with pictures has the line "Pictures show on the website, not in the GitHub app: <issue link>".
- **No pictures of terminal text.** Command, test, log and server output stays text, because text can be checked for secrets and a picture of it cannot.
- **Secrets:** if you give a password or token in a run, no picture from that run is posted on its own. They stay on your Mac in the journal pictures folder; look at them and reply "post the pictures" if you want them on the issue. Behind that, several checks run, none of them proof on its own: every credential on the run's list (the ones you gave, and the ones Superfix saw in the issue, a link, a file or a log) is replaced by `[redacted]` in the page's text and attributes, where the script can reach them; a picture taken with a saved login is held for your look too; the page's own scripts are stopped so nothing changes after the check; areas that cannot be cleaned (a drawing area, an image, a video, a page inside another page, text added by a style sheet file) stop the picture until they are hidden; and OCR reads each picture before upload. OCR can miss small or pale text, and a short password with one misread letter.
- **Needs:** a Python 3 that has the `playwright` module and a Chromium browser, plus `tesseract` and ImageMagick (`brew install tesseract imagemagick`). On this Mac, Xcode's `/usr/bin/python3` already has playwright with its browsers; Homebrew's `python3` does not, and Superfix does not use it for pictures. On another Mac, use a virtual environment: `python3 -m venv ~/.superfix/venv && ~/.superfix/venv/bin/pip install playwright && ~/.superfix/venv/bin/python -m playwright install chromium`, then that `python` is found by the probe only if it is first on PATH as `python3`. Without these, Superfix takes no pictures and says so under Not tested.
- **Qik draft pages (untested in 1.4.0):** they need a one-time saved login. Run `/usr/bin/python3 -m playwright codegen --save-storage=$HOME/.superfix/auth/<host>.json <draft url>`, log in in the window that opens, close it, then `chmod 600 ~/.superfix/auth/<host>.json`. That file holds your session cookies: never put it in a repo. Without it, no Qik picture.

### Labels, diagrams and gap notes (1.4.1)

- **Labels.** Superfix puts a yellow `superfix:awaiting-decision` label on the issue whenever it waits for you (a question, a stop, or a PR ready for your review), and a green `superfix:approved` label while it fixes. None while it diagnoses or when it is done. It only uses labels on repos you own with no workflow that reacts to issues or labels; otherwise the issue body carries a hidden marker instead (`<!-- marker superfix-awaiting-decision -->`) and the comment says "not set".
  - Everything waiting for you, on the website: https://github.com/issues?q=is%3Aopen+label%3A%22superfix%3Aawaiting-decision%22+user%3Athedanielmay
  - The same in a terminal: `gh search issues --label "superfix:awaiting-decision" --owner thedanielmay --state open`
  - What the saved search misses: issues that only carry the body marker, and issues in repos you do not own. The GitHub app's own label filter was not tested. Searching for the marker words (`superfix-awaiting-decision`) does find marked issues after a few minutes, but also any issue that mentions those words.
- **Diagrams, only when you say yes.** For Moderate or Complex work where 3 or more parts interact, the decision comment asks one numbered question with a recommended yes (so "keep executing" means yes). The diagrams are drawn after your go, by a subagent following the `diagram-design` skill's files (default style, chosen by Claude; change it with `diagram-design:profile`), checked for secrets and posted in the issue description: at most two, the cause today and the change. Private repos only, like the pictures. Rules in `references/diagrams.md`.
- **Private gap notes.** When a problem is something Superfix does not cover (a document, a process, a sheet), it writes a short note about that KIND of problem: what a playbook would need. Since 1.5.0 a note is written only for a check Superfix had no tool or access to measure (criteria mode, above). The note never names a client, repo, person, path or link and never repeats your words. Rules in `references/gaps.md`.
  - Setup: put `gap_repo=<you>/<private repo>` in `~/.superfix/config` (or set `SUPERFIX_GAP_REPO`). The repo must be private, owned by you, with no other collaborators and no webhook.
  - GitHub Apps cannot be checked from the `gh` login. Look at https://github.com/settings/installations, make sure no App can read the gap repo, then add the line `gap_repo_no_apps=<you>/<gap repo> <YYYY-MM-DD>` (the repo you checked, a space, today's date) to `~/.superfix/config`. Without that line for the same repo, or when it is older than 90 days, every note goes to `~/.superfix/gaps/` on your Mac instead. A `SUPERFIX_GAP_REPO` set anywhere else (for example by a project's settings) only counts when this line names the same repo.
  - All open notes, most seen first: `https://github.com/<you>/<gap repo>/issues?q=is%3Aopen+sort%3Acomments-desc`
- **Before and after pictures line up.** The after picture uses the same page area as the before picture. If the thing moved out of that area, the after picture is widened and the caption says so.

### Non-code problems: criteria mode (1.5.0)

For a sheet, a data file or a document, Superfix fixes only against checks you approve. For a process it drafts the change and never calls it solved. Rules and the checking tool are in `references/criteria.md`.

- **The checks, in plain words.** Each one shows today's number, the pass line and up to three example row numbers, never the personal values: "Duplicate members. Today: 8 (rows 14, 15 and 62). Must be 0." The bracket may hold only row numbers, and a scan blocks any e-mail address, phone number, link or long number in these lines The measure scripts are in the AI detail below the line.
- **Two questions for all the problems together (one pair per group if they touch different people or files), with no recommended answer.** "If every check above passes, would you consider this solved?" and "What must not get worse, for you or anyone affected?" Only your yes to the first and an answer to the second approve the checks. "Keep executing" does not: Superfix says so once, asks once more, then waits; code problems in the same issue go ahead.
- **Locked.** At your go the check lines, the measure scripts and the original files are hashed into a `criteria-sha` line in `## Decision`, with who approved them. Only those scripts run, only on those files or their copies. A changed check needs a new yes and starts a new baseline. Ticking a checklist box does not count as a change.
- **Proof.** The tool runs the scripts itself in the macOS sandbox (no network, no writes, no reads beyond the script, your file and the system); the tool, not the script, decides PASS or FAIL from the number and your pass line. Its records are chained and hashed, so a changed or hand-made record shows up; that is detection, not prevention, so each run also leaves a one-line command (`VERIFY.txt` in its folder on your Mac) that re-runs the checks and compares the numbers for you. They must fail on your original for the rows shown, then pass on the change, and a negative control (exactly one known defect put back) must fail again. A script that crashes reports ERROR, never FAIL. A try counts as progress only when a failing check got closer and nothing got worse; two tries without progress stop the run.
- **Your original is never touched.** Every change (a data file, a guide, a process) is made on a copy in the run folder on your Mac, deleted when the job ends. It is committed only on a private repo, after your yes to that question, when you say the files hold no names or contact details and a scan finds none (GitHub keeps pushed commits even after a PR is closed). Nothing is written into Google Drive, shared drives, Dropbox or iCloud Drive (Desktop and Documents too, when they sync).
- **Nothing leaves your Mac.** No send, share, publish, upload or post, by any tool or command. Messages to your team or customers are drafts. A Google Sheet or Drive file is changed only as a local copy: you put it back, send an export, and only then is it "verified on the real file".
- **Checks for later.** A process check ("refunds under 3 days") is measured on a date you get told; the issue waits with "Waiting for you: re-check on <date>". Superfix can add one reminder task to your own task list, only if you say yes to that question. Jobs with no GitHub issue are listed in `~/.superfix/journal/INDEX.md` while they wait.
- **Honest limits.** A script that misreads the file quietly is caught only when its count or rows differ from what you see in the plain lines. If every check passes but your description still seems true, Superfix says so and keeps the issue open.

### Work orders: someone else makes the change (1.6.0)

Say "work order", "someone else will do it" or "hand off" (in the request or the go reply) and Superfix diagnoses and plans as usual, but writes a work order folder instead of making the change. Code problems; 1.6.1 adds a second kind for a document, a spreadsheet or a process held in a file.
- The folder holds `workorder.md`: the steps, exact checks and a loop (change, run the checks, fix, at most 5 attempts, one commit each). A criteria work order also holds the copy to change, the locked measure scripts, their lock and the approved tick list. Anyone with git, the repo's runtime and read access to the repo can carry out the code kind: a cheaper model, a developer, or you. Give them the `WORKORDER-SHA` line Superfix prints, separately. The executor ticks and reports in `report.md` and never edits `workorder.md`. The default folder is `~/superfix-workorders/<id>/`, outside `~/.superfix`; an executor on the same Mac should run as another user, or sandboxed. Release note: an executor running as the same user on the same Mac is not supported; use another account or a sandbox.
- The work comes back as `return.bundle` inside the folder. Superfix trusts only its own locked copies and the shas in `## Decision`, runs the checks, held-back checks the executor never saw and the tests itself in a sandbox, and only then opens the PR. If something fails it asks: send it back (a fresh folder that carries on from the returned work), fix it myself, or stop.
- It costs about the same as Superfix doing it, or more; the gain is handing the work off. Rules in `references/workorder.md`.
- Since 1.6.1 the same trigger also works for criteria-mode files: the folder carries a copy (never the original, only after your explicit yes to the data question), the approved checks as a tick list, and the locked scripts with their shas.
- On return Superfix measures the copy with its own locked tool in the sandbox; a failed check is sent back while attempts remain. Success says "the counts meet your checks"; a process ends at "ready for your review", never "solved".

### Work orders for documents, spreadsheets and processes (1.6.1)

The same idea, for a document, spreadsheet or process held in a file. A criteria work order carries a copy of the file, the locked measure scripts, their lock and the approved tick list. The copy goes into the folder only after an explicit yes to the data question; the original is never in the folder.
- The criteria Step 0 writes the extracted checks block to a temp file outside the folder, so a folder that followed the work order exactly returns clean instead of being refused with `RETURN-FILES-OVER CHECKS-CHANGED`.
- A tainted return never passes, the cleanup never follows a link, the cleanup fails loud and hashes the records it keeps, and the drafts gate is tied to the run's own criteria.
- The 1.5.0 commands stay byte identical (`CRIT-1.5-UNCHANGED 106 functions`).
- Known limits: the cell value scan is a prose step, not an enforced one, so a final comment on a criteria work order can still name a member (the same exposure as 1.5.0; fixed in 1.6.2). An executor running as the same user on the same Mac is out of scope.

### The comment gate (1.6.2)

Before a comment goes onto the issue, `wo-scan-comment` scans it, and `wo-post` refuses to open the gate for a comment that was not scanned.
- The scan needs `--data <file>` (the owner's original) or `--no-data`. With neither, or with an empty list of values, it stops with `SCAN-NO-DATA` and writes no receipt.
- The receipt is written whole and records the sha of the comment and of the data file; `wo-post` refuses a cut-short receipt, a changed comment or a changed data file.
- The Stop gate comment and the final comment go through the same two commands.
- The checking tool moved to `references/crit.py`; `criteria.md` is 383 lines, down from 4168. The 1.5.0 commands are byte identical.
- After a stop the cleanup prints `CLEANUP-KEPT` for its small hash-and-path record and ends with `CLEANUP-OK`, instead of the false `CLEANUP-INCOMPLETE` warning.
- Known limit: the gate detects, it does not prevent. A model that skips it and posts with `gh issue comment` is not stopped by the tool.

### Repo settings (1.6.3)

A repo can carry a small settings file, `.superfix/project.md`, with seven keys: `base-branch`, `pr-base`, `checks`, `rules`, `do-not-edit`, `closing`, `model`. `references/project.py` reads it in Phase 0 and the `Settings:` line of the Problem Profile shows what was applied.
- Refused, and the run stops and asks: any key or `rules` line naming a safeguard (gate, secrets, redaction, merge, push, budget, approve, and so on); any `checks` command that is not one repository script run by python3, python, bash, sh or node, with no shell characters and no path leaving the repo; any value naming a credential path or an outbound destination.
- Unknown keys are reported and ignored; the rest still applies.
- Known limit: `rules` is free text. A line such as "write results to /tmp/outbox then email" is not refused; you see it at the Stop gate and approve it.
- `crit.py` is byte identical to 1.6.2 (sha256 `87bba19e92670d10fbc571292eebe0a02a85c81f65f96f743755db129317e4e1`), so jobs locked under 1.6.2 are unaffected.

### Real gates and the corrected solved check (1.6.4)

Three safeguards that used to be instructions are now real checks that fail loudly.
- The redaction pattern check is one script, `references/redact-check.py`, run with `--run <run-folder> -- <files>` or `--self-test`. It prints the exact-string word and then `PATTERN-CLEAN` or `PATTERN-HITS`, and exits 1 on `BLOCKED`, `ERROR` or `NO-RUN-FOLDER`.
- The label, diagram and gap gate snippets now exit 1 on failure.
- Zero registered checks is no longer reported as green.
- Solved check run 3 reverts only the fix's own files: modified files are restored from the approval commit, files the fix added are removed, and the expected failing guard is named. A fix that adds a new file used to revert nothing, so the check passed wrongly.
- If main moved after the proof, the run records "merged tree not re-tested". The closing state is verified after the merge.
- Skill text: issue claims are hypotheses; the issue's own control is run; readers are listed with counts; every scan needs a positive control; tests-only work gets a one-paragraph type; review depth scales with the diff; the budget counts active time; loose ends found in review are not scope creep; the mutant rule applies only to rows that pin a gate or check; merge commits are exempt from the trailer.
- Known limits: the 29 skill-text tests check that the new wording is present, not that the rules work. The three new test scripts run in CI on every pull request (from 1.6.5); the work order suites do not.

### Design & Plan (Phase 2, Moderate/Complex only)

Type-specific design step (brainstorming, threat modelling, UX iteration), then a written plan saved to `docs/superpowers/plans/YYYY-MM-DD-<slug>.md` plus a context file passed to every subagent. All Moderate and Complex work goes through a blocking expert panel review before implementation.

### Execute (Phase 3)

- **Simple** - runs inline on the main thread: branch, implement, impacted tests, simplify, re-run tests, review (the issue text is the brief), security audit only when the diff touches risky areas, verification, PR.
- **Moderate/Complex** - dispatches an autonomous agent with the context file, the plan and the brief file (`references/briefs.md`). If the run dies, restart from the Status line, `## Problems`, `## Decision`, the latest progress comment, plan checkboxes (when a plan exists), and branch log. Finished stages are not redone.
- **Budget** - set at approval. Over any limit (commits, files, time) it stops with `BUDGET STOP` and asks: extend, cut scope, or stop.
- **Solved check (code)** - the failing check fails on the approved base commit, passes with the fix, and fails again when the fix is taken out in a scratch copy. All three results are posted. If the fix fails twice, it stops and says its diagnosis was wrong.

Every path simplifies before review (never after), re-runs tests after simplifying, then reviews, security-audits, and verifies against the original repro or baseline before declaring done. Skill names are Claude Code names; where a name does not resolve (notably under opencode), the step runs inline from its purpose and the PR body says so. Tests and verification are never skipped.

### Close (Phase 4)

Pushes the branch, creates a PR with `Closes #N` in the body, and watches CI checks when the repo has them. The final comment is posted only after the checks are green. The issue closes when the PR merges, never on PR creation.

Not tested: the PR body and the final comment always end with a `## Not tested` list. An empty list says "Nothing known untested".

### Model policy

Applied automatically - no user configuration needed:

| Task | Model |
|------|-------|
| File reads, symbol lookups, quick checks | Haiku |
| Exploration, planning, implementation, review | Sonnet |
| Expert panel, complex architecture, ambiguous triage | Opus |

---

## Dependencies

Nothing is hard-required. Superfix names Claude Code skills; any step whose skill is not installed runs inline from its stated purpose, and the PR body records `ran inline: <skill>`. Tests and verification are never skipped. Install the below for full behavior. Every skill superfix can employ is listed, including the ones that run inline.

**Plugin packs (Claude Code):**

- `superpowers` ([obra/superpowers](https://github.com/obra/superpowers)) - systematic-debugging, brainstorming, test-driven-development, verification-before-completion, writing-plans, finishing-a-development-branch, subagent-driven-development, using-git-worktrees. Not available in opencode; runs inline there.
- `feature-dev` ([anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)) - code-explorer and code-architect agents. opencode: built-in Explore agent for exploration, inline otherwise.
- `pr-review-toolkit` ([same repo](https://github.com/anthropics/claude-plugins-official)) - code-reviewer, silent-failure-hunter and type-design-analyzer agents, plus the review-pr command. opencode: inline review with the same brief.
- `expert-panel` ([thedanielmay/expert-panel-skill](https://github.com/thedanielmay/expert-panel-skill)) - same where installed, else structured self-review.

**Same-name skills (both harnesses; installed copies verified identical to source):**

- `diagnose` ([javimosch/supercli](https://github.com/javimosch/supercli))
- `improve-codebase-architecture` ([same repo](https://github.com/javimosch/supercli))
- `grepai-trace-graph` ([yoanbernabeu/grepai-skills](https://github.com/yoanbernabeu/grepai-skills))
- `react-vite-best-practices` ([AsyrafHussin/agent-skills](https://github.com/AsyrafHussin/agent-skills))
- `security-audit` ([cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill))
- `code-security-audit` ([LeonMelamud/claude-code-security-review](https://github.com/LeonMelamud/claude-code-security-review))
- `refactor` ([github/awesome-copilot](https://github.com/github/awesome-copilot))
- `api-response-optimization` ([aj-geddes/useful-ai-prompts](https://github.com/aj-geddes/useful-ai-prompts))
- `accessibility` ([addyosmani/web-quality-skills](https://github.com/addyosmani/web-quality-skills)) - installed copy is v1.1, upstream is v2.0.

**Flagged: employed inline (no install resolves them here):**

- `architecture-deep-dive` - installed in this Claude Code setup, no verifiable upstream found; missing in opencode. Runs as an inline structural review.
- `ui-ux-pro-max` ([nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)), `impeccable` ([pbakaus/impeccable](https://github.com/pbakaus/impeccable)) - registered but not installed in either harness here. Runs inline from UX intent.
- `security` (threat-model step) - no such skill exists in either harness; the closest family is the memstack security skills ([cwinvestments/memstack](https://github.com/cwinvestments/memstack)). Always runs inline.
- `webapp-testing` - ships as `example-skills:webapp-testing` in [anthropics/skills](https://github.com/anthropics/skills); where it is not installed the Playwright steps run inline.
- `simplify` - bundled with some Claude Code versions, not a plugin. The fallback is the `code-simplifier` agent, then `refactor` above, else inline.
- `diagram-design` (1.4.1) - Superfix never invokes it; a subagent reads its files from the installed plugin folder to draw the optional diagrams. Without it, no diagrams.

---

## Installation

This repo is structured as a Claude Code installable plugin with a skill manifest.

### Claude Code

```bash
# From your project root (requires Claude Code with plugin support)
claude skill install https://github.com/thedanielmay/superfix-skill
```

After a new release, pull it in with:

```bash
claude plugin marketplace update thedanielmay
claude plugin update superfix@thedanielmay
```

Then restart Claude Code. The update only applies after a restart.

### opencode

opencode reads the skill straight from a local checkout. Clone it once, then symlink it into your skills directory:

```bash
git clone https://github.com/thedanielmay/superfix-skill.git ~/projects/superfix-skill
ln -s ~/projects/superfix-skill ~/.agents/skills/superfix
```

Keep the clone on `main` when you are not mid-edit, so opencode runs released text. There is no install or update step beyond `git pull`.

---

## What's inside

```
SKILL.md                        Root manifest (skills CLI discovery, kept in sync)
references                      Symlink to skills/superfix/references (for the root copy)
skills/
  superfix/
    SKILL.md                    Full skill implementation and phase definitions
    references/
      journal.md                Issue body template, Status line, labels, comments, decision message, file-mode journal
      diagnose.md               Diagnosis method, stop rules, tools and fallbacks, review header, fan-out brief
      briefs.md                 Execution brief for the fix agent (read only after approval)
      redaction.md              Credential checks before any post, commit or PR
      redact-check.py           The redaction gate: exact strings and patterns, with --self-test (1.6.4)
      evidence.md               Pictures: when, the capture script, the upload command, captions (1.4.0)
      diagrams.md               Diagrams: when to ask, the brief, the source check, render and upload (1.4.1)
      gaps.md                   Private gap notes: what they hold, the repo checks, the local folder (1.4.1)
      criteria.md               Criteria mode: check lines, questions, lock, attempts, three runs (1.5.0)
      crit.py                   The criteria and work order tool (1.5.0; its own file since 1.6.2)
      workorder.md              Work orders: both templates, the checks, the hand-off and the return (1.6.0, criteria kind 1.6.1)
      project.md                Repo settings file: the seven keys, the refusals, the output contract (1.6.3)
      project.py                The settings reader, run in Phase 0 before the type is chosen (1.6.3)
      explore.md                Exploration by type
      execute.md                Execute sequences by type, review rules, test scope, merged tree
      inventory.md              Every skill used, with its opencode name or fallback
docs/
  guide/
    how-a-run-works.md          Phase 0 to Phase 4, the Stop gate, the issue as work journal
    modes.md                    Code mode, criteria mode and work orders
    gates-and-checks.md         Every gate and check, what each blocks and its failure words
    work-orders.md              The hand-off folder and the return in detail
    settings-file.md            .superfix/project.md keys, refusals, examples
    versions.md                 One entry per tagged release, from the GitHub release notes
tests/
  prompts.md                    Fixed test prompts and pass criteria for a release
  preservation-check.py         Lists every line of a release tag (--tag, default the newest) that is gone or MOVED; fails on unexplained ones
  preservation-1.3.0.md         One justification per removed or changed line
  preservation-1.3.1.md         The same for 1.3.1, keyed by file and heading
  preservation-1.4.0.md         The same for 1.4.0, with the builder's deviations from the plan
  preservation-1.4.1.md         The same for 1.4.1
  preservation-1.4.2.md         The same for 1.4.2 (move only)
  preservation-1.5.0.md         The same for 1.5.0
  preservation-1.6.0.md         The same for 1.6.0
  preservation-1.6.1.md         The same for 1.6.1, including the criteria work order fixes
  preservation-1.6.2.md         The same for 1.6.2, including the tool move
  preservation-1.6.3.md         The same for 1.6.3
  crit-15-check.py              CRIT-1.5 guard: the 1.5.0 commands stay byte identical
  project-tests.sh              52 settings tests (1.6.3)
  redact-check-tests.sh         16 redaction gate tests (1.6.4)
  solved-close-tests.sh         11 solved check, merged tree, zero checks and closing tests (1.6.4)
  skill-text-tests.sh           29 skill text tests (1.6.4)
  workorder-tests.sh            115 work order tests (1.6.0)
  workorder-criteria-tests.sh   240 criteria work order tests (1.6.1)
  mkrig.py                      Builds one criteria work-order rig for the tests
  fixtures/workorder/           Inputs for the work order tests
  gates/                        Live-gate scripts and their README (1.6.2)
.claude-plugin/plugin.json      Plugin manifest and version
.github/workflows/              Sync check: fails a PR when the two SKILL.md copies differ
CONTRIBUTING.md                 How to work on this repo
```

The skill itself is prompt-based - no compiled code, no runtime dependencies. All behaviour is defined in `skills/superfix/SKILL.md` (mirrored at the repo root) and the files in `skills/superfix/references/` it tells the model to read. `tests/` is never loaded at run time.
Since 1.4.0 the picture step writes a Python script from `references/evidence.md` into the run folder and runs it; since 1.5.0 criteria mode does the same with `crit.py`, which lives in `references/crit.py` since 1.6.2 (it was inside `references/criteria.md` before; standard library only). It needs the tools under "Pictures" above; without them, there are no pictures and nothing else changes.

---

## Status

1.6.5, released 24 October 2026. In production; it supersedes `change-pipeline`. The classification rules and phase sequences live in the SKILL.md files; the long parts live in `skills/superfix/references/`.

The line since 1.5.0:
- 1.5.0: criteria mode for non-code problems. A gap note now means a check Superfix had no way to measure, not every non-code problem.
- 1.6.0: work orders for code.
- 1.6.1: work orders for documents, spreadsheets and processes.
- 1.6.2: the comment gate, and the tool in its own file at `references/crit.py`.
- 1.6.3: the per-repo settings file at `.superfix/project.md`.
- 1.6.4: real gates, the corrected solved check run 3, the merged tree rule and the r4 skill-text rules.
- 1.6.5: clean-up hardening, the shared work order loops, and refused kinds.

The 1.6.4 release note reports 115 work order, 240 criteria, 52 settings, 16 redaction, 11 solved check and 29 skill-text tests, 18 removed lines in the preservation record all justified, and `SKILL.md` at 439 of 440 lines.

Known limits: Qik configuration support is provisional. Pictures of Qik draft pages are untested (they need the one-time saved login above). The 29 skill-text tests check that the new wording is present, not that the rules work. The redaction, solved check and skill text test scripts run in CI on every pull request; the two work order suites still run only on this Mac, because they need `sandbox-exec` and local fixtures.
