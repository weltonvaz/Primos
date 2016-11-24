import multiprocessing as mp

def grava(x):
	arq = open('listapn.txt', 'w')
	arq.write(str(x)+'\n')
	arq.close()

def foo(q):
    q.put('hello')

if __name__ == '__main__':
    mp.set_start_method('spawn')
    q = mp.Queue()
    p = mp.Process(target=foo, args=(q,))
    p.start()
    print(q.get())
    p.join()