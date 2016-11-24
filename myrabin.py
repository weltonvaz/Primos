import os
os.system('clear')

from sympy import isprime

n = 63

def ehprimo(n):
    if isprime(n) == True:
        return n
    else:
        n += 2

while True:
    d = divmod(2**(n-1),n)
    if d[1] == 1:
        break
    else:
        ehprimo(n)

os.system('clear')
print(n)