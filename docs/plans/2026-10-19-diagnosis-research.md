## Recommendation

- **Install nothing. Write our own `references/diagnose.md`, built from about eight methods.**
  - No external skill matches Superfix's contract. That contract is: find every problem, gather evidence, test hypotheses, offer options, then stop until the owner approves.
  - The best external skills cover only one bug in code, and most go straight on to fixing it.
  - The business, document and process skills in the registry are tiny. The `fmea`, `five whys` and `process improvement` hits have 25 to 1.3K installs each, from unknown authors.
- **The idea to copy is mattpocock's rule: no check that fails, no hypothesis.**
  - It generalises well beyond code: before diagnosing anything, name one check that fails on this exact defect.
- **Already installed, so not surveyed here:** `systematic-debugging`, `diagnose`, `deep-research`, `fact-check-workflow`, `expert-panel`.

## Ranked best of the best (8)

Key: **C** = I checked the source (fetched it or read it through the gh API). **R** = I only read about it.

1. **mattpocock/skills `diagnosing-bugs`** (C, gh API source read 19 Oct 2026). MIT licence, 296K stars, 803K installs. https://github.com/mattpocock/skills/tree/main/skills/engineering/diagnosing-bugs
   - **Move:** "Failing check first". Diagnosis may not start until one command or check has been run and shown failing on the reported symptom.
   - Then shrink the case until every remaining part matters.
   - **Verdict: ADAPT.** It says to show hypotheses to the user but "don't block on it", which conflicts with Superfix's hard stop. Its Phases 5 and 6 are fixing, so cut them.
2. **Premature closure evidence: Graber, Franklin, Gordon 2005**, Arch Intern Med 165(13) (C, PubMed). https://pubmed.ncbi.nlm.nih.gov/16009864/
   - The study reviewed 100 diagnostic error cases. Premature closure (stopping once a first diagnosis is reached) was the most common cognitive cause.
   - **Move:** "Differential". Write 3 to 5 ranked hypotheses, each with a prediction that could prove it wrong, before testing any of them.
   - Keep a "ruled out, and how" list in `## Problems`.
   - **Verdict: ADAPT.**
3. **juliusbrussee/caveman `investigate-first`** (C, skills.sh page). Apache-2.0, 113K stars, 97K installs. https://skills.sh/juliusbrussee/caveman/investigate-first
   - **Move:** "Facts versus inferences". Keep observed facts apart from explanations.
   - Rank hypotheses by how strong the evidence is and how cheap they are to rule out.
   - End with "report, don't fix". It is the closest match to Superfix's stop.
   - **Verdict: ADAPT.**
4. **External evidence, not self-review: Huang et al., ICLR 2024**, arXiv 2310.01798 (C, search abstract).
   - Models fail to correct their own reasoning without outside feedback, and sometimes get worse.
   - **Move:** "Evidence or it is suspected". A root cause is marked confirmed only when a tool output, a measurement or a source document backs it.
   - **Verdict: ADAPT.**
5. **Agent RCA failure studies** (C, abstracts):
   - Riddell et al., arXiv 2601.22208, 29 Jan 2026: a taxonomy of 16 reasoning failures that predict whether the root cause is right.
   - Lu et al., arXiv 2608.21310, Aug/Oct 2026: three failure families (omitted evidence, misinterpreted evidence, unsupported reasoning). A defence aimed at those families raised top-1 accuracy by 3.5 to 35.1 points.
   - **Move:** "Self-audit before the stop". Before posting, check every claim for evidence that was skipped, misread or missing.
   - **Verdict: ADAPT.**
6. **riekelt/technical-writer `reviewing-technical-prose`** (C, gh API source read). MIT licence, 31 stars, 16K installs. https://github.com/riekelt/technical-writer
   - **Move for documents:** severity-tagged findings (BLOCKER, WARNING, OBS).
   - A "leave alone" list, so the review flags defects, not taste.
   - The rule that a rewrite must not add or drop a fact.
   - "[input wanted]" gaps instead of invented claims.
   - **Verdict: ADAPT.** Low star count, so read it, do not install it.
7. **Perspective-based reading: Basili et al. 1996**, Empir Softw Eng 1(2), doi 10.1007/BF00368702 (C, abstract only; no effect sizes seen).
   - **Move for documents and requirements:** read the document once as each role (user, tester, implementer, approver), and list what each role cannot act on.
   - Cite it as a structure, not as proven.
   - **Verdict: ADAPT.**
