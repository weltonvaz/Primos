import os

def cls():
    os.system('cls' if os.name=='nt' else 'clear')

cls()

a = 110503
b = 132050
	
for x in range(a,b,2):
	teste = divmod(2**x,x)
	if teste[1] == 2:
		print(x)
