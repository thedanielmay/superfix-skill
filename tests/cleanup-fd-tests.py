#!/usr/bin/env python3
"""In-process tests for the descriptor-relative delete helpers in crit.py (superfix-skill#167).
No model, no network. Runs on macOS and Linux, Python 3.9 or newer.
Usage: python3 tests/cleanup-fd-tests.py   (ROOT=<other checkout> tests that checkout's crit.py)"""
import importlib.util, os, pathlib, shutil, stat, sys, tempfile

ROOT = pathlib.Path(os.environ.get("ROOT", pathlib.Path(__file__).resolve().parent.parent))
TMP = pathlib.Path(tempfile.mkdtemp(prefix="cleanup-fd-tests."))
os.environ["HOME"] = str(TMP / "home")
(TMP / "home").mkdir()
spec = importlib.util.spec_from_file_location("crit", ROOT / "skills/superfix/references/crit.py")
crit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(crit)
passed, failed = 0, 0


def case(fn):
    global passed, failed
    name = fn.__name__.replace("_", "-")
    try:
        fn()
        passed += 1
        print("ok  ", name)
    except BaseException as e:  # a failing assert is the signal
        failed += 1
        print("FAIL", name, type(e).__name__, str(e)[:200])
    return fn


def fresh():
    d = TMP / ("t%d" % len(list(TMP.iterdir())))
    d.mkdir()
    return d


@case
def fd_clear_tree():
    d = fresh()
    canary = d / "canary"
    canary.mkdir()
    (canary / "keep.txt").write_text("keep")
    w = d / "work"
    (w / "a" / "b").mkdir(parents=True)
    (w / "a" / "b" / "c.csv").write_text("x")
    os.mkfifo(w / "pipe")
    os.symlink(canary, w / "l")
    fd = os.open(w, os.O_RDONLY | os.O_DIRECTORY)
    try:
        log = []
        kept = crit.woc_fd_clear(fd, str(w), os.fstat(fd).st_dev, log)
    finally:
        os.close(fd)
    assert kept == [], kept
    assert list(w.iterdir()) == [], list(w.iterdir())
    assert (canary / "keep.txt").read_text() == "keep"
    assert any(p.endswith("c.csv") for p in log), log


if hasattr(os, "chflags"):
    @case
    def fd_clear_uchg_kept():
        d = fresh()
        w = d / "work"
        w.mkdir()
        f = w / "locked.txt"
        f.write_text("x")
        os.chflags(f, stat.UF_IMMUTABLE)
        fd = os.open(w, os.O_RDONLY | os.O_DIRECTORY)
        try:
            kept = crit.woc_fd_clear(fd, str(w), os.fstat(fd).st_dev, [])
        finally:
            os.close(fd)
            os.chflags(f, 0)
        assert len(kept) == 1 and "locked.txt" in kept[0][0], kept


@case
def fd_child_link_refused():
    d = fresh()
    (d / "real").mkdir()
    os.symlink(d / "real", d / "lnk")
    fd = os.open(d, os.O_RDONLY | os.O_DIRECTORY)
    try:
        assert crit.woc_fd_child(fd, "lnk") is None
        c = crit.woc_fd_child(fd, "real")
        assert c is not None
        os.close(c)
    finally:
        os.close(fd)


@case
def fd_name_dotdot():
    for bad in ("..", ".", "", "a/b"):
        try:
            crit.woc_fd_name(bad)
        except ValueError:
            continue
        raise AssertionError("accepted " + repr(bad))
    assert crit.woc_fd_name("ok-1") == "ok-1"


@case
def fd_base_link_raises():
    home = pathlib.Path(os.environ["HOME"])
    decoy = fresh()
    os.symlink(decoy, home / "superfix-workorders")
    try:
        try:
            h, b = crit.woc_fd_base()
        except OSError:
            return
        os.close(h)
        if b is not None:
            os.close(b)
        raise AssertionError("opened a linked base")
    finally:
        os.unlink(home / "superfix-workorders")


@case
def fd_id_ok():
    assert crit.woc_id_ok("thedanielmay+repo+x-wo1")
    assert crit.woc_id_ok("a.b")
    for bad in ("..", ".x", "", "a/b", "a b"):
        assert not crit.woc_id_ok(bad), bad


if __name__ == "__main__":
    shutil.rmtree(TMP, ignore_errors=True)
    print("RESULT: %d passed, %d failed" % (passed, failed))
    sys.exit(1 if failed else 0)
