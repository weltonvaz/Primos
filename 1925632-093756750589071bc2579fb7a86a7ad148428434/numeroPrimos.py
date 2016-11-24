# -*- coding: latin1 -*-
from math import sqrt
from time import time

'''
   Implementar uma função que retorne verdadeiro se o 
   número for primo (falso caso contrário). Testar de 1 a 100.
'''

# verifica se o número é um valor inteiro
# serve para validar uma raíz quadrada exata

def checkIntNumber(n):
	return int(n) == n

# um número primo possui apenas 2 divisores: 1 e ele mesmo
# teste de força bruta, caso encontre 2 divisões, diz que o número não é primo

def verificaNumeroPrimoV1(n, showStatusFlag=False):
	if n == 2:
		return True
	elif (n == 1) or (n % 2 == 0) or (checkIntNumber(sqrt(n))):
		return False
	else:
		primoFlag = True
		limite = int(sqrt(n))

		if limite % 2 == 0:
			d = limite + 1
		else:
			d = limite
		o = n / d
		if (o <= d):
			return primoFlag

		d = 1 
		divisoes = 0
		count = 0
		while (d <= limite) and (divisoes <= 2):
			count = count + 1			
			if (n % d == 0):				
				divisoes = divisoes +1
				if (divisoes == 2) and (d != n):
					primoFlag = False
					break
			d = d + 2
		
		if showStatusFlag:
			print 'n:', n, 'd:', d, 'count:', count, 'divisoes:', divisoes
		
		return primoFlag

#---------------------------------------------------------------

# para validar se é número primo testa se o Quociente é menor que o Divisor
# este algoritmo é mais rápido para validar um número primo, quando este número
# é realmente um número primo
# obs.: número impar com raíz quadrada não é primo

def verificaNumeroPrimoV2(n, showStatusFlag=False):
	if n == 2:
		return True
	elif (n == 1) or (n % 2 == 0) or (checkIntNumber(sqrt(n))):
		return False
	else:
		primoFlag = True
		limite = int(sqrt(n))

		if limite % 2 == 0:
			d = limite + 1
		else:
			d = limite
		o = n / d
		if (o <= d):
			return primoFlag

		d, o, r = 1, 0, 0

		divisoes = 0
		count = 0
		while (d <= limite) and (divisoes <= 2):
			count = count + 1
			
			r = n % d
			
			if (r == 0):				
				divisoes = divisoes +1
				if (divisoes == 2) and (d != n):
					primoFlag = False
					break			
			else:
				o = n / d
				if (o <= d):
					primoFlag = True
					break

			d = d + 2
			
		if showStatusFlag: 
			print 'n:', n, 'd:', d, 'o:', o, 'r:', r, 'count:', count, 'divisoes:', divisoes
		return primoFlag

#---------------------------------------------------------------

def primos(max):
	primosArr = []
	for i in range(1, max+1):		
		if verificaNumeroPrimoV1(i):
			primosArr.append(i)
			print i, True
		else:
			print i, False
	return primosArr

#---------------------------------------------------------------

# primo
#checkValue = 13000011000001
#checkValue = 889177
#checkValue = 13
#checkValue = 29
#checkValue = 31

# não primos
#checkValue = 889181
#checkValue = 91
#checkValue = 8111
#checkValue = 65788321
#checkValue = 533609071631

# não é primo, mas demora para validar
#checkValue = 11111111111111111

# verificação da performance dos 2 algoritmos de validação
'''
t0 = time()
print verificaNumeroPrimoV1(checkValue, True)
t1 = time()
print verificaNumeroPrimoV2(checkValue, True)
t2 = time()

print 'function verificaNumeroPrimoV1 takes %f' %(t1-t0)
print 'function verificaNumeroPrimoV2 takes %f' %(t2-t1)

print sqrt(checkValue)
print checkIntNumber(sqrt(checkValue))
'''

# foi solicitado até 100, porém aumentei um pouco além hehe
tp1 =time()
print primos(100000)
tp2 = time()
print 'function primos takes %f' %(tp2-tp1)

# tempo de execução
# function primos takes 1.193354
