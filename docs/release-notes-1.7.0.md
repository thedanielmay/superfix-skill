# Superfix 1.7.0 release notes (draft, not released yet)

The items [superfix-skill#125](https://github.com/thedanielmay/superfix-skill/issues/125) and [superfix-skill#127](https://github.com/thedanielmay/superfix-skill/issues/127) ask for. Claude writes the final notes from this file at release time.

## What changes in 1.7.0

- **An independent review stage.** After the PR is open, Moderate, Complex and any change to a gate or prompt text get one reviewer that sees only the PR number and your own description of the problem: no plan, no diff, no brief, no journal. It opens the PR, reads it, and posts one verdict line, `INDEPENDENT-REVIEW PASS|FAIL <n> findings`, with its confidence. A FAIL blocks the ready-for-review status. The rule is in `SKILL.md` Phase 4 and the mechanics, with its limits, are in `references/execute.md`.
- **The side-findings setting takes the total from seven keys to eight.** `side-findings:` (`list` or `file`) says what the run does with a finding outside the job. `closing:` and `model:` came with the first part of this release; `model:` (`sonnet`, `opus` or `default`) is a default for the fix stage only.
- **The closing check reads the three forms GitHub honours.** `closing:` (`auto`, `closes` or `refs`) controls the PR body's issue reference. `Closes #12`, `Closes owner/repo#12` and `Closes https://github.com/owner/repo/issues/12` all count, the number is still compared, and a markdown link after the keyword, which GitHub does not read as a closing keyword, is refused with `CLOSING-BAD link-form-does-not-close <line>` instead of a misleading "no closing keyword".
- **The comment gate enforces a repo rules line that says no dashes.** `wo-scan-comment` now takes `--repo` and reads that repo's `rules:` lines the way the settings reader does. When a line says "no em or en dashes" or "no dashes", a comment holding an em or en dash fails with `STYLE-DASH <line>` and writes no receipt, so `wo-post` refuses to open the gate. The list is fixed on purpose: it does not read free text, and every other rules line is printed as `STYLE-RULE` and never enforced.
- **Side findings can be filed, not just listed.** With `side-findings: file` in the repo settings, each finding outside the job is filed as its own issue in the repo the run works in: after the redaction checks pass, at most 5 a run, labelled `superfix:side-finding`, assigned to the main issue's assignee or else the `gh` user, with the evidence file and line and nothing from your data. Your yes to the `Settings:` line at the Stop gate is that pre-authorisation, so the run asks no second question. `list`, the default, keeps every finding under `## Not tested` only.

## The crit.py check still holds

`crit.py` changes only inside its work order commands, so `tests/crit-15-check.py` still prints `CRIT-1.5-UNCHANGED 106 functions`. The 1.5.0 commands are byte identical.
