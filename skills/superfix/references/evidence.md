# Evidence pictures

New in 1.4.0 ([superfix-skill#47](https://github.com/thedanielmay/superfix-skill/issues/47)). SKILL.md ("Evidence pictures") says when to read this file: in full, before the first picture. Pictures are taken by a script, checked for secrets by a second script and OCR, and uploaded by one command per file. Nothing here replaces a rule in `references/redaction.md`; it adds the picture rules.

### When, names, cap, size, captions

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
  - Inside, in order: read `$D/secrets` (if present); open the page at 1280 by 800; hide each `--hide` element (`visibility:hidden`); find the target (`NO-MATCH`); scroll the window only, so the target is centred (never `scrollIntoView`, which also scrolls an `overflow:hidden` box and can hide the very bug); measure it, `ZERO-SIZE` on 0 width or height (no mark is drawn on nothing); blank every exact secret, then the 1.3.1 token patterns and e-mail addresses, in every text node, input and textarea value, and the `placeholder`, `title`, `alt`, `aria-label` and `value` attributes, in open shadow roots and same-origin frames too, all replaced by `[redacted]`; stop with `ERROR` if a secret is still in the page text; draw the box and the label; scan the picture area for what blanking cannot reach (canvas, img, video, svg image, object or embed, a cross-origin iframe, a closed shadow root): any one found prints `UNREACHABLE <kinds>` and saves nothing; else screenshot the area, `magick -strip -resize '1600x>'`, record the label side in `evidence/mark-<name>.side`, print `SAVED`.
  - `UNREACHABLE`: take it again with `--hide '<css of that element>'` when the element is not the problem itself, and say in the caption that it was hidden. If the target itself is such a region, no picture: use the Not tested line below.
  - `--storage <file>`: a saved login (Qik draft pages; below). Never a file inside a repo.
- `"<python>" "$D/shot.py" verify --run "$D" --name <name>` prints `OCR-CLEAN` or `OCR-BLOCKED` (every secret checked against `evidence/ocr-<name>.txt` exactly, spaces removed, and as every 8-character piece, after folding the letters OCR confuses, so one misread character does not pass), then `VIEW-MATCH`, `VIEW-MISMATCH` or `NOT-VIEWED`. Any Python 3 runs it; it needs no browser. The upload command below runs it; you do not need to.
- `"<python>" "$D/shot.py" pair --run "$D" --before <name> --after <name> --name <pair name>` makes the side-by-side picture (below) and prints `SAVED <file>`.
- `"<python>" "$D/shot.py" mcp-code ...` and `mcp-save ...`: the MCP path only (below).

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
  const clean = s => {
    if (!s) return s;
    let t = s;
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
      for (const a of ATTRS) if (el.hasAttribute(a)) { el.setAttribute(a, clean(el.getAttribute(a))); texts.push(el.getAttribute(a)); }
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
      if (k && inClip(r, ox, oy) && shown(el, win)) kinds.add(k);
      if (el.shadowRoot) scan(el.shadowRoot, win, ox, oy);
    }
  };
  scan(document, window, 0, 0);
  return [...kinds].sort();
}"""


def read_secrets(run):
    try:
        with open(os.path.join(run, "secrets"), encoding="utf-8") as f:
            return [l.rstrip("\r\n") for l in f if l.strip()]
    except FileNotFoundError:
        return []


def say(word, secrets=()):
    for s in secrets:
        word = word.replace(s, "[redacted]")
    print(word.splitlines()[0] if word else "ERROR")


def mark_closed_shadow_roots(page):
    cdp = page.context.new_cdp_session(page)
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
    for old in (a.name + ".png", a.name + ".viewed", "mark-%s.side" % a.name, "ocr-%s.txt" % a.name):
        if os.path.exists(os.path.join(ev, old)):
            os.remove(os.path.join(ev, old))
    magick = shutil.which("magick")
    if not magick:
        return say("ERROR magick not installed")
    url, server = a.url, None
    if a.serve:
        class Quiet(http.server.SimpleHTTPRequestHandler):
            def log_message(self, *x):
                pass
        handler = functools.partial(Quiet, directory=a.serve)
        server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        url = "http://127.0.0.1:%d/%s" % (server.server_address[1], a.url.lstrip("/"))
    from playwright.sync_api import sync_playwright
    try:
        with sync_playwright() as p:
            b = p.chromium.launch()
            kw = {"viewport": {"width": 1280, "height": 800}, "device_scale_factor": 1}
            if a.storage:
                if not os.path.isfile(a.storage):
                    return say("ERROR no saved login file")
                kw["storage_state"] = a.storage
            page = b.new_context(**kw).new_page()
            page.goto(url, wait_until="load")
            page.wait_for_timeout(300)
            for h in a.hide or []:
                if page.evaluate("s => { const l = document.querySelectorAll(s); l.forEach(e => e.style.setProperty('visibility', 'hidden', 'important')); return l.length; }", h) == 0:
                    return say("ERROR hide selector matched nothing")
            if page.evaluate("s => !!document.querySelector(s)", a.selector) is False:
                return say("NO-MATCH")
            # Scroll the window only. scrollIntoView would also scroll an overflow:hidden box and hide the bug.
            page.evaluate("s => { const r = document.querySelector(s).getBoundingClientRect(); window.scrollBy(r.left + r.width / 2 - innerWidth / 2, r.top + r.height / 2 - innerHeight / 2); }", a.selector)
            page.wait_for_timeout(200)
            w, h = page.evaluate("s => { const r = document.querySelector(s).getBoundingClientRect(); return [r.width, r.height]; }", a.selector)
            if w == 0 or h == 0:
                return say("ZERO-SIZE")
            if page.evaluate(BLANK_JS, {"secrets": secrets, "pats": PATS}):
                return say("ERROR a secret is still on the page after blanking")
            mark_closed_shadow_roots(page)
            m = page.evaluate(MARK_JS, {"sel": a.selector, "colour": COLOURS[a.colour], "num": a.num})
            kinds = page.evaluate(SCAN_JS, m["clip"])
            if kinds:
                return say("UNREACHABLE " + " ".join(kinds))
            raw = os.path.join(ev, a.name + ".raw.png")
            out = os.path.join(ev, a.name + ".png")
            page.screenshot(path=raw, clip=m["clip"])
            b.close()
        subprocess.run([magick, raw, "-strip", "-resize", "1600x>", out], check=True, capture_output=True)
        os.remove(raw)
        if os.path.getsize(out) > 1000000:
            subprocess.run([magick, out, "-strip", "-resize", "1280x>", "-colors", "256", out], check=True, capture_output=True)
        if os.path.getsize(out) > 1000000:
            os.remove(out)
            return say("ERROR picture over 1 MB")
        with open(os.path.join(ev, "mark-%s.side" % a.name), "w") as f:
            f.write("%s %s %s\n" % (m["side"], a.colour, a.num))
        say("SAVED " + out)
    finally:
        if server:
            server.shutdown()


def norm(s):
    return re.sub(r"[^a-z0-9]", "", s.lower().translate(str.maketrans("oil|s", "01115")))


def ocr_hit(text, secrets):
    flat, nt = re.sub(r"\s", "", text), norm(text)
    for s in secrets:
        if re.sub(r"\s", "", s) in flat:
            return True
        ns = norm(s)
        pieces = [ns[i:i + 8] for i in range(len(ns) - 7)] if len(ns) >= 8 else ([ns] if len(ns) >= 4 else [])
        if any(p in nt for p in pieces):
            return True
    return False


def verify(a, secrets):
    ev = os.path.join(a.run, "evidence")
    png, ocr = os.path.join(ev, a.name + ".png"), os.path.join(ev, "ocr-%s.txt" % a.name)
    if not os.path.isfile(ocr):
        say("ERROR no OCR file")
    else:
        with open(ocr, encoding="utf-8", errors="replace") as f:
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


def pair(a):
    ev = os.path.join(a.run, "evidence")
    b, f, out = (os.path.join(ev, n + ".png") for n in (a.before, a.after, a.name))
    if not (os.path.isfile(b) and os.path.isfile(f)):
        return say("ERROR before or after picture missing")
    lab = ["-background", "white", "-gravity", "North", "-splice", "0x44", "-pointsize", "28", "-annotate", "+0+8"]
    subprocess.run(["magick", "(", b] + lab + ["Before", ")", "(", f] + lab + ["After", ")",
                    "+append", "-strip", "-resize", "1600x>", out], check=True, capture_output=True)
    shutil.copyfile(os.path.join(ev, "mark-%s.side" % a.before), os.path.join(ev, "mark-%s.side" % a.name))
    say("SAVED " + out)


MCP_JS = """async (page) => {
  await page.setViewportSize({width: 1280, height: 800});
  const sel = %(sel)s, hide = %(hide)s, out = %(out)s;
  for (const h of hide) if (await page.evaluate(s => { const l = document.querySelectorAll(s); l.forEach(e => e.style.setProperty('visibility', 'hidden', 'important')); return l.length; }, h) === 0) return 'ERROR hide selector matched nothing';
  if (!(await page.evaluate(s => !!document.querySelector(s), sel))) return 'NO-MATCH';
  await page.evaluate(s => { const r = document.querySelector(s).getBoundingClientRect(); window.scrollBy(r.left + r.width / 2 - innerWidth / 2, r.top + r.height / 2 - innerHeight / 2); }, sel);
  await page.waitForTimeout(200);
  const [w, h] = await page.evaluate(s => { const r = document.querySelector(s).getBoundingClientRect(); return [r.width, r.height]; }, sel);
  if (w === 0 || h === 0) return 'ZERO-SIZE';
  await page.evaluate(%(blank)s, {secrets: [], pats: %(pats)s});
  const cdp = await page.context().newCDPSession(page);
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


def mcp_code(a, secrets):
    if secrets:
        return say("ERROR the secrets list is not empty: use the script path, never the MCP path")
    ev = os.path.join(a.run, "evidence")
    os.makedirs(ev, mode=0o700, exist_ok=True)
    for old in (a.name + ".png", a.name + ".viewed", "mark-%s.side" % a.name, "ocr-%s.txt" % a.name):
        if os.path.exists(os.path.join(ev, old)):
            os.remove(os.path.join(ev, old))
    j = json.dumps
    print(MCP_JS % {"sel": j(a.selector), "hide": j(a.hide or []), "out": j(os.path.join(ev, a.name + ".raw.png")),
                    "blank": BLANK_JS, "pats": j(PATS), "mark": MARK_JS, "colour": j(COLOURS[a.colour]),
                    "num": j(a.num), "scan": SCAN_JS})


def mcp_save(a):
    ev = os.path.join(a.run, "evidence")
    raw, out = os.path.join(ev, a.name + ".raw.png"), os.path.join(ev, a.name + ".png")
    if not os.path.isfile(raw):
        return say("ERROR no raw picture")
    subprocess.run(["magick", raw, "-strip", "-resize", "1600x>", out], check=True, capture_output=True)
    os.remove(raw)
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
    v = sub.add_parser("verify"); v.add_argument("--run", required=True); v.add_argument("--name", required=True)
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
    os.umask(0o077)
    if not os.path.isfile(os.path.join(a.run, "key")):
        return say("NO-RUN-FOLDER " + a.run)
    if not re.match(r"^[A-Za-z0-9._+-]+$", a.name) or (a.cmd == "pair" and not all(re.match(r"^[A-Za-z0-9._+-]+$", n) for n in (a.before, a.after))):
        return say("ERROR bad picture name")
    secrets = read_secrets(a.run)
    try:
        {"shoot": lambda: shoot(a, secrets), "verify": lambda: verify(a, secrets), "pair": lambda: pair(a),
         "mcp-code": lambda: mcp_code(a, secrets), "mcp-save": lambda: mcp_save(a)}[a.cmd]()
    except Exception as e:
        say("ERROR %s: %s" % (type(e).__name__, str(e).strip() or "no detail"), secrets)


if __name__ == "__main__":
    main()
# --- shot.py end ---
```

### Looking at each picture (the Viewed line)

After `SAVED`, Read the PNG yourself (the Read tool shows the image), then write what you SEE, never what you expect, in one line:

```bash
umask 077; printf '%s\n' 'Viewed: label 1 red, right of the Subscribe button' > "$HOME/.superfix/runs/<run-key>/evidence/<name>.viewed" && echo VIEWED-SAVED
```

- Form, exactly: `Viewed: label <number> <red|green>, <right of|left of|below> <the target in words>`.
- Never read, print, list with contents or grep a `mark-*.side` file. The upload command compares your line with the side the script drew and prints `VIEW-MATCH` or `VIEW-MISMATCH`. A Viewed line written before the picture was (re)taken is a `VIEW-MISMATCH`.
- `VIEW-MISMATCH`: Read the picture again and rewrite the line from what you see. Never edit the side file.
- The side-by-side picture: describe the left (before) mark.
- The same Viewed line goes in the AI detail of the comment that carries the picture.

### MCP path (BROWSER-MCP, only after NO-LIST)

Only when the shell probe found no `BROWSER-SCRIPT`, the Playwright MCP tools are loaded, and the exact-string check printed `NO-LIST` in this run. It uses the same blanking (patterns and e-mail only, as there is no list), marking and scanning code as the script, generated by it:

1. Write `shot.py` into the run folder (command above). Any `python3` runs these two commands; they need no browser.
2. `python3 "$D/shot.py" mcp-code --run "$D" --selector '<css>' --num 1 --colour red --name <name> [--hide '<css>']` prints a function. It refuses with `ERROR` if the list has any entry.
3. `browser_navigate` to the page. If a `file://` address is refused, serve the folder with the dev server rule below, for example `python3 -m http.server <port> --bind 127.0.0.1 --directory <dir>`.
4. `browser_run_code` with that function, unchanged. It returns `SHOT <side>`, `NO-MATCH`, `ZERO-SIZE`, `UNREACHABLE <kinds>` or `ERROR ...`, and writes `evidence/<name>.raw.png`.
5. `python3 "$D/shot.py" mcp-save --run "$D" --name <name> --num 1 --colour red --side <side from step 4>` strips and resizes it and prints `SAVED <file>`.
6. Read the picture and write the Viewed line as above. On this path the side came back in a tool result, so the Viewed line is a self-report: write `Viewed (MCP path, self-report): ...` in the AI detail.

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

One command per picture. It runs every check on that exact file and uploads only when they just printed `CLEAN` or `NO-LIST`, `OCR-CLEAN`, `VIEW-MATCH` and `PATTERN-CLEAN`. Write every value literally: `<run-key>`, `<name>` (no `.png`), `<owner>/<repo>`, `<python>` (any Python 3), and `A` = `upload` (an issue on a PRIVATE repo) or `keep` (a public repo, or no issue: the picture goes to the journal pictures folder, below). The exact-string part is the redaction.md check and the pattern part is the redaction.md pattern check plus e-mail, both on the OCR text file.

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; N='<name>'; R='<owner>/<repo>'; A='<upload or keep>'; PY='<python>'; F="$D/evidence/$N.png"; O="$D/evidence/ocr-$N"; if ! command -v tesseract >/dev/null; then echo NO-OCR; elif [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; elif [ "$A" = upload ] && [ "$(gh repo view "$R" --json visibility -q .visibility)" != PRIVATE ]; then echo NOT-PRIVATE; elif ! grep -q '^Viewed: ' "$D/evidence/$N.viewed" 2>/dev/null; then echo NOT-VIEWED; elif ! tesseract "$F" "$O" >/dev/null 2>&1; then echo "ERROR: ocr"; else E="$(L="$D/secrets"; P="$(grep -v '^[[:space:]]*$' "$L" 2>/dev/null)"; if [ -z "$P" ]; then echo NO-LIST; else H="$(printf '%s\n' "$P" | grep -F -l -f - "$O.txt")"; rc=$?; if [ $rc -gt 1 ]; then echo "ERROR: a file could not be read"; elif [ -n "$H" ]; then echo "BLOCKED $H"; else echo CLEAN; fi; fi)"; V="$("$PY" "$D/shot.py" verify --run "$D" --name "$N" | tr '\n' ' ')"; P="$(H="$( { grep -H -n -E -i '(password|passwd|pwd|secret|token|api[_-]?key|auth|bearer|cookie|session)[[:space:]]*[:=][[:space:]]*[^[:space:]]+' "$O.txt" | grep -v 'Claude-Session: https://claude.ai/code/session_'; grep -H -n -E '(^|[^A-Za-z0-9])(sk-[A-Za-z0-9]|ghp_|gho_|github_pat_)|AKIA[0-9A-Z]{16}|eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.|-----BEGIN [A-Z ]*KEY-----|://[^/[:space:]:@]+:[^/[:space:]@]+@' "$O.txt"; perl -ne 'while (/(?<![A-Za-z0-9])([A-Za-z0-9]{32,})(?![A-Za-z0-9])/g) { my $s=$1; next unless $s=~/[A-Za-z]/ && $s=~/[0-9]/; next if $s=~/^[0-9a-f]{40}$/i; next if $s=~/^[0-9a-f]{64}$/i && /sha256/i; print "$ARGV:$.:\n" } close ARGV if eof' "$O.txt"; grep -H -n -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$O.txt"; } | cut -d: -f1,2 | sort -u )"; if [ -n "$H" ]; then echo "PATTERN-HITS (file:line, read each one, then decide):"; echo "$H"; else echo PATTERN-CLEAN; fi)"; echo "$E / $V/ $P"; case "$E" in CLEAN|NO-LIST) ;; *) E=BAD;; esac; if [ "$E" != BAD ] && [ "$V" = "OCR-CLEAN VIEW-MATCH " ] && [ "$P" = PATTERN-CLEAN ]; then if [ "$A" = upload ]; then gh release upload assets "$F" --repo "$R" && echo "UPLOADED $N"; else T="$HOME/.superfix/journal/${R%%/*}-${R#*/}/pictures/${D##*/}"; mkdir -p "$T" && cp "$F" "$T/" && echo "KEPT $N $T"; fi; else echo "NOT-UPLOADED $N"; fi; fi
```

What each word means:
- `UPLOADED <name>` or `KEPT <name> <folder>`: done. Anything else: nothing left the run folder.
- `NO-OCR`: tesseract is not installed, so no picture can be checked for secrets: nothing is uploaded in 1.4.0 (Not tested line below).
- `NOT-PRIVATE`: the repo is not PRIVATE (or `gh` could not say): never upload. Run it again with `A='keep'`.
- `NOT-VIEWED`: you have not written the Viewed line: Read the picture first.
- `NOT-UPLOADED <name>` after the check line:
  - `BLOCKED` or `OCR-BLOCKED`: a session secret is in the picture. Take it again with that area hidden (`--hide`), or no picture. A false `OCR-BLOCKED` (a long run of digits on the page that matches 8 characters of a secret) is treated the same way.
  - `PATTERN-HITS`: a pattern hit in a picture blocks it. There is no "you decide" for pictures: take it again with that area hidden, or no picture.
  - `VIEW-MISMATCH` or `NOT-VIEWED`: Read the picture again and rewrite the Viewed line.
  - `NO-RUN-FOLDER` or `ERROR`: the check did not run. Fix it and run again. Silence is never a pass.
- A failed `gh release upload` (for example the name is already there) prints its own error and no `UPLOADED`: retake under the next `<i>`, never overwrite a posted picture.

### The `assets` release (once per repo)

Pictures are release assets of one standing release named `assets`, as in `thedanielmay/pullstruder`. Before the first upload, one command:

```bash
R='<owner>/<repo>'; ME="$(gh api user -q .login)"; if gh release view assets --repo "$R" >/dev/null 2>&1; then echo ASSETS-EXISTS; elif [ -z "$ME" ] || [ "${R%%/*}" != "$ME" ]; then echo "ASK-FIRST $R"; else gh release create assets --repo "$R" --title "Asset host" --notes "Hosts images referenced from issues" --latest=false && echo ASSETS-CREATED; fi
```

- `ASK-FIRST`: the repo's owner is not the signed-in user, and a release adds a tag that can start release workflows. Upload nothing yet. The decision message carries this numbered question, just before the create-issue question when there is one: "May I create a release named assets in <owner>/<repo> to hold the pictures? (no unless you say yes)". It has no recommended answer, so "keep executing" does not say yes to it. Pictures stay in the run folder until a yes; on a yes, run `gh release create assets --repo <owner>/<repo> --title "Asset host" --notes "Hosts images referenced from issues" --latest=false && echo ASSETS-CREATED`, then the upload commands, then add the pictures to the body. Without a yes, use `A='keep'`.
- Creating the release and uploading to it are the only writes before approval that leave the machine, and only on a PRIVATE repo (SKILL.md Phase 1).

### Markdown forms

- Picture line, then the caption as plain text on the next line:
  `![P1 before: the Subscribe button (red box 1) is cut in half by the bottom edge of the price card](https://github.com/<owner>/<repo>/releases/download/assets/sf-<N>-p1-before-1.png)`
  `P1 before: the Subscribe button (red box 1) is cut in half by the bottom edge of the price card.`
- Every comment with a picture carries this line once, after the pictures: `Pictures show on the website, not in the GitHub app: https://github.com/<owner>/<repo>/issues/<N>`
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
- No issue (file-mode journal): the same `A='keep'`; the journal names the local files. If the owner says yes to creating the issue and the repo is PRIVATE, run the upload command for each picture after `gh issue create`, then add them to the new issue's body.

### Qik draft pages (saved login, untested in 1.4.0)

- Qik draft sites are behind a login. The script path can use a saved login: `--storage ~/.superfix/auth/<host>.json`, made once by the owner with `playwright codegen --save-storage=~/.superfix/auth/<host>.json <draft url>` (README).
- That file holds session cookies, a credential: mode 600, never in a repo, never printed, read or posted. The owner's passwords stay in 1Password, never typed into chat.
- Without that file: no Qik picture, and the Not tested line below. Never use the MCP path or Claude in Chrome to picture a logged-in page.

### Leaked picture

If a picture with a secret was uploaded: `gh release delete-asset assets <file> --repo <owner>/<repo> --yes`, then remove its link from the body and comments (redaction.md, Leak handling), check the body and every comment again for the image link, tell the owner what leaked where, and ask them to rotate the credential.

### Not tested lines (exact)

- `Pictures: not taken, because no browser was available in this run (checked: Playwright MCP, Python playwright with a browser). Run again where Playwright works to get them.`
- `Pictures: taken but not posted, because this repo is public. They are on the owner's Mac at <path>.`
- `Picture of P<k> not taken: the page area holds a <kind> that cannot be checked for secrets.`
- `Pictures: not posted, because OCR (tesseract) is not installed, so they could not be checked for secrets.`
- `Qik draft picture not taken: the draft site needs a one-time saved login (README).`
- `Pictures: not taken, because ImageMagick (magick) is not installed.`
- `Pictures: not posted, because the assets release needs your yes in <owner>/<repo>. They are on the owner's Mac at <path>.`
