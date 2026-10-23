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

**Labels:** <LABELS-NOW, or "not set (<word>) <!-- marker superfix-<awaiting-decision|approved> -->">

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
- Diagram: ![P1 cause today: <full caption>](<url>)  (only after the owner said yes; diagrams.md)

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
Diagram: ![P1 the change: <full caption>](<url>)  (only after a yes)

## Decision
<empty until the owner answers; then the paraphrase in plain words, and last a line "Internal: approval-sha <40 hex>, approved <YYYY-MM-DD HH:MM>">

## Done when
- <each failing check the solved check re-runs>
- P<k>-C<n> [check|later|owner] <plain name>: <definition>; pass: <pass line>; how: <how>; who: <who>  (criteria mode only; references/criteria.md)
- P<k>-K<n> [check] <plain name>: <what must not get worse>; pass: <today's value>; how: measure-P<k>-K<n>.py; who: Superfix  (criteria mode only)
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
1.5.0, criteria mode (references/criteria.md): Waiting for you: re-check on <date> | Waiting for you: sign-off on <name> | Waiting for you: put it back and give me an export
1.6.0, work order mode (references/workorder.md): Waiting for you: hand the work order to someone (<where>) | Waiting for you: hand the work order back (<where>)
- Never write a time or a duration into an issue from memory; run `date` and compute it.
- When a permission check blocks one step of a run, end in `Stopped: blocked by a permission check at <step>` with the exact remaining commands listed for a human. Never write an exception the owner did not give.

**Closing verify (Phase 4)**
After the PR merges, read `closingIssuesReferences` on the PR and the issue state. A closing keyword in the PR body does not always close the issue, so verify; if the issue is still open, close it by hand with a comment. Post the comment with `gh issue comment` first, then `gh issue close`, because `close --comment` silently drops the comment when a keyword already closed the issue.

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
| Re-check, sign-off or export | final result or stop message | Status |

Every message in this table carries the required Labels: line, and every Status change runs the label commands (Labels, below). Go's body update also adds the diagrams after they pass diagrams.md.

- Any significant scope change or blocker encountered
- Child issues, when they exist: progress goes on the parent only.
- A Simple fix posts 2 comments (decision request, final result). A Moderate or Complex fix posts 3 (plus the plan comment).
- Criteria mode: the "Keep executing does not approve" notice is appended to the decision comment, edited by its recorded id (`gh api -X PATCH repos/<owner>/<repo>/issues/comments/<id> -F body=@<comment file>`, after the checks; never `--edit-last`), so it adds no comment and these counts stay the same.

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

### Labels

New in 1.4.1. The labels follow the Status line, so the owner can list everything waiting for him with one saved search (README). A Status value starting "Waiting for you", "Stopped" or "Ready for review" means `superfix:awaiting-decision`; "Fixing" means `superfix:approved`; "Diagnosing" and "Done" mean neither.

| Moment | Status (1.4.0 text) | Label after |
|---|---|---|
| Stop gate | Waiting for you: N questions | awaiting-decision |
| Go, or fast lane | Fixing problem 1 of N | approved |
| Loop back (fix failed twice), panel overturn | Waiting for you: N questions | awaiting-decision |
| Budget stop, blocker | Stopped: <reason> | awaiting-decision |
| Qik waiting for "published", held pictures | Waiting for you to publish / post the pictures? | awaiting-decision |
| PR ready | Ready for review: PR <link> | awaiting-decision |
| Work order handed off, or sent back | Waiting for you: hand the work order to someone (<where>) / back (<where>) | awaiting-decision |
| Re-diagnose after reply 1 | Diagnosing | none |
| Merged and closed | Done | none |

- Colours and descriptions: `superfix:awaiting-decision` yellow `FBCA04` "Superfix is waiting for you"; `superfix:approved` green `0E8A16` "Approved; Superfix is working"; `superfix:gap` purple `5319E7` "A kind of problem Superfix does not cover yet" (gap repo only, references/gaps.md).
- After every Status change, in this order: ensure the new label exists, add it, remove the old one (only if the read-back lists it), read back. Add before remove, so the issue is never without a label in between. Each command prints one word and is never silenced (no `2>/dev/null`).
- The `Labels:` field and the body's `**Labels:**` line are copied from `LABELS-NOW`, never typed from memory.
- Labels are not a reason to stop. When the permission check says `LABELS-SKIPPED`, or a create or add fails, carry on: the field reads `not set (<word>); marker superfix-awaiting-decision` (or `superfix-approved`), and the body line reads `**Labels:** not set (<word>) <!-- marker superfix-awaiting-decision -->`. The visible text stays plain because the Status line already says "Waiting for you"; the marker sits in the body because the body is the current state (a comment would keep matching after the state moved on). GitHub search does find the marker inside the HTML comment, a few minutes after the edit (checked in 1.4.1), but it also matches any issue that mentions the same words.
- No issue (file-mode journal): no label commands; `Labels: none (no issue)`.
- On restart: read the Status line, the `**Labels:**` line and the live labels (read-back command), then run the commands so the labels match the Status line.

