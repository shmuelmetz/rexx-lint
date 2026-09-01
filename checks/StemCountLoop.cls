/* StemCountLoop.cls -- flags `DO var = ... TO stem.0` (and the
 * `LOOP` synonym), the classic "manually-counted stem simulating an
 * array" idiom.
 *
 * `stem.0` as a hand-maintained element count, with `stem.1` through
 * `stem.N` as the elements, is inherited classic-Rexx idiom -- legal
 * and still necessary for `address ... with` stdin/stdout/stderr
 * stems, but superseded by `.Array` (or `do over`) everywhere else.
 * See AI-Priming/CONVENTIONS.md, "Do not use stem.tail to simulate
 * an array" and its "do over" section, which names this exact
 * `do i = 1 to stem.0` shape as the pattern to avoid.
 *
 * Detection: an EL.SUBKEYWORD "TO" (the loop-range keyword) whose
 * immediately following non-ignorable element is an
 * EL.COMPOUND_VARIABLE (or EL.EXPOSED_COMPOUND_VARIABLE) ending in
 * the literal tail ".0" -- verified directly against the parser for
 * `do i = 1 to stem.0`.
 *
 * Known limitation: this is a purely syntactic check with no data-
 * flow analysis, so it cannot distinguish a manually-counted array
 * simulation from a case where looping "to stem.0" is itself correct,
 * idiomatic Rexx: a stem populated by `address ... with output stem`
 * (one of the valid `address...with` I/O types alongside NORMAL,
 * STREAM, and USING -- STEM is not the only option, but it is a
 * legitimate, common one -- see AI-Priming/ooRexx/RULES.md's
 * "address...with I/O types" section). Code of that shape will be
 * flagged here even though nothing should change about it. Not fixed
 * in this version; would require tracking whether the stem's `.0`
 * was set by an address...with clause versus a hand-written
 * increment loop.
 */

::requires 'Diagnostic.cls'

::class StemCountLoop public

::method name
  return 'stem-count-loop'

::method run
  use strict arg parser

  diagnostics = .Array~new

  element = parser~firstElement
  loop until element == .Nil
     if element < .EL.SUBKEYWORD, element~value~caselessEquals('TO') then do
        target = self~nextMeaningful(element)
        if self~isStemCountTail(target) then
           diagnostics~append(self~makeDiagnostic(target))
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

::method isStemCountTail private
  use strict arg element

  if element == .Nil then return .False
  if element \< .EL.COMPOUND_VARIABLE, element \< .EL.EXPOSED_COMPOUND_VARIABLE then
     return .False
  return element~value~right(2) == '.0'

::method makeDiagnostic private
  use strict arg element

  parse value element~from with lineNum colNum

  msg = "looping 'to "element~value"' -- a manually-counted stem" ,
        || " simulating an array; consider .Array (or a real" ,
        || " collection object) with 'do over' instead"
  return .Diagnostic~new(lineNum, colNum, msg, self~name)
