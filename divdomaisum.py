import os
os.system('clear')

from sympy import divisors, divisor_count

for n in range(90529000,90529999,2):
   divs = divisors(n)
   a = (2**(n-1))-1
   for x in divs.pop(0):
      d = divmod(a,x)
      if d[1] == 0:
         print(n,'-->',x)
