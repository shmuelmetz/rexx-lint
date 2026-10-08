/* StemParenExpression.cls -- flags `stem.(expression)`, the classic
 * mistaken attempt at indirect/computed stem-tail access.
 *
 * `stem.(expr)` is NOT indirect compound-variable access in any Rexx
 * dialect -- there is no such syntax. It parses as a call to a
 * routine literally named "STEM." (including the trailing dot),
 * verified directly against the parser: for `mystem.(i)`, the
 * element covering "mystem." is a single EL.TAKEN_CONSTANT (subclass
 * EXTERNAL.FUNCTION.NAME, since the parser has no way to know the
 * routine doesn't exist), immediately followed by EL.LEFT_PARENTHESIS.
 * At runtime this fails with "routine not found" (Error 43) unless a
 * routine with that exact dotted name happens to exist, in which case
 * it silently calls the wrong thing instead -- either way, not what
 * the author meant. See AI-Priming/ooRexx/RULES.md, "Indirect/
 * computed stem access: three forms", where this was found as a real
 * recurring bug in this project's own scripts.
 *
 * Classic Rexx has no indirect-tail syntax: the idiom is to set a
 * variable first and use it as the tail (`i = expr; stem.i`). In ooRexx
 * only, `stem.[expr]` builds the tail from an expression, and a real
 * collection object with bracket notation is another option -- this
 * check flags the mistake but does not guess which correction the
 * author needs.
 */

::requires 'Diagnostic.cls'

::class StemParenExpression public

::method name
  return 'stem-paren-expression'

::method run
  use strict arg parser

  diagnostics = .Array~new

  element = parser~firstElement
  loop until element == .Nil
     if element < .EL.TAKEN_CONSTANT then do
        value = element~value
        if value~right(1) == '.' then
           diagnostics~append(self~makeDiagnostic(element, value))
     end
     element = element~next
  end

  return diagnostics

::method makeDiagnostic private
  use strict arg element, value

  parse value element~from with lineNum colNum

  msg = "'"value"(...)' calls a routine literally named '"value"',"  ,
        || " it does not access a compound variable's tail --" ,
        || " set a variable to the tail first and use "value"var;" ,
        || " in ooRexx, "value"[expr] also works"
  return .Diagnostic~new(lineNum, colNum, msg, self~name)
