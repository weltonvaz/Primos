#!/usr/bin/python

import os

def cls():
    os.system('cls' if os.name=='nt' else 'clear')

cls()

def isPrime(p):
    if(p==2): return True
    if(not(p&1)): return False
    return pow(2,p-1,p)==1
a = 13**10**6-1
print(a)
print(isPrime(a))
