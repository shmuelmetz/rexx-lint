/* ShadowedSpecialVars.cls -- flags assignments to RESULT, RC, or SIGL.
 *
 * These names are ooRexx/Rexx special variables (subroutine/function
 * return value, host-command return code, and SIGNAL/CALL source
 * line number respectively). Assigning to them directly -- including
 * as a loop control variable, a PARSE template target, a USE ARG
 * variable, or an EXPOSE'd name -- shadows the interpreter's own use
 * of the name and is almost always a mistake rather than an
 * intentional convention.
 *
 * Detection relies on the Rexx Parser's own `isAssigned` element
 * attribute, which already covers every assignment-like context
 * (plain '=', PARSE targets, USE ARG, DO/LOOP control and COUNTER
 * variables, EXPOSE/USE LOCAL/PROCEDURE EXPOSE/DROP) -- see
 * https://rexx.epbcn.com/rexx-parser/doc/ref/classes/element/#isassigned
 */

::requires 'Diagnostic.cls'

::class ShadowedSpecialVars public

::method shadowedNames class
  return .Array~of('RESULT', 'RC', 'SIGL')

::method name
  return 'shadowed-special-vars'

::method run
  use strict arg parser

  diagnostics = .Array~new

  element = parser~firstElement
  loop until element == .Nil
     if element~isAssigned then do
        shadowedName = self~matchedSpecialName(element~value)
        if shadowedName \== .Nil then
           diagnostics~append(self~makeDiagnostic(element, shadowedName))
     end
     element = element~next
  end

  return diagnostics

::method matchedSpecialName private
  use strict arg symbolValue

  do candidate over self~class~shadowedNames
     if symbolValue~caselessEquals(candidate) then
        return candidate
  end
  return .Nil

::method makeDiagnostic private
  use strict arg element, shadowedName

  parse value element~from with lineNum colNum

  msg = "variable '"shadowedName"' shadows the special variable of the same name"
  return .Diagnostic~new(lineNum, colNum, msg, self~name)
