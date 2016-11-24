n = 1257787
pm = (2**n)-1
np = (2**(n-1)*((2**n)-1))

count = 0


while True:
    n = divmod(np,8)
    if n[0] < pm:
        d = bin(n[0])
        e = d.count('1')
        f = d.count('0')-1
        break

    else:
        count += 1
        print(count)
        np = n[0]

print("Contagem: ", count)
print("Digitos 1: ", e)
print("Digitos 0: ", f)
