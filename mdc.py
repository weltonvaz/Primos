#!/usr/bin/python
# -*- coding: iso-8859-15 -*-

# Criado em:Ter 08/Jul/2008 hs 08:09
# Autor: MRSantos mrsantos4@ucs.br

from sys import argv

def mdc(n1, n2):
    if(n1 != 0 and n2 != 0 ):
        if(n1 > n2):
            dividendo = n1
            divisor = n2
        else:
            dividendo = n2
            divisor = n1

        while( dividendo % divisor != 0 ):
            resto = dividendo % divisor
            dividendo = divisor
            divisor = resto
        return divisor

    else:
        print("Os dois valores não podem ser ZEROS!!!")

n1 = 2**17-1 #int(argv[1])
n2 = 2**17   #int(argv[2])

print("Maximo divisor comum de:", n1, "e", n2, "=",  mdc( n1, n2 ))
