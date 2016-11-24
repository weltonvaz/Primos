from sympy import isprime

count = 0

for x in range(2,1000001):
    if isprime(x) == True:
        count += 1
    
print(count)