8. **Process failures: Kepner-Tregoe IS / IS NOT, plus FMEA with Action Priority** (R).
   - **Move:** a table setting where, when and how much the problem occurs against where it does not. It suits handoffs, forms and data quality, for example "only forms from site B since 1 Sept".
   - For process failure modes, rank by severity first (the AIAG-VDA 2019 Action Priority approach), not by the multiplied risk priority number (RPN). I saw this only on secondary sites.
   - **Verdict: ADAPT.**

## Generalising beyond code (business, documents, process)

- **Failing check, by domain:**
  - Data: a count that is wrong.
  - Process: a handoff whose output is missing, or a cycle time over target.
  - Document: a requirement with no owner, or a claim with no source.
- **Scope first (R):** SIPOC (suppliers, inputs, process, outputs, customers) or a one-page value stream map, to name the edges of the process before looking for causes.
- **Bottlenecks (R):** measure work in progress, throughput and lead time. By Little's law, the three are linked, so a queue that keeps growing points to the constraint.
- **Postmortem discipline (C, Google SRE book, sre.google/sre-book/postmortem-culture):**
  - Blameless: fix systems and processes, not people.
  - Write down the triggers for a full diagnosis in advance.
- **Chesterton's fence (R):** before proposing to remove a step, field or rule, record why it exists.
- **Cynefin (R, Snowden and Boone, HBR 2007):** only useful as a triage question: "is cause and effect knowable here?" If not, offer small safe probes, not a root cause.

## Safety flags

- **Registries contain harmful skills (C, Snyk ToxicSkills, 5 Feb 2026, https://snyk.io/blog/toxicskills-malicious-ai-agent-skills-clawhub).**
  - Of 3,984 skills scanned from ClawHub and skills.sh, 13.4% had at least one critical issue and 36.82% had at least one issue of any severity.
  - A CSA note describes the same corpus as ClawHub only. The primary source says both registries.
- **Install counts measure popularity, not quality.**
- **`addyosmani/debugging-and-error-recovery` shows a Snyk Warn** on skills.sh.
- **The "fact check" search returned a clone farm:** many unknown orgs each publishing `*/superpowers@web-search` with 40K to 100K installs (101-skills, magentosh, qu-skills, skills-shell). Treat them as a supply-chain risk.
- **Diagnosis is safe read-only only with limits.** It runs repro commands and reads logs, which can expose secrets and can trigger side effects. Copy mattpocock's redaction rule, and allow no writes to shared systems before approval.
- **Anything we copy is text to review, never instructions to obey.** That applies to the skill files themselves.

## Unverified or rejected

- **"LLM anchoring strongly predicts wrong root causes":** only in search snippets. Neither abstract says it. Unverified.
- **Pre-mortems give 30% more reasons:** the figure traces only to Klein's HBR summary, never to Mitchell, Russo and Pennington (1989). Unverified.
- **5 Whys:** rank it low. Card 2017, BMJ Qual Saf 26(8):671 (C), says it oversimplifies and that its popularity rests on pedigree, not evidence. At most, use it inside the differential with branches allowed.
- **Lean and Six Sigma tools (SIPOC, VSM, Ishikawa, Toyota A3):** I found no controlled evidence that they work. Use them as structure only.
- **AutoSD (Kang et al., arXiv 2304.02195; Empir Softw Eng 2024) (C):** it found the cause about as often as other methods, not more often. Its gain was explanations that helped people judge whether patches were correct (5 of 6 bugs, 20 participants). It supports the hypothesise-then-probe loop, not a claim of higher accuracy.
- **Anthropic's `debug` and `incident-response` skills (C, anthropics/knowledge-work-plugins):** SKIP. They are thin checklists, go straight to fixing, and use 5 Whys.

## The case for a small, method-based toolkit

- The strongest evidence above is about reasoning habits:
  - external evidence over self-review;
  - several hypotheses at once;
  - a failing check before any theory;
  - no evidence skipped.
- None of that evidence is about tools.
- Tool-specific skills tie Superfix to one stack.
- Each third-party file adds prompt-injection exposure.
- Eight short moves in one file can be tested with the five fixed test prompts. Twenty skills chained together cannot.
