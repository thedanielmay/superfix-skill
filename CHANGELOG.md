# Changelog

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
