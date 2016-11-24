#coding: utf8
# Programa para fins didáticos, para usar a raiz quadrada
# em seus programas use o método sqrt do módulo math
from __future__ import division

def raizq(x, chute = 1, i =20):
    # Calcula uma aproximação da raiz quadrada x após i iterações
    if i < 1:
        raise ValueError("É necessário pelo menos uma iteração")
    if chute < 1:
        chute = 1 # O chute precisa ser maior ou igual a 1, senão o resultado será incorreto
    if x < 0:
        return complex(0, raizq(-x, chute, i)) # A raíz quadrada de um número negativo é um número complexo
    else:
        for k in range(i):
            chute = 1/2*(chute+x/chute)
        return chute
