import random
import numpy as np
from sklearn.datasets import make_moons
import matplotlib.pyplot as plt

np.random.seed(1337)
random.seed(1337)

X, y = make_moons(n_samples=100, noise=0.1)
y = y * 2 - 1

plt.figure(figsize=(5, 5))
plt.scatter(X[:, 0], X[:, 1], c=y, s=20, cmap="jet")
plt.savefig("../dataset.png")

with open("../dataset.lua", "w") as f:
    f.write("X = {\n")
    for x in X:
        f.write("  {")
        f.write(str(x[0]))
        f.write(", ")
        f.write(str(x[1]))
        f.write("},\n")
    f.write("}\n")
    f.write("y = {\n")
    for v in y:
        f.write("  ")
        f.write(str(v))
        f.write(",\n")
    f.write("}\n")
