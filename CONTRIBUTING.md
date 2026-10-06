# Working on superfix

Plain steps. This repo is a prompt-only skill, so "the code" is two identical markdown files.

## Where things live

- This clone: `~/projects/skills-dev/superfix-skill`. The only place you edit.
- `~/.agents/skills/superfix` is a symlink to this clone. opencode and anything else reading that path sees your checkout directly. Do not edit through it, edit here.
- `~/.claude/plugins/cache/thedanielmay/superfix/` is Claude Code's installed copy. Never edit it. A plugin update overwrites it.
- Work is tracked in GitHub issues. Start from the epic labelled `epic`.

## The two SKILL.md files must match

- `skills/superfix/SKILL.md` is the real one (the plugin loads this).
- `SKILL.md` at the root is a copy (the skills CLI and opencode load this).
- After every edit, run: `cp skills/superfix/SKILL.md SKILL.md`
- Check before every commit: `diff skills/superfix/SKILL.md SKILL.md && echo in-sync`

## Making a change

1. Pick an issue. Update main: `git switch main && git pull`.
2. Branch: `git switch -c fix/<issue-number>-<short-slug>`.
3. Edit `skills/superfix/SKILL.md`, then copy it to the root (above).
4. Test it (next section).
5. Commit, push, open a PR with `Closes #<issue-number>` in the body. Merge, delete the branch.

## Testing a change before release

- opencode: type `superfix: <small task>`. It reads the repo file through the symlink, so it is live on your current branch.
- Claude Code: `claude --plugin-dir ~/projects/skills-dev/superfix-skill`. This loads this checkout for that one session only, without releasing anything.
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
