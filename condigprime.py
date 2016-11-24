#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
os.system('clear')

n = [2, 3, 5, 7, 13, 17]

with open("estudowelton.txt", "a") as arq:

	for exp in n[1:len(n)]:
		a = (2**n[exp])-1
		b = (2**n[exp-1])-1
		c = a - b

		d = bin(c)
		
		arq.writelines(str(d.count('1')))
		arq.writelines(';')
		arq.writelines(str(d.count('0')-1))
		arq.writelines(';')

		for x in range(0,10):
			arq.write(str(x))
			arq.writelines(';')
		
		arq.write('\n')
		
arq.close()

