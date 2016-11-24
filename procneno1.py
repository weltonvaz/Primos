#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
os.system('clear')

from sympy import divisors, divisor_count, isprime

a = 2**57885161
n1 = divmod(a,2**43112609)
n2 = divmod(a,2**42643801)
n3 = divmod(a,2**37156667)
n4 = divmod(a,2**32582657)
sn = n1[0]*n2[0]*n3[0]*n4[0]
count = 0
while True:
	d = divmod(sn,8)
	e = bin(d[0])
	f = e.count('0')-1
	if isprime(f) == True:
		print(f)
		break
	else:
		count += 1
		print(count)
	
print("Não achei nada")
