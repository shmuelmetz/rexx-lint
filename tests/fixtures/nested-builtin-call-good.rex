/* Fixture: single calls, a call whose first argument is a plain
 * variable, and a nested call that isn't the *first* argument --
 * none of these are the immediately-nested pattern this check
 * targets, so it should find nothing. */

x = strip(y)
z = translate(y, 'b', 'a')
w = translate(y, strip(a))
v = myroutine(strip(y))
