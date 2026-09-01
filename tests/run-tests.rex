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
::requires 'KeywordAsVariable.cls'
::requires 'SignalControlFlow.cls'
::requires 'BackslashEscape.cls'

::routine main
  use strict arg argLine

  here = filespec('location', .context~package~name)

  failures = 0
  failures = failures + assertFindingCount(here'fixtures\shadowed-vars-bad.rex', .ShadowedSpecialVars~new, 2)
  failures = failures + assertFindingCount(here'fixtures\shadowed-vars-good.rex', .ShadowedSpecialVars~new, 0)
  failures = failures + assertFindingCount(here'fixtures\keyword-as-variable-bad.rex', .KeywordAsVariable~new, 4)
  failures = failures + assertFindingCount(here'fixtures\keyword-as-variable-good.rex', .KeywordAsVariable~new, 0)
  failures = failures + assertFindingCount(here'fixtures\signal-control-flow-bad.rex', .SignalControlFlow~new, 2)
  failures = failures + assertFindingCount(here'fixtures\signal-control-flow-good.rex', .SignalControlFlow~new, 0)
  failures = failures + assertFindingCount(here'fixtures\backslash-escape-bad.rex', .BackslashEscape~new, 3)
  failures = failures + assertFindingCount(here'fixtures\backslash-escape-good.rex', .BackslashEscape~new, 0)

  if failures == 0 then do
     say 'All tests passed.'
     return 0
  end
  say failures 'test(s) failed.'
  return 1

::routine assertFindingCount
  use strict arg file, check, expectedCount

  parser = .Rexx.Parser~new(file)
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
