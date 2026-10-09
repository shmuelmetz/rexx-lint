/* rexx-lint.rex -- entry point for the rexx-lint static analysis tool.
 *
 * Usage:
 *   rexx rexx-lint.rex [options] file.rex [file2.rex ...]
 *
 * Options:
 *   --dialect=DIALECT   Target dialect for every file given. Checks
 *                       whose advice holds only in some dialects run
 *                       only there (see README.md, "Dialect support").
 *                       Without this flag, each file's OWN extproc or
 *                       shebang line is consulted instead (see
 *                       lib/ExtprocDialect.cls): a file that plainly
 *                       routes to a non-Rexx interpreter (perl,
 *                       python, a shell, ...) is reported and skipped
 *                       before ever reaching the parser, the same way
 *                       a genuine parse failure is; a file naming a
 *                       recognized Rexx interpreter (regina, ...) or
 *                       an unrecognized one that still looks
 *                       Rexx-shaped by name gets that dialect; a file
 *                       with no extproc/shebang line at all -- true
 *                       of every genuine Rexx file in real-world
 *                       testing -- falls back to today's oorexx
 *                       default, same as before this existed.
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
 * (invalid Rexx, not Rexx source, or not found), 4 = rexx-lint itself
 * hit an internal error (a bug in a check or in rexx-lint). A file that
 * fails to parse, and a check that fails on one file, are reported and
 * skipped -- neither aborts the rest of the run.
 *
 * Requires the Rexx Parser (Josep Maria Blasco,
 * https://github.com/JosepMariaBlasco/rexx-parser) to be reachable
 * via the program search path -- run that project's own setenv
 * script first, or otherwise add its bin/ directory to PATH.
 */

parse arg argLine
signal on syntax name InternalError
exit main(argLine)

/* Anything not trapped closer to the problem: report it, don't dump a
 * raw traceback. Exit code 4 means rexx-lint itself failed. */
InternalError:
  cond = condition('O')
  say 'rexx-lint: internal error:' cond~message ,
      '(line' cond~position 'of' filespec('name', cond~program)')'
  exit 4

::requires 'Rexx.Parser.cls'
::requires 'Diagnostic.cls'
::requires 'CheckSelector.cls'
::requires 'ExtprocDialect.cls'
::requires 'DialectParser.cls'
::requires 'ShadowedSpecialVars.cls'
::requires 'KeywordAsVariable.cls'
::requires 'SignalControlFlow.cls'
::requires 'BackslashEscape.cls'
::requires 'StemParenExpression.cls'
::requires 'StemCountLoop.cls'
::requires 'NestedBuiltinCall.cls'
::requires 'BifSignature.cls'
::requires 'DialectMismatch.cls'
::requires 'BooleanComparison.cls'
::requires 'OoRexxSyntax.cls'

::routine main
  use strict arg argLine

  dialect = ''
  dialectGiven = .False
  files = .Array~new
  onlyList = ''
  disableList = ''
  configPath = ''

  args = argLine~space~makeArray(' ')
  do a over args
     select
        when a~length > 10, a~substr(1, 10)~caselessEquals('--dialect=') then do
           dialect = a~substr(11)
           dialectGiven = .True
        end
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
     .StemCountLoop~new, .NestedBuiltinCall~new, .BifSignature~new, ,
     .DialectMismatch~new, .BooleanComparison~new)

  checks = .CheckSelector~select(allChecks, onlyList, disableList, configPath)

  totalFindings = 0
  .local~rexxlint.internalErrors = 0
  parseFailures = 0
  do file over files
     if ¬.File~new(file)~isFile then do
        say file': not found -- skipped'
        parseFailures = parseFailures + 1
        iterate
     end
     fileDialect = dialect
     /* Explicit: named by --dialect or by the file's own extproc/shebang,
      * as opposed to the oorexx fallback for a file that names nothing. */
     explicit = dialectGiven
     if ¬dialectGiven then do
        info = detectDialect(file)
        if info == .Nil then do
           parseFailures = parseFailures + 1
           iterate
        end
        if info~at('ISNONREXX') then do
           if info~at('SOURCE') == 'batch' then
              say file': not Rexx (a batch file: its first line is not a comment) -- skipped'
           else
              say file': not Rexx (' || info~at('SOURCE') || " routes to '" ,
                  || info~at('INTERPRETER') || "') -- skipped"
           parseFailures = parseFailures + 1
           iterate
        end
        if info~at('UNSUPPORTED') ¬== '' then do
           say file': not supported (' || info~at('SOURCE') || ' marks it as' ,
               info~at('UNSUPPORTED') || ', which the Rexx Parser cannot read)' ,
               || ' -- skipped'
           parseFailures = parseFailures + 1
           iterate
        end
        fileDialect = info~at('DIALECT')
        explicit = fileDialect <> ''
        /* Naming no dialect means classic Rexx, unless the code itself
         * turns out to use ooRexx syntax (decided in lintFile). */
        if fileDialect == '' then fileDialect = 'classic'
     end
     fileFindings = lintFile(file, fileDialect, explicit, checks)
     if fileFindings < 0 then parseFailures = parseFailures + 1
     else totalFindings = totalFindings + fileFindings
  end

  if .local~rexxlint.internalErrors > 0 then return 4
  if parseFailures > 0 then return 3
  if totalFindings > 0 then return 1
  return 0

