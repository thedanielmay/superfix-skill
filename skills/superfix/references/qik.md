# Qik configuration

New in 1.7.5 ([superfix-skill#144](https://github.com/thedanielmay/superfix-skill/issues/144)). SKILL.md (Coverage check, Qik configuration row) says when to read this file: in full, before the Stop gate, whenever a problem's Coverage line is the Qik configuration row. A run with no Qik problem never reads it. The four rules moved here word for word from SKILL.md (Phase 3); briefs.md carries the same four rules for the fix agent.

### Qik configuration (provisional)
Qik configuration (provisional). Load the qik skill first. No branch.
Moderate or Complex Qik work: plan and context files go in `~/.superfix/journal/<name>/`,
never in a repo, and the fix agent brief carries the four rules below.
1. Back up before the first edit: the exact before text and the undo step, in a
   folder outside any repo. No backup, no edit.
2. Edit the draft only. Never publish. Say "in the draft", never "live".
3. Close the issue only after the owner replies "published" and the change is
   checked on the live site. The ready message ends: 'Reply "published" when
   you have published. To undo, tell me "undo P1". The backup is in <folder>.'
4. If the qik skill has no backup recipe for what you are changing, stop and
   ask. Do not invent one.
Qik records solved-check runs 1 and 2 only; run 3 (restore, then re-apply) goes under Not tested.
