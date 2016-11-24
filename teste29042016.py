#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
os.system('clear')

def calculus(x,y):
    lista = []
    a = (2**x)-1
    b = (2**y)-1
    c = a-b
    d = bin(c)
    e = d.count('1')
    f = d.count('0')-1
    lista.append(x)
    lista.append(e)
    lista.append(f)
    lista.append(str(c).count('0'))
    lista.append(str(c).count('1'))
    lista.append(str(c).count('2'))
    lista.append(str(c).count('3'))
    lista.append(str(c).count('4'))
    lista.append(str(c).count('5'))
    lista.append(str(c).count('6'))
    lista.append(str(c).count('7'))
    lista.append(str(c).count('8'))
    lista.append(str(c).count('9'))
        
    return lista

n = [24036583, 25964951, 30402457, 32582657, 37156667, 42643801, 43112609, 57885161]

with open("estudowelton.txt", "a") as arq:
	for exp in range(1,len(n)):
		arq.write(str(calculus(n[exp],n[exp-1])))
		arq.write('\n')

arq.close()

