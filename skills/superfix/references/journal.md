# Issue journal

Moved from SKILL.md 1.1.1 (superfix-skill#42); edited in 1.3.0. SKILL.md says when to read this file.

When working from a GitHub issue, the issue is the single source of truth for the work. Apply this pattern throughout the pipeline:

Without an issue, the same record goes in the file-mode journal (below), outside the repo. Everything in this file applies to it, with the changes listed there.

**Issue body = living spec/plan**
Keep the issue body current, but never overwrite what the reporter wrote.
- First edit: copy the existing body word for word under a `## Original report` heading at the bottom. Never edit that section afterwards.
- Later edits: if the body already has `## Original report`, keep everything from that heading to the end untouched and rewrite only the sections above it.
- After Phase 0 and after any plan is written or significantly revised, update those sections. They should always answer: "what are we building, why, and what's out of scope?"
- Include the `## Plan` section only when a plan file exists (Moderate and Complex). Simple work has none.
- After Phase 0 the update sets the Status line to `Diagnosing` and writes the Summary. `## Problems`, `## Options` and `## Done when` are filled at the Stop gate. `## Decision` stays empty until the owner answers.
- The body file is a fixed path in this run's folder `~/.superfix/runs/<run-key>/` (redaction.md says how to build `<run-key>`; write it out literally in each command), because the shell keeps no variables between calls. Build it (first block), run both checks in `references/redaction.md` on it and wait for `CLEAN` or `NO-LIST` (a `NO-RUN-FOLDER` stops) plus `PATTERN-CLEAN` or decided hits, then post it (second block). If a hit is inside `## Original report`, stop: see "The reporter's own issue body" in redaction.md.

```bash
BODY="$(gh issue view <N> --json body -q .body)"
# Reporter's text: after the heading if it already exists, else the whole body
if printf '%s\n' "$BODY" | grep -q '^## Original report$'; then
  ORIG="$(printf '%s\n' "$BODY" | awk '/^## Original report$/{f=1;next} f')"
else
  ORIG="$BODY"
fi
umask 077; F="$HOME/.superfix/runs/<run-key>/body-<N>.md"
cat > "$F" <<'EOF'
**Status:** <value> (updated <YYYY-MM-DD HH:MM>)

Contents: Summary, Problems (P1, P2), Options, Proposed solution, Decision, Done when, Original report

## Summary
<one paragraph: what this is and why>

## Problems
### P1: <short name>
**In plain words:** <what is wrong and who sees it; length by tier, below>
- Symptom: <what the owner sees>
- Picture: ![P1 before: <full caption>](<url>)  (only when a screen shows it; evidence.md)
  P1 before: <the same caption as plain text>.
- Failing check: `<command>`
  <its output>
- Baseline: <numbers, performance only>
**Why it happens:** 1. <step, with the file:line or output that shows it> 2. <...>
- Cause: <confirmed, with its row | suspected>
  | Test | H1 predicts | H2 predicts | H3 predicts | Observed |
- Ruled out: <hypothesis>: <how>
- Siblings: <same cause found elsewhere, or none>
- After: <filled at close: the after picture, or the passing check>

Seen, not diagnosed:
- <one line each>

Tools used: <what ran, with fallbacks>. Missing: <what was not available>.

## Options
### P1
1. <option> (Recommended): <what changes>. Good: <...>. Cost or risk: <...>. Effort: <about N minutes of my time; your part: reply once>
2. <option>: <trade-offs>. Effort: <...>

Proposed budget: Up to <N> hours, touching these <N> files: <files>. I stop and ask if I go over.

## Proposed solution
### P1
1. <step: which file, what changes>
What will look different afterwards: <what the owner will see>
What could go wrong: <risk> (how I would notice: <check>)
Will stay untested: <items, or "nothing known">

## Decision
<empty until the owner answers; then the paraphrase in plain words, and last a line "Internal: approval-sha <40 hex>, approved <YYYY-MM-DD HH:MM>">

## Done when
- <each failing check the solved check re-runs>
- The owner's description no longer holds: "<owner's words, redacted>"

## Scope
<what is in scope>

## Out of scope
<what is explicitly excluded>

## Key decisions
- <decision 1>
- <decision 2>

## Plan
docs/superpowers/plans/<filename>.md   <!-- only when a plan exists -->
EOF
printf '\n## Original report\n%s\n' "$ORIG" >> "$F" && echo "BODY-READY $F"
```

After the checks, in a new call:

```bash
gh issue edit <N> --body-file ~/.superfix/runs/<run-key>/body-<N>.md
```

**Status line**
Status line, first line of the body, updated in place (a body update by design):
**Status:** <value> (updated YYYY-MM-DD HH:MM)
Values: Diagnosing | Waiting for you: N questions | Fixing problem K of N |
Stopped: <plain reason> | Ready for review: PR <link> | Waiting for you to
publish | Done

**Progress comments = timestamped changelog**
Each significant phase transition gets a progress comment, not an edit to the body, except the Status line and ## Decision, which are body updates by design. Comments accumulate as a readable audit trail of what happened and when.

Comment triggers:

| When | Comment | Body update |
|---|---|---|
| Stop gate | decision request (Problem Profile folded in) | Status, Problems, Options, Done when |
| Go received | none | Decision, Status |
| Plan approved after panel (Moderate, Complex) | plan and key decisions | Plan, Key decisions |
| Budget stop, diagnosis wrong, blocker | stop message | Status |
| PR open and CI green | final result: solved check, Not tested, PR link | Status |

- Any significant scope change or blocker encountered
- Child issues, when they exist: progress goes on the parent only.
- A Simple fix posts 2 comments (decision request, final result). A Moderate or Complex fix posts 3 (plus the plan comment).

Comment format:
Every comment and journal entry starts with:
> **In plain English:** <what was done, one sentence>. <what is needed from you, or "Nothing needed from you now.">
Two lines at most. Plain words, no emoji, no jargon without a plain
explanation, no dashes as punctuation. Dense detail for AI readers follows.
Post with `gh issue comment <N> --body-file <file>`, never inline --body.

```bash
umask 077; cat > ~/.superfix/runs/<run-key>/comment-<N>.md <<'EOF'
> **In plain English:** <what was done, one sentence>. <what is needed from you, or "Nothing needed from you now.">

<detail for AI readers>
EOF
# new call, after both checks on ~/.superfix/runs/<run-key>/comment-<N>.md:
gh issue comment <N> --body-file ~/.superfix/runs/<run-key>/comment-<N>.md
```

### Depth by tier (1.4.0)

Template fields the body must fill, with their length by the confirmed tier. A Simple fix stays short.

| Field | Simple | Moderate | Complex |
|---|---|---|---|
| In plain words | 1 to 2 sentences | up to 4 | up to 4, plus who is affected |
| Why it happens | up to 3 steps | up to 6 | up to 8 |
| Options | 1, plus "leave it" allowed | 2 or 3 | 2 or 3 |
| Proposed solution | up to 4 steps | up to 8 | up to 12, then point at the plan |

- `Contents:` sits under the Status line and names the sections in order, with the problem numbers.
- Per problem, in this order: In plain words, Symptom, Picture (only when a screen shows it), Failing check, Why it happens (numbered steps, each with the file:line or output that shows it), the 1.3.1 Cause row, Ruled out, Siblings, After (filled at close).
- Per option: what changes, good, cost or risk, effort.
- `## Proposed solution`, one block per problem: numbered steps; what will look different afterwards; what could go wrong and how I would notice; what will stay untested.

### Decision message (posted at the Stop gate)

ONE comment, or one journal entry, per run. It holds every question for this run, numbered, each with the recommended answer, the effort and the budget.

```
> **In plain English:** I found 2 problems and what causes them. I need 2 answers before I fix anything.

Reply in one line, for example "1 yes, 2 option two". "Keep executing" means yes to every question where I recommend an answer.

1. P1 (problem 1: the total is off by one): fix the loop bound (recommended) or rewrite total()? About 20 minutes of my time; your part: reply once.
2. Budget: Up to 1 hour, touching these 2 files: sum.js, test/sum.test.js. I stop and ask if I go over. OK?

---
<AI detail: Coverage block, Problem Profile, Tools used, failing check output, hypotheses table>
```

- Effort wording, exact form: "About 1 hour of my time; your part: publish once." (Qik) or "...your part: reply once." (code).
- When the work needs a login, add one line: "Please don't type passwords here. Name the 1Password item instead."
- First mention of any P number in a message reads "P1 (problem 1: <short name>)".
- One coverage line per problem, in plain words, before the numbered questions:
  - Code: This is a code problem, because you wrote "<quote>". I can find the cause and fix it.
  - Qik: This is a Qik settings problem, because you wrote "<quote>". I can fix it in the draft, but my Qik fixing is not yet proven by a test, so you check it and publish.
  - Everything else: This is not code or Qik, because you wrote "<quote>". I can only work out what is wrong, not fix it. My findings are low confidence because nothing can be run to prove them.
- Simple with one problem: the short form, three lines (problem, fix, effort) and "Go?". The effort line carries the budget in its plain wording.
- Write `Loaded: journal.md` (and the other references read so far) in the AI detail part.
- Question count: write the numbered questions first, then the callout, and state the number in digits ("I need 3 answers"). Before posting, check that the callout's number matches the numbered lines above the `---` (the Simple short form, with "Go?" and no numbered lines, is exempt):

```bash
F="$HOME/.superfix/runs/<run-key>/comment-<N>.md"; Q="$(awk '/^---$/{exit} {print}' "$F" | grep -cE '^[0-9]+\. ')"; C="$(head -1 "$F" | grep -oE '[0-9]+ answers?' | grep -oE '[0-9]+')"; if [ -n "$C" ] && [ "$Q" = "$C" ]; then echo COUNT-OK; else echo "COUNT-MISMATCH: $Q numbered questions, callout says ${C:-no number}"; fi
```

- Pictures (references/evidence.md): below the numbered questions (Simple short form: below "Go?", the three lines unchanged), the first picture of each problem that has one, each followed by its caption line, then once the line "Pictures show on the website, not in the GitHub app: <issue link>". The callout and the questions never depend on a picture. A public repo or no issue: the local folder line from evidence.md in place of the pictures. A credential given in this run (any `HELD`): the "Pictures are not posted because you gave me a password or token in this run" line from evidence.md in place of the pictures.
- The Viewed line of each picture goes in the AI detail part, never above the `---`.

### Create-issue question (description only, in a git repo with a GitHub remote)

The LAST numbered question of the decision message, always, so the owner's numbered reply stays predictable:

```
<N>. No issue exists yet. Create one in <owner/repo> (<private|PUBLIC>) with this
   record? (yes / no, keep it in a local file)
```

- This question has no recommended answer. "Keep executing" and other "yes to all" replies do not create an issue: unless the owner says yes to this question itself, the answer is no (keep the journal file, create nothing), on public and private repos alike.

- Get the visibility first: `gh repo view --json visibility -q .visibility`.
- If the repo is PUBLIC, the question adds: "It is public, so anyone can read it. The text it would post is below." and shows the redacted Original report.
- If the duplicate search (`gh issue list --state open --search "<3 key words>" --limit 5`) found a likely match, name it in the question and offer to use it instead.
- Yes: write the title to `~/.superfix/runs/<run-key>/title.txt` (under `umask 077`) and the body to a file, run both checks on both, then `gh issue create --title "$(cat ~/.superfix/runs/<run-key>/title.txt)" --body-file <body file>`. Next, BEFORE writing the issue line into the journal, move the run folder to the issue key (both keys written out, lowercase); it refuses if the target exists and then rewrites the `key` file. On `RUN-MOVED`, add a line under the journal file's Status line pointing to the issue, and continue on the issue. On `REFUSED-EXISTS`: keep the journal key, never overwrite the other folder, write the issue line as `Issue: <link> (run key: <journal run-key>)`, and tell the owner another run already holds that issue's folder. No: keep going in the journal file.

```bash
umask 077; S="$HOME/.superfix/runs/<journal run-key>"; T="$HOME/.superfix/runs/<owner>+<repo>+<N>"; if [ -e "$T" ]; then echo "REFUSED-EXISTS $T"; else mv "$S" "$T" && printf '%s\n' '<owner>+<repo>+<N>' > "$T/key" && echo RUN-MOVED; fi
```

### File-mode journal (no issue)

- Path: `~/.superfix/journal/<owner>-<repo>/<YYYY-MM-DD>-<slug>.md`, or `~/.superfix/journal/<folder-name>/<YYYY-MM-DD>-<slug>.md` when there is no remote. `mkdir -p` the folder first, then create the run folder with the journal key (redaction.md, Run folder).
- It is never inside the repo, so it is never committed and never breaks the `git status --porcelain` check.
- Same body template as above. The Status line is the file's first line, updated in place.
- `## Original report` holds the owner's description copied exactly, including URLs, record ids and commit ids. Only a credential is replaced by `[redacted]` (redaction check first). Never summarise or reword it.
- Comments become dated `### <YYYY-MM-DD HH:MM> <stage>` entries appended at the end, each starting with the plain-English callout.
- Say the file path in chat every time you stop.

### Plan comment (Moderate, Complex, after the expert panel)

```
> **In plain English:** The plan passed expert review and I am starting the fix. Nothing needed from you now.

Plan: docs/superpowers/plans/<filename>.md
Key decisions: [brief summary]
```
Post it with `--body-file` (Comment format above).

### Final comment (Phase 4, after CI is green)

```
> **In plain English:** PR <link> is open and its checks are green. Please review and merge it.

Solved check: run 1 <output>, run 2 <output>, run 3 <output>
![P1 before and after: left, <what was wrong> (red box 1); right, <what is fixed> (green box 1)](https://github.com/<owner>/<repo>/releases/download/assets/sf-<N>-p1-before-after.png)
P1 before and after: left, <what was wrong> (red box 1); right, <what is fixed> (green box 1).
Pictures show on the website, not in the GitHub app: <issue link>
Cost: about <n> USD (estimate for a <tier> run; the run cannot read its own bill)
To undo: close PR <link> without merging. After a merge, tell me "undo this" and I will revert it.
Budget used: <commits, files, time> of <budget>
Loaded: execute.md
## Not tested
- <item, and why>
```
Without an issue, write the same as a journal entry and say it in chat.

- The picture lines: one side-by-side picture per problem that had pictures (evidence.md), each with its caption; a problem with no screen gets "P<k> has no screen; its proof is the check output below." The website line once, only when there is a picture. A public repo or no issue: the local folder line instead. Pictures still held because of a credential: the same "Pictures are not posted because you gave me a password or token in this run" line, and the run waits for that answer before its end-of-run delete (evidence.md).
- Cost line: always present and always marked as an estimate, because the run cannot read its own bill. Rough figures by tier until the 1.4.0 test record gives measured ones: Simple about 2 USD, Moderate about 6 USD, Complex about 15 USD.
- Undo line: always present, in plain words. The revert command (`git revert -m 1 <merge sha>`) goes in the AI detail, not in the undo line. Qik work: "To undo, tell me "undo P1". The backup is in <folder>." instead.

### Context file (Moderate, Complex)

After plan is written, create `docs/superpowers/plans/<slug>-context.md` using this structure:

```markdown
# Context: <slug>

## Problem Profile
- Primary type: <type>
- Secondary type: <type or none>
- Complexity: <tier>
- Skill manifest: <ordered list>

## Problem Description
<full issue text or conversation summary>

## Plan
Path: docs/superpowers/plans/<plan-filename>.md

## Key Decisions from Exploration
- <decision 1>
- <decision 2>

## Relevant Files
- <path>: <why relevant>

## Evidence
<copied from ## Problems in the issue body or journal file>
```
