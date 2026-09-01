/* Fixture: SIGNAL used only for condition traps -- should find
 * nothing. */

signal on syntax
signal off syntax
signal on notready name cleanup

call somewhere
exit

cleanup:
  say 'cleaning up'
  exit

somewhere:
  return
