import os
os.system('clear')

import time
from gmpy2  import is_prime

ini = time.time()

is_prime(2**3217-1)

fim = time.time()
print("Função soma1: ", fim-ini)
