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


# ---- swap races (Task 4): the folder is swapped between its lstat and its open ----
def rig(wid="jobx"):
    """A fresh HOME holding one locked-looking job and a decoy with a canary. Returns (D, job, rec, decoy)."""
    t = fresh()
    os.environ["HOME"] = str(t / "home")
    job = t / "home" / "superfix-workorders" / wid
    (job / "work" / "sub").mkdir(parents=True)
    (job / "work" / "sub" / "data.csv").write_text("x")
    (job / "work" / "top.csv").write_text("x")
    (job / "workorder.md").write_text("WORK-ORDER: " + wid + "\n")
    D = t / "run"
    (D / "workorder" / "folder").mkdir(parents=True)
    (D / "workorder" / "folder" / "workorder.md").write_text("WORK-ORDER: " + wid + "\n")
    decoy = t / "decoy"
    (decoy / wid / "work").mkdir(parents=True)
    (decoy / wid / "work" / "canary.csv").write_text("canary")
    (decoy / "work").mkdir()
    (decoy / "work" / "canary.csv").write_text("canary")
    s = os.stat(job)
    return D, job, (s.st_dev, s.st_ino), decoy


def swapping(name, action):
    """Run `action` once, just before crit opens a path called `name`."""
    real_open, fired = os.open, []

    def wrapped(path, flags, *a, **k):
        if path == name and not fired:
            fired.append(1)
            action()
        return real_open(path, flags, *a, **k)
    return wrapped


def run_clean(D, wid, rec, name, action):
    real_open = os.open
    os.open = swapping(name, action)
    try:
        log = []
        return crit.woc_clean_job(D, wid, rec, log), log
    finally:
        os.open = real_open


def decoy_ok(*files):
    return all(f.read_text() == "canary" for f in files)


@case
def clean_job_plain():
    D, job, rec, _ = rig()
    kept = crit.woc_clean_job(D, "jobx", rec, [])
    assert kept == [] and not job.exists() and job.parent.is_dir(), kept


@case
def job_inode_mismatch_refused():
    D, job, rec, _ = rig()
    kept = crit.woc_clean_job(D, "jobx", (rec[0], rec[1] + 1), [])
    assert kept and "not the one Superfix made" in kept[0][1] and (job / "work" / "top.csv").exists(), kept


def race_base_link(legacy=False):
    D, job, rec, decoy = rig()
    base = job.parent

    def act():
        os.rename(base, base.parent / "moved")
        os.symlink(decoy, base)
    kept, _ = run_clean(D, "jobx", None if legacy else rec, "superfix-workorders", act)
    assert kept and decoy_ok(decoy / "jobx" / "work" / "canary.csv"), kept
    assert (base.parent / "moved" / "jobx" / "work" / "top.csv").exists()


def race_job_link(legacy=False):
    D, job, rec, decoy = rig()

    def act():
        os.rename(job, job.parent / "aside")
        os.symlink(decoy / "jobx", job)
    kept, _ = run_clean(D, "jobx", None if legacy else rec, "jobx", act)
    assert kept and decoy_ok(decoy / "jobx" / "work" / "canary.csv"), kept


def race_job_real_decoy(legacy=False):
    D, job, rec, decoy = rig()

    def act():
        os.rename(job, job.parent / "aside")
        shutil.copytree(decoy / "jobx", job)
    kept, _ = run_clean(D, "jobx", None if legacy else rec, "jobx", act)
    assert kept and decoy_ok(job / "work" / "canary.csv"), kept


def race_subdir_link(legacy=False):
    D, job, rec, decoy = rig()
    sub = job / "work" / "sub"

    def act():
        os.rename(sub, job / "work" / "sub-aside")
        os.symlink(decoy / "work", sub)
    kept, _ = run_clean(D, "jobx", None if legacy else rec, "sub", act)
    assert kept and decoy_ok(decoy / "work" / "canary.csv"), kept


def race_subdir_real_decoy(legacy=False):
    D, job, rec, decoy = rig()
    sub = job / "work" / "sub"

    def act():
        os.rename(sub, job / "work" / "sub-aside")
        shutil.copytree(decoy / "work", sub)
    kept, _ = run_clean(D, "jobx", None if legacy else rec, "sub", act)
    assert kept and decoy_ok(sub / "canary.csv"), kept



def reg(fn, legacy):
    def t():
        fn(legacy)
    t.__name__ = fn.__name__ + ("_legacy" if legacy else "")
    case(t)


# Note: the race-*-link tests pass with or without O_NOFOLLOW in woc_fd_child, because the lstat/fstat
# compare also refuses a swapped-in link. O_NOFOLLOW is a second guard that these tests do not isolate.
for _f in (race_base_link, race_job_link, race_job_real_decoy, race_subdir_link, race_subdir_real_decoy):
    reg(_f, False)
    reg(_f, True)  # no inode in the lock (a job from an older version): only the lstat/fstat compare protects


@case
def no_dirfd_refuses():
    D, job, rec, _ = rig()
    real_ok = crit.woc_fd_ok
    crit.woc_fd_ok = lambda: False
    try:
        kept = crit.woc_clean_job(D, "jobx", rec, [])
    finally:
        crit.woc_fd_ok = real_ok
    assert kept and "cannot delete safely" in kept[0][1] and (job / "work" / "top.csv").exists(), kept


if __name__ == "__main__":
    shutil.rmtree(TMP, ignore_errors=True)
    print("RESULT: %d passed, %d failed" % (passed, failed))
    sys.exit(1 if failed else 0)
