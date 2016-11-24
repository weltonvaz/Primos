import os
os.system('clear')

from sympy import isprime

b = 74207281

for x in range(90529001,90530000,2):
   if isprime(x) == True:
	   c = x - b
	   d = divmod(c,8)
	   if d[1] == 0:
		   e = 2**x-1
		   f = str(e)
		   if f[-1] == '7' or f[-1] == '1':
			   print(x,"==",c)
