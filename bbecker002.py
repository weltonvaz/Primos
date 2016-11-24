import os
os.system("clear")
termo = 1

ciclo = int(input("Digite o numero de ciclos da pa: "))

contador = 0
contador2 = 0

x = termo
y = termo
pa=[]
pa2=[]

while ciclo > contador:
      v = [4, 6, 2, 4, 2, 4, 2, 4, 2, 6, 4, 2] 
      tam_v = len(v) 
      elementos = ciclo * tam_v 
      pa = [x + y * v[0]] 
      for n in range(1, elementos): 
               pa.append(pa[-1] + y * v[n % tam_v])

               contador = contador+1

while ciclo > contador2:

     for x in sorted(pa):
          termo2 = x
          a = termo2
          b = termo2

       
          v = [4, 6, 2, 4, 2, 4, 2, 4, 2, 6, 4, 2] 
          tam_v = len(v) 
          elementos = ciclo * tam_v 
          pa2 = [a + b * v[0]] 
          for n in range(1, elementos): 
                   pa2.append(pa2[-1] + b * v[n % tam_v])
               

                   contador2 = contador2+1

print(pa2)
