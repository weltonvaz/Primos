#!/usr/bin/python
#-*- coding: UTF-8 -*-

import os
os.system('clear')

a = 2**79847809-1

import pickle
pickle.dump(str(a), open("m79847809.p", "wb"))

