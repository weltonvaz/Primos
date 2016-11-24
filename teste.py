import os
os.system('clear')

n = [2, 3, 5, 7, 13, 17]

with open("estudowelton.txt", "a") as arq:
    for x in range (1,len(n)):
        a = (2**(n[x]))-1
        b = (2**(n[x-1]))-1
        c = a - b
        d = bin(c)

        print('P%s;' %(n[x]))
        print(str(d.count('1')),end='')
        print(str(d.count('0')-1),end=' ')
        
        
        
        
             
arq.close()
        
                
		
