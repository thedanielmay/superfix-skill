# P1-K1 distinct members, by email with spaces trimmed and case ignored; pass: 112.
import csv, hashlib, sys
path = sys.argv[1]
data = open(path, "rb").read()
rows = list(csv.DictReader(open(path, newline="", encoding="utf-8")))
n = len({r["email"].strip().lower() for r in rows})
print("MEASURE P1-K1", n)
print("ITEMS none")
print("DATA-SHA", hashlib.sha256(data).hexdigest())
print("PASS" if n == 112 else "FAIL")
