import os

def cls():
    os.system('cls' if os.name=='nt' else 'clear')

cls()

from sympy import divisors, divisor_count

maior = 0
number = 0

for x in range(1,100):
	num = int(divisor_count(x))
	if num > maior:
		maior = num
		number = x
