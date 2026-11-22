import csv, hashlib, sys
path = sys.argv[1]
rows = list(csv.DictReader(open(path, newline="", encoding="utf-8")))
seen, items = set(), []
for n, r in enumerate(rows, start=2):
    if r["email"] in seen: items.append(n)
    seen.add(r["email"])
print("MEASURE P1-C1", len(items))
print("ITEMS", " ".join(map(str, items)) or "none")
print("DATA-SHA", hashlib.sha256(open(path, "rb").read()).hexdigest())
print("PASS" if not items else "FAIL")
