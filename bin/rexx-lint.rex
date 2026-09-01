/* rexx-lint.rex -- entry point for the rexx-lint static analysis tool.
 *
 * Usage:
 *   rexx rexx-lint.rex [--dialect=DIALECT] file.rex [file2.rex ...]
 *
 * DIALECT is accepted but not yet used to vary check behavior --
 * see README.md's "Dialect support" section. Default: oorexx.
 *
 * Requires the Rexx Parser (Josep Maria Blasco,
 * https://github.com/JosepMariaBlasco/rexx-parser) to be reachable
 * via the program search path -- run that project's own setenv
 * script first, or otherwise add its bin/ directory to PATH.
 */

parse arg argLine
exit main(argLine)

::requires 'Rexx.Parser.cls'
::requires 'Diagnostic.cls'
::requires 'ShadowedSpecialVars.cls'
::requires 'KeywordAsVariable.cls'

::routine main
  use strict arg argLine

  dialect = 'oorexx'
  files = .Array~new

  args = argLine~space~makeArray(' ')
  do a over args
     if a~length > 10, a~substr(1, 10)~caselessEquals('--dialect=') then
        dialect = a~substr(11)
     else
        files~append(a)
  end

  if files~items == 0 then do
     say 'usage: rexx rexx-lint.rex [--dialect=DIALECT] file.rex [file2.rex ...]'
     return 2
  end

  checks = .Array~of(.ShadowedSpecialVars~new, .KeywordAsVariable~new)

  totalFindings = 0
  do file over files
     totalFindings = totalFindings + lintFile(file, dialect, checks)
  end

  if totalFindings > 0 then return 1
  return 0

::routine lintFile
  use strict arg file, dialect, checks

  parser = .Rexx.Parser~new(file)

  findingCount = 0
  do check over checks
     diagnostics = check~run(parser)
     do d over diagnostics
        say file':'d~format
        findingCount = findingCount + 1
     end
  end

  return findingCount
