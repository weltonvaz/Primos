#!/usr/bin/python
#-*- coding: UTF-8 -*-

import os
os.system('clear')

from sympy import isprime

for x in range(79847800,79847850):
	if isprime(x) == True:
		print(x)