Permission check, once per run before the first label (the owner test and workflow scan of the `assets` command in evidence.md, with the label words). It prints `LABELS-OK`, or `LABELS-SKIPPED not-owner`, `LABELS-SKIPPED hooks`, `LABELS-SKIPPED workflows` (with the `FLAG` and `UNREAD` lines) or `LABELS-SKIPPED could-not-list-files`. Any webhook on the repo (or a hook list it cannot read) means `hooks`. A workflow flags when its text, with quotes and YAML anchors (`&name`, `*name`) removed first, contains `issues`, `label`, `labeled` or `unlabeled` (any case), or writes `on:` in flow syntax; a file it cannot read is `UNREAD` and counts as a flag. GitHub Apps may still react to a label; they cannot be checked from here.

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; R='<owner>/<repo>'; ME="$(gh api user -q .login)"; if [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; elif [ -z "$ME" ] || [ "${R%%/*}" != "$ME" ]; then echo "LABELS-SKIPPED not-owner"; elif [ "$(gh api "repos/$R/hooks" -q length)" != 0 ]; then echo "LABELS-SKIPPED hooks (a webhook, or the hook list could not be read)"; else L="$(gh api "repos/$R/git/trees/HEAD?recursive=1" -q 'if .truncated then "TRUNCATED" else (.tree[] | select(.type == "blob") | .path) end' 2>&1)"; rc=$?; if [ $rc -ne 0 ] && ! printf '%s\n' "$L" | grep -q 'HTTP 409'; then echo "LABELS-SKIPPED could-not-list-files"; else : > "$D/label-flags"; if [ $rc -eq 0 ]; then printf '%s\n' "$L" | grep -qx TRUNCATED && echo "UNREAD the file list is too long to read in full" >> "$D/label-flags"; printf '%s\n' "$L" | grep -i '^\.github/workflows/' | while IFS= read -r p; do T="$(gh api "repos/$R/contents/$p" -q .content 2>/dev/null | base64 -d 2>/dev/null)"; if [ -z "$T" ]; then echo "UNREAD $p" >> "$D/label-flags"; elif printf '%s\n' "$T" | sed -e "s/[\"']//g" -e 's/[&*][A-Za-z0-9_-]*//g' | grep -qiE 'issues|label|labeled|unlabeled|(^|[[:space:]])on:[[:space:]]*[[{]'; then echo "FLAG $p" >> "$D/label-flags"; fi; done; fi; if [ -s "$D/label-flags" ]; then echo "LABELS-SKIPPED workflows"; cat "$D/label-flags"; else echo LABELS-OK; fi; fi; fi
```

Ensure the label exists (prints `LABEL-EXISTS`, `LABEL-CREATED` or `LABEL-CREATE-FAILED`; GitHub's own "Not Found (HTTP 404)" line before `LABEL-CREATED` is normal). Write `L`, `C` and `T` from the colours above:

```bash
R='<owner>/<repo>'; L='superfix:awaiting-decision'; C='FBCA04'; T='Superfix is waiting for you'; E="$(printf '%s' "$L" | sed 's/:/%3A/')"; if gh api "repos/$R/labels/$E" -q .name >/dev/null; then echo "LABEL-EXISTS $L"; elif gh label create "$L" --repo "$R" --color "$C" --description "$T"; then echo "LABEL-CREATED $L"; else echo "LABEL-CREATE-FAILED $L"; exit 1; fi
```

Add (prints `LABEL-ADDED` or `LABEL-ADD-FAILED`):

```bash
R='<owner>/<repo>'; L='<label>'; if gh issue edit <N> --repo "$R" --add-label "$L"; then echo "LABEL-ADDED $L"; else echo "LABEL-ADD-FAILED $L"; exit 1; fi
```

Remove (reads first; never calls `--remove-label` on a label the issue lacks; prints `LABEL-REMOVED`, `LABEL-REMOVE-FAILED` or `LABEL-NOT-PRESENT`). For the record (1.4.1 probe): a raw `--remove-label` exits 0 when the label exists in the repo but not on the issue, and 1 when the repo has no such label.

```bash
R='<owner>/<repo>'; L='<label>'; if ! V="$(gh issue view <N> --repo "$R" --json labels -q '.labels[].name')"; then echo "LABEL-REMOVE-FAILED $L (could not read the labels)"; exit 1; elif printf '%s\n' "$V" | grep -qxF "$L"; then if gh issue edit <N> --repo "$R" --remove-label "$L"; then echo "LABEL-REMOVED $L"; else echo "LABEL-REMOVE-FAILED $L"; exit 1; fi; else echo "LABEL-NOT-PRESENT $L"; fi
```

Read back (prints `LABELS-NOW <list>`, `LABELS-NOW none`, or `LABELS-READ-FAILED`):

```bash
R='<owner>/<repo>'; if S="$(gh issue view <N> --repo "$R" --json labels -q '[.labels[].name | select(startswith("superfix:"))] | join(",")')"; then echo "LABELS-NOW ${S:-none}"; else echo LABELS-READ-FAILED; exit 1; fi
```

### Decision message (posted at the Stop gate)

ONE comment, or one journal entry, per run. It holds every question for this run, numbered, each with the recommended answer, the effort and the budget.

```
> **In plain English:** I found 2 problems and what causes them. I need 2 answers before I fix anything.

Reply in one line, for example "1 yes, 2 option two". "Keep executing" means yes to every question where I recommend an answer.

1. P1 (problem 1: the total is off by one): fix the loop bound (recommended) or rewrite total()? About 20 minutes of my time; your part: reply once.
2. Budget: Up to 1 hour, touching these 2 files: sum.js, test/sum.test.js. I stop and ask if I go over. OK?

---
<AI detail: Coverage block, Problem Profile, Tools used, failing check output, hypotheses table>
Pictures: <TAKEN n | NONE (no screen: why) | NO-BROWSER | HELD (why) | LOCAL (public repo) | NOT-POSTED (why)>
Labels: <LABELS-NOW, or not set (<word>); marker superfix-awaiting-decision>
Diagram: <ASKED (why) | NONE (why)>
Gap note: <FILED n | SEEN-AGAIN n | LOCAL n | NONE (supported)>
Work order: <NONE (normal run) | ASKED (written after go) | WRITTEN <path> | RETURNED <word> | VERIFIED <PASS or FAIL>>
Criteria: <PROPOSED n (P1, P2)[; NONE (P3: why)] | APPROVED n (...) | NONE (no Everything else problem)>
Criteria check: <criteria mode: plain name RESULT (value), ...; else NONE (no Everything else problem)>
```

- Effort wording, exact form: "About 1 hour of my time; your part: publish once." (Qik) or "...your part: reply once." (code).
- When the work needs a login, add one line: "Please don't type passwords here. Name the 1Password item instead."
- First mention of any P number in a message reads "P1 (problem 1: <short name>)".
- One coverage line per problem, in plain words, before the numbered questions:
  - Code: This is a code problem, because you wrote "<quote>". I can find the cause and fix it.
  - Qik: This is a Qik settings problem, because you wrote "<quote>". I can fix it in the draft, but my Qik fixing is not yet proven by a test, so you check it and publish.
  - Everything else: This is not code or Qik, because you wrote "<quote>". I can fix it only against checks you approve below, on a copy, never your original. For a process I only draft the change.
- Simple with one problem: the short form, three lines (problem, fix, effort) and "Go?". The effort line carries the budget in its plain wording.
- Write `Loaded: journal.md` (and the other references read so far) in the AI detail part.
- Question count: write the numbered questions first, then the callout, and state the number in digits ("I need 3 answers"). Before posting, check that the callout's number matches the numbered lines above the `---` (the Simple short form, with "Go?" and no numbered lines, is exempt):

```bash
F="$HOME/.superfix/runs/<run-key>/comment-<N>.md"; Q="$(awk '/^---$/{exit} {print}' "$F" | grep -cE '^[0-9]+\. ')"; C="$(head -1 "$F" | grep -oE '[0-9]+ answers?' | grep -oE '[0-9]+')"; if [ -n "$C" ] && [ "$Q" = "$C" ]; then echo COUNT-OK; else echo "COUNT-MISMATCH: $Q numbered questions, callout says ${C:-no number}"; fi
```

- 1.4.1, the lines check: before posting a decision comment or a final comment, check the required lines mechanically, after the count check. `K` is `decision` (only the AI detail below the LAST `---` counts) or `final` (the whole comment); lines inside code fences never count. Each of `Pictures:`, `Labels:`, `Diagram:`, `Gap note:` and `Work order:` must start a line exactly once, and the `Labels:` value must equal a fresh read-back of the issue's labels (or that value plus ` (ready for your review)`; `not set (...)` only while the issue has no superfix label; `none (no issue)` in file mode, written `R='none'`). It prints `LINES-OK`, `LINES-MISSING <which>`, `LABELS-MISMATCH line: <value>; issue: <labels>` or `LABELS-READ-FAILED`; post only after `LINES-OK`:

```bash
F="$HOME/.superfix/runs/<run-key>/comment-<N>.md"; K='<decision or final>'; R='<owner>/<repo>'; if [ "$K" = decision ]; then A="$(awk '/^[`][`][`]/{f=!f; next} f{next} /^---$/{b=""; next} {b=b $0 "\n"} END{printf "%s", b}' "$F")"; else A="$(awk '/^[`][`][`]/{f=!f; next} !f' "$F")"; fi; M=""; for k in Pictures Labels Diagram 'Gap note' 'Work order'; do [ "$(printf '%s\n' "$A" | grep -c "^$k: ")" = 1 ] || M="$M $k"; done; if [ -n "$M" ]; then echo "LINES-MISSING$M"; else V="$(printf '%s\n' "$A" | sed -n 's/^Labels: //p')"; if [ "$R" = none ]; then if [ "$V" = 'none (no issue)' ]; then echo LINES-OK; else echo "LABELS-MISMATCH line: $V; issue: none (no issue)"; fi; elif S="$(gh issue view <N> --repo "$R" --json labels -q '[.labels[].name | select(startswith("superfix:"))] | join(",")')"; then S="${S:-none}"; case "$V" in "$S"|"$S (ready for your review)") echo LINES-OK;; "not set ("*) if [ "$S" = none ]; then echo LINES-OK; else echo "LABELS-MISMATCH line: $V; issue: $S"; fi;; *) echo "LABELS-MISMATCH line: $V; issue: $S";; esac; else echo LABELS-READ-FAILED; fi; fi
```

- 1.5.0, criteria mode: right after `LINES-OK`, criteria.md's comment check also fails with `LINES-GAP-WITH-CRITERIA` when `Gap note:` counts a note, or a gap-list sentence names a problem, whose checks are proposed (only a problem marked `NONE` on the `Criteria:` line, or one with an `owner` criterion, may have a note).
- Pictures (references/evidence.md): below the numbered questions (Simple short form: below "Go?", the three lines unchanged), the first picture of each problem that has one, each followed by its caption line, then once the line "Pictures show on the website, not in the GitHub app: <issue link>". The callout and the questions never depend on a picture. A public repo or no issue: the local folder line from evidence.md in place of the pictures. A credential given in this run (any `HELD`): the "Pictures are not posted because you gave me a password or token in this run" line from evidence.md in place of the pictures.
- The Viewed line of each picture goes in the AI detail part, never above the `---`.
- Required in every decision comment and decision journal entry, and in the final comment, in the AI detail: `Pictures: TAKEN <n> | NONE (no screen: <why>) | NO-BROWSER | HELD (<why>) | LOCAL (public repo) | NOT-POSTED (<why>)`. A stop is not complete without it. `NOT-POSTED` is for `NO-OCR`, no ImageMagick and an `assets` release waiting for a yes. `TAKEN <n>` must equal the `PICTURES-SAVED` count from evidence.md. For any problem the owner could see on a screen (a web page, an app screen, a rendered document or UI), `NONE (no screen)` is wrong: first Read references/evidence.md and take the picture. `NONE` is only for problems with no screen (command output, tests, servers, config).
- 1.4.1: the budget question always ends "(recommended: yes)". The example above keeps its 1.4.0 wording.
- 1.4.1, also required in the AI detail of every decision comment and decision journal entry, and of the final comment (a stop is not complete without them):
  - `Labels: <LABELS-NOW>`, copied from the read-back command, never typed from memory; or `not set (<word>); marker superfix-awaiting-decision` (or `superfix-approved`); or `none (no issue)`.
  - `Diagram: ASKED (<why>) | NONE (<why>)` at the stop; at the end `POSTED <n> | NO (owner said no) | HELD (<why>) | LOCAL (<why>) | NOT-POSTED (<why>) | NONE (<why>)` (references/diagrams.md).
  - `Work order: NONE (normal run) | ASKED (written after go) | WRITTEN <path> | RETURNED <word> | VERIFIED <PASS or FAIL>` (1.6.0, references/workorder.md), its first word exactly as shown: every normal run writes `NONE (normal run)`; a work order run writes `ASKED (written after go)` at the stop and `WRITTEN <path>` once it is locked.
  - `Gap note: FILED <n> | SEEN-AGAIN <n> | LOCAL <n> | NONE (supported)` (references/gaps.md); the final comment adds "open notes in your gap list: <n>".
- The diagram question (exact text in references/diagrams.md) goes after the problem and budget questions and before the `assets` and create-issue questions; the create-issue question stays last.
- The gap note lines (exact text in references/gaps.md) go below the numbered questions, one per noted problem, with the gap list link only on a PRIVATE work repo.
- 1.5.0, criteria mode (references/criteria.md): above the numbered questions, after the coverage lines, the plain block (one line per criterion: "<plain name>. Today: <number> (rows <N>, <N> and <N>). Must be <pass line>.", the bracket holding row numbers only); the two shared questions after the problem questions and before the budget question, asked ONCE for all criteria-mode problems ("P1, P2 and P3"; once per group when the problems touch different people or files), with no recommended answer; the sandbox and data-commit questions (only when they apply) before the budget question, with no recommended answer; after the budget question, in this order: the diagram question, the reminder question for a `later` criterion (no recommended answer), the `assets` question, the create-issue question last. `Criteria:` and `Criteria check:` go after `Gap note:` in the AI detail; the comment check prints `CRITERIA-OK` before posting, after `LINES-OK`.

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
- No issue: the label commands do not run; the `Labels:` line reads `Labels: none (no issue)`. The `Diagram:` and `Gap note:` lines are written as for an issue.
- The decision entry carries the same required `Pictures:` line as the decision comment (Decision message, above).
- Say the file path in chat every time you stop.

### Plan comment (Moderate, Complex, after the expert panel)

```
> **In plain English:** The plan passed expert review and I am starting the fix. Nothing needed from you now.

