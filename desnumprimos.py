#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os

def cls():
    os.system('cls' if os.name=='nt' else 'clear')

cls()

for x in range(1,10):
	a = str(1)*x
	print((int(a)))
