/* DialectParser.cls -- parses a file with the Rexx Parser in the mode
 * that matches its dialect.
 *
 * z/VM, TSO/E and z/OS UNIX (omvs) files are parsed in the Rexx
 * Parser's CMS mode, and Executor files in its Executor mode. Those
 * modes accept the NOT spellings the dialects allow beyond ooRexx's
 * backslash, 'AA'x and 'AC'x: the slash (/=, /==) and U+00AC encoded in
 * UTF-8, plus the circumflex (^=, ^>, ...) for Executor. Every other
 * dialect is parsed in the default (ooRexx) mode.
 *
 * CMS mode rejects ooRexx syntax such as ~ and ::. So when a file fails
 * to parse in its dialect's mode, it is parsed again in the default mode,
 * and dialect-mismatch can then report the ooRexx syntax the dialect
 * cannot run. Only when that fails too is the file unparseable; the
 * error reported is the one from the dialect's own mode.
 *
 * Source must be in an ASCII-based code page; neither rexx-lint nor the
 * Rexx Parser reads EBCDIC. A mainframe data set is linted after it has
 * been converted; the code translation must convert the logical NOT to
 * 'AA'x or 'AC'x.
 */

::class DialectParser public

/* mode -- the Rexx Parser option for a dialect, or '' for the default. */
::method mode class
  use strict arg dialect
  if 'zvm tso omvs'~caselessWordPos(dialect) > 0 then return 'CMS'
  if dialect~caselessEquals('executor') then return 'EXECUTOR'
  return ''

/* parse -- a .Rexx.Parser for file (source may be .Nil: the parser then
 * loads the file itself). Returns .Nil, after saying why, when the file
 * cannot be parsed in either mode. */
::method parse class
  use strict arg file, source, dialect
  mode = self~mode(dialect)
  if mode == '' then return .Rexx.Parser~new(file, source)

  signal on syntax name ModeFailed
  return .Rexx.Parser~new(file, source, .Array~of(.Array~of(mode, 1)))

ModeFailed:
  modeError = condition('O')~message
  signal on syntax name BothFailed
  return .Rexx.Parser~new(file, source)

BothFailed:
  say file': could not parse ('modeError')'
  return .Nil

::requires 'Rexx.Parser.cls'
