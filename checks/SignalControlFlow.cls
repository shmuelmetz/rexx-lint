/* SignalControlFlow.cls -- flags SIGNAL used as an unconditional
 * jump (control flow) rather than to arm/disarm a condition trap.
 *
 * SIGNAL ON condition / SIGNAL OFF condition is the trap form and is
 * not flagged. Every other form -- SIGNAL label, SIGNAL VALUE expr,
 * SIGNAL namespace:label -- transfers control immediately and drops
 * the entire active call stack (unlike CALL), which is easy to miss
 * when reading code that looks like an ordinary jump. This is legal,
 * sometimes necessary (leaving deeply nested loops, for instance),
 * but worth a style warning since it is also a common source of
 * "why did my pending FINALLY/cleanup code never run" bugs.
 *
 * Detection: find EL.KEYWORD elements whose value is SIGNAL, look at
 * the next non-ignorable element, and check whether it is the
 * EL.SUBKEYWORD "ON" or "OFF" -- verified empirically (elements.rex)
 * that SIGNAL ON/OFF's ON/OFF token is EL.SUBKEYWORD, while a plain
 * SIGNAL label target is an EL.TAKEN_CONSTANT with subCategory
 * LABEL.NAME, and SIGNAL VALUE's VALUE token is also EL.SUBKEYWORD
 * but is not itself a trap -- so the check is specifically "is the
 * next word ON or OFF", not merely "is the next word a subkeyword".
 */

::requires 'Diagnostic.cls'

::class SignalControlFlow public

::method name
  return 'signal-control-flow'

::method run
  use strict arg parser

  diagnostics = .Array~new

  element = parser~firstElement
  loop until element == .Nil
     if element < .EL.KEYWORD, element~value~caselessEquals('SIGNAL') then do
        nextWord = self~nextMeaningful(element)
        if \self~isTrapForm(nextWord) then
           diagnostics~append(self~makeDiagnostic(element))
     end
     element = element~next
  end

  return diagnostics

::method nextMeaningful private
  use strict arg element

  nxt = element~next
  loop while nxt \== .Nil, nxt~ignorable
     nxt = nxt~next
  end
  return nxt

::method isTrapForm private
  use strict arg word

  if word == .Nil then return .False
  if word \< .EL.SUBKEYWORD then return .False
  return word~value~caselessEquals('ON') | word~value~caselessEquals('OFF')

::method makeDiagnostic private
  use strict arg element

  parse value element~from with lineNum colNum

  msg = 'SIGNAL used as an unconditional jump, not a condition trap;' ,
        || ' this drops the entire active call stack, unlike CALL'
  return .Diagnostic~new(lineNum, colNum, msg, self~name)
