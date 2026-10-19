# Working on superfix

Plain steps. This repo is a prompt-only skill, so "the code" is markdown: `SKILL.md` (two identical copies) and the files in `skills/superfix/references/`.

## Where things live

- This clone: `~/projects/skills-dev/superfix-skill`. Keep it on `main`: opencode reads it. Edit in a worktree of it (see Making a change).
- `~/.agents/skills/superfix` is a symlink to this clone. opencode and anything else reading that path sees your checkout directly. Do not edit through it, edit here.
- `~/.claude/plugins/cache/thedanielmay/superfix/` is Claude Code's installed copy. Never edit it. A plugin update overwrites it.
- Work is tracked in GitHub issues. Start from the epic labelled `epic`.
- At run time each Superfix run keeps its credential list and scratch files in `~/.superfix/runs/<owner>-<repo>-<issue number or journal file name>/` (see `skills/superfix/references/redaction.md`); the journal files stay in `~/.superfix/journal/`.

## The two SKILL.md files must match

- `skills/superfix/SKILL.md` is the real one (the plugin loads this).
- `SKILL.md` at the root is a copy (the skills CLI and opencode load this).
- `skills/superfix/references/` holds the long parts that `SKILL.md` tells the model to Read when a step needs them. The root `references` is a symlink to it, so the root copy works for opencode. Do not copy files there.
- After every edit, run: `cp skills/superfix/SKILL.md SKILL.md`
- Check before every commit: `diff skills/superfix/SKILL.md SKILL.md && echo in-sync`

## Making a change

1. Pick an issue. Update main: `git switch main && git pull`.
2. Branch in a separate worktree, never in this clone, because opencode reads this clone and it must stay on `main`: `git worktree add ../superfix-<short-slug> -b fix/<issue-number>-<short-slug> origin/main`. Do all the steps below inside that worktree. Remove it after the merge with `git worktree remove ../superfix-<short-slug>`.
3. Edit `skills/superfix/SKILL.md`, then copy it to the root (above). If behaviour, scope, or installation changed, update `README.md` too: plain human description of what the skill is, what it does, and install directions for Claude Code and opencode.
4. Run the preservation check: `python3 tests/preservation-check.py "$PWD"`. It lists every line of the last release that is gone from the skill files. Each one needs a line in `tests/preservation-<version>.md` (format below). It must exit 0. Nothing useful is cut without a named reason. The check takes the release tag to compare against: `--tag v1.3.0` (default: the newest `v*` tag reachable from `HEAD~`, printed on the first line), and reads `tests/preservation-<version in plugin.json>.md` in the format `- <file> > <heading> :: <exact old line> :: <reason>`; a line under a different heading or file is MOVED and its reason names the new place. When starting the next release, start a new justification file.
5. Test it (next section).
6. Commit, push, open a PR with `Closes #<issue-number>` in the body. Merge, delete the branch.

## Testing a change before release

- opencode: type `superfix: <small task>`. It reads the repo file through the symlink, so it is live on your current branch.
- Claude Code: `claude --plugin-dir ~/projects/skills-dev/superfix-<short-slug>` (the worktree). This loads that checkout for that one session only, without releasing anything.
- Try one Simple task and one Moderate task. Check the thing you changed actually happened.

## Releasing and deploying

Claude Code installs superfix through the marketplace repo `thedanielmay/claude-marketplace`, which points at this repo. A release is: new version here, matching version there, then pull it in.

1. In this repo, change `version` in `.claude-plugin/plugin.json` (for example `1.0.0` to `1.1.0`). Merge to `main`.
2. Tag and push: `git tag v1.1.0 && git push origin v1.1.0`.
3. In `thedanielmay/claude-marketplace`, change superfix's `version` in `.claude-plugin/marketplace.json` to the same number. Merge to `main`.
4. Pull it into Claude Code:
   - `claude plugin marketplace update thedanielmay`
   - `claude plugin update superfix@thedanielmay`
   - Restart Claude Code. The update only applies after a restart.
5. Check it worked:
   - `~/.claude/plugins/installed_plugins.json` shows the new version and the new commit SHA for `superfix@thedanielmay`.
   - `diff ~/.claude/plugins/cache/thedanielmay/superfix/<version>/skills/superfix/SKILL.md skills/superfix/SKILL.md` prints nothing.
6. opencode needs no deploy step. It already reads this checkout. Keep the clone on `main` when you are not mid-edit, so opencode runs released text.

Not yet confirmed by a real release: whether Claude Code needs the version bump to notice a change. Bump it every time until proven otherwise, then edit this line.
