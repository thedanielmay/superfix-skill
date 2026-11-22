import hashlib, sys
print("ITEMS none"); print("DATA-SHA", hashlib.sha256(open(sys.argv[1], "rb").read()).hexdigest()); print("FAIL")
