/* rexx-lint.rex -- entry point for the rexx-lint static analysis tool.
 *
 * Usage:
 *   rexx rexx-lint.rex [options] file.rex [file2.rex ...]
 *
 * Options:
 *   --dialect=DIALECT   Target dialect (accepted, not yet used to vary
 *                       check behavior -- see README.md's "Dialect
 *                       support" section). Default: oorexx.
 *   --checks=A,B,C      Run only these checks (by name), ignoring the
 *                       default full set.
 *   --disable=A,B,C     Run the default full set except these checks.
 *   --config=PATH       Read the active-check list from PATH instead
 *                       of the default .rexxlintrc (see below).
 *
 * --checks and --disable are mutually exclusive with each other, but
 * either one on the command line overrides a config file. With
 * neither given, a config file is used if one is found -- either the
 * path given via --config=, or, failing that, a file named
 * .rexxlintrc in the current directory. With no CLI selection and no
 * config file, every check runs (today's default set). See
 * lib/CheckSelector.cls for the selection logic itself.
 *
 * .rexxlintrc format: one check name per line; blank lines and lines
 * starting with "#" are ignored. Each name listed is enabled; a name
 * not listed is not run. Example:
 *
 *   # active checks for this project
 *   shadowed-special-vars
 *   keyword-as-variable
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

  dialect = 'oorexx'
  files = .Array~new
  onlyList = ''
  disableList = ''
  configPath = ''

  args = argLine~space~makeArray(' ')
  do a over args
     select
        when a~length > 10, a~substr(1, 10)~caselessEquals('--dialect=') then
           dialect = a~substr(11)
        when a~length > 9, a~substr(1, 9)~caselessEquals('--checks=') then
           onlyList = a~substr(10)
        when a~length > 10, a~substr(1, 10)~caselessEquals('--disable=') then
           disableList = a~substr(11)
        when a~length > 9, a~substr(1, 9)~caselessEquals('--config=') then
           configPath = a~substr(10)
        otherwise
           files~append(a)
     end
  end

  if files~items == 0 then do
     say 'usage: rexx rexx-lint.rex [--dialect=DIALECT] [--checks=A,B,...]' ,
         || ' [--disable=A,B,...] [--config=PATH] file.rex [file2.rex ...]'
     return 2
  end

  allChecks = .Array~of(.ShadowedSpecialVars~new, .KeywordAsVariable~new, ,
     .SignalControlFlow~new, .BackslashEscape~new, .StemParenExpression~new, ,
     .StemCountLoop~new, .NestedBuiltinCall~new)

  checks = .CheckSelector~select(allChecks, onlyList, disableList, configPath)

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
