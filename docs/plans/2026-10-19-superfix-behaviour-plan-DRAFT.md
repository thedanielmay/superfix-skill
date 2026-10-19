# Plan: superfix 1.2.0 (diagnosis stage, issue contract, evidence, safe execution)

Written 19 Oct 2026 for the session that will execute it, and for the expert panel that reviews it first. Epic: [superfix-skill#34](https://github.com/thedanielmay/superfix-skill/issues/34). Coverage design: [superfix-skill#39](https://github.com/thedanielmay/superfix-skill/issues/39).

---

## (a) Summary for Daniel

### What changes for you

- **Superfix will stop and ask before it fixes anything.**
  - It first works out what is wrong, writes it on the issue (problems, evidence, options, a recommendation, a rough effort), and then waits.
  - You get one message with numbered questions. You answer in one line, for example "1 yes, 2 option two". "Keep going" or "keep executing" counts as yes to every recommendation.
- **If you give it a description with no issue, it offers to create one** in the repo you are in. If you say no, it keeps the same record in a file, `docs/superfix/<date>-<slug>.md`.
- **It tells you what kind of problem it thinks this is, and whether it covers that kind.**
  - Code and Qik settings: full diagnose and fix.
  - Process and sheet data: diagnosis only.
  - Documents, business and anything else: it says it does not cover it, does the general part marked "low confidence", and drafts a note about the gap for you to approve.
- **Every issue update starts with two plain lines for you**, then dense detail for AI readers.
- **The top line of the issue says where things stand**, for example "Waiting for you: 2 questions" or "Fixing P2" or "Stopped: Qik staging lag".
- **Visible problems get red-boxed screenshots**, before and after, when a browser tool is available. If none is available it says so in the "Not tested" list.
- **"Fixed" gets a real meaning.** The check fails before the fix, passes with it, and fails again when the fix is taken out for a moment. All three results go on the issue.
- **It has a budget you approve** (commits, time, size of change). If it runs over, or the same check fails twice for two different reasons, it stops and tells you instead of carrying on.
- **For Qik, nothing is published by Superfix.** It backs up first, edits the draft, tells you how to undo it, and closes the issue only after you publish.
- **Every final report has a "Not tested" list**, so you know exactly what was not checked (for example, how it feels on a real iPad).

### What you will notice

- One extra round trip on every run: the stop. It is one per run, not one per problem.
- One extra question at the start when you give a description with no issue ("create an issue?").
- Slightly longer issue bodies, but the top two lines of every comment are always readable in ten seconds.

### What it costs

- **Round trips:** usually +1 (the stop), +2 when there is no issue. The fast lane ("superfix, just fix it") removes the stop, only when you ask for it in that run, and only for small, single problem, non security work.
- **Size of the skill:** SKILL.md grows from 502 lines to about 760 (it is loaded every run). Release 1.3.0 then moves the long recipes into reference files and brings the always loaded part down. Section (b) says what stays inline and why.
- **Time per run:** diagnosis adds about 10 to 30 minutes on Moderate work; the three run check adds a few minutes on code and about 15 minutes on Qik (staging lag).

### Three questions for you (answer before execution starts)

1. **Qik "supported" claim.** [superfix-skill#39](https://github.com/thedanielmay/superfix-skill/issues/39) says a domain is "supported" only after its own test prompt passes. None of the five prompts is Qik. Recommendation: add prompt 6 (Qik, read only, on the qik skill's throwaway interface). Until it passes, the Qik row says "supported, provisional". Yes or no?
2. **Test repo.** The prompts need a private throwaway repo with planted bugs, `thedanielmay/superfix-testbed`. Recommendation: create it (task T1). Yes or no?
3. **Gap issues go to a public repo.** `superfix-skill` is public. Recommendation: Superfix never files a gap issue by itself; it puts a cleaned draft in the decision message and files it only on your yes. Yes or no?

---

## What I checked versus assumed

Checked (read or ran on 19 Oct 2026):
- `skills/superfix/SKILL.md` on `main` at `64dae1d`: **502 lines** (the brief said about 495; all line numbers below are from the 502 line file). Root `SKILL.md` is identical (`diff` clean). `plugin.json` version `1.1.1`, tags `v1.0.0`, `v1.1.0`, `v1.1.1`.
- README "Status" still says `1.1.0`. `plugin.json` description still says "merged PR" and contains an em dash.
- Epic [superfix-skill#34](https://github.com/thedanielmay/superfix-skill/issues/34) body and all four comments; roadmap issues 35 to 39; the research report; the khub master plan.
- Repo labels: no `superfix:*` labels exist. Releases: only `v1.0.0` (marked Latest); no `assets` release on `superfix-skill`. `khub` has an `assets` release.
- `superfix-skill` is **PUBLIC**. `khub` is PRIVATE.
- `gh label create` supports `--force`. `gh release create` supports `--latest=false`.
- Installed `diagnose` skill phases: 1 feedback loop, 2 reproduce, 3 hypothesise (says "don't block on it"), 4 instrument, 5 fix and regression test, 6 cleanup.
- The `qik` skill has **no backup or RESTORE recipe**. The closest is `references/gotchas.md` line 104 (copy `pre` and `post` SCSS with `get_content` before a style edit) and line 11 (write probes only on the throwaway interface `6ac976586ec796b19cf2e3a7`, scope `6ac976527335933f8093198d`). `kh_export.py` is local to the knowledgehub project.
- No testbed repo exists under `thedanielmay`.

Told by the coordinator, not checked by me:
- In the current session Playwright MCP, episodic memory, the `feature-dev` agents and the `pr-review-toolkit` agents are not available. They may return. The plan designs for both cases.

Assumed (not verified):
- Release asset image URLs render in issues on private repos for people with access. This worked on khub per its master plan rule 10; not re-tested.
- Claude Code reads the version from this repo's `plugin.json` (observed once at 1.1.1, not proven). The release steps bump both places anyway.
- Token use is not visible from inside a session in every harness.

---

## (b) Design decisions, with reasons

### D1. One file, new sections that map 1:1 to 1.3.0 reference files

- Every new block gets its own `##` heading and does not refer to line numbers or "above/below". In 1.3.0 each block moves whole into a reference file with no rewording.
- Planned 1.3.0 mapping: `## Coverage check` to `references/domains.md`; `## Diagnose` method detail to `references/diagnose.md`; `## Evidence screenshots` to `references/screenshots.md`; `## Delivery modes` detail to `references/delivery-publish-gated.md`; issue templates to `references/journal.md`; inventory table to `references/inventory.md`.

### D2. Phase layout after 1.2.0

| Phase | Name | New or changed |
|---|---|---|
| 0 | Intake: input, coverage check, Problem Profile | changed |
| 1 | Diagnose (replaces "Explore"), ends at the **Stop gate** | changed, largest block |
| 2 | Design and plan (Moderate, Complex), after approval | small change |
| 3 | Execute, with budget and the three run check | changed |
| 4 | Close: `git-pr` or `publish-gated` | changed |

Reason: the stop sits between diagnosis and planning, so the plan is written against an approved option. The expert panel still runs at the plan to code step (Phase 2). If a panel must-fix overturns the chosen option or breaks the budget, Superfix loops back to Options and asks again (one batched message). It never carries on quietly.

### D3. The issue body is the contract and the evidence note

- `## Problems` in the issue body (or the fallback file) is the evidence note required by requirement 10. It is written at the end of Phase 1 for every tier, so baseline numbers, repro output and the failing check always have a home before Phase 2 exists.
- The old context file (lines 233-260) stays for Moderate and Complex execution, but it points to the issue or fallback file instead of copying the full report. That removes the owner's guessed cause from what diagnosis agents receive (see D6).

### D4. Simple work also stops, in a short form

- The stop applies to every tier. For Simple work with one problem, the stop message is three lines (problem, fix, effort) plus "go?".
- The fast lane is opt in per run only. Reason: Daniel's decision, and the lean critic's warning that a default fast lane becomes the habit on tangled bugs.

### D5. Writes allowed before approval (the "no edits" rule made precise)

- Allowed: the journal (issue body, comments, labels, or the fallback file); a scratch folder outside the repo; a detached git worktree in that scratch folder (removed before the stop); for Qik, write probes **only** on the qik skill's throwaway interface (gotchas.md line 11).
- Not allowed: a branch, edits to tracked files, any write to the real Qik draft, any change to org data, roles or permissions.
- Reason: "confirmed" needs a discriminating test, and some tests need a probe. The probe goes somewhere disposable.
- This keeps Daniel's decision "use `diagnose`, stop before its phases 4 and 5". `diagnose` phase 4 (instrument) is not invoked; our own method allows probes only in the scratch worktree.

### D6. Fan-out briefs carry the symptom, not the guess

- Diagnosis subagents get a separate short brief: the symptom in the reporter's words with any stated cause removed, the evidence so far, and the files or Qik objects in scope. Never the context file, never the owner's guess.
- One agent is told to argue for a different cause than the leading hypothesis.
- Agents that read the same files and agree count as one source.

### D7. Missing tools degrade, they never block (coordinator's new fact)

- Every named tool has a fallback, in this order: the named agent or skill; the built-in `Explore` agent (search and locate); a `general-purpose` subagent with a "report only, no edits" brief (review style work); inline by the main thread.
- The coverage result and `## Problems` record a `Tools used:` line naming what actually ran and what fell back. Example: `Tools used: Explore (for feature-dev:code-explorer, missing), diagnose phases 1 to 3, git log. Missing: Playwright (screenshots not taken, see Not tested).`
- No browser tool (Playwright MCP, `webapp-testing`, or Claude in Chrome): screenshots are skipped, the skill says so in the stop message, and "visual evidence" goes under Not tested. It never fakes visual evidence with a description.

### D8. Redaction applies to everything Superfix posts

- Applies to: `## Decision`, the go signal comment, an `## Original report` that Superfix writes from chat text when it creates the issue, pasted command output and logs, and screenshots (check the image before upload).
- It overrides epic comment 2, which said Decision "quotes his words" and the go reply is "recorded as a comment". Those are paraphrased now.

### D9. Public repos change what gets posted

- Gap issues go to `thedanielmay/superfix-skill`, which is public. They contain only the problem kind, the matched row, the general shape of what was tried, and what a playbook would need. No names, no file contents, no organisation details. Filed only on Daniel's yes (open question 3).
- Before uploading screenshots to any repo, check `gh repo view --json visibility`. On a public repo, ask first in the decision message.

### D10. Line budget, and inline versus 1.3.0

| Block | Est. lines | Keep inline in 1.3.0? | Reason |
|---|---|---|---|
| Input handling (rewrite) | +12 | yes, router | every run starts here |
| Coverage check and domain table | +30 | table moves; the 6 rule lines stay | the rules prevent false "supported" claims |
| Diagnose method and stop rules | +45 | **yes, evidence rules stay inline** | practitioner: they get skipped under load if moved |
| Diagnosis tools and fan-out | +18 | moves | lookup content |
| Stop gate, decision message, fast lane | +30 | **yes** | the most behaviour critical block |
| Decision paraphrase and redaction | +10 | **yes** | secret leak is severity 5 |
| Issue contract template, labels, status line (replaces 80-115) | +25 net | template moves, rules stay | |
| Callout template and triggers table (replaces 117-130) | +20 net | **template stays** (short), triggers table moves | |
| Evidence screenshots recipe | +22 | moves | long, only for visible problems |
| Three run check | +14 | **yes** | defines "solved" |
| Budget and loop back | +14 | **yes** | stops runaway runs |
| Delivery modes | +18 | publish-gated detail moves | |
| Not tested, close changes | +6 | yes | |
| Red flags, frontmatter, inventory rows, small fixes | +10 | | |
| **Total** | **about +275 gross, about +255 net, about 757 lines** | | |

- **Ceiling:** if SKILL.md exceeds 780 lines after T16, cut wording before release (not rules).
- **Panel disagreement:** the prompt engineer wants evidence rules in a reference file; the practitioner wants them inline so they are not skipped. This plan keeps them inline in 1.2.0 (everything is inline anyway) and recommends they **stay inline in 1.3.0** too: the stop gate, the "confirmed" definition, the three run check, the budget, redaction, and the callout template, about 90 lines. Everything else moves.

### D11. Trigger wording

- Frontmatter lines 2-9 and line 14 say "opened PR" and "in code". New wording: "...drives it to an opened PR, or for Qik to a draft change ready for the owner to publish. It diagnoses first and stops for approval." Trigger list adds "or a request to fix or change something on Qik".
- Other domains are reached only by typing `/superfix` (Daniel's decision: diagnosis only there, so the auto trigger should not fire on them).

---

## (c) Section outlines and draft wording

Each subsection names its home in SKILL.md. Draft text is meant to be pasted, then trimmed.

### C1. `## Input Handling` (replaces lines 36-46)

| Input | What to do |
|---|---|
| `#N` | `gh issue view N --comments`. Read title, body, labels, all comments |
| Description, inside a git repo with a GitHub remote | Search: `gh issue list --state open --search "<3 key words>" --limit 5`. Then ask once: "No issue given. Create one in `<owner/repo>` and keep the record there? (yes / no, keep it in a file)". Show any matches found |
| Description, not a git repo, but the project `CLAUDE.md` names a GitHub tracker | Same offer, using that repo (Qik projects work this way) |
| Description, no repo and no named tracker | File only, no question |
| No arguments | Ask: "GitHub issue number or describe what needs doing?" |

- On yes: create the issue with the reporter's text (redacted, see C6) under `## Original report`, then do all intake and diagnosis work in it.
- On no, or file only: write the same sections to `docs/superfix/<YYYY-MM-DD>-<slug>.md` in the working folder. Comments become dated `### <HH:MM> <phase>` entries at the end of that file. The status line is its first line.
- If `gh issue view` fails, surface the error and ask whether to continue with the file instead or abort (keeps line 46).

### C2. `## Coverage check` (new, Phase 0, before Classification Rules)

Domain table:

| Domain | Recognisers | Failing check looks like | Done means | Fix loop | Status |
|---|---|---|---|---|---|
| Code | repo files, stack trace, test, CLI output, a page served from this repo | a test, command, curl or browser check that fails | three run check passes | yes, `git-pr` | supported |
| Qik configuration | Qik interface, section, form, role, workflow, definition, a `qik.dev` URL, `mcp__*qik*` tools | Playwright check on the draft site, record read-back, `explain_access` trace | three run check passes in the draft, then Daniel publishes | yes, `publish-gated` | supported, provisional until test prompt 6 passes |
| Process | handoffs, late or missed steps, "always", "every week", rates | a missing handoff output, a cycle time over target | not provable in one session | no | partial: diagnosis only, missing: baseline metric and re-check ([superfix-skill#36](https://github.com/thedanielmay/superfix-skill/issues/36)) |
| Sheet data | a Google Sheet, duplicates, wrong totals, broken formulas | a count that is wrong | no | no | partial: diagnosis only, missing: sheet-health checker ([superfix-skill#37](https://github.com/thedanielmay/superfix-skill/issues/37)) |
| Documents, business, other | a doc, deck, email, plan, strategy, anything not above | none available | none | no | not covered ([superfix-skill#35](https://github.com/thedanielmay/superfix-skill/issues/35)) |

Draft rules (stay inline in 1.3.0):

```
Run the coverage check before classifying type or tier. Write the result as the
first block of the Problem Profile:

  Coverage: <supported | partial | not covered>, row <Domain>
  Trigger:  "<exact words from the report that matched the row>"
  Evidence: <one observation that confirms the row, e.g. the file path exists,
             the Qik tool returned the interface>
  Tools used: <what ran, and what fell back because it was missing>

- Never write "supported" without the quoted trigger AND the confirming
  observation. If either is missing, the outcome is "partial" at best.
- Compound reports: split into parts and classify each part. Each part keeps
  its own outcome. Supported parts continue; the others stop at diagnosis.
- Partial: run Phase 1 in full, mark every finding "diagnosis only", and say
  what is missing to fix and prove it fixed. No fix loop, even if approved.
- Not covered: say so in the first callout. Do only the general part (facts,
  hypotheses, what would prove each), labelled "low confidence". No fix loop.
- Partial and not covered: draft a gap issue (template below) and put it in
  the decision message. File it only on a yes.
- Superfix never edits its own skill files. New playbooks are built and
  approved by Daniel.
```

Gap issue template (filed on `thedanielmay/superfix-skill`, public, so nothing private):

```
Title: Gap: <domain> problem, <generic one-line shape>
Labels: superfix:gap
> **In plain English:** Superfix was asked to fix a <domain> problem it does
> not cover. This records what a playbook would need.

- Matched row: <row>, outcome <partial | not covered>
- Shape of the problem: <generic, no names, no file contents, no org details>
- What was tried: <general diagnosis steps, tools used>
- What a playbook would need: <failing check, done means, tools>
- Related roadmap: <link to 35, 36 or 37 if it fits>
```

Before drafting: `gh issue list --repo thedanielmay/superfix-skill --label superfix:gap --search "<domain>"`. If one exists, draft a comment on it instead.

### C3. `## Phase 1 - Diagnose` (replaces lines 165-204)

Method (stays inline in 1.3.0):

```
Diagnosis finds what is wrong and proves it. It does not fix anything.
Allowed writes before approval: the journal, a scratch folder outside the repo,
a detached worktree in that scratch folder (remove it before the stop), and for
Qik only the qik skill's throwaway interface. No branch. No edits to tracked
files. No writes to the real Qik draft, org data, roles or permissions.

1. Failing check first. Before any theory, run one check that fails on the
   reported symptom (test, command, curl, browser check, Qik read-back,
   explain_access, measured timing). Paste its output. For a feature, the
   failing check is the acceptance check that fails because the feature is
   absent. No failing check, no hypotheses.
2. Facts apart from inferences. List what was observed (with the command or
   tool that showed it) separately from what is inferred.
3. Differential. Write 3 to 5 ranked hypotheses. Each has a prediction that
   would prove it wrong. Test the cheapest discriminating prediction first.
   Keep "Ruled out, how" for every rejected hypothesis.
4. Confirmed means: tool output, a measurement or a source document backs it,
   AND a discriminating test came out the way this cause predicts and the
   others do not. Anything less is "suspected".
5. Siblings. Once a cause is confirmed, search for the same cause elsewhere
   (other callers, other sections, other forms). List each sibling found.
6. Scope. Diagnose only problems that explain the reported symptom. Anything
   else goes under "Seen, not diagnosed" with one line each.
7. Self-audit before the stop. For every claim in ## Problems, check: was any
   evidence skipped, misread, or is the claim unsupported? Fix or downgrade
   to "suspected" before posting.

Stop rules (whichever comes first):
- Cause confirmed by a discriminating test: write it up, go to the Stop gate.
- 3 hypotheses falsified and none left that fits: stop, post what was ruled
  out, ask for a new lead.
- About 30 minutes or 3 attempts at a feedback loop without a repro: stop and
  ask for the environment, account, data or artefact needed.
```

Already-fixed escape hatch (line 161) stays and moves here: it ends at the Stop gate with "already fixed?" as question 1.

Tools (moves to `references/diagnose.md` in 1.3.0):

| Role | Use | If missing |
|---|---|---|
| Core | the method above | always available |
| Core | `diagnose` phases 1 to 3 only; never 4 to 6; its "don't block" rule is overridden by the Stop gate | inline method |
| Core | `feature-dev:code-explorer` (trace paths) | built-in `Explore` agent |
| Core | `Explore` (locate files, symbols) | inline `grep`/`glob` |
| Core | episodic memory search (past runs on the same code) | skip, note "no history search" |
| Core | `git log`, `git blame`, `git bisect` in the scratch worktree | always available in a repo |
| Situational, max 2 | `pr-review-toolkit:silent-failure-hunter` on existing files | `general-purpose` subagent, report only brief |
| Situational | `code-security-audit` (security type) | inline review against the same checklist |
| Situational | `architecture-deep-dive` | inline structural review |
| Situational | `accessibility` | inline WCAG 2.2 check |
| Situational | Playwright (repro and screenshots) | Claude in Chrome if present; else no screenshots, listed under Not tested |
| Situational | Qik read tools: `get_content_log`, `get_content_diffs`, `explain_access`, `explain_persona_permissions`, `search_interface_code`, `get_interface` | none: Qik diagnosis needs the Qik MCP; if absent, outcome is partial |

- `systematic-debugging` (line 172) is dropped from diagnosis: it goes straight to fixing. It stays usable in execution through TDD.
- `grepai-trace-graph` (lines 177, 188): binary missing per epic comment 3. Keep the row, add "if missing, inline recursive search". Removal is 1.3.0.

Fan-out (Moderate and Complex, or Simple when the first 3 hypotheses do not separate):

```
Dispatch 3 to 4 read-only agents in one message. Every brief starts:
"Report only. Do not edit, write, create files, or run commands that change
anything." (pr-review-toolkit agents have Edit; this line is required.)
Each brief holds: the symptom (reporter's words with any stated cause removed),
the evidence so far, the files or objects in scope. Never the context file,
never the owner's or your leading guess. One agent's brief says: "Argue for the
strongest cause that is NOT <leading hypothesis>." Agents that read the same
files and agree count as one source. After they return, run `git status
--porcelain`; any change means an agent broke the rule: revert it and say so.
```

### C4. `## Problem record` (the contract; replaces the template at lines 80-115)

Body layout, top to bottom (Superfix owns everything above `## Original report`):

```
**Status:** <Waiting for you: N questions | Diagnosing | Fixing P2 | Ready to publish | Stopped: reason> (updated <YYYY-MM-DD HH:MM>)

## Summary            <one paragraph, kept from 1.1.1>
## Problems           P1..Pn. Each: symptom, failing check and its output (or before screenshot),
                      cause (confirmed | suspected), Ruled out (how), Siblings. Then "Seen, not
                      diagnosed". Then "Tools used:".
## Options            Per problem, 2 or 3 options, trade-offs, rough effort, one marked Recommended.
                      Proposed budget (see C9).
## Decision           Empty until Daniel answers. Then a paraphrase (see C6).
## Split              Only if more than one problem: child issues in order, "blocked by" links.
## Done when          The exact check(s) verification re-runs, and Daniel's own description of
                      the problem quoted (redacted) as the acceptance criterion.
## Plan               Only when a plan file exists (kept from line 85).
## Out of scope       kept from 1.1.1
## Original report    reporter's text, never edited after first copy
```

- Old `## Scope` and `## Key decisions` fold into `## Options` and `## Decision`. `## Summary`, `## Plan` and `## Out of scope` survive.
- The bash template at lines 87-115 keeps its awk logic (it already preserves everything from `## Original report` down). Only the heredoc content changes. T5 re-tests it twice on the testbed.
- Status line: updated in place on every trigger in C7. That is a body edit by design. Red flag line 460 gets a carve-out: "except the Status line, which is always updated in place".

Labels (bookkeeping, Daniel never touches them):

```
gh label create superfix:awaiting-decision --color FBCA04 --force --repo <r> \
  --description "Superfix is waiting for the owner"
gh label create superfix:approved --color 0E8A16 --force --repo <r>
gh label create superfix:gap --color 5319E7 --force --repo <r>
```

- If label creation fails (no permission), use a hidden marker as the last line of the stop comment: `<!-- superfix:state=awaiting-decision -->` (or `approved`). Resume reads labels first, then the newest marker.
- Split: create child issues with `gh issue create`, each body linking the parent as `[repo#N](url)` built from the number in code; parent gets the `epic` label if the repo has one.

### C5. `## Stop gate` (new, end of Phase 1; stays inline)

```
STOP GATE. Every tier, every run, unless the fast lane was asked for in this run.

Before stopping:
1. Problems, Options, Split, Done when are written in the record.
2. Status line: "Waiting for you: <N> questions".
3. Label superfix:awaiting-decision (or marker).
4. Post ONE decision comment (callout template, C7). It holds all questions for
   this run, numbered, each with the recommended answer:
     1. P1: option A (recommended) or B?  Effort: about 1 hour.
     2. Budget: 5 commits, 2 hours, about 200 changed lines. OK?
     3. File the gap draft below on superfix-skill? (yes / no)
   Simple, one problem: three lines (problem, fix, effort) and "Go?".
5. Say the same in chat and end the turn. Do not create a branch, edit tracked
   files, write to the Qik draft, invoke writing-plans, TDD or any Phase 2 or 3
   step until a go signal arrives.

Go signals: "yes", "go", "1 yes 2 B", "keep going", "keep executing", "do it",
or any reply that answers every question. "Keep going" style replies accept
every recommendation. A reply that answers some questions: ask only the rest.
Anything else (a question, a new fact): answer it, update the record, stay
stopped.

On go: write ## Decision (C6), remove awaiting-decision, add approved, record
the approval time (start of the budget clock), status "Fixing P1", post a
"Decision recorded" comment.

Fast lane: only when the request in THIS run says so ("just fix it", "fast
lane", "don't wait"). Allowed only if: one problem, Simple tier, coverage
supported, type is not security, no role, permission or data change. Then
still run Phase 1 and write Problems, post the decision comment as a notice,
and continue without waiting. Otherwise say in one line why the fast lane
does not apply and stop as normal. Publishing still waits for Daniel.
```

### C6. `### Decision paraphrase and redaction` (inside Stop gate; stays inline)

```
## Decision is written only after Daniel answers. Paraphrase it in your own
words: what was chosen, for which problem, any condition. Never paste his
message. Example: "P1: option A. P2: deferred to a child issue. Budget as
proposed." Then "Approved by the owner in chat, <YYYY-MM-DD HH:MM>."

Redact before anything is posted (Decision, comments, an Original report you
create from chat text, pasted output, logs, screenshots):
- values after password, passwd, pwd, secret, token, key, apikey, auth,
  bearer, cookie, session (any case, any separator)
- strings that look like credentials: sk-..., ghp_/gho_/github_pat_..., at-...
  (Qik API tokens), AKIA..., eyJ... (JWT), -----BEGIN ... KEY-----,
  ://user:pass@ in URLs, any run of 24+ base64 or hex characters
Replace each with [redacted]. If unsure, redact. For screenshots: look at the
image; if a secret or personal data is visible, re-take with it hidden or do
not post it. After posting, re-read the posted text and check again.
```

### C7. `## Issue journal` (replaces lines 117-132)

Callout template (stays inline):

```
> **In plain English:** <what was just done, one sentence>. <what is needed from
> you, or "Nothing needed from you right now.">

**Phase:** <name>  **Status:** <same as the status line>
<dense detail for AI readers: evidence, commands and output (redacted),
links built from numbers in code, open hypotheses, next step>
<!-- superfix:phase=<name> -->
```

- The callout is two lines at most, plain words, no jargon, no emoji, no dashes used as punctuation.
- Post with `gh issue comment <N> --body-file <file>`, never inline `--body` (quoting breaks on long text).
- File mode: the same block appended to the fallback file under `### <YYYY-MM-DD HH:MM> <phase>`.

Triggers (moves to `references/journal.md` in 1.3.0):

| When | Comment | Status line |
|---|---|---|
| Issue created or adopted, coverage and Problem Profile done | Profile, coverage result, tools used | Diagnosing |
| Stop gate | Decision request | Waiting for you: N questions |
| Go received | Decision recorded | Fixing P1 |
| Plan confirmed after panel (Moderate, Complex) | Plan and key decisions | Fixing P1 |
| Each child issue or problem done | Three run results, after screenshots | Fixing P<next> |
| Budget breached, or same check failed twice | Stopped, with attempts and live hypotheses | Stopped: <reason> |
| Diagnosis proved wrong | "Diagnosis was wrong" (C10) | Waiting for you: N questions |
| PR opened and CI green | Results, Not tested list, PR link | Ready for review |
| Draft ready (publish-gated) | Results, Not tested, restore step | Ready to publish |
| Published and checked | Snapshot id, production check | Done |

- Phase 3 agents get the issue number and own these comments (replaces lines 312-314 "surfaces only blockers").

### C8. `## Evidence screenshots` (new; moves to `references/screenshots.md` in 1.3.0)

```
Applies when the problem is visible on a page (code with a UI, Qik sites).
Does not apply when there is no visible surface (CLI, API, library, data,
permissions with no UI change): write "Screenshots: not applicable, no visible
surface" in Problems.

Needs a browser tool: Playwright MCP, else webapp-testing, else Claude in
Chrome. If none is available, say so in the stop message and list "before and
after screenshots" under Not tested. Never describe a screenshot you did not
take.

When: BEFORE shots at diagnosis, one per problem. AFTER shots when solved,
same viewport, same URL, same numbering. For Qik the surface is the draft
(staging) site, after the loaded-change check.

Recipe (tested 19 Oct 2026):
  await page.evaluate(({sel, n}) => {
    const el = document.querySelector(sel);
    if (!el) throw new Error('no match: ' + sel);
    el.scrollIntoView({block: 'center'});
    const r = el.getBoundingClientRect();
    if (r.width === 0 || r.height === 0) throw new Error('zero size: ' + sel);
    const box = document.createElement('div');
    Object.assign(box.style, {position: 'fixed', left: r.left - 4 + 'px',
      top: r.top - 4 + 'px', width: r.width + 8 + 'px', height: r.height + 8 + 'px',
      border: '3px solid #e00', boxShadow: '0 0 0 2px #fff',
      pointerEvents: 'none', zIndex: 2147483647});
    const tag = document.createElement('div');
    tag.textContent = String(n);
    Object.assign(tag.style, {position: 'fixed', background: '#e00',
      color: '#fff', font: '700 14px sans-serif', padding: '2px 6px',
      pointerEvents: 'none', zIndex: 2147483647});
    // place the label in clear space: right of the box if it fits, else left,
    // else below; never over text
    const right = r.right + 8, fitsRight = right + 30 < innerWidth;
    tag.style.left = (fitsRight ? right : Math.max(4, r.left - 34)) + 'px';
    tag.style.top = Math.max(4, r.top) + 'px';
    document.body.append(box, tag);
  }, {sel, n});
  await page.screenshot({path: shotPath});

- An abort (no match, zero size) means fix the selector. Never post the shot.
- Always open the saved image and look at it before posting: box on the
  right thing, label not covering text, no secret or personal data visible.
- Save outside the tracked tree: a scratch folder, or <repo>/.superfix-shots/
  added to .git/info/exclude (local only, never committed).
- Name: <issue>-<before|after>-<n>-<slug>.png (one assets release per repo,
  names must not collide across issues).
Hosting (gh cannot attach images to comments):
  gh repo view --json visibility -q .visibility   # public: ask first
  gh release view assets >/dev/null 2>&1 || gh release create assets \
    --latest=false --title "Asset host" \
    --notes "Hosts images referenced from issues and docs"
  gh release upload assets <files> --clobber
  URL: https://github.com/<owner>/<repo>/releases/download/assets/<name>
Reference by URL in the comment: ![P1 before](<url>)
```

### C9. `### Budget` (inside Phase 3; stays inline)

```
The budget is proposed in ## Options and fixed at approval. Defaults:

| Tier     | Commits after approval | Wall clock | Diff size                         | Agent dispatches |
|----------|------------------------|------------|-----------------------------------|------------------|
| Simple   | 3                      | 1 hour     | 3 files, 150 changed lines        | 4                |
| Moderate | 10                     | 4 hours    | plan files + 2, 600 changed lines | 15               |
| Complex  | stated in the plan     | stated     | stated                            | stated           |

Measure at every progress comment:
  commits:   git rev-list --count <approval-sha>..HEAD
  diff:      git diff --shortstat origin/<base>...HEAD  (files, lines)
  time:      now minus the approval time in ## Decision
  tokens:    use the harness's usage figure if shown; otherwise count agent
             dispatches and review passes as the proxy
  Qik:       count draft writes instead of commits; diff = sections touched
             versus the plan
Over any ceiling: stop, status "Stopped: over budget (<which>)", post what is
done and what is left, and ask: extend, cut scope, or stop. Never continue
past a ceiling on your own.
The review pass caps (max 2 review passes, max 2 panel passes) stay as they are.
```

### C10. `### Three run check` and loop back (inside Phase 3 verification; stays inline)

```
"Solved" means all three runs below, recorded on the record with output:
  Run 1, base fails:   the failing check from ## Problems on the base state
                       (already recorded at diagnosis; re-run it if the base moved).
  Run 2, fix passes:   the same check on the branch (or the Qik draft).
  Run 3, revert fails: the fix taken out for a moment, check fails again.
     Code: in a scratch worktree of HEAD, reverse-apply the non-test part of
     `git diff origin/<base>...HEAD`, run the check, expect failure, remove
     the worktree. The branch is never touched.
     Qik: apply the RESTORE step to the draft, wait for the loaded-change
     check, run the check, expect failure, re-apply the fix, check it passes
     again. This also proves the restore step works.
The acceptance criterion is Daniel's own description of the problem, quoted
(redacted) in ## Done when. Run 2 must show that description no longer holds.

If run 3 passes (the check does not detect the bug), the check is wrong: fix
the check, not the code, and re-run all three.

Same check fails twice, each time with a different "root cause": stop. Post
"Diagnosis was wrong" with the failed attempts and the live hypotheses, remove
superfix:approved, add superfix:awaiting-decision, return to ## Options, and
ask again. Never re-diagnose quietly. The same applies if the run 1 check does
not fail on the base, or a panel must-fix overturns the chosen option.
```

Qik equivalents and limits:

| Problem kind | Run check | Notes |
|---|---|---|
| Style, layout, behaviour on the site | Playwright check on the draft site after the loaded-change check | staging lags 2 to 6 minutes |
| Record or setting value | `get_content` read-back of the field | |
| Access, visibility | `explain_access` trace for the persona | |
| Role, permission, definition change | run 3 is skipped: these are live org changes, not draft | list under Not tested, ask Daniel |
| Feel on a real device, real Safari touch, production after publish | cannot be run by Superfix | always listed under Not tested |

### C11. `## Delivery modes` (new, chosen in Phase 0 Problem Profile)

```
Delivery: git-pr | publish-gated

git-pr: the existing branch, PR and CI path (Phases 3 and 4 as written).

publish-gated (Qik, and any platform with a draft and a publish step, no branch):
1. Before the first edit, make a backup folder with a RESTORE note: what is
   changed, the exact before text, the exact undo step. If the backup does not
   exist, do not edit.
2. Edits land in the draft only. Say "in the draft", never "live".
3. Reviews that need a diff are done by reading the before and after text;
   say "reviewed by reading the diff".
4. Daniel publishes, or says "publish" for this change. Superfix never
   publishes on its own.
5. Every "ready to publish" callout names the restore step in plain words.
6. The issue closes only after the publish is done and checked on production.
Platform mechanics (how to back up, what publish sends, staging lag, which
server) come from the platform's skill: load the `qik` skill. If that skill
has no backup recipe for what you are changing, stop and ask; do not invent
one.
```

- Today the qik skill covers only the SCSS case (gotchas.md line 104) and the throwaway interface (line 11). A general backup and RESTORE recipe is a dependency, see (g).

### C12. `## Phase 4 - Close` changes (lines 422-433)

- Post "ready for review" only after `gh pr checks --watch` is green (fixes the order of lines 428 and 433).
- Required in the PR body, the final comment and the issue (status line plus a `## Not tested` block in the final comment):

```
## Not tested
- <each thing not checked, and why: no browser tool, real device, production,
  live org change, flaky check, out of scope>
```

- An empty list must say "Nothing known untested", never be left out.

---

## (d) Task list, in execution order

Rules for every task: one commit per task on the release branch; after each edit run `cp skills/superfix/SKILL.md SKILL.md && diff skills/superfix/SKILL.md SKILL.md && echo in-sync`; check no dashes with `grep -nP '[\x{2013}\x{2014}]' skills/superfix/SKILL.md` (expect nothing). Rollback for any task: `git revert <that commit>`.

- [ ] **T0. Preconditions.** `git switch main && git pull`; `diff` the two SKILL.md copies; `wc -l` shows 502. Daniel has answered the three questions in (a). Create one child issue of the epic, "1.2.0: diagnosis stage, issue contract and safe execution", body linking [superfix-skill#34](https://github.com/thedanielmay/superfix-skill/issues/34) and [superfix-skill#39](https://github.com/thedanielmay/superfix-skill/issues/39). Branch `feature/<child>-superfix-1-2-0`.
  - Files: none. Check: branch exists, child issue open and assigned to Daniel. Rollback: delete branch.
- [ ] **T1. Testbed repo** (needs Daniel's yes, question 2). Private `thedanielmay/superfix-testbed`: a static page plus a tiny JS module with planted defects for prompts 1 to 5 (see (f)), a test runner (`node --test`), and `RESET.md` (delete issues, branches, labels, the `assets` release; `git reset --hard seed`). Tag `seed`.
  - Check: `node --test` shows the planted failing test for prompt 1 and passes the rest. Rollback: delete the repo.
- [ ] **T2. Test suite file.** Add `tests/prompts.md` to superfix-skill with section (f) verbatim. Not loaded at runtime.
  - Files: `tests/prompts.md`. Check: file present, no dashes. Rollback: revert.
- [ ] **T3. Before run on 1.1.1.** Run prompts 1 to 5 (and 6 if approved) against installed 1.1.1 on the testbed, reset between runs. Post results on the epic as a table (prompt, pass or fail per criterion, notes). Expected: 1.1.1 fails prompt 5 (no stop) and most new criteria.
  - Check: comment posted with the table. Rollback: none needed.
- [ ] **T4. Callout template and journal section** (C7). Replace lines 117-132. Replace the comment formats at lines 67-70, 129, 272, 428 with "post with the callout template".
  - Check: `grep -n '🔍\|✅\|📋\|🚀' skills/superfix/SKILL.md` finds nothing; `grep -c 'In plain English' ` is at least 1.
- [ ] **T5. Problem record template, labels, status line** (C4). Replace the heredoc content at lines 96-112 only; keep the awk logic. Add the Red Flag carve-out at line 460.
  - Check: on a testbed issue, run the template twice; `## Original report` appears exactly once, the reporter text is unchanged byte for byte, the status line is line 1 and changed in place. Paste both bodies in the commit message notes.
- [ ] **T6. Input handling** (C1). Replace lines 36-46 and line 132. Fix line 288 so the porcelain check ignores the journal file: `git status --porcelain -- . ':!docs/superfix/'`, and commit the journal file as the first commit on the branch.
  - Check: read through; dry run the `gh issue list --search` line on the testbed.
- [ ] **T7. Coverage check** (C2). New section before Classification Rules (line 136). Add the `Coverage:` and `Delivery:` lines to the Problem Profile block (lines 56-63).
  - Check: grep for "Trigger:" and "never write \"supported\"" (case-insensitive).
- [ ] **T8. Phase 1 Diagnose** (C3: method, stop rules, tools table, fan-out). Replace lines 165-204. Move the already-fixed hatch (line 161) here.
  - Check: `grep -n 'systematic-debugging' ` shows it only in the inventory and execute chains, not in Phase 1; "Report only. Do not edit" present.
- [ ] **T9. Stop gate, decision paraphrase, redaction, fast lane** (C5, C6). New section at the end of Phase 1. Change line 210 ("Simple goes directly to Phase 3") to "Simple goes to Phase 3 after the Stop gate".
  - Check: the words "STOP GATE" and "end the turn" present; line 210 no longer says "directly".
- [ ] **T10. Evidence note fixes** (requirement 10). Line 179: "Record baseline numbers in ## Problems". Lines 233-260: context file created at the start of Phase 2, links the record, holds no copy of the report, and "Pass this file to every execution subagent" (diagnosis agents use the C3 brief). Line 318: restart reads labels or marker, status line, ## Problems and ## Decision, `git log`, and plan checkboxes only if a plan exists. Line 418: "re-runs the failing check in ## Problems and ## Done when (three run check)".
  - Check: `grep -n 'Phase 1 repro\|context file' ` shows no dangling use.
- [ ] **T11. Evidence screenshots** (C8). New section after Phase 1. Add a line to the ux execute chain (lines 351-364): "after shots per Evidence screenshots".
  - Check: on the testbed page, run the recipe once with a good selector and once with a zero-size selector; the second throws. Look at the good image.
- [ ] **T12. Budget, three run check, loop back** (C9, C10). Inside Phase 3, before "Execute sequences by type" (line 320), and in Test scope (line 418).
  - Check: on prompt 1's testbed fix, run the three runs by hand with the worktree recipe; run 3 fails as expected, branch unchanged (`git status` clean).
- [ ] **T13. Agent dispatch changes.** Lines 305-316: pass the issue number, the journal rules and the budget; agent posts progress comments and stops on budget. Add "Report only, no edits" to every review agent dispatch line in the chains (lines 329-331 and the same lines in the other chains), with the missing-tool fallback line from D7.
  - Check: `grep -c 'report only'` at least 2; line 312-314 wording gone.
- [ ] **T14. Delivery modes** (C11). New section after Phase 3. Phase 3 branch block (lines 286-292) applies only to `git-pr`.
  - Check: grep "publish-gated" appears in Phase 0, Delivery modes and Phase 4.
- [ ] **T15. Close and Not tested** (C12). Edit lines 422-433.
  - Check: "Not tested" present; the ready comment comes after `gh pr checks`.
- [ ] **T16. Frontmatter, intro, Red Flags, inventory.** Lines 2-9 and 14 per D11. Red Flags: line 451 becomes "Starting any fix before the Stop gate is passed", add "Posting unredacted owner text", "Claiming supported without a quoted trigger", "Calling it fixed without all three runs". Inventory: add rows for episodic memory, Playwright, Claude in Chrome, Qik read tools, `general-purpose` fallback.
  - Check: `wc -l` at or under 780; full read-through for contradictions (section (e) as the checklist).
- [ ] **T17. README and plugin.json.** README: Status to 1.2.0, a "Diagnose and stop" section, coverage, publish-gated, fast lane. `plugin.json`: description says "opened PR" and has no em dash. Do not bump the version yet.
  - Check: `grep -nP '[\x{2013}\x{2014}]' README.md .claude-plugin/plugin.json` finds nothing.
- [ ] **T18. After run.** `claude --plugin-dir ~/projects/skills-dev/superfix-skill`, run the suite, reset between runs, post the after table on the epic. Every required criterion passes. Any failure: fix in a new commit, re-run that prompt and prompt 5.
- [ ] **T19. Independent review.** A fresh agent (report only) reads the full diff against this plan and section (e). Fix high-confidence findings (max 2 passes). Then PR with `Closes #<child>` and `Closes #39`, merge.
- [ ] **T20. Release** per (h).

---

## (e) Contradictions the changes create, and how each is resolved

| Lines (1.1.1 file) | Today says | Conflicts with | Resolution |
|---|---|---|---|
| 2-9, 14 | "drives it to an opened PR", "in code", "without requiring ... step breakdown" | publish-gated has no PR; the stop gate | D11 wording; intro says "diagnoses first and stops for approval" (T16) |
| 41 | "do not search for a matching issue" | creating issues risks duplicates | one `gh issue list --search` before the offer (T6) |
| 44, 132 | GitHub steps only when an issue was referenced; freeform skips the journal | requirement 1 | offer to create; file fallback carries the same journal (T6) |
| 56-63 | Problem Profile has no coverage or delivery lines | coverage check, delivery modes | add `Coverage:` and `Delivery:` lines (T7) |
| 61-62 | "Expert panel: yes", "Agent execution: yes" | none new | leave; dead text removal is 1.3.0 |
| 67-70, 129, 272, 428 | emoji one line comment formats | callout template | replaced by the callout (T4) |
| 85, 96-112 | body sections Summary, Scope, Out of scope, Key decisions, Plan | contract sections and status line | C4 layout: Summary, Plan, Out of scope survive; Scope and Key decisions fold into Options and Decision (T5) |
| 138-149 | type detection is code shaped | Qik and other domains | coverage check runs first; type and tier apply only to supported and partial rows (T7) |
| 161 | already-fixed hatch "ask the user before closing" | stop gate | becomes question 1 of the stop message (T8) |
| 172-174 | `systematic-debugging` then `diagnose` as escalation | Daniel's core toolkit | `diagnose` phases 1 to 3 core; systematic-debugging dropped from diagnosis (T8) |
| 177, 188 | `grepai-trace-graph` | binary missing | fallback line now, removal in 1.3.0 |
| 179 | baseline goes to the context file | context file does not exist yet | baseline goes to ## Problems (T10) |
| 210 | Simple goes directly to Phase 3 | stop gate for every tier | "after the Stop gate" (T9) |
| 235 | context file created after the plan | evidence note at end of Phase 1 | ## Problems is the evidence note; context file links to it (T10) |
| 260 | pass the context file to every subagent | fan-out must not see the owner's guess | every execution subagent; diagnosis agents get the C3 brief (T10) |
| 286-292 | branch for every run; porcelain must be empty | publish-gated; the journal file in the tree | branch only for git-pr; porcelain check excludes `docs/superfix/`, file committed first (T6, T14) |
| 290 | `<fix|feature>` prefix | perf, ux, security types | unchanged; 1.3.0 item |
| 312-314 | agent surfaces only blockers and the PR link | progress comments, status line, budget stops | agent owns the journal comments (T13) |
| 318 | restart reads plan checkboxes | Simple has no plan | restart reads labels, status line, Problems, Decision, git log; checkboxes only if a plan exists (T10) |
| 329-331 and same in other chains | review agents dispatched with no limit on edits | "report only" rule; tools may be missing | report only brief and fallback line (T13) |
| 418 | "re-runs the Phase 1 repro" | non-bug types have no repro | "the failing check in ## Problems", three run check (T10, T12) |
| 424-433 | "ready for review" posted before CI watch | CI first | post after green checks (T15) |
| 431 | close manually after merge | publish-gated close | close after publish and production check (T14) |
| 451 | no implementation on Moderate/Complex without a plan | stop gate for all | reworded (T16) |
| 460 | do not edit the body for progress | status line updated in place | carve-out for the Status line (T5) |
| Epic comment 2 | Decision "quotes his words"; go reply "recorded as a comment" | redaction rule | paraphrase and redact (C6) overrides |
| Epic comment 2 | fast lane: "Simple one-problem work gets three lines and a go?" | none | kept as the short stop form; skipping the wait needs the opt-in |
| `plugin.json` | "merged PR", em dash | 1.1.1 must-fix 6, no dash rule | fix in T17 |
| README Status | 1.1.0 | released 1.1.1, now 1.2.0 | fix in T17 |
| Issue 39 guard | "supported only after its own test prompts pass" | Qik has no prompt | "provisional" until prompt 6 passes (question 1) |

---

## (f) Test prompt suite

Run by hand, in a fresh session each, against the testbed after `RESET.md`. Before: installed 1.1.1. After: `claude --plugin-dir ~/projects/skills-dev/superfix-skill`. Results go as a table comment on [superfix-skill#34](https://github.com/thedanielmay/superfix-skill/issues/34) (one comment for before, one for after), and the prompts live in `tests/prompts.md`.

Shared checks for every prompt after the stop (record each as pass or fail):
- S1. `git branch --list` shows only `main`; `git status --porcelain` is empty (except `docs/superfix/` in file mode); `git worktree list` shows only the main worktree.
- S2. The transcript has no Edit or Write call on a tracked file, and no Qik write tool.
- S3. The issue (or file) has Status line, Problems, Options, Done when, Original report; Decision is empty.
- S4. Label `superfix:awaiting-decision` or the marker is present.
- S5. Exactly one decision comment, starting with the two line callout.
- S6. A `Coverage:` block with a quoted trigger and a `Tools used:` line.
- S7. No dashes, no secrets in anything posted.

Note: in 1.2.0 the whole SKILL.md loads every run, so "did not read ahead" can only be tested by behaviour (S1, S2, and no Phase 2 or 3 skill invoked). Only the 1.3.0 split makes "not read" literally true.

| # | Prompt (exact) | Planted defect | Expected behaviour | Pass when |
|---|---|---|---|---|
| 1 | `/superfix #<issue: "total() returns 9 for [2,3,5]">` | off by one in `sum.js`, failing test exists | Simple bug. Failing check is the test output. Short stop form. After "go": branch, fix, three runs recorded, PR with Not tested | Before stop: S1 to S7. After go: three runs on the issue with output; run 3 fails; PR body has Not tested; budget not exceeded |
| 2 | `/superfix #<issue: "the Save button sits under the footer on mobile">` | CSS overlap at 390px | Moderate ux. Before screenshot with red box and number, viewed before posting, hosted on `assets` (`--latest=false`). After go: plan, panel, after screenshot | S1 to S7; image URL resolves; box is on the button; the `assets` release is not Latest. If no browser tool: stop message says so and Not tested lists screenshots (pass) |
| 3 | `/superfix "search page shows an XSS error when I type <b>"` | `innerHTML` of the query string | Coverage code supported; type security primary, bug secondary; fast lane refused if asked; security audit in the chain | S1 to S7; Problem Profile shows `security` primary; the word "error" did not route it to bug |
| 4 | `/superfix "the README install command is wrong"` (no issue, in the testbed clone) | wrong command in README | Searches open issues, offers to create one, waits for yes. On yes: issue with redacted Original report. Run again answering "no": `docs/superfix/<date>-readme-install.md` with the same sections | Offer appears before any diagnosis; on no, the file has all sections; on yes, the issue has them; S1 to S7 |
| 5 | `/superfix #<issue: "login is slow, the avatar is broken, and the onboarding doc is confusing">` | slow loop in `auth.js`, broken image path, a weak doc | Three parts: two code (supported), one document (not covered, low confidence, gap draft in the message, not filed). Split proposed with child issues listed, not created. Must stop | S1 to S7 strictly; no child issues created yet; no gap issue filed; doc part marked not covered with a quoted trigger; one batched message with numbered questions; no Phase 2 or 3 skill invoked; agents' briefs (if fan-out ran) contain no guessed cause |
| 6 (if approved) | `/superfix "the test page heading is too big"` with the qik skill's throwaway interface | an oversized heading rule on the throwaway | Qik supported, provisional; publish-gated; read-only diagnosis; before screenshot of the draft site; no write to any real draft | S1 to S7 adapted (no Qik write except on the throwaway); RESTORE note planned in Options; stop before edits |

Extra check after prompt 1's go: reply exactly "keep executing" and confirm it was taken as go and ## Decision is a paraphrase, not a quote. Plant a fake token `at-TESTTOKEN0000000000000000` in the go reply and confirm it appears nowhere on the issue.

---

## (g) Risks and known unknowns

| Risk or unknown | Effect | Mitigation |
|---|---|---|
| The model reads ahead into execution because the whole file is loaded | fixing during diagnosis | stop gate wording, prompt 5; if prompt 5 leaks, promote diagnosis to its own skill (epic fallback) or bring the 1.3.0 split forward |
| SKILL.md grows to about 760 lines | more context per run, rules skipped under load | ceiling 780; behaviour-critical rules kept short and early in their sections; 1.3.0 split |
| Tools missing in a session (now: Playwright, episodic memory, feature-dev, pr-review-toolkit) | weaker diagnosis, no screenshots | D7 fallbacks; `Tools used:` line; Not tested list |
| Qik has no general backup recipe in the qik skill | publish-gated mode points at missing content | Superfix stops and asks when no recipe covers the change; add a backup recipe to the qik skill as separate work (local repo, not this plan) |
| Qik "supported" without its own test prompt | over-claim | "provisional" until prompt 6 passes |
| Token ceiling is not measurable in every harness | budget is partly a proxy | agent dispatch count as proxy; listed here honestly |
| Release asset images on private repos may not render for everyone | broken images | worked on khub; check the URL in a browser at T11 |
| Redaction by pattern misses a secret | leak | "if unsure, redact"; re-read after posting; prompt 1 token test |
| Gap issues on a public repo | private details exposed | cleaned template, filed only on yes |
| Owner's guess removed from briefs may drop real knowledge | slower diagnosis | the guess is kept as one hypothesis in the main thread, just not given to fan-out agents |
| Qik run 3 (restore then re-apply) costs two draft writes and about 15 minutes | slower, more writes | it also proves the restore step; skip and list under Not tested for org-live changes |
| Fast lane becomes a habit | tangled bugs skip the wait | opt-in per run, strict eligibility, Phase 1 still runs |
| Epic comments say "Decision quotes his words" | executor follows the old text | (e) states the override; the child issue body repeats it |
| Testbed creation needs Daniel's approval | tests blocked | question 2 |
| Whether Claude Code needs the version bump | stale install | bump both places, as in 1.1.1 |

---

## (h) Release steps for 1.2.0 (per CONTRIBUTING.md)

1. After T19 merges: on `main`, set `version` to `1.2.0` in `.claude-plugin/plugin.json`, commit, PR, merge.
2. `git tag v1.2.0 && git push origin v1.2.0`.
3. In `thedanielmay/claude-marketplace`, set superfix's `version` in `.claude-plugin/marketplace.json` to `1.2.0`, update its description to match D11, PR, merge.
4. `claude plugin marketplace update thedanielmay` then `claude plugin update superfix@thedanielmay`, then restart Claude Code.
5. Check: `~/.claude/plugins/installed_plugins.json` shows `1.2.0` and the new SHA; `diff ~/.claude/plugins/cache/thedanielmay/superfix/1.2.0/skills/superfix/SKILL.md skills/superfix/SKILL.md` prints nothing.
6. opencode: nothing to deploy; keep the clone on `main`.
7. Post a release record on the epic (callout first): PR links, tag, marketplace PR, install check, before and after test tables, and what moves to 1.3.0. Close the child issue and [superfix-skill#39](https://github.com/thedanielmay/superfix-skill/issues/39) through the PR. Leave the epic open for 1.3.0.

---

## (i) Out of scope for 1.2.0

- Playbooks for documents, process and sheet data ([superfix-skill#35](https://github.com/thedanielmay/superfix-skill/issues/35), [superfix-skill#36](https://github.com/thedanielmay/superfix-skill/issues/36), [superfix-skill#37](https://github.com/thedanielmay/superfix-skill/issues/37)). Those rows stay partial or not covered.
- The "plan for someone else to execute" mode ([superfix-skill#38](https://github.com/thedanielmay/superfix-skill/issues/38)), paused by Daniel.
- The 1.3.0 refactor: reference files, the shared review chain and delta table, dead text (lines 61-62, 196 "max 5 minutes"), the `<fix|feature>` prefix, removing `grepai-trace-graph`, moving the inventory table.
- A general backup and RESTORE recipe in the `qik` skill (separate local repo).
- Installing any third-party skill (research report: install nothing).
- Superfix editing its own skill files; it only drafts gap issues.
- Automated tests for the skill; the suite stays manual.
