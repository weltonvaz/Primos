def convert(decimal,newBase,str,letters):
        if decimal >= newBase:
                x = decimal % newBase
                y = decimal / newBase   
                str = letters[x] + str
                if y < newBase:
                        str = letters[y] + str
                return convert(y,newBase,str,letters)   
        else:
                if len(str) == 0:
                        str = letters[decimal] + str
                return str
let = "01"
print(convert(31,2,"",let))
