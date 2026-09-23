/* bif-signature-bad.rex -- each numbered call is a genuine signature error. */
x = 'hello world'
a = substr(x)                  /* 1: too few arguments */
b = length(x, 2)               /* 2: too many arguments */
c = left(x,, 'p')              /* 3: required argument 2 omitted */
d = substr(x, 0, 3)            /* 4: position must be > 0 */
e = left(x, -1)                /* 5: length must not be negative */
f = abs('abc')                 /* 6: not a number */
g = strip(x, 'Z')              /* 7: not an option letter */
h = center(x, 2.5)             /* 8: not a whole number */
