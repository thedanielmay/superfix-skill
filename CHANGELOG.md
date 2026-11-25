# Changelog

## 1.12.1 - 2026-11-26

- Issue links in side findings and research reports use `<repo>#<N>` as the label. The link address keeps the owner.
- Issues the skill creates or asks the owner to decide on are assigned to the `gh` user, by adding the person who must act (others stay assigned). A failed assignment is reported and does not stop the run.
- CONTRIBUTING.md no longer asks for a version change in the marketplace list.

## 1.12.0 - 2026-11-23

- #174: the trigger names issue-led and explicitly requested runs only. A Simple fix with one problem drops the label and diagram ceremony.
  - `SKILL.md` description starts on "superfix", an issue number, an explicit request to take a change to a pull request, or a document or data clean-up against approved criteria. The catch-all code-change trigger is gone. Criteria mode, work orders and Qik stay in this skill.
  - `SKILL.md` Stop gate states the Simple path once: three-line decision, body with the Status line, ## Problems and ## Done when, `not set (simple)` for Labels, no label commands, no diagram question. Moderate and Complex keep the full process.
  - `references/journal.md` agrees on the shorter body and the `not set (simple)` Labels line.
  - `tests/skill-text-tests.sh` checks the new trigger, the Simple rule and the run folder definition.
- #175: the run folder is defined where it is first used, the evidence script is a script file, and examples are neutral.
  - `SKILL.md` defines `<D>` at the comment gate as `$HOME/.superfix/runs/<run-key>`, the folder in `references/redaction.md`.
  - The 754-line `shot.py` block moves from `references/evidence.md` to `references/shot.py` byte for byte. evidence.md keeps one line naming the script and its copy command. No script behaviour changed.
  - Run-key and work-order examples use `owner/repo` instead of the maintainer's own accounts. The real expert-panel marketplace command stays.
  - Prose lines over about 200 characters are wrapped. The four line-cap checks move from 352 to 400 lines because wrapping adds lines without adding rules.
  - `tests/preservation-check.py` treats a marked script block like the marked `crit.py` block: one hash line, so a verbatim move is one justified MOVED line. `tests/preservation-1.12.0.md` records every removed line.

## 1.11.0 - 2026-11-23

- #173: the full test suite runs at approval-sha before the fix, and a flaky test is named in the PR body.
  - `references/execute.md` ### Test scope: run the full suite once at approval-sha before any edit and save the failing tests as the baseline.
  - Run the full suite again at the end and compare its failures with the baseline.
  - A test that fails only at the end is new. Re-run that single test once before calling it new. A pass on the re-run makes it flaky; name it in the PR body, not new.
  - A test in the baseline that still fails is pre-existing. List it in the PR body. Never fix it silently and never hide it.
  - A repo with no test suite is named in the PR body.
  - `SKILL.md` gains one pointer line in the Solved check and stays under the 352 line cap.
  - `tests/skill-text-tests.sh` checks the baseline run and the flaky re-run. `tests/preservation-1.11.0.md` records the version and replaced lines.

## 1.10.0 - 2026-11-23

- #172: the run checks the repo's visibility before its first post. A public security run publishes no exploit detail.
  - Before the first comment, label or body edit, the run checks visibility with `gh repo view <owner>/<repo> --json visibility -q .visibility`. It writes `Visibility: PUBLIC|PRIVATE|INTERNAL` in the decision comment's AI detail.
  - A PUBLIC repo with `security` as the primary or secondary type gets a neutral decision comment, neutral progress comments, neutral body sections and a neutral PR description. Each holds only "Security problem diagnosed; details are in the local journal".
  - The failing input, the payload, the vulnerable code path and the reproduction steps stay in the file-mode journal outside the repo. The chat message tells the owner to consider GitHub private vulnerability reporting.
  - `SKILL.md` holds the short rule at the Stop gate and at the security type row. `references/journal.md` holds the command and the full rule.
  - `tests/skill-text-tests.sh` checks both files. `tests/preservation-1.10.0.md` records the version line change.

## 1.9.0 - 2026-11-23

- #167: the criteria clean-up deletes one job folder, through file handles it holds open.
  - Send-back rounds go inside the job folder as `<id>/r2/`, `<id>/r3/`. Round 1 stays at `<id>/`. A job locked by an older version keeps its `<id>-r<n>/` folders, and its next round goes to `<id>/r<n>/`.
  - The lock records the job folder's device and inode. A restored or swapped folder is refused: nothing in it is deleted.
  - `wo-cleanup` is the last step of every ending except a send-back (a pass, RETURN-CAP, NO-PROGRESS, a stop, a refused send-back), after the final comment is posted. No ending deletes the job folder by itself.
    - A pass keeps only the verified copy and leaves the job folder empty. A second `wo-cleanup --all` (or plain `wo-cleanup` once the copy is gone) deletes the copy and the job folder. Every other ending deletes everything.
    - Until `wo-cleanup` runs, the data stays in `~/superfix-workorders`.
  - An older `<id>-r<n>/` folder is deleted only when its `workorder.md` names this job id. Without one, or with another id, it is left alone.
  - `wo-lock` refuses when it cannot read the job folder's identity, so every new lock carries the inode record.
  - `KEPT` lines print the top-level name and a count, not nested names. The full paths go to the log.
  - The log opens without following a link and is forced to mode 600; a link at the log path prints `CLEANUP-LOG-REFUSED` and nothing is deleted.
  - Every deleted path is written to `workorder/cleanup-log` in the run folder. The log is local and no command prints it.
  - New words: `WORKORDER-ID-BAD`, `WORKORDER-JOB-MOVED` and `KEPT <path> (<reason>)`. The empty `~/superfix-workorders` folder stays.
  - `tests/cleanup-fd-tests.py` holds the swap-race tests. `docs/guide/versions.md` no longer says safe deletion needs Python 3.11.
  - `tests/preservation-1.9.0.md` records the changed lines.

