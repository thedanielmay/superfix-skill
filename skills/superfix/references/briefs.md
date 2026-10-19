# Agent briefs

New in 1.3.0. Agents never load SKILL.md, so a rule kept only there is invisible to them. Every dispatch passes this file by absolute path and copies the matching brief into the agent prompt. SKILL.md and `references/diagnose.md` say which brief goes to which agent.

### Review header

REVIEW HEADER (first line of every review agent brief):

```
Report only. Do not edit, write or create files, and do not run commands that
change anything. Return findings with confidence; the caller applies fixes.
```

- Use it for every review or read-only agent: the `pr-review-toolkit` agents (they have the Edit tool), `feature-dev:code-explorer`, `Explore`, a `general-purpose` reviewer, and every fan-out agent.
- After any such agent returns, run `git status --porcelain`. Any change means the agent broke the rule: revert it and say so.

### Fan-out brief (diagnosis, Phase 1)

FAN-OUT BRIEF: the review header, then: symptom (owner's words, any stated cause
removed), evidence so far, files or objects in scope, and for one agent:
"Argue for the strongest cause that is NOT <leading hypothesis>." Return facts
with the command that showed each, then inferences, separately.

```
<review header>
Symptom (owner's words, stated cause removed): <text>
Evidence so far: <failing check and its output, facts observed>
In scope: <files or objects>
[one agent only] Argue for the strongest cause that is NOT <leading hypothesis>.
Return: 1. facts, each with the command or tool that showed it. 2. inferences, separately.
```

- Never include the context file, the owner's guess at the cause, or your leading hypothesis (except as the thing the one agent argues against).

### Fix agent brief (Moderate, Complex; Phase 3)

FIX AGENT BRIEF (Moderate, Complex): branch, context file, plan file, Problem
Profile, execute.md path, this file's path, the budget and approval-sha from
the ## Decision section, the session redaction file path. Before every commit, run the
budget commands; over any limit, stop and return a message whose first line is
exactly BUDGET STOP, then done, left, used versus budget. Before every push or
post, run the redaction check (references/redaction.md, absolute path given).
Run the solved check before declaring done. Tick plan checkboxes as you go.
Do not post to GitHub; return results to the caller.

Budget commands (copy into the brief with the real values):

```bash
git rev-list --count <approval-sha>..HEAD -- . ':(exclude)docs/superpowers/plans'   # commits
git diff --name-only <approval-sha>...HEAD                                          # files; any file not named = over
date                                                                                # time, minus the approval time
```

Solved check (copy into the brief): run 1, the failing check from `## Problems` on approval-sha, fails. Run 2, the same check on the branch, passes. Run 3, in a scratch worktree of HEAD, reverse-apply the non-test part of `git diff <approval-sha>...HEAD`, run the check, expect failure, remove the worktree; the branch is never touched. Return all three outputs. Two failed run-2 attempts, whatever the cause: stop and return "My fix failed twice, so my diagnosis was wrong." with used versus budget.
