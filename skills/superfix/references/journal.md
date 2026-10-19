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
- The body file is a fixed path, because the shell keeps no variables between calls. Build it (first block), run both checks in `references/redaction.md` on it and wait for `CLEAN` or `NO-LIST` plus `PATTERN-CLEAN` or decided hits, then post it (second block). If a hit is inside `## Original report`, stop: see "The reporter's own issue body" in redaction.md.

```bash
BODY="$(gh issue view <N> --json body -q .body)"
# Reporter's text: after the heading if it already exists, else the whole body
if printf '%s\n' "$BODY" | grep -q '^## Original report$'; then
  ORIG="$(printf '%s\n' "$BODY" | awk '/^## Original report$/{f=1;next} f')"
else
  ORIG="$BODY"
fi
F="$HOME/.superfix/check/body-<N>.md"; mkdir -p "$HOME/.superfix/check"
cat > "$F" <<'EOF'
**Status:** <value> (updated <YYYY-MM-DD HH:MM>)

## Summary
<one paragraph: what this is and why>

## Problems
### P1: <short name>
- Symptom: <what the owner sees>
- Failing check: `<command>`
  <its output>
- Baseline: <numbers, performance only>
- Cause: <confirmed, with its row | suspected>
  | Test | H1 predicts | H2 predicts | H3 predicts | Observed |
- Ruled out: <hypothesis>: <how>
- Siblings: <same cause found elsewhere, or none>

Seen, not diagnosed:
- <one line each>

Tools used: <what ran, with fallbacks>. Missing: <what was not available>.

## Options
### P1
1. <option> (Recommended): <trade-offs>. Effort: <about N minutes of my time; your part: reply once>
2. <option>: <trade-offs>. Effort: <...>

Proposed budget: Up to <N> hours, touching these <N> files: <files>. I stop and ask if I go over.

## Decision
<empty until the owner answers; then the paraphrase and approval-sha>

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
gh issue edit <N> --body-file ~/.superfix/check/body-<N>.md
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
mkdir -p ~/.superfix/check && cat > ~/.superfix/check/comment-<N>.md <<'EOF'
> **In plain English:** <what was done, one sentence>. <what is needed from you, or "Nothing needed from you now.">

<detail for AI readers>
EOF
# new call, after both checks on ~/.superfix/check/comment-<N>.md:
gh issue comment <N> --body-file ~/.superfix/check/comment-<N>.md
```

### Decision message (posted at the Stop gate)

ONE comment, or one journal entry, per run. It holds every question for this run, numbered, each with the recommended answer, the effort and the budget.

```
> **In plain English:** I found 2 problems and what causes them. I need 2 answers before I fix anything.

Reply in one line, for example "1 yes, 2 option two". "Keep executing" means yes to all my recommendations.

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

### Create-issue question (description only, in a git repo with a GitHub remote)

The LAST numbered question of the decision message, always, so the owner's numbered reply stays predictable:

```
<N>. No issue exists yet. Create one in <owner/repo> (<private|PUBLIC>) with this
   record? (yes / no, keep it in a local file)
```

- Get the visibility first: `gh repo view --json visibility -q .visibility`.
- If the repo is PUBLIC, the question adds: "It is public, so anyone can read it. The text it would post is below." and shows the redacted Original report.
- If the duplicate search (`gh issue list --state open --search "<3 key words>" --limit 5`) found a likely match, name it in the question and offer to use it instead.
- Yes: write the title to `~/.superfix/check/title.txt` and the body to a file, run both checks on both, then `gh issue create --title "$(cat ~/.superfix/check/title.txt)" --body-file <body file>`, add a line under the journal file's Status line pointing to the issue, and continue on the issue. No: keep going in the journal file.

### File-mode journal (no issue)

- Path: `~/.superfix/journal/<owner>-<repo>/<YYYY-MM-DD>-<slug>.md`, or `~/.superfix/journal/<folder-name>/<YYYY-MM-DD>-<slug>.md` when there is no remote. `mkdir -p` the folder first.
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
Budget used: <commits, files, time> of <budget>
Loaded: execute.md
## Not tested
- <item, and why>
```
Without an issue, write the same as a journal entry and say it in chat.

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
