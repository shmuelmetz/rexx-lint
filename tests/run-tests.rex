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
::requires 'CheckSelector.cls'
::requires 'ShadowedSpecialVars.cls'
::requires 'KeywordAsVariable.cls'
::requires 'SignalControlFlow.cls'
::requires 'BackslashEscape.cls'
::requires 'StemParenExpression.cls'
::requires 'StemCountLoop.cls'
::requires 'NestedBuiltinCall.cls'

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
  failures = failures + assertFindingCount(here'fixtures\backslash-escape-known-limitation.rex', .BackslashEscape~new, 2)
  failures = failures + assertFindingCount(here'fixtures\stem-paren-expression-bad.rex', .StemParenExpression~new, 1)
  failures = failures + assertFindingCount(here'fixtures\stem-paren-expression-good.rex', .StemParenExpression~new, 0)
  failures = failures + assertFindingCount(here'fixtures\stem-count-loop-bad.rex', .StemCountLoop~new, 1)
  failures = failures + assertFindingCount(here'fixtures\stem-count-loop-good.rex', .StemCountLoop~new, 0)
  failures = failures + assertFindingCount(here'fixtures\nested-builtin-call-bad.rex', .NestedBuiltinCall~new, 2)
  failures = failures + assertFindingCount(here'fixtures\nested-builtin-call-good.rex', .NestedBuiltinCall~new, 0)

  /* CheckSelector.cls unit tests -- tested directly in-process rather
   * than via a CLI subprocess. address system does support this (a
   * simple one-argument call works fine, verified via trace i), but
   * a command string with two quoted, backslash-laden path arguments
   * specifically and reproducibly fails silently (rc=0, no output,
   * no error) even though the identical string runs correctly both
   * typed directly and via the child's own ::REQUIRES resolution --
   * confirmed with trace i that the constructed command string
   * itself is byte-for-byte correct either way. Recorded as a real
   * finding in AI-Priming/ooRexx/RULES.md rather than chased further;
   * testing the selection logic directly sidesteps it entirely and
   * is more in keeping with how every other check here is tested. */
  allChecks = .Array~of(.ShadowedSpecialVars~new, .KeywordAsVariable~new, .SignalControlFlow~new)
  failures = failures + assertSelectedNames( ,
     .CheckSelector~select(allChecks, 'shadowed-special-vars', '', ''), ,
     'shadowed-special-vars', '--checks= selects only the named check')
  failures = failures + assertSelectedNames( ,
     .CheckSelector~select(allChecks, '', 'keyword-as-variable', ''), ,
     'shadowed-special-vars signal-control-flow', ,
     '--disable= excludes the named check, keeps the rest')
  failures = failures + assertSelectedNames( ,
     .CheckSelector~select(allChecks, '', '', ''), ,
     'shadowed-special-vars keyword-as-variable signal-control-flow', ,
     'no selection at all returns every check')

  configFile = here'fixtures\sample.rexxlintrc'
  call lineout configFile, '# comment and a blank line follow'
  call lineout configFile, ''
  call lineout configFile, 'signal-control-flow'
  call stream configFile, 'c', 'close'
  failures = failures + assertSelectedNames( ,
     .CheckSelector~select(allChecks, '', '', configFile), ,
     'signal-control-flow', ,
     '--config=PATH selects the names listed in the file, skipping blanks/comments')

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

::routine assertSelectedNames
  use strict arg selectedChecks, expectedNamesBlank, label

  gotNames = ''
  do check over selectedChecks
     gotNames = gotNames check~name
  end
  gotNames = gotNames~strip

  if gotNames == expectedNamesBlank then do
     say 'ok  'label' ('gotNames')'
     return 0
  end

  say 'FAIL 'label': expected ['expectedNamesBlank'], got ['gotNames']'
  return 1