## 1.8.5 - 2026-11-23

- #166: the cap rig in `tests/workorder-criteria-tests.sh` reads its loop count and round names from `WO_LIMIT` in `crit.py`, refuses to run when `MAX_ATTEMPTS` differs from it, and a fence comment says no test goes inside the rig.

## 1.8.4 - 2026-11-23

- Adds the marketplace icon approved by Daniel (thedanielmay/agent-tools#2).

## 1.8.3 - 2026-11-23

- Marketplace file gains a description, so the full check passes again (thedanielmay/agent-tools#10).

## 1.8.2 - 2026-11-23

- #156: a stale plugin copy is easy to spot after an update.
  - `SKILL.md` body line 1 now reads `# Superfix Orchestrator (version X.Y.Z)`. It replaces the old heading, so the file stays 348 lines (cap 352).
  - `CONTRIBUTING.md`: the release steps end with "Restart Claude Code", and say how to read the version after the restart.
  - `tests/skill-text-tests.sh` (run in CI) checks that body line 1 and `metadata.version` equal `plugin.json`, that a wrong version is caught, and that the last release step is the restart.
  - `tests/preservation-1.8.2.md` records the version and heading changes.

## 1.8.1 - 2026-11-23

- #155: `references/skill-route.md` now says a behaviour check takes at least 10 samples per version and that the pass line is a count, for example "10 of 10". todo-skill#1 passed a "fix removed" run by chance with one sample.
  - `tests/skill-route-tests.sh` has two new cases that check the text is present.
  - `tests/preservation-1.8.1.md` records the version bump.

## 1.8.0 - 2026-11-22

- Skill route (agent-tools#8 stage 4): a plain "superfix it" on a skill now runs the expert-panel skill review and files only the findings the owner picks.
  - New `references/skill-route.md`: the test that finds a skill target, the review, show and file steps, the install check, and the check and version rules for fixing a picked issue.
  - SKILL.md has one new pointer (6 lines, 348 in all, cap stays 352). Every other target never reads the new file.
  - New `tests/skill-route-tests.sh`, added to the CI list. It runs the detection snippet from the route file.
  - `tests/preservation-1.8.0.md` records the version bump.

## 1.7.7 - 2026-11-22

- #144 step C: `journal.md` is split so a run reads only the parts it needs. SKILL.md has the same 342 lines plus one (343, cap stays 352): each pointer now names the new file.
  - `journal.md` keeps what every issue run needs before or at the stop: the body template, Status line, comment triggers and format, Depth by tier, Labels, the Decision message and the lines check. 402 lines became 279.
  - New `references/journal-nofile.md`: the File-mode journal and the Create-issue question, read in full only by a run with no issue (SKILL.md Input Handling).
  - New `references/journal-close.md`: the Final comment, Side findings and the closing verify, read in full at Phase 4 (SKILL.md Phase 4).
  - `references/phase2.md` now also holds the Plan comment and the Context file template (Moderate and Complex, read at go). `execute.md`, `criteria.md` and `redaction.md` pointers name the new homes.
  - Moved sections are word for word; each new file says that "above" means `journal.md`. Tests that looked for moved text read the new file. `tests/preservation-1.7.7.md` justifies every removed line.

## 1.7.6 - 2026-11-22

- #144 step B, one owner per rule, with #118 folded in. Each rule that was written in SKILL.md and in a reference now lives once, in the file the model reads when the rule applies; the other place keeps a pointer naming the file and heading. SKILL.md goes from 364 to 342 lines (cap 352).
  - Labels: the table, commands and failure fallback stay in `journal.md`; SKILL.md keeps one pointer and the Done-after-merge sentence.
  - Required decision comment lines: forms stay in `journal.md`; SKILL.md names all seven lines (it had missed `Work order:` and `Criteria check:`).
  - Independent review: rules and limits stay in `execute.md`; SKILL.md keeps the heading, the verdict word and the FAIL rule.
  - Leak and reporter-body credential rules stay in `redaction.md`; the gate rules stay in SKILL.md. Gap note placement stays in `gaps.md`. The pre-approval writes line in `evidence.md` points to SKILL.md Phase 1. The work order comment gate bullet in `workorder.md` points to SKILL.md Stop gate step 3 and keeps only what a work order adds.
  - #118: `execute.md` has one shared chain (10 steps) and a table of what each type adds or skips (bug, performance, ux, architecture, security, feature, and a Simple row that replaces the chain that was in SKILL.md). 85 lines became 23.
  - `briefs.md` solved-check comments now carry SKILL.md's stricter clauses (name the failing guard; run 3 fails through the same guard).
  - Left as two copies on purpose: the review header (`diagnose.md` is read before go, `execute.md` by fix agents), the budget commands (SKILL.md for the main thread, `briefs.md` for agents), the Qik four rules (`qik.md` and `briefs.md`), the solved check (SKILL.md and `briefs.md`), the repo settings paragraph, and the work order trigger.
  - `tests/preservation-1.7.6.md` justifies every removed line; the SKILL.md line caps in two tests drop from 374 to 352.

## 1.7.5 - 2026-11-22

- #144 step A: text that only one mode uses moved out of SKILL.md, which goes from 430 to 364 lines. The criteria and work order mode steps (already in `criteria.md` and `workorder.md`), the evidence, diagram and research detail, the Qik rules (new `references/qik.md`), and the expert panel and Moderate and Complex dispatch steps (new `references/phase2.md`) are read at the step that needs them. The line caps in the tests are now 374.

## 1.7.4 - 2026-11-22

- Removed personal data from the repo's current files: home folder paths in the test notes and old plans, a Drive path in a test note, and a client name and private repo names used as examples. They are now made-up names or placeholders. The rule in `gaps.md` (a repo name or run key blocks the phrases built from it) is unchanged (#136).
- The root `SKILL.md` copy and the root `references` link are gone: `skills/superfix/` is the only copy. An OpenCode or `~/.agents` link to the repo root must now point at `<clone>/skills/superfix` (#135).
- Stopped tracking a compiled Python file in `tests/`.
- Added `tests/leak-check.sh`, which runs in CI and fails on a home path with a real user name, an email-shaped Drive path, or a tracked compiled file. It prints file and line only. It cannot know a client or repo name, so those still depend on the writing rule.
- `briefs.md` now gives fix agents the same run 3 command as SKILL.md (#143).
- `wo-lock` now refuses a new work order with no `KINDS:` line (`WORKORDER-KIND-MISSING`). `wo-check` on an older locked work order without one still passes and prints one NOTE line (#141).
- `workorder.md` now says a squash inside round 1 cannot be detected (git shows one commit), so the attempt count reads 1 (#142).
- The 9 work order criteria tests that #134 broke pass again (the test helper now reads the full `python3 -I .../crit.py` command form), and a macOS CI job runs tests/workorder-kinds-tests.sh. The other two work order test files need files outside the repo and still run by hand (#147, #150).

## 1.7.3 - 2026-11-22

- The `project.py` commands in SKILL.md and project.md now name the script by its full path (`python3 -I "<skill dir>/references/project.py" ...`). Before, they used a path relative to the current folder, which only worked inside Superfix's own repo, so the settings step and the closing check failed in every other repo (#138).
- `project.py` now refuses a repo path that is not a folder, and any unknown option (such as `--help`), with `PROJECT-REFUSED` and exit 1. Before, a wrong path read as "no settings" (#138).
- `tests/bare-command-tests.sh` also fails on a `references/` script run by a relative path, in a backticked span or a code block.

## 1.7.2 - 2026-11-22

- The comment gate commands in SKILL.md and workorder.md now name `crit.py` (`python3 -I ".../crit.py" wo-scan-comment ...`). Before, they read as programs on the PATH, and a run that could not find them posted a comment without the gate (#134).
- Added `tests/bare-command-tests.sh`, which fails when a backticked `wo-...` command with arguments is written without `crit.py`, and runs in CI.

## 1.7.1 - 2026-11-22

- Added a marketplace manifest, an MIT licence and this changelog.
- Added `license` and `metadata.version` to the SKILL.md frontmatter (both copies, still identical).
- Moved the version history from the README into this changelog, and added an Install section.
- Ignored `__pycache__/` and backup files in git.

## 1.7.0 - 2026-10-24
- The independent review stage, the closing and model and side-findings settings, the comment gate style check, and the research issue type.

## 1.6.5
- Clean-up hardening, the shared work order loops, and refused kinds.

## 1.6.4
- Real gates, the corrected solved check run 3, the merged tree rule and the r4 skill-text rules.

## 1.6.3
- The per-repo settings file at `.superfix/project.md`.

## 1.6.2
- The comment gate, and the tool in its own file at `references/crit.py`.

## 1.6.1
- Work orders for documents, spreadsheets and processes.

## 1.6.0
- Work orders for code.

## 1.5.0
- Criteria mode for non-code problems. A gap note now means a check Superfix had no way to measure, not every non-code problem.

Earlier versions: see `docs/guide/versions.md` and the git tags.
