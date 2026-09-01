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
 * Exit codes: 0 = clean, 1 = at least one finding, 2 = no files given
 * (usage error), 3 = at least one file could not be parsed at all
 * (invalid Rexx, or not Rexx source). A file that fails to parse is
 * reported and skipped -- it does not abort the rest of the run.
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
  parseFailures = 0
  do file over files
     result = lintFile(file, dialect, checks)
     if result < 0 then parseFailures = parseFailures + 1
     else totalFindings = totalFindings + result
  end

  if parseFailures > 0 then return 3
  if totalFindings > 0 then return 1
  return 0

/* lintFile -- parse and check one file. Returns the finding count on
 * success, or -1 if the file could not be parsed at all (invalid
 * Rexx, or genuinely not Rexx -- e.g. a .cmd file routed to a
 * different interpreter via "extproc perl"; real-world testing
 * against 111 files from an actual ArcaOS-era script collection
 * found over a third weren't Rexx source at all, which crashed the
 * *entire* multi-file run before this trap was added, since
 * .Rexx.Parser~new raises an uncaught SYNTAX condition that
 * otherwise propagates straight past the caller's own DO loop). The
 * SIGNAL ON SYNTAX trap is set fresh on each call, so a failure here
 * is caught within this one file's processing and never reaches
 * main's loop -- the next file is still attempted. */
::routine lintFile
  use strict arg file, dialect, checks

  signal on syntax name ParseFailed

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

ParseFailed:
  cond = condition('O')
  say file': could not parse ('cond~message')'
  return -1
