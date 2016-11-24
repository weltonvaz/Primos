#!/usr/bin/python

import os

def cls():
    os.system('cls' if os.name=='nt' else 'clear')

cls()

a = 2**79847791-1

print(len(str(a)))
