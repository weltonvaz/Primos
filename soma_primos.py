#! /usr/bin/python

from millerrabin import *
import os
os.system("clear")


primos = [n for n in range(3000, 4000) if is_prime(n)]

grupo1 = 0
grupo2 = 0
grupo3 = 0

contador = 1

for x in primos:
	if contador == 1:
		grupo1 += x
	elif contador == 2:
		grupo2 += x
	elif contador == 3:
		grupo3 += x
		contador = 0
	
	contador += 1

print("Tenhos na lista ",len(primos)," elementos")
print("Grupo1 tem ", grupo1)
print("Grupo2 tem ", grupo2)
print("Grupo3 tem ", grupo3)

