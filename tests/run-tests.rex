/* run-tests.rex -- fixture-based regression tests for rexx-lint.
 *
 * Requires the Rexx Parser to be on the program search path (run
 * its setenv script first). Run from anywhere; paths below are
 * relative to this file's own directory.
 */

parse arg argLine
exit main(argLine)

::requires 'Rexx.Parser.cls'
::requires 'Diagnostic.cls'
::requires 'ShadowedSpecialVars.cls'

::routine main
  use strict arg argLine

  here = filespec('location', .context~package~name)

  failures = 0
  failures = failures + assertFindingCount(here'fixtures\shadowed-vars-bad.rex', 2)
  failures = failures + assertFindingCount(here'fixtures\shadowed-vars-good.rex', 0)

  if failures == 0 then do
     say 'All tests passed.'
     return 0
  end
  say failures 'test(s) failed.'
  return 1

::routine assertFindingCount
  use strict arg file, expectedCount

  parser = .Rexx.Parser~new(file)
  check = .ShadowedSpecialVars~new
  diagnostics = check~run(parser)

  if diagnostics~items == expectedCount then do
     say 'ok  'file' ('expectedCount' finding(s))'
     return 0
  end

  say 'FAIL 'file': expected 'expectedCount' finding(s), got 'diagnostics~items
  do d over diagnostics
     say '     'd~format
  end
  return 1
