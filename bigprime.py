import os

def cls():
    os.system('cls' if os.name=='nt' else 'clear')

cls()

import time

ini = time.time()
num = (2**80000033)-1

primosg = open("M80000033.txt","w")
primosg.write(str(num))

primosg.close()
fim = time.time()

print("Tempo decorrido: ", fim-ini)
print("Quantidade digitos:", len(str(num)))
