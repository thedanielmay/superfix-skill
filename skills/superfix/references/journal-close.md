# Closing a run: final comment, side findings, closing verify

New in 1.7.7 ([superfix-skill#144](https://github.com/thedanielmay/superfix-skill/issues/144) step C). SKILL.md (Phase 4) says when to read this file: in full, at Phase 4, before the final comment, on every run. It is not needed before the stop. The sections moved here word for word from `journal.md`; "above" in them means `journal.md` (Comment format, Labels, Decision message), which the run has already read. The lines check for the final comment is in `journal.md` (Decision message), with `K='final'`.

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
- Diagrams (1.4.1): when posted, one pointer line after the picture lines, not the diagrams themselves: "The diagrams of the cause and of the change are in the issue description, under P1 and under Proposed solution (default style, chosen by Claude)." The `Labels:` line of the final comment is the `LABELS-NOW` read-back value followed by the fixed suffix ` (ready for your review)`, for example `superfix:awaiting-decision (ready for your review)`, because "Ready for review" brings that label back. Never typed from memory; the lines check in journal.md compares it with the issue.

### Side findings (1.7.0)

A side finding is something the run found and did not fix: a broken link next to the file it edited, a test that fails for another reason, a stale sentence. `side-findings: list` (the default, and what an absent key means) leaves every one of them under `## Not tested`.

With `side-findings: file`, the owner's yes to the `Settings:` line at the Stop gate is the approval to file them, so there is no separate question. Then, in this order:

- After the redaction checks pass on the title and on the body.
- At most 5 a run; the sixth and later stay under `## Not tested` with a line saying why.
- Never a finding that quotes a value from the owner's data: that one stays under `## Not tested`.
- Label `superfix:side-finding`, colour `1D76DB`, description "Found while working on another issue": ensure it exists with the same ensure command shape as the labels above, then the same add and read-back commands.
- Assignee: the main issue's assignee, or else the user `gh` is logged in as (`gh api user -q .login`).
- Title: the finding in one plain line, with no value from the data.
- Body: it starts "Found while working on [<repo>#<N>](https://github.com/<owner>/<repo>/issues/<N>)", an explicit markdown link labelled `<repo>#<N>`, never a bare number and never in backticks; then the evidence: the file and line, and the command output that showed it. Replace output containing values from the owner's data with a value-free excerpt or omit it; if the finding cannot be safely redacted, keep it under `## Not tested` only.
- A create that fails is reported with its output and never retried blindly; the rest of the run carries on.
- In the final comment, each `## Not tested` bullet that was filed ends "filed as <link>".
- No issue (file-mode journal): nothing is filed, and the findings stay under `## Not tested`.

### Closing verify (Phase 4)
After the PR merges, read `closingIssuesReferences` on the PR and the issue state. A closing keyword in the PR body does not always close the issue, so verify; if the issue is still open, close it by hand with a comment. Post the comment with `gh issue comment` first, then `gh issue close`, because `close --comment` silently drops the comment when a keyword already closed the issue.
