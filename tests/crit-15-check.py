#!/usr/bin/env python3
"""CRIT-1.5-CHANGED: everything in the crit.py block that is not 1.6.1's own work
must stay byte for byte identical to v1.6.0.

Compared: every top-level function except cmd_wo_* and woc_* helpers (cmd_remind
stops at the work-orders comment: the WO constants below it are checked with
the module lines), main() except the contiguous wo-parser block (wo-check
through wo-sendback), and every other line of the block except the constant
statements below and the `, contextlib` / `, io` import delta.
Skipped regions use exact AST boundaries, so a line smuggled between two
functions (even between two skipped ones) is still compared.
The wo-parser block is parsed: every statement must be a p("wo-*") parser call
(or add_argument/set_defaults on its result, inside for/if nesting); anything
else in the block (a set_defaults hijack, an append call) fails as "parsers".
The constants are matched by exact AST value, not line text: WO_KINDS and
WO_REQUIRED_CRITERIA must equal the known 1.6.1 values; WO_LIMIT, WO_REQUIRED
and R_CALL must equal v1.6.0; a WOC_* name must exist in v1.6.0 with an equal
value (a new WOC_X, or code smuggled into a constant line, fails).
Skipped helpers must be plain: no decorators at all (any decorator runs at
import) and only constant defaults (a Call default such as
globals().__setitem__ runs at import); anything else fails under its own name.
Allowed 1.6.1 differences, and nothing else:
- WO_KINDS = {"code", "criteria"} (was {"code"});
- the WO_REQUIRED_CRITERIA line (new);
- `, contextlib` and `, io` inside the single stdlib import line (for capturing
  the 1.5.0 progress output inside wo-sendback);
- the bodies of def cmd_wo_* and def woc_* (any new helper, plainly written),
  and the wo-parser block in main() (p("wo-*") calls with their options).
Usage: python3 tests/crit-15-check.py [path-to-crit.py-or-criteria.md]
Takes the tool file directly, or a criteria.md holding the block between
the crit.py markers (old tags and tampered copies); both shapes compare
the same bytes.
Prints CRIT-1.5-CHANGED <names> and exits 1 on any other difference, else
CRIT-1.5-UNCHANGED. The plan names measure, baseline, lock, attempt, finish,
later, amend, comment, sendcheck and verify; later has no cmd_ function (later
criteria ride inside attempt and finish).
"""
import ast
import re
import subprocess
import sys
import textwrap

CRIT_PATH = "skills/superfix/references/crit.py"
OLD_CRIT_MD = "skills/superfix/references/criteria.md"
SKIP_DEF = ("cmd_wo_", "woc_")
EXPECTED_KINDS = {"code", "criteria"}
EXPECTED_WO_REQUIRED_CRITERIA = ["WORK-ORDER", "CHECKS-KIND", "SOURCE", "BASE", "FILES",
                                 "LIMITS", "CHECKS-SHA", "BASELINE", "DELIVER"]
EXACT_OLD_CONSTS = ("WO_LIMIT", "WO_REQUIRED", "R_CALL")


def block(text):
    m = re.search(r"(?ms)^# --- crit.py start ---\n(.*)^# --- crit.py end ---$", text)
    if not m:
        print("CRIT-1.5-CHANGED (no crit.py block)")
        sys.exit(1)
    return m.group(1)


def tool_text(text):
    lines = text.splitlines()
    if lines and lines[0].strip() == "# --- crit.py start ---":
        lines = lines[1:]
    if lines and lines[-1].strip() == "# --- crit.py end ---":
        lines = lines[:-1]
    stripped = "\n".join(lines) + ("\n" if text.endswith("\n") else "")
    if "# --- crit.py start ---" in stripped:
        m = re.search(r"(?ms)^# --- crit.py start ---\n(.*)^# --- crit.py end ---$", stripped)
        if m:
            return m.group(1)
    return stripped


def tree_of(py):
    try:
        return ast.parse(py)
    except SyntaxError:
        print("CRIT-1.5-CHANGED (crit.py block does not parse)")
        sys.exit(1)


def defs(py):
    """{name: body} for every top-level def; cmd_remind stops at the
    work-orders comment (the WO constants below it are module lines)."""
    out = {}
    for m in re.finditer(r"(?ms)^def (\w+)\(.*?(?=^def |\Z)", py):
        name, body = m.group(1), m.group(0)
        if name == "cmd_remind":
            body = body.split("# ---------- work orders")[0]
        out[name] = body
    return out


