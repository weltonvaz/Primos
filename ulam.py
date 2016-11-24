import math
import itertools

def primes():
    yield 2
    primesSoFar = [2]
    for candidate in itertools.count(3, 2):
        for prime in (i for i in primesSoFar if i <= int(math.sqrt(candidate))):
            if 0 == candidate % prime:
                break
        else:
            primesSoFar.append(candidate)
            yield candidate

def main():
    for p in primes():
        if p > 100:
            break
        print p,

if __name__ == "__main__":
    main()
