# Preservation justifications for 1.3.0

One line per 1.2.0 line that is removed or changed: `- <exact old line> :: <manifest row name>`. The manifest is section (d) D-1 of the 1.3.0 plan. `tests/preservation-check.py` reads this file.

## Justifications

- | `/issue "description"` | Use the text directly - do not search for a matching issue | :: Input row `/issue "description"` ("do not search for a matching issue")
- GitHub-specific steps (posting comments, closing) run only when an issue was referenced. When one is referenced, Read `references/journal.md` first (see the work journal section). :: "GitHub-specific steps (posting comments, closing) run only when an issue was referenced. When one is referenced, Read `references/journal.md` first"
- Post as first GitHub comment if issue exists: :: "Post as first GitHub comment if issue exists" plus the 🔍 command
- gh issue comment <N> --body "🔍 Problem Profile: [type] / [tier] - [one sentence summary]. Skill manifest: [list]. Starting exploration." :: "Post as first GitHub comment if issue exists" plus the 🔍 command
- When working from a GitHub issue, the issue is the single source of truth for the work. The body template, the progress comment triggers and the comment format are in `references/journal.md` (in this skill's base directory). Read it in full as soon as an issue is referenced, before the first comment or body edit, and write `Loaded: journal.md` in the Problem Profile comment. :: Work journal paragraph ("write `Loaded: journal.md` in the Problem Profile comment")
- ## Phase 1 - Explore :: "## Phase 1 - Explore" heading
- Read `references/explore.md` in full (this skill's base directory) and run the exploration listed for the primary type, and for the secondary type if there is one. Write `Loaded: explore.md` in the Phase 1 progress comment, or in your next message to the user if there is no issue. :: "Write `Loaded: explore.md` in the Phase 1 progress comment..."
- Re-assess the provisional tier. If scope is larger than described, upgrade and state why. Post updated comment if issue exists. :: Confirm tier after exploration; "Post updated comment if issue exists."
- Applies to **Moderate and Complex** only. Simple goes directly to Phase 3. :: "Applies to **Moderate and Complex** only. Simple goes directly to Phase 3."
- **Pass this file path to every subagent.** Every subagent reads the same source of truth. :: "**Pass this file path to every subagent.**"
- gh issue comment <N> --body "📋 Plan approved after expert panel review. Starting implementation. :: 📋 plan comment
- Key decisions: [brief summary]" :: 📋 plan comment
- Before implementing, Read `references/execute.md` in full (this skill's base directory). It holds the execute sequences by type, the code review rules and the test scope. Write `Loaded: execute.md` in the Phase 3 progress comment, or in your next message to the user if there is no issue. :: Phase 3 read execute.md; "Write `Loaded: execute.md` in the Phase 3 progress comment"
- On restart (limit, crash, new session): read the latest progress comment on the issue (if any), the plan file's task checkboxes, and `git log` on the branch. Continue from the first unfinished stage. Do not redo finished stages. :: Restart line
- If GitHub issue exists: :: 🚀 "PR created" comment, posted before CI watch
- gh issue comment <N> --body "🚀 PR #<PR> created - ready for review." :: 🚀 "PR created" comment, posted before CI watch
- | Plan already exists in `docs/superpowers/plans/` | Run exploration as normal; skip design step and `writing-plans`; create context file from existing plan; verify plan reflects current codebase state before expert panel | :: Shortcut: plan already exists
- - Subagents without the context file - undefined hand-offs produce blind reviews :: Red flags (13): changed "Subagents without the context file" (N1)
- - Upgrading Simple→Moderate/Complex after implementation has started - stop, commit/stash partial work, return to Phase 2, write a plan accounting for what's already implemented, run expert panel, then continue :: Red flags (13): changed "Upgrading Simple→..." (N6)
- - Editing the issue body for progress updates instead of adding a comment - body = current state, comments = history :: Red flags (13): changed "Editing the issue body for progress updates" (N7)
- Each significant phase transition gets a progress comment - not an edit to the body. Comments accumulate as a readable audit trail of what happened and when. :: journal.md "Progress comments = timestamped changelog... not an edit to the body."
- Required progress comment triggers: :: journal.md triggers list and ✅ format
- - Phase 0 complete: problem profile posted (already required above) :: journal.md triggers list and ✅ format
- - Phase 1 complete: complexity tier confirmed, key findings summarised :: journal.md triggers list and ✅ format
- - Phase 2 complete: plan approved after expert panel (already required above) :: journal.md triggers list and ✅ format
- - Phase 3 complete: implementation done, tests green, PR created (already required in Phase 4) :: journal.md triggers list and ✅ format
- gh issue comment <N> --body "✅ Phase N complete - [one sentence summary of outcome]. Next: [next step]." :: journal.md triggers list and ✅ format
- **This applies only when an issue was referenced.** Freeform-description invocations skip all GitHub journal steps. :: journal.md "Freeform-description invocations skip all GitHub journal steps."
- - Measure before planning: run actual timing/profiling. Record baseline numbers in context file. :: explore.md "Record baseline numbers in context file."
- - Verification re-runs the Phase 1 repro or baseline on the real surface (test, curl, CLI, Playwright, or the measured timing for performance), pastes the output, and states whether the issue's stated goal is met :: execute.md "Verification re-runs the Phase 1 repro or baseline..."
- Moved word for word from SKILL.md 1.1.1 (superfix-skill#42). SKILL.md says when to read this file. :: "Moved word for word from SKILL.md 1.1.1" first lines of journal, explore, execute


## Justifications, review pass 1

Lines changed by the review pass 1 decisions (coordinator, 19 Oct 2026). The reason for each is under "Review pass 1" in Deviations.

- F="$(mktemp)" :: journal.md awk logic and `--body-file` call
- printf '\n## Original report\n%s\n' "$ORIG" >> "$F" :: journal.md awk logic and `--body-file` call
- gh issue edit <N> --body-file "$F" :: journal.md awk logic and `--body-file` call

## Deviations

Places where the build differs from the plan, with the reason. Recorded by the builder (T0 to T15).

- T0: no commit, because T0 changes no file. The child issue also has the label `harness` (coordinator instruction) and is linked as a sub-issue of the epic.
- T2: `tests/prompts.md` has a three-line header above the section (g) text, which is otherwise copied word for word.
- T4, redaction.md: the plan's recipe was made runnable.
  - Added a `[ -s "$SECRETS" ]` guard. Found in the T4 test: macOS grep with an empty pattern file matches every line, so an empty session list would block every post.
  - Wrote the three pattern checks as concrete `grep` and `perl` commands. File names are written out, because zsh does not split a variable into several names.
  - Added an allowlist entry for the `Claude-Session:` commit trailer. Without it the keyword rule (`session:`) flags every commit message.
- T5, briefs.md: added the budget commands and the solved-check steps to the fix agent brief. Agents never load SKILL.md, so without them the brief names checks the agent cannot see.
- T6, diagnose.md: added one sentence on "Everything else" problems (no check can fail, findings low confidence) and a closing "Output: the evidence note" section that points at the journal.md template.
- T7: no testbed exists yet (T1 is the coordinator's) and `superfix-skill` is PUBLIC, so no scratch issue was created. Instead, the bash block in journal.md was run twice locally, with `gh issue view` and `gh issue edit` replaced by reads and writes of a local file. Result: `## Original report` appears once, the reporter text is byte-identical, and the Status line is line 1 and changed in place.
- T7: the decision message short form (Simple, one problem) carries the budget on its effort line, so it stays three lines plus "Go?".
- T8 and T14: the C2 lines "Write the result at the top of the Problem Profile:" plus three field lines became one sentence, because the Problem Profile block already has the same three lines (Coverage, Trigger, Evidence).
- T10 verify: "plan file's task checkboxes" also appears in the KEPT UNCHANGED line "The agent ticks the plan file's task checkboxes as each task completes." That line is in the Moderate and Complex path, where a plan always exists. The restart line has "if a plan exists".
- T11, frontmatter (D11): "It diagnoses first and stops for approval before fixing." was added as a new last line of the description instead of being inserted before "Triggers on:". D-1 has no row for the frontmatter, and this way no 1.2.0 line changes. Same for the intro (section (f) row 1): a new paragraph, the old line kept word for word.
- T14: SKILL.md was 472 lines after T11. To reach 391:
  - Moved to journal.md: the context file template (its intro sentence moved word for word), the plan comment, the final comment template, and the three plain coverage lines for the decision message.
  - Removed the 14 `---` section dividers in the body. No rule text was removed.
  - Merged the 1.2.0 "Exploration by type" paragraph in SKILL.md into the C3 paragraph (the heading still exists in explore.md).
  - Stop gate, Decision and redaction trigger, solved check and budget stay inline.
- T13: the preservation output is posted on the child issue once, after T14, so it shows the final text and saves a comment.
- Sizes: journal.md is 221 lines (plan estimate about 100), because of the T14 moves and the full template.
- Phase 0 heading kept as "## Phase 0 - Problem Profile". D3 names the phase "Intake, coverage check, Problem Profile", but D-1 has no row for a heading change. The new line "Run the Coverage check (Classification Rules) first, then type and tier." gives the order.
- inventory.md: its first line "Moved word for word from SKILL.md 1.1.1" was kept, because D-1 lists only journal, explore and execute for that change.
- CONTRIBUTING: besides the worktree rule and the preservation check, the "This clone" bullet and the `--plugin-dir` line were edited to match the worktree rule.

### Review pass 1

- Decision 1 (stateless redaction): journal.md writes the body to the fixed path `~/.superfix/check/body-<N>.md` and posts it in a separate call after the checks, because `F="$(mktemp)"` is lost between Bash calls. The awk logic and the `--body-file` post are unchanged in substance. The bash block was re-run twice locally (zsh): Original report once, reporter text identical, Status line 1.
