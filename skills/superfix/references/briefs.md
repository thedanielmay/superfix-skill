# Execution brief

New in 1.3.0. Read only after the owner approves at the Stop gate. Agents never load SKILL.md, so a rule kept only there is invisible to them. The fix agent dispatch passes this file by absolute path and copies the brief below into the agent prompt. The review header and the fan-out brief used during diagnosis are in `references/diagnose.md`; review agents during execution get the review header written out in `references/execute.md`.

### Fix agent brief (Moderate, Complex; Phase 3)

FIX AGENT BRIEF (Moderate, Complex): branch, context file, plan file, Problem
Profile, execute.md path, this file's path, the budget and approval-sha from
the ## Decision section, the run folder written out in full (`$HOME/.superfix/runs/<run-key>`, list `secrets`).
Before every commit, run the budget commands; over any limit, stop and return
a message whose first line is exactly BUDGET STOP, then done, left, used
versus budget. Run the solved check before declaring done. Tick plan
checkboxes as you go.
PICTURES RULE (do not skip): every problem with a before picture gets an after
picture in solved-check run 2 (references/evidence.md, retake), or a stated
reason; return a `Pictures:` line (journal.md) with your result.
Return each retake's CROP-ALIGNED, CROP-WIDENED or CROP-DIFFERENT word with the picture name.

GitHub rule (the only one): you may commit locally, push the branch and open
the PR, each only after the redaction checks in references/redaction.md
(absolute path given, run on that literal folder) print CLEAN or NO-LIST, and PATTERN-CLEAN or hits you
decided, on the diff, the commit messages and the PR body file. Open the PR
with `--body-file`. Never post issue comments, edit the issue body or change
the Status line: return those results to the caller, which posts them.
Never add or remove labels and never write gap notes or diagrams; the main thread does those.
NO-RUN-FOLDER (the folder or its key file is missing) is a stop: commit,
push and post nothing, and return it to the caller.

After pictures: during solved-check run 2, take them with the script in
references/evidence.md (absolute path given) and save them in the run folder.
Never upload pictures: return their names; the caller runs the upload command.
Use the interpreter the caller names (its BROWSER-SCRIPT line), the same page,
size and target as the before picture, a green box and the same number:
`"<python>" "<run folder>/shot.py" retake --run "<run folder>" --source <before name> --name <after name>`
reads `evidence/<before name>.json` and takes it the same way (add --url or
--serve only if the page now lives in another folder). A before picture taken
on the MCP path: return that to the caller, which retakes it on that path.
A problem the owner could see on a screen needs an after picture, or a stated reason.
If the run's secrets list has any entry, say so with the names: the caller
keeps those pictures on the Mac until the owner says "post the pictures".

Qik work (copy into the brief when the coverage row is Qik configuration): no
git branch; plan and context files live in `~/.superfix/journal/<name>/`.
1. Back up before the first edit: the exact before text and the undo step, in a
   folder outside any repo. No backup, no edit.
2. Edit the draft only.
3. Never publish. Say "in the draft", never "live".
4. If the qik skill has no backup recipe for what you are changing, stop and
   return the question. Do not invent one.

Criteria mode: never edit the original or write into a cloud folder; never change a measure script or a criterion line; never call a send, share, publish or write tool on anything outside the repo and the run folder; return CRITERIA-CHANGED if the lock check fails.
Run measure scripts only through criteria.md's tool (`attempt` for every attempt, which measures by itself), never directly, and never with `--unsandboxed-ok` unless the caller says the owner said yes to the sandbox question. Never edit the attempts file, the records or the lock file.

Budget commands (copy into the brief with the real values):

```bash
git rev-list --count <approval-sha>..HEAD -- . ':(exclude)docs/superpowers/plans'   # commits
git diff --name-only <approval-sha>...HEAD                                          # files; any file not named = over
date                                                                                # time, minus the approval time
```

Solved check (copy into the brief; `<s1>`, `<s3>` are new folders from `mktemp -d`, written out in full):

```bash
git worktree add --detach <s1> <approval-sha> && git -C <s1> checkout <branch> -- <new or changed test paths>   # run 1 in <s1>: must fail
# run 2: the same check on the branch: must pass
git worktree add --detach <s3> HEAD && git -C <s3> diff <approval-sha>..HEAD -- . ':!test' ':!tests' ':!*.test.*' | git -C <s3> apply -R   # run 3 in <s3>: must fail
git worktree remove --force <path>; git worktree prune   # after each run, and whenever a step fails
```

Run 3 is not applicable for a behaviour-keeping refactor or a brand-new module or feature where taking the code out cannot fail meaningfully: say why and list it under Not tested; it does not count as a pass. Return all three outputs. Two failed run-2 attempts, whatever the cause: stop and return "My fix failed twice, so my diagnosis was wrong." with used versus budget.
