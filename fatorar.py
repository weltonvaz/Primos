#!/usr/bin/python

import os

def cls():
    os.system('cls' if os.name=='nt' else 'clear')

cls()

def primes(n):
    if n < 2: return
    yield 2
    plist = [2]
    for i in range(3,n):
        test = True
        for j in plist:
            if j>n**0.5:
                break
            if i%j==0:
                test = False
                break
        if test:
            plist.append(i)
            yield i

def pfactors(n):
    for p in primes(n):
        while n%p==0:
            yield p
            n=n//p
            if n==1: return

list(pfactors(99999))
	
