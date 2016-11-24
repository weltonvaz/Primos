#! /usr/bin/python
os.system("clear")

import sympy import isprime

xhums = 0
yzero = 521
prime = 521
anter = 0

while True:
    d = int('0b' + '1'*xhums + '0'*yzero,2)
    anter = prime + d
    if isprime() == True:
        print()
    else:
