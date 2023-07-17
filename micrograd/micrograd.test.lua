local Value = (require "micrograd.engine").Value

a = Value(-4.0)
b = Value(2.0)
c = a + b
d = a * b + b ^ 3
c = c + c + 1
c = c + c + 1 + (-a)
d = d + d * 2 + (b + a):relu()
d = d + 3 * d + (b - a):relu()
e = c - d
f = e ^ 2
g = f / 2.0
g = g + 10.0 / f
assert(string.format("%.4f", g.data) == "24.7041")
g:backward()
assert(string.format("%.4f", a.grad) == "138.8338")
assert(string.format("%.4f", b.grad) == "645.5773")
