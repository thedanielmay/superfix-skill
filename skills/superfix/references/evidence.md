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

`shot.py` is written into the run folder from this file, by a command, never typed out by hand. `<skill dir>` is this skill's base directory, written out in full (the folder that holds `SKILL.md` and `references/`):

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; if [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; else mkdir -p "$D/evidence" && awk '/^# --- shot.py start ---$/{f=1} f{print} /^# --- shot.py end ---$/{f=0}' '<skill dir>/references/evidence.md' > "$D/shot.py" && grep -q '^# --- shot.py end ---$' "$D/shot.py" && echo "SHOT-READY $D/shot.py"; fi
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

The script, exactly as the command above writes it:

```python
# --- shot.py start ---
# superfix 1.4.0 evidence pictures. Written into the run folder from
# references/evidence.md. Each command prints one word line. It never prints
# a secret, a matched line or the label side.
import argparse, functools, http.server, json, os, re, shutil, subprocess, sys, threading

COLOURS = {"red": "#e00", "green": "#080"}
PATS = [
    [r"(password|passwd|pwd|secret|token|api[_-]?key|auth|bearer|cookie|session)\s*[:=]\s*\S+", "gi"],
    [r"(sk-[A-Za-z0-9]|ghp_|gho_|github_pat_)\S*", "g"],
    [r"AKIA[0-9A-Z]{16}", "g"],
    [r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*", "g"],
    [r"-----BEGIN [A-Z ]*KEY-----", "g"],
    [r"://[^/\s:@]+:[^/\s@]+@", "g"],
    [r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}", "g"],
]

BLANK_JS = r"""({secrets, pats}) => {
  const res = pats.map(p => new RegExp(p[0], p[1]));
  const run = /(?<![A-Za-z0-9])[A-Za-z0-9]{32,}(?![A-Za-z0-9])/g;
  const ZW = /[\u00AD\u200B-\u200F\u2060\uFEFF\u202A-\u202E]/g;
  const clean = s => {
    if (!s) return s;
    let t = s;
    const z = t.replace(ZW, '');
    if (secrets.some(x => z.includes(x))) t = z;
    for (const x of secrets) t = t.split(x).join('[redacted]');
    for (const r of res) t = t.replace(r, '[redacted]');
    return t.replace(run, m => (/[A-Za-z]/.test(m) && /[0-9]/.test(m) && !/^[0-9a-f]{40}$/i.test(m)) ? '[redacted]' : m);
  };
  const ATTRS = ['placeholder', 'title', 'alt', 'aria-label', 'value'];
  const texts = [];
  const walk = root => {
    const doc = root.ownerDocument || root;
    const tw = doc.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    for (let n = tw.nextNode(); n; n = tw.nextNode()) { n.nodeValue = clean(n.nodeValue); texts.push(n.nodeValue); }
    for (const el of root.querySelectorAll('*')) {
      for (const at of [...el.attributes]) {
        const v = at.value;
        const c = ATTRS.includes(at.name) ? clean(v) : secrets.reduce((t, x) => t.split(x).join('[redacted]'), v);
        if (c !== v) el.setAttribute(at.name, c);
        texts.push(c);
      }
      if ('value' in el && typeof el.value === 'string' && /^(INPUT|TEXTAREA|SELECT)$/.test(el.tagName)) {
        if (el.tagName !== 'SELECT') el.value = clean(el.value);
        texts.push(el.value);
      }
      if (el.shadowRoot) walk(el.shadowRoot);
      if (/^(IFRAME|FRAME)$/.test(el.tagName)) { try { if (el.contentDocument) walk(el.contentDocument); } catch (e) {} }
    }
  };
  walk(document);
  const all = texts.join('\n');
  return secrets.some(x => all.includes(x));
}"""

CHECK_JS = r"""(secrets) => {
  const flat = s => (s || '').replace(/[\s\u00AD\u200B-\u200F\u2060\uFEFF\u202A-\u202E]+/g, '');
  const ss = secrets.map(flat).filter(x => x);
  const has = s => { const f = flat(s); return ss.some(x => f.includes(x)); };
  const kinds = new Set();
  const doc = (d, top) => {
    if (d.body && has(d.body.innerText)) kinds.add(top ? 'split-text' : 'frame-text');
    for (const el of d.querySelectorAll('*')) {
      for (const ps of ['::before', '::after', '::marker']) {
        const c = d.defaultView.getComputedStyle(el, ps).content;
        if (c && c !== 'none' && c !== 'normal' && has(c)) kinds.add('css-content');
      }
      if (el.shadowRoot && has(el.shadowRoot.textContent)) kinds.add('split-text');
      if (/^(IFRAME|FRAME)$/.test(el.tagName)) { try { if (el.contentDocument) doc(el.contentDocument, false); } catch (e) {} }
    }
  };
  doc(document, true);
  return [...kinds].sort();
}"""

MARK_JS = r"""({sel, colour, num}) => {
  const el = document.querySelector(sel);
  const r = el.getBoundingClientRect();
  const vw = innerWidth, vh = innerHeight, pad = 4, gap = 6;
  const box = document.createElement('div');
  box.setAttribute('data-sf-mark', '1');
  Object.assign(box.style, {position: 'fixed', left: (r.left - pad) + 'px', top: (r.top - pad) + 'px',
    width: (r.width + 2 * pad) + 'px', height: (r.height + 2 * pad) + 'px', border: '3px solid ' + colour,
    boxShadow: '0 0 0 2px #fff', boxSizing: 'border-box', pointerEvents: 'none', zIndex: '2147483647',
    margin: '0', padding: '0', background: 'transparent'});
  document.documentElement.appendChild(box);
  const lab = document.createElement('div');
  lab.setAttribute('data-sf-mark', '1');
  lab.textContent = num;
  Object.assign(lab.style, {position: 'fixed', left: '0px', top: '0px', font: 'bold 16px Helvetica, Arial, sans-serif',
    lineHeight: '20px', color: '#fff', background: colour, padding: '1px 7px', borderRadius: '3px',
    boxShadow: '0 0 0 2px #fff', pointerEvents: 'none', zIndex: '2147483647', margin: '0', visibility: 'hidden'});
  document.documentElement.appendChild(lab);
  const lw = lab.offsetWidth, lh = lab.offsetHeight;
  const cands = [
    ['right', r.right + pad + gap, r.top + r.height / 2 - lh / 2],
    ['left', r.left - pad - gap - lw, r.top + r.height / 2 - lh / 2],
    ['below', r.left, r.bottom + pad + gap],
  ].map(([s, x, y]) => [s, x, Math.max(2, Math.min(y, vh - lh - 2))]);
  const hit = (a, b) => a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top;
  const busy = q => {
    const tw = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    for (let n = tw.nextNode(); n; n = tw.nextNode()) {
      if (!n.nodeValue.trim()) continue;
      const rg = document.createRange(); rg.selectNodeContents(n);
      for (const b of rg.getClientRects()) if (hit(q, b)) return true;
    }
    for (const e of document.querySelectorAll('input,textarea,select,button,img,canvas,video,svg,iframe')) {
      if (e === el) continue;
      if (hit(q, e.getBoundingClientRect())) return true;
    }
    return hit(q, r);
  };
  const room = c => c[1] >= 2 && c[1] + lw <= vw - 2 && c[2] >= 2 && c[2] + lh <= vh - 2;
  const q = c => ({left: c[1] - 2, top: c[2] - 2, right: c[1] + lw + 2, bottom: c[2] + lh + 2});
  let pick = cands.find(c => room(c) && !busy(q(c))) || cands.find(room) || cands[0];
  lab.style.left = pick[1] + 'px'; lab.style.top = pick[2] + 'px'; lab.style.visibility = 'visible';
  const L = lab.getBoundingClientRect();
  const mx = 320, my = 200;
  const x0 = Math.max(0, Math.min(r.left - mx, L.left - 8)), y0 = Math.max(0, Math.min(r.top - my, L.top - 8));
  const x1 = Math.min(vw, Math.max(r.right + mx, L.right + 8)), y1 = Math.min(vh, Math.max(r.bottom + my, L.bottom + 8));
  return {side: pick[0], clip: {x: Math.floor(x0), y: Math.floor(y0), width: Math.ceil(x1 - x0), height: Math.ceil(y1 - y0)}};
}"""

SCAN_JS = r"""(clip) => {
  const kinds = new Set();
  const inClip = (r, ox, oy) => r.width > 0 && r.height > 0 && r.right + ox > clip.x && r.left + ox < clip.x + clip.width
    && r.bottom + oy > clip.y && r.top + oy < clip.y + clip.height;
  const shown = (el, win) => { const cs = win.getComputedStyle(el); return cs.visibility !== 'hidden' && cs.display !== 'none' && parseFloat(cs.opacity) !== 0; };
  const scan = (root, win, ox, oy) => {
    for (const el of root.querySelectorAll('*')) {
      if (el.hasAttribute('data-sf-mark')) continue;
      const t = el.tagName.toLowerCase();
      let k = null;
      if (t === 'canvas') k = 'canvas';
      else if (t === 'img' || (t === 'input' && (el.type || '').toLowerCase() === 'image')) k = 'img';
      else if (t === 'video') k = 'video';
      else if (t === 'image' && el.namespaceURI === 'http://www.w3.org/2000/svg') k = 'svg-image';
      else if (t === 'object' || t === 'embed') k = 'embed';
      else if (el.hasAttribute('data-sf-closed')) k = 'closed-shadow-root';
      const r = el.getBoundingClientRect();
      if (t === 'iframe' || t === 'frame') {
        let d = null; try { d = el.contentDocument; } catch (e) {}
        if (!d) k = 'cross-origin-iframe';
        else if (inClip(r, ox, oy) && shown(el, win)) scan(d, el.contentWindow, ox + r.left, oy + r.top);
      }
      if (!k) {
        const IMG = /url\(|image-set\(/i;
        for (const ps of [null, '::before', '::after', '::marker']) {
          const cs = win.getComputedStyle(el, ps);
          for (const p of ['background-image', 'content', 'mask-image', '-webkit-mask-image', 'border-image-source', 'list-style-image', 'cursor'])
            if (IMG.test(cs.getPropertyValue(p) || '')) k = 'css-image';
        }
      }
      if (k && inClip(r, ox, oy) && shown(el, win)) kinds.add(k);
      if (el.shadowRoot) scan(el.shadowRoot, win, ox, oy);
    }
  };
  scan(document, window, 0, 0);
  return [...kinds].sort();
}"""



MCP_JS = """async (page) => {
  await page.setViewportSize({width: 1280, height: 800});
  const sel = %(sel)s, hide = %(hide)s, out = %(out)s;
  const cdp = await page.context().newCDPSession(page);
  await cdp.send('Emulation.setScriptExecutionDisabled', {value: true});
  for (const h of hide) if (await page.evaluate(s => { const l = document.querySelectorAll(s); l.forEach(e => e.style.setProperty('visibility', 'hidden', 'important')); return l.length; }, h) === 0) return 'ERROR hide selector matched nothing';
  if (!(await page.evaluate(s => !!document.querySelector(s), sel))) return 'NO-MATCH';
  await page.evaluate(s => { const r = document.querySelector(s).getBoundingClientRect(); window.scrollBy(r.left + r.width / 2 - innerWidth / 2, r.top + r.height / 2 - innerHeight / 2); }, sel);
  await page.waitForTimeout(200);
  const [w, h] = await page.evaluate(s => { const r = document.querySelector(s).getBoundingClientRect(); return [r.width, r.height]; }, sel);
  if (w === 0 || h === 0) return 'ZERO-SIZE';
  await page.evaluate(%(blank)s, {secrets: [], pats: %(pats)s});
  const stack = [(await cdp.send('DOM.getDocument', {depth: -1, pierce: true})).root];
  while (stack.length) { const n = stack.pop();
    for (const r of n.shadowRoots || []) if (r.shadowRootType === 'closed') await cdp.send('DOM.setAttributeValue', {nodeId: n.nodeId, name: 'data-sf-closed', value: '1'});
    stack.push(...(n.children || []), ...(n.shadowRoots || []), ...(n.contentDocument ? [n.contentDocument] : [])); }
  const m = await page.evaluate(%(mark)s, {sel, colour: %(colour)s, num: %(num)s});
  const kinds = await page.evaluate(%(scan)s, m.clip);
  if (kinds.length) return 'UNREACHABLE ' + kinds.join(' ');
  await page.screenshot({path: out, clip: m.clip});
  return 'SHOT ' + m.side;
}"""

# 1.4.1 aligned crops: the same window-only centring as in shoot, used again when a retake cannot reach the stored scroll.
CENTRE_JS = "s => { const r = document.querySelector(s).getBoundingClientRect(); window.scrollBy(r.left + r.width / 2 - innerWidth / 2, r.top + r.height / 2 - innerHeight / 2); }"
# 1.4.1: the box round all the marks (the drawn box and its number), and the window size.
MARKS_JS = "() => { const rs = [...document.querySelectorAll('[data-sf-mark]')].map(e => e.getBoundingClientRect()); return [Math.min(...rs.map(r => r.left)), Math.min(...rs.map(r => r.top)), Math.max(...rs.map(r => r.right)), Math.max(...rs.map(r => r.bottom)), innerWidth, innerHeight]; }"

LIMIT = 30  # seconds for each page step; past it the script prints ERROR timeout and stops
NAME = re.compile(r"^[A-Za-z0-9._+-]+$")


def read_secrets(run):
    try:
        with open(os.path.join(run, "secrets"), encoding="utf-8") as f:
            raw = [ZW.sub("", l.rstrip("\r\n")) for l in f if l.strip()]
    except FileNotFoundError:
        return []
    return [x for x in raw if x]


def page_secrets(secrets):
    """The secrets as the page check uses them: also reversed, for text drawn right to left."""
    return secrets + [x[::-1] for x in secrets if x[::-1] != x]


ZW = re.compile("[\u00ad\u200b-\u200f\u2060\ufeff\u202a-\u202e]")


def tidy(msg, secrets=()):
    """At most 60 characters: URLs cut to scheme and host, long letter or digit runs and secrets hidden."""
    m = (msg.strip().splitlines() or ["no detail"])[0]
    for s in secrets:
        m = m.replace(s, "...")
    m = re.sub(r"([A-Za-z][A-Za-z0-9+.-]*://)([^/\s'\"?#]*)[^\s'\"]*", lambda x: x.group(1) + re.sub(r"^[^@]*@", "", x.group(2)), m)
    m = re.sub(r"[A-Za-z0-9]{12,}", "...", m)
    return m[:60]


def say(word, secrets=()):
    for s in secrets:
        word = word.replace(s, "[redacted]")
    print(word.splitlines()[0] if word else "ERROR")
    sys.stdout.flush()


def timed(fn, *args):
    """Run one page step; if it takes longer than LIMIT, print ERROR timeout and stop the process."""
    t = threading.Timer(LIMIT, lambda: (say("ERROR timeout"), os._exit(3)))
    t.start()
    try:
        return fn(*args)
    finally:
        t.cancel()


def magick(*args):
    exe = shutil.which("magick")
    if not exe:
        raise RuntimeError("magick not installed")
    subprocess.run([exe] + list(args), check=True, capture_output=True)


def small_enough(out):
    """At most 1 MB, else one smaller try, else the picture is removed."""
    if os.path.getsize(out) > 1000000:
        magick(out, "-strip", "-resize", "1280x>", "-colors", "256", out)
    if os.path.getsize(out) > 1000000:
        os.remove(out)
        return False
    return True


def clear(ev, name):
    for old in (name + ".png", name + ".ocr.png", name + ".viewed", name + ".json", "mark-%s.side" % name, "ocr-%s.txt" % name):
        if os.path.exists(os.path.join(ev, old)):
            os.remove(os.path.join(ev, old))


def mark_closed_shadow_roots(cdp):
    root = cdp.send("DOM.getDocument", {"depth": -1, "pierce": True})["root"]
    hosts, stack = [], [root]
    while stack:
        n = stack.pop()
        for sr in n.get("shadowRoots", []):
            if sr.get("shadowRootType") == "closed":
                hosts.append(n["nodeId"])
        stack.extend(n.get("children", []) + n.get("shadowRoots", []))
        if "contentDocument" in n:
            stack.append(n["contentDocument"])
    for h in hosts:
        cdp.send("DOM.setAttributeValue", {"nodeId": h, "name": "data-sf-closed", "value": "1"})


def shoot(a, secrets):
    ev = os.path.join(a.run, "evidence")
    os.makedirs(ev, mode=0o700, exist_ok=True)
    clear(ev, a.name)
    if not shutil.which("magick"):
        return say("ERROR magick not installed")
    a.serve = os.path.abspath(a.serve) if a.serve else None
    a.storage = os.path.abspath(os.path.expanduser(a.storage)) if a.storage else None
    url, server = a.url, None
    if a.serve:
        class Quiet(http.server.SimpleHTTPRequestHandler):
            def log_message(self, *x):
                pass
        server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Quiet, directory=a.serve))
        threading.Thread(target=server.serve_forever, daemon=True).start()
        url = "http://127.0.0.1:%d/%s" % (server.server_address[1], a.url.lstrip("/"))
    from playwright.sync_api import sync_playwright
    raw = os.path.join(ev, a.name + ".raw.png")
    out, ocr = os.path.join(ev, a.name + ".png"), os.path.join(ev, a.name + ".ocr.png")
    try:
        with sync_playwright() as p:
            b = p.chromium.launch()
            # 2x pixels: the OCR copy keeps them; the posted picture is scaled back to 1x.
            kw = {"viewport": {"width": 1280, "height": 800}, "device_scale_factor": 2}
            if a.storage:
                if not os.path.isfile(a.storage):
                    return say("ERROR no saved login file")
                kw["storage_state"] = a.storage
            page = b.new_context(**kw).new_page()
            page.set_default_timeout(LIMIT * 1000)
            page.set_default_navigation_timeout(LIMIT * 1000)
            timed(page.goto, url)
            try:
                page.wait_for_load_state("networkidle", timeout=5000)
            except Exception:
                pass
            timed(page.wait_for_timeout, 300)
            cdp = timed(page.context.new_cdp_session, page)
            # From here the page's own scripts cannot run, so nothing can write text after the checks.
            timed(cdp.send, "Emulation.setScriptExecutionDisabled", {"value": True})
            # CSS animations and transitions keep running without scripts: freeze them, so what is checked is what is shot.
            timed(cdp.send, "Animation.enable")
            timed(cdp.send, "Animation.setPlaybackRate", {"playbackRate": 0})
            ps = page_secrets(secrets)
            ev_ = lambda js, arg=None: timed(page.evaluate, js, arg)
            for h in a.hide or []:
                if ev_("s => { const l = document.querySelectorAll(s); l.forEach(e => e.style.setProperty('visibility', 'hidden', 'important')); return l.length; }", h) == 0:
                    return say("ERROR hide selector matched nothing")
            if ev_("s => !!document.querySelector(s)", a.selector) is False:
                return say("NO-MATCH")
            # Scroll the window only. scrollIntoView would also scroll an overflow:hidden box and hide the bug.
            ev_("s => { const r = document.querySelector(s).getBoundingClientRect(); window.scrollBy(r.left + r.width / 2 - innerWidth / 2, r.top + r.height / 2 - innerHeight / 2); }", a.selector)
            page.wait_for_timeout(200)
            # 1.4.1 aligned crops: a retake scrolls to where the before picture was taken, so both show the same page area.
            al, crop, off = getattr(a, "align", None), None, None
            if al:
                got = ev_("p => { window.scrollTo(p[0], p[1]); return [scrollX, scrollY]; }", al["scroll"])
                page.wait_for_timeout(200)
                if [round(v) for v in got] != [round(v) for v in al["scroll"]]:
                    # The page cannot scroll there now (for example it got shorter): centre the target again, as in 1.4.0.
                    ev_(CENTRE_JS, a.selector)
                    page.wait_for_timeout(200)
                    al = dict(al, reach=False)
            w, h = ev_("s => { const r = document.querySelector(s).getBoundingClientRect(); return [r.width, r.height]; }", a.selector)
            if w == 0 or h == 0:
                return say("ZERO-SIZE")
            arg = {"secrets": ps, "pats": PATS}
            if ev_(BLANK_JS, arg):
                return say("UNREACHABLE text")
            left = ev_(CHECK_JS, ps)
            if left:
                return say("UNREACHABLE " + " ".join(left))
            timed(mark_closed_shadow_roots, cdp)
            m = ev_(MARK_JS, {"sel": a.selector, "colour": COLOURS[a.colour], "num": a.num})
            if al:
                # Inside the before area: the same area. Inside the window: the union of both areas. Else: 1.4.0 behaviour.
                mk, c = ev_(MARKS_JS), al["clip"]
                if al.get("reach") is False or mk[0] < 0 or mk[1] < 0 or mk[2] > mk[4] or mk[3] > mk[5]:
                    crop = "CROP-DIFFERENT"
                    if al.get("reach") is not False:
                        ev_("() => document.querySelectorAll('[data-sf-mark]').forEach(e => e.remove())")
                        ev_(CENTRE_JS, a.selector)
                        page.wait_for_timeout(200)
                        m = ev_(MARK_JS, {"sel": a.selector, "colour": COLOURS[a.colour], "num": a.num})
                elif mk[0] >= c["x"] and mk[1] >= c["y"] and mk[2] <= c["x"] + c["width"] and mk[3] <= c["y"] + c["height"]:
                    crop, off, m["clip"] = "CROP-ALIGNED", [0, 0], dict(c)
                else:
                    u = m["clip"]
                    x0, y0 = min(c["x"], u["x"]), min(c["y"], u["y"])
                    x1, y1 = max(c["x"] + c["width"], u["x"] + u["width"]), max(c["y"] + c["height"], u["y"] + u["height"])
                    crop, off = "CROP-WIDENED", [c["x"] - x0, c["y"] - y0]
                    m["clip"] = {"x": x0, "y": y0, "width": x1 - x0, "height": y1 - y0}
            sc = ev_("() => [scrollX, scrollY]")
            kinds = ev_(SCAN_JS, m["clip"])
            if kinds:
                return say("UNREACHABLE " + " ".join(kinds))
            # Blank and check once more, right before the screenshot.
            if ev_(BLANK_JS, arg) or ev_(CHECK_JS, ps):
                return say("UNREACHABLE text")
            timed(lambda: page.screenshot(path=raw, clip=m["clip"]))
            b.close()
        magick(raw, "-strip", ocr)
        magick(raw, "-resize", "50%", "-strip", "-resize", "1600x>", out)
        os.remove(raw)
        if not small_enough(out):
            return say("ERROR picture over 1 MB")
        with open(os.path.join(ev, "mark-%s.side" % a.name), "w") as f:
            f.write("%s %s %s\n" % (m["side"], a.colour, a.num))
        with open(os.path.join(ev, a.name + ".json"), "w") as f:
            rec = {"path": "script", "python": sys.executable, "url": a.url, "serve": a.serve, "selector": a.selector,
                   "hide": a.hide or [], "storage": a.storage, "colour": a.colour, "num": a.num, "held": False}
            cl = m["clip"]
            rec["page_clip"] = {"x": cl["x"] + sc[0], "y": cl["y"] + sc[1], "width": cl["width"], "height": cl["height"]}
            rec["scroll"], rec["crop"], rec["offset"] = sc, crop or "", off
            if a.storage:
                rec.update(held=True, reason="taken with a saved login")
            json.dump(rec, f)
        if crop:
            say(crop)
        say("SAVED " + out)
    finally:
        if os.path.exists(raw):
            os.remove(raw)
        if server:
            server.shutdown()


def retake(a, secrets):
    ev = os.path.join(a.run, "evidence")
    try:
        with open(os.path.join(ev, a.source + ".json")) as f:
            j = json.load(f)
    except (FileNotFoundError, ValueError):
        return say("ERROR no record of " + a.source)
    if j.get("path") == "mcp":
        return say("ERROR the before picture was taken on the MCP path: take this one with mcp-code too (only after NO-LIST)")
    for k in ("url", "serve"):
        if getattr(a, k):
            j[k] = getattr(a, k)
    a.url, a.serve, a.selector, a.hide, a.storage = j["url"], j["serve"], j["selector"], j["hide"], j["storage"]
    a.colour, a.num = a.colour or "green", j["num"]
    a.align = {"clip": {"x": j["page_clip"]["x"] - j["scroll"][0], "y": j["page_clip"]["y"] - j["scroll"][1], "width": j["page_clip"]["width"], "height": j["page_clip"]["height"]}, "scroll": j["scroll"]} if j.get("page_clip") and j.get("scroll") is not None else None
    shoot(a, secrets)


# OCR folding: letters OCR confuses become one character, on both sides.
FOLD = [("rn", "m"), ("vv", "w")]
TABLE = str.maketrans("oil|gbzs", "01119825")


def norm(s):
    s = ZW.sub("", s).lower()
    for x, y in FOLD:
        s = s.replace(x, y)
    return re.sub(r"[^a-z0-9]", "", s.translate(TABLE))


def ocr_hit(text, secrets):
    flat, nt = re.sub(r"\s", "", text), norm(text)
    for s in secrets:
        if re.sub(r"\s", "", s) in flat:
            return True
        ns = norm(s)
        pieces = [ns[i:i + 6] for i in range(len(ns) - 5)] if len(ns) >= 6 else ([ns] if len(ns) >= 4 else [])
        if any(p in nt for p in pieces):
            return True
    return False


def ocr(a):
    ev = os.path.join(a.run, "evidence")
    png, big = os.path.join(ev, a.name + ".png"), os.path.join(ev, a.name + ".ocr.png")
    up = os.path.join(ev, a.name + ".up.png")
    if not os.path.isfile(png):
        return say("ERROR no picture")
    tess = shutil.which("tesseract")
    if not tess:
        return say("NO-OCR")
    try:
        # The posted picture, the 2x copy, and a larger grey copy: small or pale text is read best in one of them.
        magick(big if os.path.isfile(big) else png, "-resize", "200%", "-colorspace", "Gray", "-normalize", up)
        parts = []
        for img in (png, big, up):
            if os.path.isfile(img):
                r = subprocess.run([tess, img, "-"], capture_output=True, text=True)
                if r.returncode:
                    return say("ERROR ocr")
                parts.append(r.stdout)
        with open(os.path.join(ev, "ocr-%s.txt" % a.name), "w", encoding="utf-8") as f:
            f.write("\n".join(parts))
        say("OCR-READY")
    finally:
        if os.path.exists(up):
            os.remove(up)


def verify(a, secrets):
    ev = os.path.join(a.run, "evidence")
    png, txt = os.path.join(ev, a.name + ".png"), os.path.join(ev, "ocr-%s.txt" % a.name)
    if not os.path.isfile(txt):
        say("ERROR no OCR file")
    else:
        with open(txt, encoding="utf-8", errors="replace") as f:
            say("OCR-BLOCKED" if ocr_hit(f.read(), secrets) else "OCR-CLEAN")
    viewed, side = os.path.join(ev, a.name + ".viewed"), os.path.join(ev, "mark-%s.side" % a.name)
    if not os.path.isfile(viewed):
        return say("NOT-VIEWED")
    if not os.path.isfile(side) or not os.path.isfile(png) or os.path.getmtime(viewed) < os.path.getmtime(png):
        return say("VIEW-MISMATCH")
    with open(side) as f:
        want = f.read().split()
    with open(viewed, encoding="utf-8") as f:
        got = re.match(r"Viewed: label (\S+) (red|green), (right of|left of|below) \S", f.readline())
    ok = got is not None and [got.group(3).split()[0], got.group(2), got.group(1)] == want
    say("VIEW-MATCH" if ok else "VIEW-MISMATCH")


def size(path):
    """1.4.1: width and height of a picture, read by magick."""
    r = subprocess.run([shutil.which("magick") or "magick", "identify", "-format", "%w %h", path], check=True, capture_output=True, text=True)
    return [int(v) for v in r.stdout.split()[:2]]


def pad_halves(ev, a, b, f):
    """1.4.1: put halves of unequal size on one canvas, grey #e5e5e5 where nothing was captured.
    A CROP-WIDENED after picture records where the before area sits inside it (offset); otherwise centred."""
    sb, sf = size(b), size(f)
    if sb == sf:
        return b, f, []
    try:
        with open(os.path.join(ev, a.after + ".json")) as fh:
            j = json.load(fh)
    except (FileNotFoundError, ValueError):
        j = {}
    W, H = max(sb[0], sf[0]), max(sb[1], sf[1])
    res, pads = [], []
    for src, (w, h), tag, o in ((b, sb, "before", j.get("offset") if j.get("crop") == "CROP-WIDENED" else None), (f, sf, "after", None)):
        if [w, h] == [W, H]:
            res.append(src)
            continue
        o = o or [(W - w) // 2, (H - h) // 2]
        p = os.path.join(ev, "%s-%s.pad.raw.png" % (a.name, tag))
        magick("-size", "%dx%d" % (W, H), "xc:#e5e5e5", src, "-geometry", "+%d+%d" % (round(o[0]), round(o[1])), "-composite", p)
        res.append(p)
        pads.append(p)
    return res[0], res[1], pads


def pair(a):
    ev = os.path.join(a.run, "evidence")
    b, f, out = (os.path.join(ev, n + ".png") for n in (a.before, a.after, a.name))
    if not (os.path.isfile(b) and os.path.isfile(f)):
        return say("ERROR before or after picture missing")
    clear(ev, a.name)
    lab = ["-background", "white", "-gravity", "North", "-splice", "0x44", "-pointsize", "28", "-annotate", "+0+8"]
    # 1.4.1 aligned crops: halves of unequal size (CROP-WIDENED or CROP-DIFFERENT) go on one canvas first, so they line up.
    b, f, pads = pad_halves(ev, a, b, f)
    magick(*(["(", b] + lab + ["Before", ")", "(", f] + lab + ["After", ")", "+append", "-strip", "-resize", "1600x>", out]))
    for p in pads:
        os.remove(p)
    bo, fo = (os.path.join(ev, n + ".ocr.png") for n in (a.before, a.after))
    if os.path.isfile(bo) and os.path.isfile(fo):
        magick(bo, fo, "+append", "-strip", os.path.join(ev, a.name + ".ocr.png"))
    if not small_enough(out):
        return say("ERROR picture over 1 MB")
    shutil.copyfile(os.path.join(ev, "mark-%s.side" % a.before), os.path.join(ev, "mark-%s.side" % a.name))
    held = []
    for n in (a.before, a.after):
        try:
            with open(os.path.join(ev, n + ".json")) as fh:
                if json.load(fh).get("held"):
                    held.append(n)
        except (FileNotFoundError, ValueError):
            pass
    with open(os.path.join(ev, a.name + ".json"), "w") as fh:
        json.dump({"path": "pair", "held": bool(held), "reason": "made from held pictures" if held else ""}, fh)
    say("SAVED " + out)




def diagram(a, secrets):
    """1.4.1 diagrams (references/diagrams.md): render the first <svg> of a checked diagram file to a PNG.
    Page scripts off; only file: and Google Fonts are let through; paper background; 1 to 9 node groups."""
    dg = os.path.join(a.run, "diagrams")
    src = os.path.realpath(a.html)
    if os.path.dirname(src) != os.path.realpath(dg) or not src.endswith(".html") or not os.path.isfile(src):
        return say("ERROR the diagram file must be an .html file in the run folder's diagrams folder")
    if not shutil.which("magick"):
        return say("ERROR magick not installed")
    for old in (a.name + ".png", a.name + ".ocr.png", a.name + ".viewed", a.name + ".json", "ocr-%s.txt" % a.name):
        if os.path.exists(os.path.join(dg, old)):
            os.remove(os.path.join(dg, old))
    from playwright.sync_api import sync_playwright
    raw = os.path.join(dg, a.name + ".raw.png")
    out, big = os.path.join(dg, a.name + ".png"), os.path.join(dg, a.name + ".ocr.png")
    blocked = []

    def gate(route):
        u = route.request.url
        host = re.sub(r"^[a-z]+://([^/:?#]*).*$", r"\1", u, flags=re.S) if "://" in u else ""
        if u.startswith("file:") or (u.startswith("https://") and host in ("fonts.googleapis.com", "fonts.gstatic.com")):
            return route.continue_()
        blocked.append(host or "other")
        return route.abort()

    try:
        with sync_playwright() as p:
            b = p.chromium.launch()
            ctx = b.new_context(viewport={"width": 1280, "height": 800}, device_scale_factor=2, java_script_enabled=False)
            ctx.route("**/*", gate)
            page = ctx.new_page()
            page.set_default_timeout(LIMIT * 1000)
            timed(page.goto, "file://" + src)
            try:
                page.wait_for_load_state("networkidle", timeout=10000)
            except Exception:
                pass
            if blocked:
                return say("UNREACHABLE remote-asset")
            if not timed(page.evaluate, "() => !!document.querySelector('svg')"):
                return say("NO-SVG")
            n = timed(page.evaluate, "() => document.querySelectorAll('svg g[data-sf-node]').length")
            if n < 1 or n > 9:
                return say("ERROR boxes %d" % n)
            box = timed(page.evaluate, "() => { const r = document.querySelector('svg').getBoundingClientRect(); return {x: r.left, y: r.top, width: r.width, height: r.height}; }")
            kinds = timed(page.evaluate, SCAN_JS, box)
            if timed(page.evaluate, "() => document.getElementsByTagNameNS('http://www.w3.org/2000/svg', 'foreignObject').length"):
                kinds = sorted(set(kinds) | {"foreign-object"})
            if kinds:
                return say("UNREACHABLE " + " ".join(kinds))
            if not timed(page.evaluate, "async () => { await document.fonts.ready; return document.fonts.check('600 12px Geist'); }"):
                return say("ERROR fonts: the Geist font did not load (no network?)")
            timed(lambda: page.locator("svg").first.screenshot(path=raw))
            b.close()
        magick(raw, "-background", "#f5f5f5", "-flatten", "-strip", big)
        magick(raw, "-background", "#f5f5f5", "-flatten", "-resize", "50%", "-strip", "-resize", "1600x>", out)
        os.remove(raw)
        if not small_enough(out):
            return say("ERROR picture over 1 MB")
        with open(os.path.join(dg, a.name + ".json"), "w") as f:
            json.dump({"path": "diagram", "html": src, "nodes": n, "held": bool(secrets), "reason": "a secret is on the list" if secrets else ""}, f)
        say("SAVED " + out)
    finally:
        if os.path.exists(raw):
            os.remove(raw)


def diagram_verify(a, secrets):
    """1.4.1: OCR the rendered diagram, look for every listed secret, and check the self-report Viewed line."""
    dg = os.path.join(a.run, "diagrams")
    png, big, txt = (os.path.join(dg, x) for x in (a.name + ".png", a.name + ".ocr.png", "ocr-%s.txt" % a.name))
    if not os.path.isfile(png):
        return say("ERROR no picture")
    tess = shutil.which("tesseract")
    if not tess:
        return say("NO-OCR")
    up = os.path.join(dg, a.name + ".up.png")
    try:
        magick(big if os.path.isfile(big) else png, "-resize", "200%", "-colorspace", "Gray", "-normalize", up)
        parts = []
        for img in (png, big, up):
            if os.path.isfile(img):
                r = subprocess.run([tess, img, "-"], capture_output=True, text=True)
                if r.returncode:
                    return say("ERROR ocr")
                parts.append(r.stdout)
    finally:
        if os.path.exists(up):
            os.remove(up)
    with open(txt, "w", encoding="utf-8") as f:
        f.write("\n".join(parts))
    say("OCR-BLOCKED" if ocr_hit("\n".join(parts), secrets) else "OCR-CLEAN")
    viewed = os.path.join(dg, a.name + ".viewed")
    if not os.path.isfile(viewed) or os.path.getmtime(viewed) < os.path.getmtime(png):
        return say("NOT-VIEWED")
    with open(viewed, encoding="utf-8") as f:
        say("VIEWED-SELF-REPORT" if f.readline().startswith("Viewed (self-report): diagram, ") else "NOT-VIEWED")


def mcp_code(a, secrets):
    if secrets:
        return say("ERROR the secrets list is not empty: use the script path, never the MCP path")
    ev = os.path.join(a.run, "evidence")
    os.makedirs(ev, mode=0o700, exist_ok=True)
    clear(ev, a.name)
    with open(os.path.join(ev, a.name + ".json"), "w") as f:
        json.dump({"path": "mcp", "selector": a.selector, "hide": a.hide or [], "colour": a.colour, "num": a.num}, f)
    j = json.dumps
    print(MCP_JS % {"sel": j(a.selector), "hide": j(a.hide or []), "out": j(os.path.join(ev, a.name + ".raw.png")),
                    "blank": BLANK_JS, "pats": j(PATS), "mark": MARK_JS, "colour": j(COLOURS[a.colour]),
                    "num": j(a.num), "scan": SCAN_JS})


def mcp_save(a):
    ev = os.path.join(a.run, "evidence")
    raw, out = os.path.join(ev, a.name + ".raw.png"), os.path.join(ev, a.name + ".png")
    if not os.path.isfile(raw):
        return say("ERROR no raw picture")
    magick(raw, "-strip", "-resize", "1600x>", out)
    os.remove(raw)
    if not small_enough(out):
        return say("ERROR picture over 1 MB")
    with open(os.path.join(ev, "mark-%s.side" % a.name), "w") as f:
        f.write("%s %s %s\n" % (a.side, a.colour, a.num))
    say("SAVED " + out)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("shoot")
    s.add_argument("--run", required=True); s.add_argument("--url", required=True); s.add_argument("--serve")
    s.add_argument("--selector", required=True); s.add_argument("--num", required=True)
    s.add_argument("--colour", choices=["red", "green"], required=True); s.add_argument("--name", required=True)
    s.add_argument("--storage"); s.add_argument("--hide", action="append")
    dg = sub.add_parser("diagram")  # 1.4.1, references/diagrams.md
    dg.add_argument("--run", required=True); dg.add_argument("--html", required=True); dg.add_argument("--name", required=True)
    dv = sub.add_parser("diagram-verify")  # 1.4.1
    dv.add_argument("--run", required=True); dv.add_argument("--name", required=True)
    rt = sub.add_parser("retake")
    rt.add_argument("--run", required=True); rt.add_argument("--source", required=True); rt.add_argument("--name", required=True)
    rt.add_argument("--colour", choices=["red", "green"]); rt.add_argument("--url"); rt.add_argument("--serve")
    for n in ("verify", "ocr"):
        v = sub.add_parser(n); v.add_argument("--run", required=True); v.add_argument("--name", required=True)
    pr = sub.add_parser("pair"); pr.add_argument("--run", required=True); pr.add_argument("--before", required=True)
    pr.add_argument("--after", required=True); pr.add_argument("--name", required=True)
    mc = sub.add_parser("mcp-code")
    for k in ("run", "selector", "num", "name"):
        mc.add_argument("--" + k, required=True)
    mc.add_argument("--colour", choices=["red", "green"], required=True); mc.add_argument("--hide", action="append")
    ms = sub.add_parser("mcp-save")
    for k in ("run", "num", "name"):
        ms.add_argument("--" + k, required=True)
    ms.add_argument("--colour", choices=["red", "green"], required=True)
    ms.add_argument("--side", choices=["right", "left", "below"], required=True)
    a = ap.parse_args()
    a.run = os.path.abspath(a.run)
    os.umask(0o077)
    # Whole-run limit as well, for a step that hangs outside timed().
    whole = threading.Timer(LIMIT * 4, lambda: (say("ERROR timeout"), os._exit(3)))
    whole.daemon = True
    whole.start()
    if not os.path.isfile(os.path.join(a.run, "key")):
        return say("NO-RUN-FOLDER " + a.run)
    names = [a.name] + [getattr(a, k) for k in ("before", "after", "source") if getattr(a, k, None)]
    if not all(NAME.match(n) for n in names):
        return say("ERROR bad picture name")
    secrets = read_secrets(a.run)
    if a.cmd in ("diagram", "diagram-verify"):
        # 1.4.1 diagrams: their own commands and their own folder (diagrams/), so the picture count stays as in 1.4.0.
        try:
            (diagram if a.cmd == "diagram" else diagram_verify)(a, secrets)
        except Exception as e:
            kind = type(e).__name__
            code = "timeout" if kind == "TimeoutError" else ("browser" if kind == "Error" else "python")
            say("ERROR timeout" if code == "timeout" else "ERROR %s: %s" % (code, tidy(str(e), secrets)))
        return
    try:
        {"shoot": lambda: shoot(a, secrets), "retake": lambda: retake(a, secrets), "verify": lambda: verify(a, secrets),
         "ocr": lambda: ocr(a), "pair": lambda: pair(a), "mcp-code": lambda: mcp_code(a, secrets),
         "mcp-save": lambda: mcp_save(a)}[a.cmd]()
    except Exception as e:
        kind = type(e).__name__
        code = "timeout" if kind == "TimeoutError" else ("browser" if kind == "Error" else "python")
        say("ERROR timeout" if code == "timeout" else "ERROR %s: %s" % (code, tidy(str(e), secrets)))


if __name__ == "__main__":
    main()
# --- shot.py end ---
```

### Aligned crops

New in 1.4.1. In 1.4.0 `retake` centred the moved target again, so the after picture showed a different page area. Now `shoot` stores the area it cut (`page_clip`, in page terms) and the scroll position in `evidence/<name>.json`, and `retake` scrolls back to that position, measures the after target and its mark, then:
- `CROP-ALIGNED`: the mark is inside the stored area. The after picture uses exactly the before area.
- `CROP-WIDENED`: the mark is partly outside the stored area but inside the window. The after picture shows both areas together (their union); `pair` puts the before picture on a canvas of that size at its place, grey `#e5e5e5` where nothing was captured, so the two halves line up. The caption adds: "the after side shows a wider area because <target> moved; grey means not in the before picture".
- `CROP-DIFFERENT`: the mark is outside the window at that scroll position, or the page can no longer scroll there. The 1.4.0 behaviour: the target is centred again. `pair` centres the smaller half on a grey canvas so the halves are the same size, and the caption says the two sides show different areas of the page.
- No full-page shot for the large case: the marks are `position:fixed`, and a full-page shot would move them.
- A before picture taken by 1.4.0 (no stored area) is retaken as in 1.4.0, with no CROP word. The MCP path keeps the 1.4.0 behaviour (Not tested).

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

Pictures are release assets of one standing release named `assets`, as in `thedanielmay/pullstruder`. Creating that release adds a tag named `assets` to the repo, which can start workflows that run on new tags or releases, and notifies people who watch the repo's releases. Webhooks, GitHub Apps and repository rules cannot be checked from here and may also react to a new tag. So it is never created blind. Before the first upload, one command:

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; R='<owner>/<repo>'; ME="$(gh api user -q .login)"; if [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; elif [ -z "$ME" ] || [ "${R%%/*}" != "$ME" ]; then echo "ASK-FIRST $R"; elif gh release view assets --repo "$R" >/dev/null 2>&1; then echo ASSETS-EXISTS; elif gh api "repos/$R/git/ref/tags/assets" >/dev/null 2>&1; then echo "ASK-FIRST-TAG $R"; else L="$(gh api "repos/$R/git/trees/HEAD?recursive=1" -q 'if .truncated then "TRUNCATED" else (.tree[] | select(.type == "blob") | .path) end' 2>&1)"; rc=$?; if [ $rc -ne 0 ] && ! printf '%s\n' "$L" | grep -q 'HTTP 409'; then echo "ERROR: could not list the repo files"; else : > "$D/workflow-flags"; if [ $rc -eq 0 ]; then printf '%s\n' "$L" | grep -qx TRUNCATED && echo "UNREAD the file list is too long to read in full" >> "$D/workflow-flags"; printf '%s\n' "$L" | grep -i '^\.github/workflows/' | while IFS= read -r p; do T="$(gh api "repos/$R/contents/$p" -q .content 2>/dev/null | base64 -d 2>/dev/null)"; if [ -z "$T" ]; then echo "UNREAD $p" >> "$D/workflow-flags"; elif printf '%s\n' "$T" | grep -qiE 'push|release|create|tags|workflow_run|workflow_call|repository_dispatch|(^|[[:space:]])"?on"?:[[:space:]]*[[{]'; then echo "FLAG $p" >> "$D/workflow-flags"; fi; done; fi; if [ -s "$D/workflow-flags" ]; then echo "ASK-FIRST-WORKFLOWS $R"; cat "$D/workflow-flags"; else gh release create assets --repo "$R" --title "Asset host" --notes "Hosts images referenced from issues" --latest=false && echo ASSETS-CREATED; fi; fi; fi
```

- `ASSETS-EXISTS` or `ASSETS-CREATED`: go on to the upload commands.
- `ASK-FIRST`: the signed-in user does not own the repo (whether or not the release exists). `ASK-FIRST-TAG`: a tag named `assets` exists but no release. `ASK-FIRST-WORKFLOWS`: some file under `.github/workflows/` (any depth, any case) contains one of the words `push`, `release`, `create`, `tags`, `workflow_run`, `workflow_call` or `repository_dispatch`, or writes `on:` in flow syntax (`on: [...]` or `on: {...}`), or could not be read (`FLAG` and `UNREAD` lines name the files). False alarms are fine: the check is a text search, on purpose. No workflow files at all (or an empty repo) means none. In every ASK case upload nothing yet. The decision message carries this numbered question, just before the create-issue question, which stays last: "May I create a release named assets in <owner>/<repo> to hold the pictures? It adds a tag named assets, which can start workflows that run on new tags or releases and notifies people who watch the repo's releases; webhooks, GitHub Apps and repository rules cannot be checked from here and may also react. (yes / no)". It has NO recommended answer, like the create-issue question: "keep executing" does not cover it, and anything but an explicit yes to it is no. On a yes, run `gh release create assets --repo <owner>/<repo> --title "Asset host" --notes "Hosts images referenced from issues" --latest=false && echo ASSETS-CREATED`, then the upload commands, then add the pictures to the body. Without a yes, use `A='keep'`, and the `Pictures:` line says `NOT-POSTED (the assets release needs your yes)`.
- Creating the `assets` release and its tag, only after these ownership and workflow checks, and uploading to it are the only writes before approval that leave the machine, and only for a PRIVATE repo you own (SKILL.md Phase 1).
- Labels and gap notes (SKILL.md Phase 1) are also allowed before approval.

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
