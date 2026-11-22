# Skill route

Read this file in full only when the target is a skill. Every other target skips it.

## When this route applies

Run this test in Phase 0, before the Coverage check result is written. `P` is the path the owner named, else the working folder.

```bash
is_skill_target() { # $1 = folder; prints SKILL-TARGET or NOT-SKILL
  local p="$1" f
  for f in "$p/SKILL.md" "$p"/skills/*/SKILL.md; do
    [ -f "$f" ] && [ "$(head -1 "$f")" = "---" ] \
      && sed -n '2,/^---$/p' "$f" | grep -q '^name:' \
      && sed -n '2,/^---$/p' "$f" | grep -q '^description:' \
      && { echo SKILL-TARGET; return; }
  done; echo NOT-SKILL; }
```

- The test looks only at the named folder and at `skills/*/SKILL.md` one level down. It never searches deeper.
- A `SKILL.md` under `tests/fixtures/`, `docs/` or `node_modules/` does not count.
- A `SKILL.md` without frontmatter `name` and `description` does not count.
- The route runs only for a plain request: "superfix it", "superfix this skill", or a path with no issue number and no described defect.
- A request with an issue number or a described defect on a skill repo stays on the Code row of the Coverage check. The fix then follows "Fixing a picked issue" below.
- Any other target: stop reading this file and use the normal path.

## Step 1: review

- Confirm that the `expert-panel` skill is in the skill list and that its version is 1.1.0 or later (the first version with the skill-review mode).
- If it is missing or older, stop. Say: "The expert-panel skill 1.1.0 or later is not installed, so the skill review cannot run. Nothing was filed." Give the install line from that skill's README.
  - Do not review by hand.
  - Do not fall back to the code path.
- Repeat the mode's cost line to the owner before the run. The review costs about 320,000 tokens.
- Call the Skill tool with `expert-panel` and the argument `--skill-review <path>`, plus only the flags the owner gave. That flag wins over every other flag in that skill.
- Do not copy the mode's stages, briefs or scripts into superfix. The mode owns them.
- If the run ends without a findings list, say so and stop. Do not invent findings.

## Step 2: show

- Print the numbered findings and the cost warning that the mode gives.
- Ask which findings to file, with the question tool.

## Step 3: file

- File only the findings the owner picked. The skill-review mode builds the issues.
- Post nothing before the pick.
- A decision item (a choice that belongs to the owner) is never filed as a fix.
- A "keep going", "keep executing" or away-mode reply is not a pick. Only a reply that names findings is a pick.
- Away mode: stop after step 2 and print the findings. File nothing and fix nothing.

## Fixing a picked issue

Applies when the fix target is a skill repo (same test). It adds to the normal fix path and replaces nothing. The repo's own `CLAUDE.md` wins over this file.

- Run the skill repo's own checker: the `checks` commands in its `.superfix/project.md`, or its pre-commit hook. It must pass before the PR opens.
  - A failing check is a stop, never a skip.
  - If neither exists, say so in one line under Not tested.
- Choose the version part by what a user sees: MAJOR for a removed or renamed command, MINOR for a new ability, PATCH for a fix or wording change.
- Bump every version field in the same commit: `.claude-plugin/plugin.json` and the `metadata.version` string in `SKILL.md`. They must match. Put no version in `marketplace.json` or in README prose.
- Add a `CHANGELOG.md` heading `## X.Y.Z - <date>`, newest first, with one plain bullet per change.
- Tag the bump commit `vX.Y.Z` after the merge.
- Run the repo's own preservation and test rules too.

## Not in this route

- No change to code, bug, feature, research, Qik, document or data behaviour.
- No change to the expert-panel skill or its skill-review mode.
- No filing or fixing without an explicit pick.
- No marketplace submission. That stays the owner's decision.
