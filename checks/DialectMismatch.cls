/* DialectMismatch.cls -- flags ooRexx-only syntax (~, ~~, [ ], ::
 * directives) in a file explicitly marked as another dialect: classic
 * Rexx, Regina, z/VM, z/OS UNIX (omvs) or TSO/E, whether by --dialect or
 * by the file's own extproc/shebang line. Such code will not run there.
 *
 * Environment symbols (.Array, .true) are not flagged: in those dialects
 * a symbol starting with a period is a legal constant symbol, so it is a
 * different meaning, not a syntax error.
 *
 * One finding per kind of construct, at its first occurrence, with the
 * number of occurrences.
 */

::requires 'Diagnostic.cls'
::requires 'OoRexxSyntax.cls'

::class DialectMismatch public

/* appliesTo -- only for a file explicitly marked as a non-ooRexx dialect;
 * a file that names no dialect is classified by its syntax instead. */
::method appliesTo
  use strict arg dialect, explicit
  return explicit & 'classic regina zvm omvs tso'~caselessWordPos(dialect) > 0

::method name
  return 'dialect-mismatch'

::method run
  use strict arg parser

  diagnostics = .Array~new
  do sign over .OoRexxSyntax~signs(parser, .False)
     msg = "'"sign~text"' ("sign~kind") is ooRexx syntax, not available in" ,
        || " this file's dialect"
     if sign~count > 1 then msg = msg '('sign~count 'uses)'
     diagnostics~append(.Diagnostic~new(sign~line, sign~column, msg, self~name))
  end
  return diagnostics