def parser_block_src(py):
    """Source lines from the wo-check parser line through the wo-sendback line."""
    out, on = [], False
    for l in py.splitlines():
        s = l.strip()
        if re.match(r"^(s = )?p\(\"wo-check\"", s):
            on = True
        if on:
            out.append(l)
            if re.match(r"^(s = )?p\(\"wo-sendback\"", s):
                break
    return "\n".join(out)


def parser_block_ok(src):
    """Every statement is a p("wo-*") call (or its add_argument/set_defaults,
    inside for/if nesting). Anything else fails."""
    try:
        tree = ast.parse(textwrap.dedent(src))
    except SyntaxError:
        return False
    ok = True

    def first_is_wo(call, loopvars):
        if not (isinstance(call.func, ast.Name) and call.func.id == "p" and call.args):
            return False
        a0 = call.args[0]
        if isinstance(a0, ast.Constant) and isinstance(a0.value, str):
            return a0.value.startswith("wo-")
        return isinstance(a0, ast.Name) and a0.id in loopvars

    def check(stmts, loopvars, pvars):
        nonlocal ok
        for st in stmts:
            if isinstance(st, ast.Assign) and len(st.targets) == 1 \
                    and isinstance(st.targets[0], ast.Name) and isinstance(st.value, ast.Call) \
                    and first_is_wo(st.value, loopvars):
                pvars.add(st.targets[0].id)
            elif isinstance(st, ast.Expr) and isinstance(st.value, ast.Call) \
                    and isinstance(st.value.func, ast.Attribute) \
                    and isinstance(st.value.func.value, ast.Name) \
                    and st.value.func.value.id in pvars \
                    and st.value.func.attr in ("add_argument", "set_defaults"):
                pass
            elif isinstance(st, (ast.For, ast.If)):
                extra = set()
                if isinstance(st, ast.For):
                    for n in ast.walk(st.target):
                        if isinstance(n, ast.Name) and isinstance(n.ctx, ast.Store):
                            extra.add(n.id)
                check(st.body, loopvars | extra, pvars)
                check(st.orelse, loopvars | extra, pvars)
            else:
                ok = False

    check(tree.body, set(), set())
    return ok


def top_assigns(py):
    """{name: [Assign nodes]} for top-level `name = ...` statements."""
    out = {}
    for n in tree_of(py).body:
        if isinstance(n, ast.Assign) and len(n.targets) == 1 and isinstance(n.targets[0], ast.Name):
            out.setdefault(n.targets[0].id, []).append(n)
    return out


def check_constants(now_py, old_py):
    """Constants by exact AST value. Returns [bad names]."""
    bad = []
    now_a, old_a = top_assigns(now_py), top_assigns(old_py)

    def one(d, name):
        ns = d.get(name, [])
        return ns[0] if len(ns) == 1 else None

    def lit(node):
        try:
            return ast.literal_eval(node.value)
        except (AttributeError, ValueError, TypeError, SyntaxError, MemoryError, RecursionError):
            return None

    if lit(one(now_a, "WO_KINDS") or ast.Expr(value=ast.Constant(None))) != EXPECTED_KINDS:
        bad.append("WO_KINDS")
    if lit(one(now_a, "WO_REQUIRED_CRITERIA") or ast.Expr(value=ast.Constant(None))) != EXPECTED_WO_REQUIRED_CRITERIA:
        bad.append("WO_REQUIRED_CRITERIA")
    for name in EXACT_OLD_CONSTS:
        n, o = one(now_a, name), one(old_a, name)
        if n is None or o is None or ast.dump(n.value) != ast.dump(o.value):
            bad.append(name)
    old_woc = {k: v[0] for k, v in old_a.items() if k.startswith("WOC_")}
    for k, v in now_a.items():
        if not k.startswith("WOC_"):
            continue
        o = old_woc.get(k)
        if o is not None:
            if ast.dump(v[0].value) != ast.dump(o.value):
                bad.append(k)
        elif not _is_pure_re_compile(v[0].value):
            # a 1.6.1-added WOC_* line must be a plain re.compile: anything
            # else (WOC_X = ..., code smuggled into the name) fails
            bad.append(k)
    return bad


