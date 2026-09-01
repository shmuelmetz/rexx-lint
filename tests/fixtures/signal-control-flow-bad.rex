/* Fixture: SIGNAL used as control flow, not a condition trap. */

signal on syntax
signal off syntax

signal mylabel
exit

label = 'mylabel'
signal value label
exit

mylabel:
  say 'here'
