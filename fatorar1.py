#!/usr/bin/python

import os

def cls():
    os.system('cls' if os.name=='nt' else 'clear')

cls()

def get_prime_factors(number):
    """
    Return prime factor list for a given number
        number - an integer number
        Example: get_prime_factors(8) --> [2, 2, 2].
    """
    if number == 1:
        return []

    # We have to begin with 2 instead of 1 or 0
    # to avoid the calls infinite or the division by 0
    for i in range(2, number):
        # Get remainder and quotient
        rd, qt = divmod(number, i)
        if not qt: # if equal to zero
            return [i] + get_prime_factors(rd)

    return [number]

print(get_prime_factors(42))