def _is_pure_re_compile(node):
    """re.compile(<str>[, re.<flag>]): no attribute, subscript or call smuggle."""
    if not (isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute)
            and isinstance(node.func.value, ast.Name) and node.func.value.id == "re"
            and node.func.attr == "compile" and not node.keywords):
        return False
    for a in node.args:
        if isinstance(a, ast.Constant):
            continue
        if isinstance(a, ast.Attribute) and isinstance(a.value, ast.Name) and a.value.id == "re":
            continue
        return False
    return bool(node.args)


def skipped_hygiene(py):
    """Skipped helpers must be plain: no decorators, only constant defaults."""
    bad = []
    for n in tree_of(py).body:
        if not (isinstance(n, ast.FunctionDef) and n.col_offset == 0 and n.name.startswith(SKIP_DEF)):
            continue
        if n.decorator_list:
            bad.append(n.name)
            continue
        for d in list(n.args.defaults) + [x for x in n.args.kw_defaults if x is not None]:
            if not isinstance(d, ast.Constant):
                bad.append(n.name)
                break
    return bad


def kept_lines(py):
    """Kept lines: everything outside skipped def bodies (exact AST boundaries)
    and outside the constant statements below, minus the wo-parser block and
    the import delta. Blank lines are ignored: removing a skipped def leaves
    its padding behind, which carries no meaning. A line shared with another
    top-level statement (a `;` smuggle) is never skipped."""
    py = strip_wo_parsers(py)
    tree = tree_of(py)
    const_names = {"WO_KINDS", "WO_REQUIRED_CRITERIA"} | set(EXACT_OLD_CONSTS)
    ranges = [(n.lineno - 1, n.end_lineno) for n in tree.body]

    def shared(i):
        return sum(1 for a, b in ranges if a <= i < b) > 1

    skip = set()
    for n in tree.body:
        if isinstance(n, ast.FunctionDef) and n.col_offset == 0 and n.name.startswith(SKIP_DEF):
            skip.update(range(n.lineno - 1, n.end_lineno))
        elif isinstance(n, ast.Assign) and len(n.targets) == 1 and isinstance(n.targets[0], ast.Name) \
                and (n.targets[0].id in const_names or n.targets[0].id.startswith("WOC_")):
            skip.update(range(n.lineno - 1, n.end_lineno))
    skip = {i for i in skip if not shared(i)}
    out = []
    for i, l in enumerate(py.splitlines()):
        if i in skip or not l.strip():
            continue
        out.append(l)
    return "\n".join(out).replace(", contextlib", "").replace(", io", "")


def strip_wo_parsers(text):
    """Drop the contiguous wo-parser block (wo-check line through wo-sendback line)."""
    lines, out, skip = text.splitlines(), [], False
    for l in lines:
        s = l.strip()
        if re.match(r"^(s = )?p\(\"wo-check\"", s):
            skip = True
        if skip:
            if re.match(r"^(s = )?p\(\"wo-sendback\"", s):
                skip = False
            continue
        out.append(l)
    return "\n".join(out)


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else CRIT_PATH
    now_py = tool_text(open(path).read())
    old_md = subprocess.run(["git", "show", f"v1.6.0:{OLD_CRIT_MD}"],
                            capture_output=True, text=True)
    if old_md.returncode:
        print("CRIT-1.5-CHANGED (cannot read v1.6.0 text)")
        return 1
    old_py = block(old_md.stdout)
    now_f, old_f = defs(now_py), defs(old_py)
    bad = []
    for n in sorted(now_f):
        if n.startswith(SKIP_DEF):
            continue
        mine, theirs = now_f[n], old_f.get(n)
        if n == "main" and theirs is not None:
            mine, theirs = strip_wo_parsers(mine), strip_wo_parsers(theirs)
        if theirs is None or mine != theirs:
            bad.append(n)
    bad += sorted(n for n in old_f if not n.startswith(SKIP_DEF) and n not in now_f)
    if not parser_block_ok(parser_block_src(now_py)):
        bad.append("parsers")
    bad += check_constants(now_py, old_py)
    bad += skipped_hygiene(now_py)
    if kept_lines(now_py) != kept_lines(old_py):
        bad.append("module-text")
    if bad:
        print("CRIT-1.5-CHANGED " + " ".join(sorted(set(bad))))
        return 1
    kept = sorted(n for n in now_f if not n.startswith(SKIP_DEF))
    print(f"CRIT-1.5-UNCHANGED {len(kept)} functions")
    return 0


if __name__ == "__main__":
    sys.exit(main())
