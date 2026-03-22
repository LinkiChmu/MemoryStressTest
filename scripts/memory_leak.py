import numpy as np
import time

data = []
for i in range(10):
    print(f"Allocating chunk {i} ...")
    data.append(np.random.rand(10000, 10000)) #  800 Mb
    time.sleep(5)

input("Press Enter to exit ...")