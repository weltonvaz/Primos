#! /usr/bin/python

import os
os.system("clear")
 
#numero = int(input("Digite um numero positivo maior que zero: "))
# numero = int(numero)
def ndivisores(numero):
    resto = numero
     
    if (numero <= 0):
        print ("Numero invalido!")
     
    else:
         
        divisor = 2
        fatores = {}
        n_divisores = 1
     
        #fatorar o numero
        while resto >= 0 and divisor <= resto:
            if( resto % divisor == 0 ):
                #salvar o numero de vezes que cada fator aparece (expoentes)
                if( divisor in fatores ):
                    fatores[divisor] += 1
                else:
                    fatores[divisor] = 1
     
                resto = resto // divisor
            else:
                divisor += 1
         
        #combinacao dos expoentes
        for expoente in fatores.values():
            #soma um ao expoente para considerar o 0 (expoente nao aparecer no multiplo)
            n_divisores *= expoente + 1
     
        return n_divisores

for x in range(1,100):
    print("O numero: %d, tem %d divisores " %(x,ndivisores(x)))
