# Diagrams

New in 1.4.1 ([superfix-skill#51](https://github.com/thedanielmay/superfix-skill/issues/51)). SKILL.md ("Diagrams") says when to read this file: in full, before the diagram question at the Stop gate. A diagram explains the fix to the owner; it never informs the choice (the pictures and the write-up do that), so it is drawn only after go. Every rule of `references/evidence.md` and `references/redaction.md` still holds; this file adds the diagram rules. Every command below writes each value out literally, because the shell keeps no variables between calls, and prints one word: silence is never a pass.

### When to ask

- Ask only when ALL hold:
  - the confirmed tier is Moderate or Complex;
  - the cause, or the change you will recommend, names 3 or more distinct files, functions or states that interact;
  - the problem will be fixed (coverage row Code or Qik);
  - there is an issue on a PRIVATE repo (a public repo or no issue: nothing would be posted, so do not ask).
- Never for Simple, the fast lane, an "Everything else" problem, or a one-line fix.
- Otherwise the AI detail says `Diagram: NONE (<why>)`, for example `Diagram: NONE (Simple)` or `Diagram: NONE (public repo)`.

### The question (exact, one numbered question)

It goes after the problem and budget questions and before the `assets` and create-issue questions (the create-issue question stays last):

```
<k>. Diagrams: may I add two small diagrams to the issue (the cause today and the change, about <b> boxes each, about 1 USD)? They show on the website, not in the GitHub app. I draw them after your go, so they do not change the options above. (recommended: yes)
```

- `<b>` is the number of boxes you plan (at most 9).
- The owner's standing rule is to ask before any diagram for GitHub content; this question is that ask. "Keep executing" says yes to it, as to every question with a recommended answer.
- In the AI detail: `Diagram: ASKED (<the 3 or more parts, by name>)`.

Before asking, run the `assets` release check in a dry form (no create). It is the evidence.md command with the last step changed to print a word instead of creating:

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; R='<owner>/<repo>'; ME="$(gh api user -q .login)"; if [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; elif [ -z "$ME" ] || [ "${R%%/*}" != "$ME" ]; then echo "ASK-FIRST $R"; elif gh release view assets --repo "$R" >/dev/null 2>&1; then echo ASSETS-EXISTS; elif gh api "repos/$R/git/ref/tags/assets" >/dev/null 2>&1; then echo "ASK-FIRST-TAG $R"; else L="$(gh api "repos/$R/git/trees/HEAD?recursive=1" -q 'if .truncated then "TRUNCATED" else (.tree[] | select(.type == "blob") | .path) end' 2>&1)"; rc=$?; if [ $rc -ne 0 ] && ! printf '%s\n' "$L" | grep -q 'HTTP 409'; then echo "ERROR: could not list the repo files"; else : > "$D/workflow-flags"; if [ $rc -eq 0 ]; then printf '%s\n' "$L" | grep -qx TRUNCATED && echo "UNREAD the file list is too long to read in full" >> "$D/workflow-flags"; printf '%s\n' "$L" | grep -i '^\.github/workflows/' | while IFS= read -r p; do T="$(gh api "repos/$R/contents/$p" -q .content 2>/dev/null | base64 -d 2>/dev/null)"; if [ -z "$T" ]; then echo "UNREAD $p" >> "$D/workflow-flags"; elif printf '%s\n' "$T" | grep -qiE 'push|release|create|tags|workflow_run|workflow_call|repository_dispatch|(^|[[:space:]])"?on"?:[[:space:]]*[[{]'; then echo "FLAG $p" >> "$D/workflow-flags"; fi; done; fi; if [ -s "$D/workflow-flags" ]; then echo "ASK-FIRST-WORKFLOWS $R"; cat "$D/workflow-flags"; else echo "ASSETS-WOULD-CREATE $R"; fi; fi; fi
```

- `ASSETS-EXISTS`: the question as above.
- `ASSETS-WOULD-CREATE` (a PRIVATE repo you own, no `assets` release yet, no flagged workflow): the question adds, before `(recommended: yes)`: "Yes also lets me create a private image store on this repo."
- `ASK-FIRST`, `ASK-FIRST-TAG` or `ASK-FIRST-WORKFLOWS`: the question ends `(no recommendation: <the reason in plain words>)` in place of `(recommended: yes)`, so "keep executing" does not cover it; anything but an explicit yes is no. The 1.4.0 `assets` question (evidence.md) is still asked as well when pictures need it.
- `NO-RUN-FOLDER` or `ERROR`: the check did not run; fix it and run it again.

### After go: the brief

Only after a yes. First find the diagram skill and record the style (once per Mac):

```bash
SK="$(ls -d "$HOME"/.claude/plugins/cache/diagram-design/diagram-design/*/skills/diagram-design 2>/dev/null | sort -V | tail -1)"; if [ -n "$SK" ] && [ -f "$SK/SKILL.md" ] && [ -f "$SK/scripts/self_check.py" ] && [ -f "$SK/assets/template.html" ]; then echo "DIAGRAM-SKILL $SK"; else echo DIAGRAM-SKILL-MISSING; fi
```

```bash
umask 077; C="$HOME/.superfix/config"; if grep -q '^diagram_style=' "$C" 2>/dev/null; then echo STYLE-SET; else mkdir -p "$HOME/.superfix" && printf '%s\n' 'diagram_style=default (chosen by Claude; change it with diagram-design:profile)' >> "$C" && echo STYLE-WRITTEN; fi
```

- `DIAGRAM-SKILL-MISSING`: no diagrams; `Diagram: NOT-POSTED (diagram skill not found)`. No `BROWSER-SCRIPT` line in this run (evidence.md, Finding the tools): `Diagram: NOT-POSTED (no browser script)`.
- Superfix never invokes the diagram skill and never writes a `.diagram-design` marker (it would sit in the clone and break the stop check). A subagent follows the skill's files.

Write the brief to `$HOME/.superfix/runs/<run-key>/diagrams/brief.md` (under `umask 077`), with every path absolute and written out in full. Its text comes from `## Problems` and the approved option, redacted text only (never a credential, never the owner's words in quotes):

```
DIAGRAM BRIEF (superfix 1.4.1). Do not ask any question; the owner cannot be reached.
Read these four files first: <SK>/SKILL.md, <SK>/references/type-flowchart.md,
<SK>/references/style-guide.md, <SK>/assets/template.html.
Style: the shipped default tokens. The owner's tool chose the default style on purpose, so skip
onboarding and the style gate. Type: flowchart. Size: doc-inline.
Diagram 1, the cause today: nodes <id: label (file:line)>, edges <id -> id>, accent node <id> (the part that fails).
Diagram 2, the change: the same layout; accent node <id> (the part that changes).
Write exactly two files, nothing else anywhere:
  /Users/<you>/.superfix/runs/<run-key>/diagrams/sf-<N>-diagram-problem.html
  /Users/<you>/.superfix/runs/<run-key>/diagrams/sf-<N>-diagram-solution.html
Every node is a <g data-sf-node="<id>"> group; at most 9 per diagram. No <image>, no
<foreignObject>, no script, no external asset beyond Google Fonts. Do not write a .diagram-design
file or anything in a git repository. Proceed and list your assumptions in your reply.
Return exactly one line first: DIAGRAMS-WRITTEN <path> <path>, or DIAGRAM-QUESTION <one line>.
```

- Each node is a real file, function, step or state from `## Problems`. Drop the solution diagram if it would look the same as the problem one, and say so.
- Run the exact-string check (redaction.md) on the brief file before dispatch; `BLOCKED` stops it.
- Dispatch: `Agent` [sonnet/high] with the brief copied into the prompt. One dispatch.
- `DIAGRAM-QUESTION <line>`: nothing is drawn or posted; `Diagram: NOT-POSTED (the diagram skill needed an answer)` and the Not tested line below. The run never ends on the skill's question; the fix goes on.
- After it returns, the clone must be unchanged: `if [ -z "$(git -C '<clone>' status --porcelain)" ]; then echo CLONE-CLEAN; else echo CLONE-CHANGED; git -C '<clone>' status --porcelain; fi`. `CLONE-CHANGED`: remove what the subagent wrote there, say so, and post no diagram.
- Put the subagent's assumptions in the AI detail of the final comment.

### Source check (before rendering, one command per file)

It writes a normalised copy (`<name>.norm.txt`: entities decoded, zero-width and direction characters removed, and the text with tags removed so text split across `<tspan>` joins up) and a copy with all spaces removed (`<name>.flat.txt`). The exact-string check runs on all three; the skill's `self_check.py` must print `OK`; the pattern check (redaction.md, plus e-mail) runs on the file and the normalised copy, never on the copy without spaces; the file must hold 1 to 9 `data-sf-node` groups. `<python>` is the BROWSER-SCRIPT interpreter; `<SK>` the skill folder from `DIAGRAM-SKILL`.

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; N='<name>'; PY='<python>'; SK='<SK>'; F="$D/diagrams/$N.html"; if [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; elif [ ! -f "$F" ]; then echo "DIAGRAM-SOURCE-BLOCKED missing"; else B="$("$PY" -I -c 'import html, re, sys
f = sys.argv[1]; s = open(f, encoding="utf-8", errors="replace").read()
zw = re.compile("[­​-‏⁠﻿‪-‮]")
t = re.sub(r"\s+", " ", zw.sub("", html.unescape(re.sub(r"<[^>]*>", "", s))))
open(f[:-5] + ".norm.txt", "w").write(zw.sub("", html.unescape(s)) + "\n" + t + "\n")
open(f[:-5] + ".flat.txt", "w").write(re.sub(r"\s+", "", t) + "\n")
print(len(re.findall(r"<g\b[^>]*\bdata-sf-node", s)))' "$F")"; if [ -z "$B" ]; then echo "DIAGRAM-SOURCE-BLOCKED normalise"; else X="$(L="$D/secrets"; P="$(grep -v '^[[:space:]]*$' "$L" 2>/dev/null)"; if [ -z "$P" ]; then echo NO-LIST; else H="$(printf '%s\n' "$P" | grep -F -l -f - "$F" "$D/diagrams/$N.norm.txt" "$D/diagrams/$N.flat.txt")"; rc=$?; if [ $rc -gt 1 ]; then echo ERROR; elif [ -n "$H" ]; then echo BLOCKED; else echo CLEAN; fi; fi)"; K="$("$PY" -I "$SK/scripts/self_check.py" "$F" 2>&1 | head -1)"; H="$( { grep -H -n -E -i '(password|passwd|pwd|secret|token|api[_-]?key|auth|bearer|cookie|session)[[:space:]]*[:=][[:space:]]*[^[:space:]]+' "$F" "$D/diagrams/$N.norm.txt"; grep -H -n -E '(^|[^A-Za-z0-9])(sk-[A-Za-z0-9]|ghp_|gho_|github_pat_)|AKIA[0-9A-Z]{16}|eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.|-----BEGIN [A-Z ]*KEY-----|://[^/[:space:]:@]+:[^/[:space:]@]+@|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$F" "$D/diagrams/$N.norm.txt"; perl -ne 'while (/(?<![A-Za-z0-9])([A-Za-z0-9]{32,})(?![A-Za-z0-9])/g) { my $s=$1; next unless $s=~/[A-Za-z]/ && $s=~/[0-9]/; next if $s=~/^[0-9a-f]{40}$/i; print "$ARGV:$.:\n" } close ARGV if eof' "$F" "$D/diagrams/$N.norm.txt"; } | cut -d: -f1,2 | sort -u )"; case "$X" in CLEAN|NO-LIST) ;; BLOCKED) echo "DIAGRAM-SOURCE-BLOCKED exact"; X=STOP;; *) echo "DIAGRAM-SOURCE-BLOCKED exact (the check did not run)"; X=STOP;; esac; if [ "$X" != STOP ]; then if [ "$K" != "OK $F" ]; then echo "DIAGRAM-SOURCE-BLOCKED self-check"; elif [ -n "$H" ]; then echo "DIAGRAM-SOURCE-BLOCKED pattern"; echo "$H"; elif [ "$B" -lt 1 ] || [ "$B" -gt 9 ]; then echo "DIAGRAM-SOURCE-BLOCKED boxes $B"; else echo DIAGRAM-SOURCE-CLEAN; fi; fi; fi; fi
```

- `DIAGRAM-SOURCE-CLEAN`: go on to render.
- `DIAGRAM-SOURCE-BLOCKED <exact|pattern|self-check|boxes N|missing|normalise>`: that diagram is not rendered or posted. A pattern hit blocks it; there is no "you decide" for diagrams. `Diagram: NOT-POSTED (<why>)` and the Not tested line below.

### Render

Write `shot.py` into the run folder first (evidence.md, The capture script), then:

```bash
D="$HOME/.superfix/runs/<run-key>"; "<python>" "$D/shot.py" diagram --run "$D" --html "$D/diagrams/<name>.html" --name <name>
```

- It prints `SAVED <file>`, `NO-SVG`, `UNREACHABLE <kinds>`, `ERROR boxes <n>` or `ERROR <reason>`. Inside: page scripts off, only `file:` and Google Fonts let through (anything else is `UNREACHABLE remote-asset`), the first `<svg>` only, a paper background (a transparent picture with dark text is unreadable on GitHub's dark theme), the Geist font checked as loaded (else `ERROR fonts`), and the picture scan from evidence.md plus `foreignObject`.
- It writes `diagrams/<name>.png` (1x, at most 1600 px wide, stripped), `diagrams/<name>.ocr.png` (2x, for OCR) and `diagrams/<name>.json`. Diagrams live in `diagrams/`, never in `evidence/`, so the `PICTURES-SAVED` count and the picture upload command stay exactly as in 1.4.0.
- Any other result: no diagram, `Diagram: NOT-POSTED (<word>)`, the Not tested line below. There is no ImageMagick fallback: it renders without the fonts.

### Looking at each diagram (Viewed, a self-report)

Read the PNG yourself, then write what it shows in one line. You wrote the brief, so you know what it should show; this line is a self-report, not a check. What protects a diagram is the source check, OCR and the held rule.

```bash
umask 077; printf '%s\n' 'Viewed (self-report): diagram, <what it shows, in words>' > "$HOME/.superfix/runs/<run-key>/diagrams/<name>.viewed" && echo VIEWED-SAVED
```

`"<python>" "$D/shot.py" diagram-verify --run "$D" --name <name>` prints `OCR-CLEAN` or `OCR-BLOCKED`, then `VIEWED-SELF-REPORT` or `NOT-VIEWED` (no line, a different form, or a line older than the PNG). The upload command runs it; you do not need to.

### The diagram upload command (one per file; never evidence.md's picture command)

Same structure as the picture command. `A` is `upload` (an issue on a PRIVATE repo), `approved` (only after the owner replied "post the pictures" in this run, after these diagrams were drawn) or `keep` (anything else). The `assets` release must exist first: on a yes to the diagram question when the dry check said `ASSETS-WOULD-CREATE`, run evidence.md's `assets` command (it creates the release after the same checks).

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; N='<name>'; R='<owner>/<repo>'; A='<upload, approved or keep>'; PY='<python>'; F="$D/diagrams/$N.png"; O="$D/diagrams/ocr-$N"; if ! command -v tesseract >/dev/null; then echo NO-OCR; elif [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; else if [ "$A" = upload ] && grep -q '[^[:space:]]' "$D/secrets" 2>/dev/null; then A=keep; echo "HELD $N: a credential is on this run's list, so the diagram stays on the Mac until the owner says post the pictures"; fi; case "$A" in upload|approved) U=yes;; *) U=no;; esac; if [ "$U" = yes ] && [ "$(gh repo view "$R" --json visibility -q .visibility)" != PRIVATE ]; then echo NOT-PRIVATE; elif ! grep -q '^Viewed (self-report): diagram, ' "$D/diagrams/$N.viewed" 2>/dev/null; then echo NOT-VIEWED; else V="$("$PY" "$D/shot.py" diagram-verify --run "$D" --name "$N" | tr '\n' ' ')"; E="$(L="$D/secrets"; P="$(grep -v '^[[:space:]]*$' "$L" 2>/dev/null)"; if [ -z "$P" ]; then echo NO-LIST; else H="$(printf '%s\n' "$P" | grep -F -l -f - "$O.txt")"; rc=$?; if [ $rc -gt 1 ]; then echo "ERROR: a file could not be read"; elif [ -n "$H" ]; then echo "BLOCKED $H"; else echo CLEAN; fi; fi)"; P="$(H="$( { grep -H -n -E -i '(password|passwd|pwd|secret|token|api[_-]?key|auth|bearer|cookie|session)[[:space:]]*[:=][[:space:]]*[^[:space:]]+' "$O.txt"; grep -H -n -E '(^|[^A-Za-z0-9])(sk-[A-Za-z0-9]|ghp_|gho_|github_pat_)|AKIA[0-9A-Z]{16}|eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.|-----BEGIN [A-Z ]*KEY-----|://[^/[:space:]:@]+:[^/[:space:]@]+@|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$O.txt"; perl -ne 'while (/(?<![A-Za-z0-9])([A-Za-z0-9]{32,})(?![A-Za-z0-9])/g) { my $s=$1; next unless $s=~/[A-Za-z]/ && $s=~/[0-9]/; next if $s=~/^[0-9a-f]{40}$/i; print "$ARGV:$.:\n" } close ARGV if eof' "$O.txt"; } | cut -d: -f1,2 | sort -u )"; if [ -n "$H" ]; then echo "PATTERN-HITS:"; echo "$H"; else echo PATTERN-CLEAN; fi)"; echo "$E / $V/ $P"; case "$E" in CLEAN|NO-LIST) ;; *) E=BAD;; esac; if [ "$E" != BAD ] && [ "$V" = "OCR-CLEAN VIEWED-SELF-REPORT " ] && [ "$P" = PATTERN-CLEAN ]; then if [ "$U" = yes ]; then gh release upload assets "$F" --repo "$R" && echo "DIAGRAM-UPLOADED $N"; else T="$HOME/.superfix/journal/${R%%/*}-${R#*/}/diagrams/${D##*/}"; mkdir -p "$T" && cp "$F" "$T/" && echo "DIAGRAM-KEPT $N $T"; fi; else echo "DIAGRAM-NOT-UPLOADED $N"; fi; fi; fi
```

- `DIAGRAM-UPLOADED <name>` or `DIAGRAM-KEPT <name> <folder>`: done. Anything else: nothing left the run folder.
- `HELD`: any entry in the secrets list holds every diagram on the Mac, like a picture (`Diagram: HELD (<why>)`); "post the pictures" releases them too, through this command with `A='approved'`.
- `NOT-PRIVATE`: never upload; run it again with `A='keep'`. `NO-OCR`: nothing is uploaded.
- `DIAGRAM-NOT-UPLOADED` after `BLOCKED`, `OCR-BLOCKED` or `PATTERN-HITS`: no diagram, no retry with the same text. After `NOT-VIEWED`: Read it, write the line, run again.
- A failed `gh release upload` (the name is taken) prints its own error and no `DIAGRAM-UPLOADED`: render again under the next name (`-2`), never overwrite.

### Names, captions and where they go

- Names: `sf-<N>-diagram-problem` and `sf-<N>-diagram-solution` (letters, digits, `.`, `_`, `+`, `-`). At most two per run.
- Captions carry the meaning, because the GitHub app does not show these pictures. Read on their own, they say what the diagram shows:
  - `P1 cause today: the CLI, the server and the page each add up the prices themselves; the page skips the third price (orange box).`
  - `P1 the change: one shared list of columns feeds the CLI, the server and the page (orange box).`
- Issue body only, in a go body update after `DIAGRAM-UPLOADED`: the problem diagram under the problem (`- Diagram:` in the journal.md template), the solution diagram under `## Proposed solution`, each as `![<caption>](https://github.com/<owner>/<repo>/releases/download/assets/<name>.png)` with the caption as plain text on the next line, and the website line once.
- The final comment carries one pointer line, not the pictures: `The diagrams of the cause and of the change are in the issue description, under P1 and under Proposed solution (default style, chosen by Claude).`
- A panel overturn that changes the approved option: the overturn message says the solution diagram is out of date; after the new go it is drawn again or removed from the body.

### The Diagram: line (required, journal.md)

- Decision comment: `Diagram: ASKED (<why>) | NONE (<why>)`.
- Final comment: `Diagram: POSTED <n> | NO (owner said no) | HELD (<why>) | LOCAL (<why>) | NOT-POSTED (<why>) | NONE (<why>)`. `LOCAL` is a diagram that passed every check but stays on the Mac (`DIAGRAM-KEPT`, for example the `assets` release did not get a yes).

### Not tested lines (exact)

- `Diagrams: not drawn, because the diagram skill needed an answer this run cannot give.`
- `Diagrams: not posted, because rendering failed (<word>).`
- `Diagrams: not posted, because the source failed a secrets check.`
- `Diagrams: not posted, because you gave me a password or token in this run. They are on the owner's Mac at <path>.`
