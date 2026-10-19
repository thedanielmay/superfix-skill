# Diagnosis method

New in 1.3.0. SKILL.md Phase 1 says when to read this file. The exploration skills in `references/explore.md` collect the evidence; this method decides what the evidence proves. Diagnosis does not fix anything. It ends at the Stop gate in SKILL.md.

Before approval the only writes allowed are the journal, a scratch folder outside the repo, and a detached worktree inside that folder (removed before the stop). No branch, no edits to tracked files, no Qik writes, no change to org data, roles or permissions.

### Method

1. Failing check first. Before any theory, run one check that fails on the
   reported symptom (test, command, curl, page check, Qik read-back, measured
   timing). Paste its output. For a feature, the check is the acceptance
   check that fails because the feature is absent. No failing check, no
   hypotheses.
2. Facts apart from inferences. List what was observed, each with the command
   or tool that showed it, separately from what you infer.
3. Differential. Write 3 to 5 ranked hypotheses. Each has a prediction that
   would prove it wrong. Test the cheapest discriminating prediction first.
   Keep "Ruled out, how" for each rejected one.
4. Confirmed means a filled row, using a test that is NOT the step-1 check:
   | Test | H1 predicts | H2 predicts | H3 predicts | Observed |
   Only the hypothesis whose prediction matches the observation is confirmed.
   Anything less is "suspected".
5. Siblings. Once confirmed, search for the same cause elsewhere (other
   callers, sections, forms). List each one found.
6. Scope. Diagnose only problems that explain the reported symptom. Anything
   else goes under "Seen, not diagnosed", one line each.
7. Self-audit before the stop. For each claim in ## Problems: was evidence
   skipped, misread, or missing? Fix it or downgrade to "suspected".

A report with several problems: run the method for each one (P1, P2, ...). A problem in the "Everything else" coverage row usually has no check that can fail. Say so in place of step 1, run steps 2 to 7 from what can be read, and mark every finding low confidence (never "confirmed" without a filled row).

### Stop rules

Stop rules, whichever comes first:
- Cause confirmed by a filled row: go to the Stop gate.
- 3 hypotheses falsified and none left that fits: go to the Stop gate with
  what was ruled out, and ask for a new lead.
- About 30 minutes, or 3 attempts at a feedback loop, without a failing check:
  go to the Stop gate and ask for the environment, account, data or file needed.
The 30 minutes covers the whole diagnosis. The 5-minute cap on the Explore
lookup in explore.md is one step inside it.

### Existing skills, with their limits

Existing skills, with their limits:
- systematic-debugging: Phases 1 to 3 only. Its Phase 4 (Implementation) waits
  for approval.
- diagnose: Phases 1 to 3 only. Its Phases 4 to 6 write files; never before
  approval. Its "don't block" rule is overridden by the Stop gate.
- Every other skill in explore.md: as listed there.

Already fixed: if the failing check cannot fail on current main, the escape
hatch in SKILL.md applies; it becomes question 1 of the decision message.

### Tools and fallbacks

Additions for diagnosis. Nothing is removed from `references/explore.md` or `references/inventory.md`.

| Tool | Use | If missing |
|---|---|---|
| exploration skills in explore.md | as listed per type | each one's fallback in inventory.md |
| built-in `Explore` agent | locate files and symbols | inline `grep` and `glob` |
| `general-purpose` subagent, report-only header | review-style reading | inline by the main thread |
| episodic memory search | past runs on the same code | skip; write "no history search" |
| `git log`, `git blame`, `git bisect` in the scratch worktree | when the symptom started | always present in a repo |
| Playwright MCP, else Claude in Chrome | reproduce a visible symptom | none; list "visual check" under Not tested |
| Qik read tools (`get_content`, `get_content_log`, `get_content_diffs`, `explain_access`, `search_interface_code`, `get_interface`) | Qik evidence | none; Qik diagnosis is then "Everything else" level, low confidence |

Missing tools fall back, never block, in this order: the named skill or agent; the built-in `Explore` agent; a `general-purpose` subagent with the report-only header from `references/briefs.md`; inline. Record what ran in `## Problems`, for example:
`Tools used: Explore (for feature-dev:code-explorer, missing), systematic-debugging phases 1 to 3, git log. Missing: Playwright.`

### Fan-out

Moderate and Complex, or Simple when the first hypotheses do not separate:
dispatch 3 to 4 read-only agents in one message, each with the fan-out brief
from briefs.md (absolute path in the dispatch). Each gets the symptom in the
reporter's words with any stated cause removed, the evidence so far, and the
files or objects in scope. Never the context file, never the owner's guess,
never your leading hypothesis. One agent argues for the strongest cause that
is NOT the leading hypothesis. Agents that read the same files and agree count
as one source. Afterwards run `git status --porcelain`; any change means an
agent broke the rule: revert it and say so in the decision message.

### Output: the evidence note

End of Phase 1, every tier: write `## Problems` in the issue body (or the file-mode journal), using the template in `references/journal.md`. Per problem: symptom, failing check and its output, baseline numbers (performance), cause (confirmed with its row, or suspected), Ruled out (how), Siblings. Then "Seen, not diagnosed", then the `Tools used:` line. Later steps (context file, solved check, restart) read the evidence from here.
