/* Fixture: classic Rexx only; .TRUE here is just a constant symbol. */
x = translate('abc')
say x .true
call helper
exit
helper:
  return 1
