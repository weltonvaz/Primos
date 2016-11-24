#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os

def cls():
    os.system('cls' if os.name=='nt' else 'clear')

cls()

from math import exp
import random

for n in range(3,2281,2):
	a = random.randint(1,n-1)
	b = a**(n-1)
	if (b % n) == 1:
		d = divmod(2**(n-1),n)
		if d[1] == 1:
			e = bin(d[0])
			f = e.count('1')
			g = e.count('0')-1
			if f+g >= 25:
				h = str((2**n)-1)
				if 0
					# esta identado
					print(n)
