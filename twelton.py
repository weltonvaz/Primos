#!/usr/local/bin/python3
# Teorema de Welton - versão 01/2015
import os
os.system("clear")

vprimo = int(input("Digite um número: "))

vpar = int((vprimo - 1) / 2)

vverifica = 0

for vfator in str(vpar):
	vverifica += int(vfator)
	
while vverifica == 0:
	if ((vpar - vverifica)+(vpar + vverifica)) == vpar:
		print ("True")
	else:
		print("False")
		vverifica = vverifica - 1
		
		
	
