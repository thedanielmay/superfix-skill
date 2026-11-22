# Changelog

## 1.7.4 - 2026-11-22

- Removed personal data from the repo's current files: home folder paths in the test notes and old plans, a Drive path in a test note, and a client name and private repo names used as examples. They are now made-up names or placeholders. The rule in `gaps.md` (a repo name or run key blocks the phrases built from it) is unchanged (#136).
- The root `SKILL.md` copy and the root `references` link are gone: `skills/superfix/` is the only copy. An OpenCode or `~/.agents` link to the repo root must now point at `<clone>/skills/superfix` (#135).
- Stopped tracking a compiled Python file in `tests/`.
- Added `tests/leak-check.sh`, which runs in CI and fails on a home path with a real user name, an email-shaped Drive path, or a tracked compiled file. It prints file and line only. It cannot know a client or repo name, so those still depend on the writing rule.
- `briefs.md` now gives fix agents the same run 3 command as SKILL.md (#143).
- `wo-lock` now refuses a new work order with no `KINDS:` line (`WORKORDER-KIND-MISSING`). `wo-check` on an older locked work order without one still passes and prints one NOTE line (#141).
- `workorder.md` now says a squash inside round 1 cannot be detected (git shows one commit), so the attempt count reads 1 (#142).
- Fixed 9 failing rows in `tests/workorder-criteria-tests.sh`: its `docrun.py` helper now strips the leading `python3 -I "D/crit.py"` that #134 added to the documented commands. CI now also runs the three work order test files on macOS, since they need `sandbox-exec` (#147).

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
