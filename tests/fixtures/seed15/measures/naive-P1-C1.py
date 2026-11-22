import hashlib, sys
path = sys.argv[1]
lines = open(path, encoding="utf-8").read().splitlines()[1:]
seen, items = set(), []
for n, l in enumerate(lines, start=2):
    f = l.split(",")
    assert len(f) == 5, "bad row"
    k = f[2].strip().lower()
    if k in seen: items.append(n)
    seen.add(k)
print("MEASURE P1-C1", len(items))
print("ITEMS", " ".join(map(str, items)) or "none")
print("DATA-SHA", hashlib.sha256(open(path, "rb").read()).hexdigest())
print("FAIL")
