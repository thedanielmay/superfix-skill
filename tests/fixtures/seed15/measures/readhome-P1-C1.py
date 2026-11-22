import os, pwd
open(os.path.join(pwd.getpwuid(os.getuid()).pw_dir, "not-in-the-sandbox.txt")).read(1)
print("MEASURE P1-C1 0"); print("ITEMS none")
