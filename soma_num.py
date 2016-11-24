import os
os.system('clear')

vpar = 18532395500947174450709383384936679868383424444311405679463280782405796233163977
vverifica = 0

for vfator in str(vpar):
	vverifica = vverifica + (int(vfator))**2
	print(vfator)
print (vverifica)
