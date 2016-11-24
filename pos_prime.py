def isprime(num,primes):
    for divi in primes:
        if num%divi == 0:
            return False
    return True

M = 100000

num,counter,primes = 2,1,[]
while counter <= M:
    if isprime(num,primes) == True:
        counter += 1
        print(num)
        primes.append(num)
    num += 1


