/* NestedBuiltinCall.cls -- flags a built-in function call whose first
 * argument is itself an immediate built-in function call, e.g.,
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
 * rexx-parser/bin/parser/BIFs.cls) rather than a hand-curated word list of
 * its own, which would only risk being a worse copy of the same
 * information.
 *
 * Detection: an EL.TAKEN_CONSTANT with subcategory BUILTIN.FUNCTION.
 * NAME, immediately followed by EL.LEFT_PARENTHESIS, whose first
 * non-ignorable content is itself a BUILTIN.FUNCTION.NAME taken
 * constant immediately followed by another EL.LEFT_PARENTHESIS --
 * verified directly against the parser for `translate(strip(y))`.
 *
 * Only string functions are flagged: the outer function must be a method
 * of the String class in the target dialect, since it is the one that
 * becomes a message (`strip(linein(f))` is `linein(f)~strip`). The inner
 * call becomes the receiver -- chained too when it is also a String
 * method (`x~strip~translate`), left as a call otherwise. For ooRexx and
 * Executor the test is the running interpreter (''~hasMethod(name)); for
 * OREXX (Object REXX on OS/2/ArcaOS) it is the String class's method list
 * in its reference (REXX.INF, "Methods the String Class Defines"), which
 * has no LOWER or UPPER; for NetRexx, the built-in methods of the REXX
 * class (NetRexx 4.02 Language Reference, "The built-in methods"), with
 * the advice in NetRexx's own notation, `x.strip.translate`.
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

::attribute dialect private

/* appliesTo -- string methods exist only in the object-oriented dialects,
 * so this check runs only when the dialect is ooRexx, OREXX, Executor or
 * NetRexx and was named explicitly (--dialect, or the file's own extproc/shebang)
 * or inferred from ooRexx syntax in the file -- not for a file taken as
 * classic Rexx. The dialect is kept for run, which needs its method list. */
::method appliesTo
  use strict arg dialect, explicit
  self~dialect = dialect~lower
  return explicit & 'oorexx orexx executor netrexx'~caselessWordPos(dialect) > 0

/* orexxStringMethods -- OREXX's String class methods that have a
 * same-named built-in function (REXX.INF, "Methods the String Class
 * Defines"). */
::method orexxStringMethods class
  return 'ABBREV ABS BITAND BITOR BITXOR B2X CENTER CENTRE CHANGESTR' ,
         'COMPARE COPIES COUNTSTR C2D C2X DATATYPE DELSTR DELWORD D2C' ,
         'D2X FORMAT INSERT LASTPOS LEFT LENGTH MAX MIN OVERLAY POS' ,
         'REVERSE RIGHT SIGN SPACE STRIP SUBSTR SUBWORD TRANSLATE TRUNC' ,
         'VERIFY WORD WORDINDEX WORDLENGTH WORDPOS WORDS X2B X2C X2D'

/* netrexxStringMethods -- NetRexx's built-in methods of the REXX class
 * (NetRexx 4.02 Language Reference, 48.2 "The built-in methods"). */
::method netrexxStringMethods class
  return 'ABBREV ABS B2X C2D C2X CENTER CENTRE CHANGESTR COMPARE COPIES' ,
         'COPYINDEXED COUNTSTR D2B D2C D2X DATATYPE DELSTR DELWORD EXISTS' ,
         'FORMAT INSERT LASTPOS LEFT LENGTH LOWER MAX MIN OVERLAY POS' ,
         'REVERSE RIGHT SEQUENCE SIGN SOUNDEX SPACE STRIP SUBSTR SUBWORD' ,
         'TRANSLATE TRUNC UPPER VERIFY WORD WORDINDEX WORDLENGTH WORDPOS' ,
         'WORDS X2B X2C X2D'

/* isStringMethod -- whether the built-in function name is also a String
 * method in the target dialect. */
::method isStringMethod private
  use strict arg name
  select
     when self~dialect == 'orexx' then
        return self~class~orexxStringMethods~caselessWordPos(name) > 0
     when self~dialect == 'netrexx' then
        return self~class~netrexxStringMethods~caselessWordPos(name) > 0
     otherwise
        return ''~hasMethod(name)
  end

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
           if innerCandidate ¬== .Nil, innerCandidate << .BUILTIN.FUNCTION.NAME then do
              afterInnerName = self~nextMeaningful(innerCandidate)
              if self~isOpenParen(afterInnerName), ,
                 self~isStringMethod(element~value) then
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
  loop while nxt ¬== .Nil, nxt~ignorable
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

  outer = outerElement~value~lower
  inner = innerElement~value~lower
  if self~dialect == 'netrexx' then do
     /* NetRexx: dot notation; a no-argument method may drop its "()" */
     if self~isStringMethod(inner) then example = 'x.'inner'.'outer
     else example = inner'(...).'outer
     msg = "'"outerElement~value"("innerElement~value"(...))' -- nested" ,
           || " calls read inside-out; consider chained methods instead," ,
           || " e.g., '"example"'"
  end
  else do
     if self~isStringMethod(inner) then example = 'x~'inner'~'outer
     else example = inner'(...)~'outer
     msg = "'"outerElement~value"("innerElement~value"(...))' -- nested" ,
           || " built-in calls read inside-out; consider chained methods" ,
           || " instead, e.g., '"example"'"
  end
  return .Diagnostic~new(lineNum, colNum, msg, self~name)
