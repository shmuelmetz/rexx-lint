/* NestedBuiltinCall.cls -- flags a built-in function call whose first
 * argument is itself an immediate built-in function call, e.g.
 * `translate(strip(x))`, as a candidate for ooRexx chained-method
 * style: `x~strip~translate`.
 *
 * Verified directly against the installed interpreter (not assumed):
 * of 49 classic BIFs spot-checked via ~hasMethod (all the string/word/
 * conversion/bit/numeric ones a nested call is likely to involve --
 * ABBREV, CENTER/CENTRE, CHANGESTR, COMPARE, COPIES, DATATYPE, DELSTR,
 * DELWORD, INSERT, LASTPOS, LEFT, LENGTH, LOWER, MATCH, MATCHCHAR,
 * OVERLAY, POS, REVERSE, RIGHT, SPACE, STRIP, SUBSTR, SUBWORD,
 * TRANSLATE, UPPER, VERIFY, WORD, WORDINDEX, WORDLENGTH, WORDPOS,
 * WORDS, X2C, C2X, X2D, D2X, X2B, B2X, C2D, D2C, BITAND, BITOR,
 * BITXOR, ABS, SIGN, MAX, MIN, TRUNC, FORMAT), all 49 have a direct
 * String-object method equivalent. Given that coverage, this check
 * relies on the Rexx Parser's own BUILTIN.FUNCTION.NAME recognition
 * (it already carries a real, maintained BIF list -- see
 * rexx-parser/bin/BIFs.cls) rather than a hand-curated word list of
 * its own, which would only risk being a worse copy of the same
 * information.
 *
 * Detection: an EL.TAKEN_CONSTANT with subcategory BUILTIN.FUNCTION.
 * NAME, immediately followed by EL.LEFT_PARENTHESIS, whose first
 * non-ignorable content is itself a BUILTIN.FUNCTION.NAME taken
 * constant immediately followed by another EL.LEFT_PARENTHESIS --
 * verified directly against the parser for `translate(strip(y))`.
 *
 * Deliberately narrow: only the *immediately* nested case (the
 * nested call is the very first thing inside the outer call's
 * parentheses) is flagged, not a nested call appearing as a later
 * argument (`translate(y, strip(x))`) or nested more than one level
 * deep beyond the first hop. This avoids the much harder problem of
 * tracking argument boundaries and full parenthesis nesting, at the
 * cost of missing some real cases -- a narrower true-positive-only
 * check over a broader, noisier one.
 */

::requires 'Diagnostic.cls'

::class NestedBuiltinCall public

::method name
  return 'nested-builtin-call'

::method run
  use strict arg parser

  diagnostics = .Array~new

  element = parser~firstElement
  loop until element == .Nil
     if element << .BUILTIN.FUNCTION.NAME then do
        afterOuterName = self~nextMeaningful(element)
        if self~isOpenParen(afterOuterName) then do
           innerCandidate = self~nextMeaningful(afterOuterName)
           if innerCandidate \== .Nil, innerCandidate << .BUILTIN.FUNCTION.NAME then do
              afterInnerName = self~nextMeaningful(innerCandidate)
              if self~isOpenParen(afterInnerName) then
                 diagnostics~append(self~makeDiagnostic(element, innerCandidate))
           end
        end
     end
     element = element~next
  end

  return diagnostics

::method nextMeaningful private
  use strict arg element

  if element == .Nil then return .Nil
  nxt = element~next
  loop while nxt \== .Nil, nxt~ignorable
     nxt = nxt~next
  end
  return nxt

::method isOpenParen private
  use strict arg element

  if element == .Nil then return .False
  return element < .EL.LEFT_PARENTHESIS

::method makeDiagnostic private
  use strict arg outerElement, innerElement

  parse value outerElement~from with lineNum colNum

  msg = "'"outerElement~value"("innerElement~value"(...))' -- nested" ,
        || " built-in calls read inside-out; consider chained methods" ,
        || " instead, e.g. 'x~"innerElement~value~lower"~"outerElement~value~lower"'"
  return .Diagnostic~new(lineNum, colNum, msg, self~name)
