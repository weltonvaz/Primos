#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
os.system('clear')

def grava(x):
	arq = open('listapn.txt', 'w')
	arq.write(str(x)+'\n')
	arq.close()

for x in range(2000,2300):
	c = 2**x
	d = divmod(c,8)
	if d[1] == 0:
		e = bin(c)
		f = e.count('0')-1
		if f == 1279:
			print(x)
			grava(x)
	else:
		print("%d--> Não funciona" %(x))
