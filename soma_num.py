import os
os.system('clear')

vpar = 7212610147295474909544523785043492409969382148186765460082500085393519556525921455588705423020751421
vverifica = 0

for vfator in str(vpar):
	vverifica = vverifica + (int(vfator))**2
	print(vfator)
print (vverifica)
