# Evidence pictures

New in 1.4.0 ([superfix-skill#47](https://github.com/thedanielmay/superfix-skill/issues/47)). SKILL.md ("Evidence pictures") says when to read this file: in full, before the first picture. Pictures are taken by a script, checked for secrets in several layers, and uploaded by one command per file. Nothing here replaces a rule in `references/redaction.md`; it adds the picture rules.

### When, names, cap, size, captions

- **A credential you SEE, not only one you are TOLD, goes on the list.** Whenever the reporter's issue body, the chat, a URL the owner gave (its query string too), a file the run read (`.env`, config) or a log shows a credential, append it to the run's `secrets` list (redaction.md, Session list) BEFORE any picture is taken.
- **A credential in play in this run means no automatic upload.** When the run's `secrets` list has any entry, or a picture was taken with a saved login (`--storage`, which the script marks `"held": true`), no picture is uploaded on its own: the upload command keeps it on the Mac (it prints `HELD`), and the decision and final comments say: `Pictures are not posted because you gave me a password or token in this run. They are on your Mac at <path>. Look at them, then reply "post the pictures" if you want them on the issue.` A reply "post the pictures" uploads them, still through the upload command and all its checks (`A='approved'`). Blanking and OCR are a second line of defence, not proof; the owner's own look is the check that counts. With an empty list and no saved login there is no known secret, so the normal flow applies. When the stop rule for a credential in the reporter's original issue body fires (redaction.md), that credential is on the list, so every picture already taken in this run is held too.
- **The `Pictures:` line** (journal.md, required in the AI detail of the decision comment and of the final comment): `Pictures: TAKEN <n> | NONE (no screen: <why>) | NO-BROWSER | HELD (<why>) | LOCAL (public repo) | NOT-POSTED (<why>)`. `NOT-POSTED` covers `NO-OCR`, no ImageMagick and an `assets` release still waiting for a yes. `TAKEN <n>` must equal the number of pictures saved in the run folder, counted with:

```bash
D="$HOME/.superfix/runs/<run-key>"; if [ -d "$D/evidence" ]; then echo "PICTURES-SAVED $(find "$D/evidence" -maxdepth 1 -name '*.png' ! -name '*.ocr.png' ! -name '*.raw.png' | wc -l | tr -d ' ')"; else echo 'PICTURES-SAVED 0'; fi
```

- Take a picture only for a problem the owner can see on a screen: a page, a rendered component, a Qik draft page. Command, test, log and backend output stays text, never an image: text can be searched and checked by the redaction grep, a picture of it cannot.
- **Before** pictures: end of Phase 1, after the failing check ran. **After** pictures: during solved-check run 2, on the branch, same page, same viewport, same target.
- **Marks:** a 3px box with a white outer edge round the target, and a numbered label in clear space beside it (right, left or below, never above, because a label above covers text). Before is red `#e00`, after is green `#080`, same number as the problem (1 for P1). A second mark on P1 is a second picture with the label `1b`.
- **Cap:** 2 pictures per problem per stage, 6 per issue. Simple: 1 before and 1 after per problem.
- **Size:** viewport 1280 by 800, cut to the area round the target (never a long full page); at most 1600 px wide, metadata stripped, under 1 MB. The script does all three.
- **Names** (letters, digits, `.`, `_`, `+`, `-` only): `sf-<N>-p<k>-before-<i>.png`, `sf-<N>-p<k>-after-<i>.png`, `sf-<N>-p<k>-before-after.png`. File-mode runs use the journal slug instead of `<N>`. A retake after a failed upload uses the next `<i>`.
- **Captions carry the meaning.** The GitHub app does not show these pictures; the website does. The alt text and the caption line say what is wrong (or fixed) and where, in full words, and name the colour and number of the mark, so colour is never the only signal. Read on its own, the comment must say everything the picture shows.
  - Before: `P1 before: the Subscribe button (red box 1) is cut in half by the bottom edge of the price card.`
  - After: `P1 after: the whole Subscribe button (green box 1) sits inside the price card.`
  - Side by side: `P1 before and after: left, the button is cut off (red box 1); right, it sits fully inside the card (green box 1).`
  - No `[`, `]` or line break in a caption; no secret, file content or token in a caption (the redaction checks run on the comment and body files as always).

### Finding the tools (every run, before the first picture)

Follow the user's browser order rules first when the user has them. Take the picture with the first tool in that order that can run the blanking and checks below. Use the Playwright paths below only when that order cannot take the picture, or when the user asks for Playwright or a new browser. Without such a rule, keep the order below.

1. Look at your own tool list for `mcp__plugin_playwright_playwright__browser_run_code` (or any `mcp__*playwright*__browser_run_code`).
   - Listed in full: usable.
   - Listed by name only as a deferred tool (a system reminder names deferred tools): load it first with ToolSearch `select:mcp__plugin_playwright_playwright__browser_navigate,mcp__plugin_playwright_playwright__browser_run_code,mcp__plugin_playwright_playwright__browser_close`.
   - Not there at all: absent. A `claude -p` session can have a different tool set from an interactive one, so look in this run, never assume.
2. Shell probe, one call. It tries named interpreters and proves a browser launches:

```bash
for p in python3 /usr/bin/python3; do command -v "$p" >/dev/null 2>&1 && "$p" -c 'from playwright.sync_api import sync_playwright as s; b=s().start().chromium.launch(); b.close()' >/dev/null 2>&1 && { echo "BROWSER-SCRIPT $p"; break; }; done; echo PROBE-DONE
```

3. Choose, in this order:
   - `BROWSER-SCRIPT <python>` printed before `PROBE-DONE`: the script path, with that interpreter written out as `<python>` in every command below (on a Mac with Xcode it is often `/usr/bin/python3`, because Homebrew's `python3` has no playwright module).
   - Else Playwright MCP usable AND the exact-string check in redaction.md prints `NO-LIST` (no credential given this run): `BROWSER-MCP`. The MCP path cannot read the secrets file without pasting it into a tool call, so it is never used when the list has any entry.
   - Else `NO-BROWSER`: no pictures; the Not tested line below.
4. Claude in Chrome is never a picture source: it is the owner's real, signed-in browser. It stays a diagnosis aid, as in 1.3.1.
5. Write what you found in `Tools used:`, for example `Pictures: BROWSER-SCRIPT /usr/bin/python3; Playwright MCP: deferred, loaded; tesseract and magick present.` or `Pictures: NO-BROWSER; Playwright MCP: absent.`

### The capture script (script path)

`shot.py` lives in `references/shot.py` and is written into the run folder by the command below, never typed out by hand. `<skill dir>` is this skill's base directory, written out in full (the folder that holds `SKILL.md` and `references/`):

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; if [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; else mkdir -p "$D/evidence" && awk '/^# --- shot.py start ---$/{f=1} f{print} /^# --- shot.py end ---$/{f=0}' '<skill dir>/references/shot.py' > "$D/shot.py" && grep -q '^# --- shot.py end ---$' "$D/shot.py" && echo "SHOT-READY $D/shot.py"; fi
```

Interface (every command prints one word line; it never prints a secret, a matched line or the label side):

- `"<python>" "$D/shot.py" shoot --run "$D" --url <url> [--serve <dir>] --selector '<css>' --num 1 --colour red|green --name <name> [--hide '<css>']... [--storage <file>]` prints exactly one of `SAVED <file>`, `NO-MATCH`, `ZERO-SIZE`, `UNREACHABLE <kinds>`, `ERROR <reason>`, `NO-RUN-FOLDER <folder>`.
  - `--url` is a `file://` or `http://` address. With `--serve <dir>`, the script serves that folder itself on 127.0.0.1 (a free port, in a thread, stopped when it ends; no background process) and `--url` is the path inside it, for example `--serve <clone>/public --url /pricing.html`.
  - Inside, in order: read `$D/secrets` (if present); open the page at 1280 by 800 (2x pixels); wait for the network to go quiet (at most 5 seconds) and 300 ms more; **stop the page's own scripts** (`Emulation.setScriptExecutionDisabled`), so no timer or late fetch can write text after the checks; hide each `--hide` element (`visibility:hidden`); find the target (`NO-MATCH`); scroll the window only, so the target is centred (never `scrollIntoView`, which also scrolls an `overflow:hidden` box and can hide the very bug); measure it, `ZERO-SIZE` on 0 width or height (no mark is drawn on nothing); freeze CSS animations and transitions; blank every exact secret (also written backwards, and with soft hyphens, zero-width and direction characters removed from the page text and the secret before comparing) in every text node and every attribute, and the 1.3.1 token patterns and e-mail addresses in text, input and textarea values and the `placeholder`, `title`, `alt`, `aria-label` and `value` attributes, in open shadow roots and same-origin frames too, all replaced by `[redacted]`; **check** that no exact secret (spaces removed) is left in the page text as shown (`innerText`, which catches a secret split over two elements), in a same-origin frame, or in the CSS `content` of any `::before`, `::after` or `::marker`: any hit it cannot blank prints `UNREACHABLE split-text`, `frame-text` or `css-content`; draw the box and the label; scan the picture area for what blanking cannot reach (canvas, img, video, svg image, object or embed, a cross-origin iframe, a closed shadow root, and any CSS image: a computed `background-image`, `content`, `mask-image`, `border-image-source`, `list-style-image` or `cursor` value with `url(` or `image-set(`, on the element or its `::before`, `::after` or `::marker`, printed `css-image`; every such image counts, same-origin files included, as an `img` element does, because an image file can hold text too; a gradient has no `url(` and is fine): any one found prints `UNREACHABLE <kinds>` and saves nothing; blank and check once more right before the screenshot; take it at 2x, keep that as `evidence/<name>.ocr.png` for OCR, and post a 1x copy (`magick -strip -resize`, at most 1600 px wide, under 1 MB); record the label side in `evidence/mark-<name>.side` and how the picture was taken in `evidence/<name>.json`; print `SAVED`.
  - `UNREACHABLE`: take it again with `--hide '<css of that element>'` when the element is not the problem itself, and say in the caption that it was hidden. If the target itself is such a region, no picture: use the Not tested line below.
  - `--storage <file>`: a saved login (Qik draft pages; below). Never a file inside a repo.
  - Every page step has a 30 second limit and the whole run 120 seconds; past it the script prints `ERROR timeout` and stops.
  - An `ERROR` line is one code word (`timeout`, `browser`, `python`, or a fixed reason) and at most 60 characters: any URL is cut to its scheme and host, any run of 12 or more letters or digits becomes `...`, and listed secrets are hidden. Raw Playwright or Python messages are never printed.
  - `--serve` and `--storage` are stored as absolute paths, so `retake` works from any working folder. `--storage` marks the picture `"held": true`.
- `"<python>" "$D/shot.py" ocr --run "$D" --name <name>` reads the posted picture, the 2x copy and a larger grey copy with tesseract into `evidence/ocr-<name>.txt` and prints `OCR-READY`. The upload command runs it.
- `"<python>" "$D/shot.py" verify --run "$D" --name <name>` prints `OCR-CLEAN` or `OCR-BLOCKED`, then `VIEW-MATCH`, `VIEW-MISMATCH` or `NOT-VIEWED`. The OCR part looks for every secret exactly (spaces removed), and as every 6-character piece after folding the letters OCR confuses (o and 0, l, i and 1, g and 9, b and 8, z and 2, s and 5, rn and m). For a secret of 13 or more characters one misread character cannot hide it; a shorter secret with a misread near its middle can pass, and OCR can miss small or pale text altogether. Any Python 3 runs it; it needs no browser. The upload command runs it; you do not need to.
- `"<python>" "$D/shot.py" retake --run "$D" --source <before name> --name <after name> [--url <url>] [--serve <dir>]` takes the after picture exactly as the before one was taken (it reads `evidence/<before name>.json`: address, served folder, target, hidden elements, saved login, number), with a green box unless `--colour` says otherwise. Pass `--url` or `--serve` only when the page now lives elsewhere (for example the clone in place of the scratch worktree). A before picture taken on the MCP path prints `ERROR`: take the after one on the MCP path too, which is allowed only when the list prints `NO-LIST`.
  - `retake` scrolls to where the before picture was taken and keeps its area (Aligned crops, below). It prints `CROP-ALIGNED`, `CROP-WIDENED` or `CROP-DIFFERENT` on the line before `SAVED`.
- `"<python>" "$D/shot.py" pair --run "$D" --before <name> --after <name> --name <pair name>` makes the side-by-side picture (below) and prints `SAVED <file>`.
- `"<python>" "$D/shot.py" mcp-code ...` and `mcp-save ...`: the MCP path only (below).
- `"<python>" "$D/shot.py" diagram ...` and `diagram-verify ...` (1.4.1): diagrams only, in the run folder's `diagrams/` folder, never `evidence/` (references/diagrams.md).

`shot.py` is the script in `references/shot.py`; the command above copies it into the run folder, and each run calls it as `"<python>" "$D/shot.py" <subcommand> ...` (interface above).

### Aligned crops

New in 1.4.1. In 1.4.0 `retake` centred the moved target again, so the after picture showed a different page area. Now `shoot` stores the area it cut (`page_clip`, in page terms) and the scroll position in `evidence/<name>.json`, and `retake` scrolls back to that position, measures the after target and its mark, then:
- `CROP-ALIGNED`: the mark is inside the stored area. The after picture uses exactly the before area.
- `CROP-WIDENED`: the mark is partly outside the stored area but inside the window. The after picture shows both areas together (their union); `pair` puts the before picture on a canvas of that size at its place, grey `#e5e5e5` where nothing was captured, so the two halves line up. The caption adds: "the after side shows a wider area because <target> moved; grey means not in the before picture".
- `CROP-DIFFERENT`: the mark is outside the window at that scroll position, or the page can no longer scroll there. The 1.4.0 behaviour: the target is centred again. `pair` centres the smaller half on a grey canvas so the halves are the same size, and the caption says the two sides show different areas of the page.
- No full-page shot for the large case: the marks are `position:fixed`, and a full-page shot would move them.
- A before picture taken by 1.4.0 (no stored area) is retaken as in 1.4.0, with no CROP word. The MCP path keeps the 1.4.0 behaviour (Not tested).
- The result is also stored as `crop` in the after picture's `evidence/<name>.json` (that file may be read; only `mark-*.side` may not). Whoever writes the caption reads it there, so the caption is right even when the fix agent took the after picture.

### Looking at each picture (the Viewed line)

After `SAVED`, Read the PNG yourself (the Read tool shows the image), then write what you SEE, never what you expect, in one line:

```bash
umask 077; printf '%s\n' 'Viewed: label 1 red, right of the Subscribe button' > "$HOME/.superfix/runs/<run-key>/evidence/<name>.viewed" && echo VIEWED-SAVED
```

- Form, exactly: `Viewed: label <number> <red|green>, <right of|left of|below> <the target in words>`.
- Never read, print, list with contents or grep a `mark-*.side` file. The upload command compares your line with what the script drew (side, colour and number) and prints `VIEW-MATCH` or `VIEW-MISMATCH`. A Viewed line written before the picture was (re)taken is a `VIEW-MISMATCH`.
- What this is worth: a speed bump, not proof. It makes a line written without opening the picture likely to fail (the side depends on the page), but the colour and number are known in advance and a lucky guess passes, so it does not prove the picture was looked at. It is not what protects a credential: a run with any credential holds every picture until the owner has looked (top of this file).
- `VIEW-MISMATCH`: Read the picture again and rewrite the line from what you see. Never edit the side file.
- The side-by-side picture: describe the left (before) mark.
- The same Viewed line goes in the AI detail of the comment that carries the picture.

### MCP path (BROWSER-MCP, only after NO-LIST)

Only when the shell probe found no `BROWSER-SCRIPT`, the Playwright MCP tools are loaded, and the exact-string check printed `NO-LIST` in this run. It uses the same blanking (patterns and e-mail only, as there is no list), marking and scanning code as the script, generated by it:

1. Write `shot.py` into the run folder (command above). Any `python3` runs these two commands; they need no browser.
2. `python3 "$D/shot.py" mcp-code --run "$D" --selector '<css>' --num 1 --colour red --name <name> [--hide '<css>']` prints a function. It refuses with `ERROR` if the list has any entry.
3. `browser_navigate` to the page. If a `file://` address is refused, serve the folder with the dev server rule below, for example `python3 -m http.server <port> --bind 127.0.0.1 --directory <dir>`.
4. `browser_run_code` with that function, unchanged. It stops the page's own scripts first, as the script path does. It returns `SHOT <side>`, `NO-MATCH`, `ZERO-SIZE`, `UNREACHABLE <kinds>` or `ERROR ...`, and writes `evidence/<name>.raw.png`.
5. `python3 "$D/shot.py" mcp-save --run "$D" --name <name> --num 1 --colour red --side <side from step 4>` strips and resizes it and prints `SAVED <file>`.
6. Read the picture and write the Viewed line as above. On this path the side came back in a tool result, so the Viewed line is a self-report: write `Viewed (MCP path, self-report): ...` in the AI detail.
7. The after picture of a problem pictured this way is taken the same way (`retake` refuses it), and only when the list still prints `NO-LIST`. The MCP path takes the picture at 1x, so OCR reads it from a larger copy only.

### A project's own dev server

When the page needs the project's server (for example `npm run dev`), start it in the background and keep its PID in the run folder; stop it by that PID, never with `pkill -f`:

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; cd '<clone or scratch worktree>' && { nohup <start command> > "$D/server.log" 2>&1 & echo $! > "$D/server.pid"; echo SERVER-STARTED; }
```

```bash
D="$HOME/.superfix/runs/<run-key>"; if [ -f "$D/server.pid" ]; then kill "$(cat "$D/server.pid")" && rm -f "$D/server.pid" && echo SERVER-STOPPED; else echo NO-SERVER; fi
```

- Before approval, run it in the scratch worktree (diagnose.md), never in the repo. Stop it before the Stop gate and at the end of the run. `server.log` is a scratch file: never post it.
- A start command that forks (some `npm` scripts) can leave a child running after the kill: check the port is free (`lsof -i :<port>`) and kill that PID by number.

### The upload command (one per file)

One command per picture. It runs every check on that exact file and uploads only when they just printed `CLEAN` or `NO-LIST`, `OCR-CLEAN`, `VIEW-MATCH` and `PATTERN-CLEAN`. Write every value literally: `<run-key>`, `<name>` (no `.png`), `<owner>/<repo>`, `<python>` (any Python 3), and `A`:
- `upload`: an issue on a PRIVATE repo. When the secrets list has any entry it prints `HELD` and keeps the picture instead (top of this file).
- `approved`: only after the owner replied "post the pictures" in this run, AFTER those pictures were taken (never an older reply in the thread, never for pictures held by an earlier run). It uploads with every check, list or no list. The script cannot tell whether the owner really said it: this rule is kept by you, not by a check.
- `keep`: a public repo, or no issue. The picture goes to the journal pictures folder (below). Any other value also means `keep`.

The exact-string part is the redaction.md check and the pattern part is the redaction.md pattern check plus e-mail, both on the OCR text file.

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; N='<name>'; R='<owner>/<repo>'; A='<upload, approved or keep>'; PY='<python>'; F="$D/evidence/$N.png"; O="$D/evidence/ocr-$N"; if ! command -v tesseract >/dev/null; then echo NO-OCR; elif [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; else if [ "$A" = upload ] && { grep -q '[^[:space:]]' "$D/secrets" 2>/dev/null || grep -q '"held": true' "$D/evidence/$N.json" 2>/dev/null; }; then A=keep; echo "HELD $N: a credential is in play in this run (a secret on the list, or a saved login), so the picture stays on the Mac until the owner says post the pictures"; fi; case "$A" in upload|approved) U=yes;; *) U=no;; esac; if [ "$U" = yes ] && [ "$(gh repo view "$R" --json visibility -q .visibility)" != PRIVATE ]; then echo NOT-PRIVATE; elif ! grep -q '^Viewed: ' "$D/evidence/$N.viewed" 2>/dev/null; then echo NOT-VIEWED; elif [ "$("$PY" "$D/shot.py" ocr --run "$D" --name "$N")" != OCR-READY ]; then echo "ERROR: ocr"; else E="$(L="$D/secrets"; P="$(grep -v '^[[:space:]]*$' "$L" 2>/dev/null)"; if [ -z "$P" ]; then echo NO-LIST; else H="$(printf '%s\n' "$P" | grep -F -l -f - "$O.txt")"; rc=$?; if [ $rc -gt 1 ]; then echo "ERROR: a file could not be read"; elif [ -n "$H" ]; then echo "BLOCKED $H"; else echo CLEAN; fi; fi)"; V="$("$PY" "$D/shot.py" verify --run "$D" --name "$N" | tr '\n' ' ')"; P="$(H="$( { grep -H -n -E -i '(password|passwd|pwd|secret|token|api[_-]?key|auth|bearer|cookie|session)[[:space:]]*[:=][[:space:]]*[^[:space:]]+' "$O.txt" | grep -v 'Claude-Session: https://claude.ai/code/session_'; grep -H -n -E '(^|[^A-Za-z0-9])(sk-[A-Za-z0-9]|ghp_|gho_|github_pat_)|AKIA[0-9A-Z]{16}|eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.|-----BEGIN [A-Z ]*KEY-----|://[^/[:space:]:@]+:[^/[:space:]@]+@' "$O.txt"; perl -ne 'while (/(?<![A-Za-z0-9])([A-Za-z0-9]{32,})(?![A-Za-z0-9])/g) { my $s=$1; next unless $s=~/[A-Za-z]/ && $s=~/[0-9]/; next if $s=~/^[0-9a-f]{40}$/i; next if $s=~/^[0-9a-f]{64}$/i && /sha256/i; print "$ARGV:$.:\n" } close ARGV if eof' "$O.txt"; grep -H -n -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$O.txt"; } | cut -d: -f1,2 | sort -u )"; if [ -n "$H" ]; then echo "PATTERN-HITS (file:line, read each one, then decide):"; echo "$H"; else echo PATTERN-CLEAN; fi)"; echo "$E / $V/ $P"; case "$E" in CLEAN|NO-LIST) ;; *) E=BAD;; esac; if [ "$E" != BAD ] && [ "$V" = "OCR-CLEAN VIEW-MATCH " ] && [ "$P" = PATTERN-CLEAN ]; then if [ "$U" = yes ]; then gh release upload assets "$F" --repo "$R" && echo "UPLOADED $N"; else T="$HOME/.superfix/journal/${R%%/*}-${R#*/}/pictures/${D##*/}"; mkdir -p "$T" && cp "$F" "$T/" && echo "KEPT $N $T"; fi; else echo "NOT-UPLOADED $N"; fi; fi; fi
```

What each word means:
- `UPLOADED <name>` or `KEPT <name> <folder>`: done. Anything else: nothing left the run folder.
- `HELD <name>`: a credential is in play in this run: the secrets list has an entry, or the picture was taken with a saved login (`"held": true` in `evidence/<name>.json`, also for a side-by-side made from it). The picture is checked and kept (`KEPT`), never uploaded, until the owner replies "post the pictures"; then run the command again with `A='approved'`.
- `NO-OCR`: tesseract is not installed, so no picture can be checked for secrets: nothing is uploaded in 1.4.0 (Not tested line below).
- `NOT-PRIVATE`: the repo is not PRIVATE (or `gh` could not say): never upload. Run it again with `A='keep'`.
- `NOT-VIEWED`: you have not written the Viewed line: Read the picture first.
- `NOT-UPLOADED <name>` after the check line:
  - `BLOCKED` or `OCR-BLOCKED`: a session secret, or a 6-character piece of one, is in the picture's OCR text. Take it again with that area hidden (`--hide`), or no picture. A false `OCR-BLOCKED` (page text that happens to share 6 characters with a secret) is treated the same way.
  - `PATTERN-HITS`: a pattern hit in a picture blocks it. There is no "you decide" for pictures: take it again with that area hidden, or no picture.
  - `VIEW-MISMATCH` or `NOT-VIEWED`: Read the picture again and rewrite the Viewed line.
  - `NO-RUN-FOLDER` or `ERROR`: the check did not run. Fix it and run again. Silence is never a pass.
- A failed `gh release upload` (for example the name is already there) prints its own error and no `UPLOADED`: retake under the next `<i>`, never overwrite a posted picture.

### What each check does, and what it cannot do

- **Blanking** (in the page, before the picture) replaces each exact secret on the list, also written backwards and also when invisible characters (soft hyphen, zero-width and direction marks) sit inside it, and the token patterns and e-mail addresses, with `[redacted]`. It only knows the secrets on the list and the patterns. It cannot reach text drawn as pixels (canvas, images, video, CSS images), text inside a cross-origin frame or a closed shadow root, or CSS text from a stylesheet file, so those make the picture `UNREACHABLE`.
- **The page check** (after blanking, and again just before the picture) looks for each exact secret in the text as shown, across elements, in same-origin frames and in `::before`, `::after` and `::marker` content. A secret it cannot blank stops the picture.
- **Stopping the page's scripts** keeps a timer or a late network answer from writing text between the check and the picture.
- **OCR** reads the picture three ways and looks for each secret and its 6-character pieces. It can miss small, pale or unusual text, and a short secret with one misread character.
- **The owner's look** is the only check that counts when a credential is in play in this run: those pictures are held until the owner says "post the pictures".
- **Animations:** the page's CSS animations and transitions are frozen with its scripts, so the text checked is the text in the picture.
- **Viewed** is a speed bump against posting a picture nobody opened, not proof (above).

### The `assets` release (once per repo)

Pictures are release assets of one standing release named `assets`, as in any private repo you own. Creating that release adds a tag named `assets` to the repo, which can start workflows that run on new tags or releases, and notifies people who watch the repo's releases. Webhooks, GitHub Apps and repository rules cannot be checked from here and may also react to a new tag. So it is never created blind. Before the first upload, one command:

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; R='<owner>/<repo>'; ME="$(gh api user -q .login)"; if [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; elif [ -z "$ME" ] || [ "${R%%/*}" != "$ME" ]; then echo "ASK-FIRST $R"; elif gh release view assets --repo "$R" >/dev/null 2>&1; then echo ASSETS-EXISTS; elif gh api "repos/$R/git/ref/tags/assets" >/dev/null 2>&1; then echo "ASK-FIRST-TAG $R"; else L="$(gh api "repos/$R/git/trees/HEAD?recursive=1" -q 'if .truncated then "TRUNCATED" else (.tree[] | select(.type == "blob") | .path) end' 2>&1)"; rc=$?; if [ $rc -ne 0 ] && ! printf '%s\n' "$L" | grep -q 'HTTP 409'; then echo "ERROR: could not list the repo files"; else : > "$D/workflow-flags"; if [ $rc -eq 0 ]; then printf '%s\n' "$L" | grep -qx TRUNCATED && echo "UNREAD the file list is too long to read in full" >> "$D/workflow-flags"; printf '%s\n' "$L" | grep -i '^\.github/workflows/' | while IFS= read -r p; do T="$(gh api "repos/$R/contents/$p" -q .content 2>/dev/null | base64 -d 2>/dev/null)"; if [ -z "$T" ]; then echo "UNREAD $p" >> "$D/workflow-flags"; elif printf '%s\n' "$T" | grep -qiE 'push|release|create|tags|workflow_run|workflow_call|repository_dispatch|(^|[[:space:]])"?on"?:[[:space:]]*[[{]'; then echo "FLAG $p" >> "$D/workflow-flags"; fi; done; fi; if [ -s "$D/workflow-flags" ]; then echo "ASK-FIRST-WORKFLOWS $R"; cat "$D/workflow-flags"; else gh release create assets --repo "$R" --title "Asset host" --notes "Hosts images referenced from issues" --latest=false && echo ASSETS-CREATED; fi; fi; fi
```

- `ASSETS-EXISTS` or `ASSETS-CREATED`: go on to the upload commands.
- `ASK-FIRST`: the signed-in user does not own the repo (whether or not the release exists). `ASK-FIRST-TAG`: a tag named `assets` exists but no release. `ASK-FIRST-WORKFLOWS`: some file under `.github/workflows/` (any depth, any case) contains one of the words `push`, `release`, `create`, `tags`, `workflow_run`, `workflow_call` or `repository_dispatch`, or writes `on:` in flow syntax (`on: [...]` or `on: {...}`), or could not be read (`FLAG` and `UNREAD` lines name the files). False alarms are fine: the check is a text search, on purpose. No workflow files at all (or an empty repo) means none. In every ASK case upload nothing yet. The decision message carries this numbered question, just before the create-issue question, which stays last: "May I create a release named assets in <owner>/<repo> to hold the pictures? It adds a tag named assets, which can start workflows that run on new tags or releases and notifies people who watch the repo's releases; webhooks, GitHub Apps and repository rules cannot be checked from here and may also react. (yes / no)". It has NO recommended answer, like the create-issue question: "keep executing" does not cover it, and anything but an explicit yes to it is no. On a yes, run `gh release create assets --repo <owner>/<repo> --title "Asset host" --notes "Hosts images referenced from issues" --latest=false && echo ASSETS-CREATED`, then the upload commands, then add the pictures to the body. Without a yes, use `A='keep'`, and the `Pictures:` line says `NOT-POSTED (the assets release needs your yes)`.
- Pre-approval writes: SKILL.md Phase 1 lists every allowed one. The `assets` release, its tag (only after these ownership and workflow checks) and the uploads to it are the only ones that leave the machine, and only for a PRIVATE repo you own.
- 1.4.1, one deliberate exception to the rule above that creating the release needs an explicit yes with no recommended answer: a yes to the diagram question (references/diagrams.md), which carries a recommended yes, also allows creating it, but only when the dry check there prints `ASSETS-WOULD-CREATE`, meaning the repo is PRIVATE and yours, with no `assets` release or tag, no webhook and no flagged workflow. Every other case keeps the rule above. Why: the owner chose a recommended yes for diagrams, and in that one case every mechanical check has passed.

### Markdown forms

- Picture line, then the caption as plain text on the next line:
  `![P1 before: the Subscribe button (red box 1) is cut in half by the bottom edge of the price card](https://github.com/<owner>/<repo>/releases/download/assets/sf-<N>-p1-before-1.png)`
  `P1 before: the Subscribe button (red box 1) is cut in half by the bottom edge of the price card.`
- Every comment with a picture carries this line once, after the pictures: `Pictures show on the website, not in the GitHub app: https://github.com/<owner>/<repo>/issues/<N>`
- A credential in play in this run (any `HELD`): in place of the pictures, the decision comment and the final comment say `Pictures are not posted because you gave me a password or token in this run, or I used a saved login. They are on your Mac at ~/.superfix/journal/<owner>-<repo>/pictures/<run-key>/. Look at them, then reply "post the pictures" if you want them on the issue.` That reply is not a numbered question and "keep executing" does not say it.
- Where they go:
  - Issue body: every picture, under its problem (`- Picture:` in the journal.md template).
  - Decision comment: the first picture of each problem, below the numbered questions, with its caption and the website line. The two-line callout and the questions never depend on a picture.
  - Final comment: one side-by-side picture per problem that had pictures, its caption, the website line. A problem with no screen gets one line: "P<k> has no screen; its proof is the check output below."
- Side by side, after the after picture passed the upload command: `"<python>" "$D/shot.py" pair --run "$D" --before sf-<N>-p<k>-before-1 --after sf-<N>-p<k>-after-1 --name sf-<N>-p<k>-before-after`. It runs this command (labels Before and After inside the image):
  `magick \( <before> -background white -gravity North -splice 0x44 -pointsize 28 -annotate +0+8 Before \) \( <after> -background white -gravity North -splice 0x44 -pointsize 28 -annotate +0+8 After \) +append -strip -resize '1600x>' <pair>`
  It is a new image: Read it, write its Viewed line (the left mark), and send it through the upload command like any other.

### Public repo, or no issue

- In 1.4.0 nothing is uploaded to a public repo, ever. Pictures are still taken and checked, with `A='keep'`, which copies each clean picture to `~/.superfix/journal/<owner>-<repo>/pictures/<run-key>/`, outside the run folder, so it survives the end-of-run delete. A picture that failed a check is not kept; it is deleted with the run folder.
- The decision comment says, in place of the picture: `Pictures are on the owner's Mac, not posted because this repo is public: ~/.superfix/journal/<owner>-<repo>/pictures/<run-key>/`
- No issue (file-mode journal): the same `A='keep'`; the journal names the local files. If the owner says yes to creating the issue and the repo is PRIVATE, run the upload command for each picture after `gh issue create` (`A='upload'`, so a credential in the list still holds them), then add them to the new issue's body.
- Held pictures at the end of the run: when pictures are still held at the final comment, the end-of-run delete waits for the owner's answer ("post the pictures", or no), because the upload command needs the run folder and its list. Status: "Waiting for you: post the pictures?". Any other reply, or a restart that finds no answer, asks once more and then deletes the run folder as usual; the kept copies stay in the journal pictures folder.
- Pictures held by an earlier run are never uploaded by a later run. If a run folder is reused (for example a reopened issue) and its `evidence/` holds pictures from before, delete them before the first new picture, or ask the owner.

### Qik draft pages (saved login, untested in 1.4.0)

- Qik draft sites are behind a login. The script path can use a saved login: `--storage ~/.superfix/auth/<host>.json`, made once by the owner with `playwright codegen --save-storage=~/.superfix/auth/<host>.json <draft url>` (README).
- That file holds session cookies, a credential: mode 600, never in a repo, never printed, read or posted. The owner's passwords stay in 1Password, never typed into chat.
- Without that file: no Qik picture, and the Not tested line below. Never use the MCP path or Claude in Chrome to picture a logged-in page.

### Leaked picture

If a picture with a secret was posted (redaction.md, Leak handling):
1. Delete the comment that shows it (`gh api -X DELETE repos/<o>/<r>/issues/comments/<id>`); never edit a comment, GitHub keeps edit history.
2. Edit the issue BODY only to remove the picture's link, and tell the owner the old body stays in the edit history until they delete that revision on the GitHub page.
3. Delete the file: `gh release delete-asset assets <file> --repo <o>/<r> --yes`. Check the body and every comment again for the link.
4. Tell the owner to rotate the credential, and say what leaked where.

### Not tested lines (exact)

Name the kind in plain words: canvas is "a drawing area", img "an image", video "a video", svg-image "a drawn image", embed "an embedded object", cross-origin-iframe "a page inside another page", closed-shadow-root "a hidden part of the page", split-text "text split across parts of the page", frame-text "text in a page inside another page", css-content "text added by the page's style sheet", text "text that could not be cleaned".

- `Pictures: not taken, because no browser was available in this run (checked: Playwright MCP, Python playwright with a browser). Run again where Playwright works to get them.`
- `Pictures: taken but not posted, because this repo is public. They are on the owner's Mac at <path>.`
- `Picture of P<k> not taken: the page area holds <kind in plain words> that cannot be checked for secrets.`
- `Pictures: not posted, because OCR (tesseract) is not installed, so they could not be checked for secrets.`
- `Qik draft picture not taken: the draft site needs a one-time saved login (README).`
- `Pictures: not taken, because ImageMagick (magick) is not installed.`
- `Pictures: not posted, because the assets release needs your yes in <owner>/<repo>. They are on the owner's Mac at <path>.`
- `Pictures: not posted, because you gave me a password or token in this run. They are on the owner's Mac at <path>.`
