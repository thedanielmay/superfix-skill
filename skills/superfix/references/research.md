# Research runs: a question, a report, one validation pass

New in 1.7.0. `SKILL.md` Phase 0 names the type; this file holds the flow, the report shape, the validation brief and the limits.

A research issue asks a question and wants an answer. It is not a bug and no file has to change. Examples: which of two libraries still gets releases, where a number in a document comes from, whether a page still says what the README says.

## Detection

Label `research`, or the owner asks what is true, asks you to find out, to investigate or to compare two or more things, and asks for no change. One word of change ("and fix it") makes it a normal run: the type is then the change, and the questions join its diagnosis.

## Flow

1. Phase 0 and Phase 1 as usual, without a failing check: the questions are the work. Record each one as Q1, Q2 and so on at the top of `## Problems`, in the owner's words where he asked in words.
2. Explore read only, and keep the evidence with each step: the file and line, or the command and its output. A claim without one of those is not a claim yet.
3. Write the report below into the `## Report` section of the issue body or journal file, and stop at the Stop gate as usual: the owner's go is needed before anything is posted, and the comment goes through the comment gate like any other.
4. One validation agent, then the conclusion.
5. A research run makes no code change, no branch and no PR. Its output is a comment on the issue and a `## Report` body section. With no issue, it is a journal file, as for any other run.

## The report

One block per question:

```
Q1 <the question, as asked>
Answer: <one or two sentences, plainly>
Evidence: <file:line, and what it says>; <the command, and the output trimmed to the lines that carry the answer>
Certainty: confirmed | suspected
```

Rules: no answer without evidence; a claim you could not check is `suspected` and says what would settle it; never a value from the owner's data (redaction.md); never a bare issue number (house style: a markdown link labelled `owner/repo#N`).

## The validation pass, one agent and once

The agent gets the report and the questions only: not the exploration notes, not the plan, not the commands you ran. Its brief:

```
VALIDATION BRIEF: here are the questions and the report. For every claim in the report,
return exactly one line:
  Q<n> <the claim, quoted>: CONFIRMED, with the evidence you found yourself
  Q<n> <the claim, quoted>: CORRECTED <what is right>, with the evidence you found yourself
  Q<n> <the claim, quoted>: REFUTED <why>, with the evidence you found yourself
Evidence is a file and line, or a command and its output. You report and you ask
questions. You do not write the conclusion, and you do not change the report.
```

Then the main thread writes the conclusion:

- Apply every CORRECTED line, drop every REFUTED claim, and keep every CONFIRMED claim as it stands.
- Say in the comment which claims the agent CONFIRMED and which ones were not checked by it. A claim the agent did not return stays unvalidated and is marked as such in the report.
- A report with zero validated claims cannot be posted as a conclusion: post the questions and what is missing instead, and stop.

## Limits

- The validator runs on the same account and the same model family. Its independence is a fresh context, nothing more: it never saw your work, but it is not a second opinion from a different engine.
- It cannot prove it looked at the evidence it cites: it can copy a file and a line out of the report without opening anything.
- CONFIRMED is not proof. It means a fresh context, given the same report, found the same thing where the report said it would be.
