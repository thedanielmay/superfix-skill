# P1-C1 duplicate members: rows whose email, with spaces trimmed and case
# ignored, matches an earlier row. Row numbers as the sheet shows them (header = row 1).
import csv, hashlib, sys
path = sys.argv[1]
data = open(path, "rb").read()
rows = list(csv.DictReader(open(path, newline="", encoding="utf-8")))
seen, items = set(), []
for n, r in enumerate(rows, start=2):
    k = r["email"].strip().lower()
    if k in seen:
        items.append(n)
    seen.add(k)
print("MEASURE P1-C1", len(items))
print("ITEMS", " ".join(map(str, items)) or "none")
print("DATA-SHA", hashlib.sha256(data).hexdigest())
print("PASS" if len(items) == 0 else "FAIL")
