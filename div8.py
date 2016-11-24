n = 57885161
pm = (2**n)-1

divi = 2**31-1
count = 0

while True:
    p = divmod(pm,divi)
    if p[0] < divi:
        d = bin(p[0])
        e = d[0]
        f = d[1]
        break

    else:
        count += 1
        print(count)
        pm = p[0]

print("Contagem: ", count)
print("Dividendo: ", e)
print("Resto ==>: ", f)
