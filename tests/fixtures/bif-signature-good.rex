/* bif-signature-good.rex -- valid calls, and calls the check must not judge. */
x = 'hello world'
a = substr(x, 1, 3)
b = left(x, 5, '*')
c = strip(x, 'T')
d = substr(x, n)               /* variable argument: not a constant, skipped */
e = left(x, length(x) - 1)
f = max(1, 2, 3)               /* special-cased BIF */
g = word(x, 2)
call substr x, 2
h = pos('o', x, 5)
i = abs(-3.5)
say wordindex(x, 1)
