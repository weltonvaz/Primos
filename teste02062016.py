import os
os.system('clear')

for x in range(4,1000):
	if x % 3 == 0 and x % 8 == 0 and x % 24 == 0:
		print(x)
