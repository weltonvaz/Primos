#! /usr/bin/python
 
numero = raw_input("Digite um numero positivo maior que zero: ")
numero = int(numero)
 
resto = numero
 
if( numero <= 0 ):
    print "Numero invalido!"
 
else:
    divisor = 2
    fatores = {}
    soma_divisores = 1
 
    #fatorar o numero
    while resto >= 0 and divisor <= resto:
        if( resto % divisor == 0 ):
            #salvar o numero de vezes que cada fator aparece (expoentes)
            if( fatores.has_key(divisor) ):
                fatores[divisor] += 1
            else:
                fatores[divisor] = 1
 
            resto = resto // divisor
        else:
            divisor += 1
 
 
    #soma todos os divisores (multiplicacao da progressao geometrica de cada fator)
    for fator, expoente in fatores.items():
        soma_divisores *= (fator**(expoente+1) - 1)/(fator - 1)
 
    print "Soma dos Divisores: %d" % soma_divisores