/* lintFile -- parse and check one file. Returns the finding count on
 * success, or -1 if the file could not be parsed at all (invalid
 * Rexx, or genuinely not Rexx -- e.g., a .cmd file routed to a
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
  use strict arg file, dialect, explicit, checks

  signal on syntax name ParseFailed

  source = .ExtprocDialect~sourceWithoutBom(file)
  /* Parsed in the Rexx Parser mode for the dialect (CMS for z/VM, TSO/E
   * and z/OS UNIX; Executor), whether the dialect came from --dialect or
   * from the file's own extproc/shebang line. */
  parser = .DialectParser~parse(file, source, dialect)
  if parser == .Nil then return -1

  findingCount = 0

  /* A file that names no dialect is classic Rexx unless it uses ooRexx
   * syntax; then it is ooRexx, and the ooRexx-only checks apply. Say so,
   * as a note (not counted as a finding), so the advice is not a mystery. */
  if ¬explicit then do
     signs = .OoRexxSyntax~signs(parser)
     if signs~items > 0 then do
        sign = signs[1]
        dialect = 'oorexx'
        explicit = .True
        noteMsg = "dialect inferred as ooRexx from '"sign~text"' ("sign~kind")"
        say file':'.Diagnostic~new(sign~line, sign~column, noteMsg, 'dialect', 'note')~format
     end
  end

  /* The BOM was stripped only so linting can continue. Never silently:
   * ooRexx 5.2 itself rejects a leading BOM in every case tried (before a
   * comment, before code, before a shebang: Error 13.1), and a BOM also
   * hides a first-line comment, extproc or shebang from any interpreter
   * or kernel that expects it at byte 1. So it is reported as a finding. */
  if source ¬== .Nil then do
     bomMsg = 'UTF-8 byte-order mark ignored for linting; interpreters may' ,
        || ' reject it (e.g., ooRexx 5.2: Error 13.1) or miss a first-line' ,
        || ' comment, extproc or shebang that must start at byte 1'
     say file':'.Diagnostic~new(1, 1, bomMsg, 'utf8-bom')~format
     findingCount = findingCount + 1
  end
  found = .Array~new
  do check over checks
     /* A check with an appliesTo method decides for itself whether it
      * applies to this file's dialect; a check without one always does. */
     if check~hasMethod('APPLIESTO') then
        if ¬check~appliesTo(dialect, explicit) then iterate
     found~appendAll(runCheck(check, parser, file))
  end

  /* Report in source order, not grouped by check. */
  found = found~sortWith(.DiagnosticOrder~new)
  do d over found
     say file':'d~format
     findingCount = findingCount + 1
  end

  return findingCount

ParseFailed:
  cond = condition('O')
  say file': could not parse ('cond~message')'
  return -1

/* detectDialect -- .ExtprocDialect~detect with a trap: a file it cannot
 * read or make sense of is reported and skipped (returns .Nil). */
::routine detectDialect
  use strict arg file

  signal on syntax name DetectFailed
  signal on notready name DetectFailed
  return .ExtprocDialect~detect(file)

DetectFailed:
  cond = condition('O')
  say file': could not read the first lines to detect the dialect ('cond~message')'
  return .Nil

/* runCheck -- run one check on one parsed file. An error inside the check
 * is a rexx-lint bug, not a problem with the file: report it as such and
 * let the remaining checks run (returns no findings for this check). */
::routine runCheck
  use strict arg check, parser, file

  signal on syntax name CheckFailed
  return check~run(parser)

CheckFailed:
  cond = condition('O')
  say file': internal error in check' check~name':' cond~message ,
      '(line' cond~position 'of' filespec('name', cond~program)') -- check skipped'
  .local~rexxlint.internalErrors = .local~rexxlint.internalErrors + 1
  return .Array~new

