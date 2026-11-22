# P2-C1 median days from refund request to payment; measured once there are at least 20 refunds.
import csv, datetime, statistics, sys
rows = list(csv.DictReader(open(sys.argv[1], newline="", encoding="utf-8")))
if len(rows) < 20:
    sys.exit(3)   # not measurable yet
d = [(datetime.date.fromisoformat(r["paid"]) - datetime.date.fromisoformat(r["requested"])).days for r in rows]
print("MEASURE P2-C1", statistics.median(d))
print("ITEMS none")
