#! /usr/bin/python

from millerrabin import *
import os
os.system("clear")


primos = [n for n in range(2, 1000000) if is_prime(n)]

grupo1 = []
grupo2 = []
grupo3 = []
grupo4 = []

contador = 1

for x in primos:
	if contador == 1:
		grupo1.append(x)
	elif contador == 2:
		grupo2.append(x)
	elif contador == 3:
		grupo3.append(x)
		contador = 0
	
	contador += 1

print("Tenhos na lista ",len(primos)," elementos")
print("Grupo1 tem ", len(grupo1))
print("Grupo2 tem ", len(grupo2))
print("Grupo3 tem ", len(grupo3))

