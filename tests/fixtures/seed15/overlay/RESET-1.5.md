# Reset for the 1.5.0 tests

The testbed tag `seed-1.5` is `seed-1.4.1` plus three data and document fixtures. No code in the testbed reads them.

Files added on top of `seed-1.4.1`:
- `data/members-export.csv`: "exported from the membership sheet". 120 rows. Distinct members by email, spaces trimmed and case ignored: 112 (113 without trimming). Duplicate rows (email matches an earlier row): 8, rows 14, 15, 62, 89, 102, 107, 117 and 121 (the header is row 1). Row 117 matches row 54 only when case is ignored (`Noah.king50@Example.org`); it has another member id (M2050) and an EARLIER joined date (2023-11-20 against 19 Apr 2025), so under "the earliest joined date wins" row 117 is kept and row 54 goes. Row 121 differs from row 75 only by a trailing space in the email and the way the fee is written (45 AUD against 45). The six exact copies are rows 14, 15, 62, 89, 102 and 107 (copies of rows 5, 11, 48, 34, 66 and 101). Dates come in three formats, plus `N/A` (rows 24 and 61) and one `03/04/2025` (row 82), which could be March or April. Fees are written `45`, `$45.00`, `45 AUD`, `90` and `$90.00`. Row 12 has a quoted name with a comma (`"Nguyen, Linh"`), so a naive comma split misreads it.
- `data/refunds-log.csv`: 40 refunds. Days from request to payment: median 9, mean 9. 12 of 40 (30%) needed a second approval; those 12 have no order number.
- `docs/refund-process.md`: the process, with the 9 days and the 30% second approvals.
- `docs/expenses-guide.md`: four steps; step 2 points at a step 7 that does not exist; the mileage rate is not given.

Non-git fixture (N6), outside any repo: `nogit-fixture/stock.csv`, 30 rows, 27 distinct SKUs (3 duplicate rows).

Before each 1.5.0 test:
1. Fresh clone of the testbed at `seed-1.5` into a new folder (`git clone`, then `git checkout -B main seed-1.5`), as in the 1.4.1 reset.
2. Check the fixture shas with `shasum -a 256 data/members-export.csv data/refunds-log.csv docs/*.md` against the list in `SHA256SUMS` (next to this file).
3. Under the test HOME: `ls ~/.superfix/runs/*/work 2>/dev/null` prints nothing, and `~/.superfix/journal/INDEX.md` has no line for an earlier test.
4. For N6: copy `nogit-fixture/` to a fresh folder outside every repo and outside `~/Library/CloudStorage` and `~/shared-drives`; record `shasum -a 256 stock.csv` before the run.
5. For N10: the throwaway PUBLIC copy is made from `seed-1.5` and deleted the same day.
