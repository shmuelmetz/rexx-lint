/* Fixture: whether a nested call is flagged depends on the dialect: the
 * outer function must be a string method there; the inner need not be. */

a = translate(strip(y))   /* flagged in ooRexx, OREXX and NetRexx */
b = upper(strip(y))       /* UPPER is a string method in ooRexx and NetRexx, not OREXX */
c = strip(linein(f))      /* outer STRIP is a string method: flagged everywhere */
d = space(arg(1))         /* outer SPACE is a string method: flagged everywhere */
e = linein(strip(f))      /* outer LINEIN is no string method: never flagged */
