import os
os.system('clear')

x = 9216
lista = []
lista1 = []

for x in range(1,x):
    if x % 96 == 0:
        if x % 24 == 0:
            if x % 4 == 0:
                lista.append(x)

for y in range(0,len(lista)):
    d = bin(lista[y])
    if (d.count('0')-1) == 7 and (d.count('1')) == 6:
        lista1.append(lista[y])

print("Quantidade de numeros na lista: ", len(lista))
print("Quantidade de numeros na lista1: ",len(lista1))