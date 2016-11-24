#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
os.system('clear')

for x in range(13,101):
	a = divmod(2^x-1,2)
	if a[1]== 1:
		print(x)
