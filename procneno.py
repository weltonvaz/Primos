#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
os.system('clear')

from sympy import divisors, divisor_count, isprime

a = 2**57885161
n1 = divmod(a,2**61)
n2 = divmod(a,2**31)
n3 = divmod(a,2**19)
n4 = divmod(a,2**17)
sn = n1[0]*n2[0]*n3[0]*n4[0]

while True:
	d = divmod(sn,8)
	e = bin(d[0])
	f = e.count('0')-1
	if isprime(f) == True:
		print(f)
		break
	
print("Não achei nada")
