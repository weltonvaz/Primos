import os
os.system('clear')

x = 4
y = 2**859433-1
count = 1

d = divmod((x**2)-2,y)

while d[1] != 0:
    d = divmod((d[1]**2)-2,y)
    count += 1

print("executado, %s vezes" %count)

print("Fim do programa")

