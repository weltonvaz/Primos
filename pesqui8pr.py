import os
os.system('clear')

x = 74207281
y = 2

while True:
	d = int(('0b'+ '1'*y + '0'*x),2)
	e = divmod(d,8)
	if e[1] == 0:
		print("PESQUISA FINALIZADA")
		print(y)
		break
	else:
		y += 1
		print(d)
