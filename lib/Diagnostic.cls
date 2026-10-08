/* Diagnostic.cls -- a single finding produced by a rexx-lint check. */

::class Diagnostic public

::attribute line
::attribute column
::attribute message
::attribute check
::attribute severity

::method init
  use strict arg line, column, message, check, severity = 'warning'
  self~line = line
  self~column = column
  self~message = message
  self~check = check
  self~severity = severity

::method format
  return self~line':'self~column': 'self~severity': 'self~message' ['self~check']'

/* DiagnosticOrder -- comparator for sorting diagnostics by line, then
 * column, then check name. */
::class DiagnosticOrder public inherit Comparator

::method compare
  use strict arg left, right
  if left~line <> right~line then return sign(left~line - right~line)
  if left~column <> right~column then return sign(left~column - right~column)
  return left~check~compareTo(right~check)
