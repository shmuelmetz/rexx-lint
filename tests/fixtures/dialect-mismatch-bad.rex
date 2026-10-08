/* Fixture: ooRexx-only syntax, which a classic-Rexx file cannot use. */
x = 'abc'~upper
y = x~~reverse
z = x[1]
say .true
::routine helper
  return 1
