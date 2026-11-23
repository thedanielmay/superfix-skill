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
    import urllib.parse
    raw = os.path.join(dg, a.name + ".raw.png")
    out, big = os.path.join(dg, a.name + ".png"), os.path.join(dg, a.name + ".ocr.png")
    blocked = []

    def gate(route):
        u = route.request.url
        host = re.sub(r"^[a-z]+://([^/:?#]*).*$", r"\1", u, flags=re.S) if "://" in u else ""
        # Only the diagram file itself among file: addresses; any other file (<use href>, @import, url()) is blocked.
        if u.startswith("file:") and urllib.parse.unquote(urllib.parse.urlsplit(u).path) == src:
            return route.continue_()
        if u.startswith("https://") and host in ("fonts.googleapis.com", "fonts.gstatic.com"):
            return route.continue_()
        blocked.append("local-file" if u.startswith("file:") else "remote-asset")
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
                return say("UNREACHABLE " + " ".join(sorted(set(blocked))))
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
