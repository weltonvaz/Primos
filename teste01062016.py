from sympy import isprime

for x in range(2,101):
    a = 2**x-1
    b = 2**x
    c = a+b
    if int(str(c)[-1]) == 7 and isprime(c) == True:
        print(x,"-->",c)
