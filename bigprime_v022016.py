#!/usr/bin/python

import os

def cls():
    os.system('cls' if os.name=='nt' else 'clear')

cls()

from sympy import isprime

print(isprime((2**11213)-1))
