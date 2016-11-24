import os
os.system("clear")
from sympy import isprime

x = 1
y = 607

while True:
    c = int('0b'+'1'*x+'0'*y,2)
    d = divmod(c,8)
    if d[1] == 0:
        print(x)
        break
    else:
        x += 1