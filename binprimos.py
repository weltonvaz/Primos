# -*- coding: UTF-8 -*-
n = 11
np = (2**(n-1))*((2**n)-1)
count = 0

d = 0
e = []
f = 0
g = []

a = bin(np)
b = a.count('1')
c = a.count('0')-1

for x in range(1,c):
    d = int(('0b' + '1' * b + '0' * x),2)
    e.append(d)

print(sum(e))

g.append(1)

for y in range(1,b):
    f = int(('0b1' + '0' * y ),2)
    g.append(f)
print(sum(g))

h = f = int(('0b' + '1' * b ),2)
g.append(h)

wp = (sum(g))+(sum(e))

print(wp == np)