Plan: docs/superpowers/plans/<filename>.md
Key decisions: [brief summary]
Labels: <LABELS-NOW>
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
Pictures: <the same required line, now for the after pictures too>
Labels: <LABELS-NOW, or not set (<word>); marker superfix-awaiting-decision>
Diagram: <POSTED n | NO (owner said no) | HELD (why) | LOCAL (why) | NOT-POSTED (why) | NONE (why)>
Gap note: <FILED n | SEEN-AGAIN n | LOCAL n | NONE (supported)>; open notes in your gap list: <n>
Criteria check: <criteria mode: plain name RESULT (before -> after), ...; else NONE (no Everything else problem)>
Work order: <NONE (normal run) | VERIFIED <PASS or FAIL>>
Executor: <work order mode only: the Report's EXECUTOR line, quoted in a code block after the redaction checks>
| check | before | after | must be | result |  (criteria mode only: one row per criterion, references/criteria.md)
## Not tested
- <item, and why>
```
Without an issue, write the same as a journal entry and say it in chat.

- The picture lines: one side-by-side picture per problem that had pictures (evidence.md), each with its caption; a problem with a before picture has an after picture or a stated reason (for example "P1 after picture not taken: <why>"); a problem with no screen gets "P<k> has no screen; its proof is the check output below." The website line once, only when there is a picture. A public repo or no issue: the local folder line instead. Pictures still held because of a credential: the same "Pictures are not posted because you gave me a password or token in this run" line, and the run waits for that answer before its end-of-run delete (evidence.md).
- Cost line: always present and always marked as an estimate, because the run cannot read its own bill. Rough figures by tier until the 1.4.0 test record gives measured ones: Simple about 2 USD, Moderate about 6 USD, Complex about 15 USD.
- Undo line: always present, in plain words. The revert command (`git revert -m 1 <merge sha>`) goes in the AI detail, not in the undo line. Qik work: "To undo, tell me "undo P1". The backup is in <folder>." instead.
- Diagrams (1.4.1): when posted, one pointer line after the picture lines, not the diagrams themselves: "The diagrams of the cause and of the change are in the issue description, under P1 and under Proposed solution (default style, chosen by Claude)." The `Labels:` line of the final comment is the `LABELS-NOW` read-back value followed by the fixed suffix ` (ready for your review)`, for example `superfix:awaiting-decision (ready for your review)`, because "Ready for review" brings that label back. Never typed from memory; the lines check below compares it with the issue.

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
