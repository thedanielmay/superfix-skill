# Refund process

Exported from the shared operations folder. No code reads this file.

Refunds take 9 days on average. About 30% of refunds need a second approval, because the refund form has no field for the order number, so the second approver has to look the order up by hand.

1. The customer emails support asking for a refund.
2. Support fills in the refund form (customer name, amount, reason).
3. The finance officer checks the request against the order. If the order cannot be found from the form, the request goes to the finance manager for a second approval.
4. The finance manager approves or rejects it, usually in the Friday batch.
5. Finance pays the refund in the next payment run (Tuesdays and Thursdays).
6. Support emails the customer that the refund has been paid.

The log of every refund is `data/refunds-log.csv` (requested date, paid date, whether a second approval was needed).
