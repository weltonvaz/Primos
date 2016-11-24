import os

def cls():
    os.system('cls' if os.name=='nt' else 'clear')

cls()

from miller_rabin import *

primos = []

for x in range(2,1001):
	num = (2**x)-1
	if is_prime(num) == True:
		print("%d == %d" %(x,num))
		primos.append(num)
