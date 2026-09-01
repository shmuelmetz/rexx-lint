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
