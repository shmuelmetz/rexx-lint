/* BifSignature.cls -- checks a call to a built-in function against that
 * function's signature: too many arguments, too few, an omitted required
 * argument, and a *literal* argument whose value can't be right (a
 * negative length, a position of 0, a non-numeric value where a number
 * is required, an option letter the function doesn't accept).
 *
 * The signature data is not duplicated here. It is Josep Maria Blasco's
 * own table -- .Parser.BIFInfo (minArgs / maxArgs / argType per BIF),
 * loaded into the environment by the Rexx Parser (bin/parser/BIFs.cls) --
 * so it tracks his fixes, option letters included: an argument type that
 * is not one of the named types in NAMEDTYPES is a set of option letters
 * (BLT, ACDEIORS, ...). NAMEDTYPES itself is maintained by hand; the test
 * suite fails if the parser introduces an argument type that is neither a
 * named type nor shaped like a letter set, so rerun it after updating the
 * parser. The checks are modelled on his rxcheck utility's
 * CheckBIFArgs routine, which raises the first problem as a SYNTAX
 * condition and stops; this check reports every problem, non-fatally.
 *
 * Only literal arguments are type-checked; anything that isn't a
 * constant (a variable, an expression) is skipped. BIFs with special
 * argument rules in rxcheck (D2C, D2X, MAX, MIN, RANDOM, XRANGE, STREAM,
 * ARG, RXQUEUE, BEEP, the stream-I/O family whose argument numbers are
 * shifted) get the count and omitted-argument checks only, not the
 * literal-value ones.
 *
 * A call is skipped when a label in the same body, or a ::ROUTINE in the
 * package, has the same name as the BIF.
 */

::requires 'Diagnostic.cls'

::class BifSignature public

::constant SPECIAL 'D2C D2X MAX MIN RANDOM XRANGE STREAM ARG RXQUEUE BEEP CHARIN CHAROUT CHARS LINEIN LINEOUT LINES QUALIFY'
::constant EXTERNAL 'BEEP DIRECTORY FILESPEC'
::constant NAMEDTYPES 'ANY PAD SEP STREAM BIN HEX SYM RANGE UNI UTF8 D2 F ACEFILNOR NUM LENGTH POS WHOLE WHOLE>0 WHOLE>=0 MAX MIN 0_90 0_99'

::method name
  return 'bif-signature'

::method run
  use strict arg parser

  diagnostics = .Array~new
  package = parser~package

  bodies = .Array~new
  bodies~append(package~prolog~body)
  do fragment over package~directives
     body = fragment~body
     if body ¬== .Nil, ¬body~isEmpty then bodies~append(body)
  end

  do body over bodies
     labels = body~labels
     do called over body~calledRoutineNames
        name = called[1]
        label = name~value
        if name < .ALL.SYMBOLS, labels~hasIndex(label) then iterate
        if .Parser.BIF[label] == .Nil then iterate
        if package~routines[label] ¬== .Nil then iterate
        info = .Parser.BIFInfo[label]
        if info~maxArgs == .Nil then iterate
        self~checkCall(diagnostics, name, label, info, called[2])
     end
  end

  return diagnostics

::method checkCall private
  use strict arg diagnostics, name, label, info, arguments

  if self~EXTERNAL~wordpos(label) > 0 then return

  nArgs = arguments~arg()
  maxArgs = info~maxArgs
  minArgs = info~minArgs

  if maxArgs ¬== '*', nArgs > maxArgs then do
     self~report(diagnostics, name, label 'takes at most' maxArgs 'argument(s); called with' nArgs)
     return
  end
  if nArgs < minArgs then do
     self~report(diagnostics, name, label 'requires at least' minArgs 'argument(s); called with' nArgs)
     return
  end

  if label == 'ARG', nArgs > 0 then minArgs = 1
  checkUpTo = minArgs - 1 + (nArgs > minArgs)
  if maxArgs == '*', label ¬== 'XRANGE' then checkUpTo = nArgs
  do argN = 1 to checkUpTo
     if arguments~arg(argN, 'O') then do
        self~report(diagnostics, name, label': required argument' argN 'is omitted')
        return
     end
  end

  if self~SPECIAL~wordpos(label) > 0 then return

  do argN = 1 to nArgs
     if arguments~arg(argN, 'O') then iterate
     literal = self~literalValue(arguments~arg(argN))
     if literal == .Nil then iterate
     type = info~argType[argN]
     if type == .Nil then iterate
     problem = self~valueProblem(type, literal)
     if problem ¬== '' then do
        self~report(diagnostics, name, label': argument' argN problem)
        return
     end
  end

/* literalValue -- the value of a constant argument, or .Nil if the
 * argument is not a constant (a variable or a general expression). */
::method literalValue private
  use strict arg argTerm

  select case argTerm~class
     when .Literal.String.Term then return argTerm~theString~value
     when .Symbol.Term then do
        symbol = argTerm~symbol
        if symbol ¬< .ALL.NUMBERS then return .Nil
        return symbol~value
     end
     when .Prefix.Expression then do
        term = argTerm~term
        if ¬term~isA(.Symbol.Term) then return .Nil
        symbol = term~symbol
        if symbol ¬< .ALL.NUMBERS then return .Nil
        minus = .False
        do sign over argTerm~prefixes
           if sign~value == '-' then minus = ¬minus
           else if sign~value ¬== '+' then return .Nil
        end
        literal = symbol~value
        if minus then return '-'literal
        return literal
     end
     otherwise return .Nil
  end

/* valueProblem -- '' if the literal is acceptable for the declared type,
 * else a short description of what is wrong. */
::method valueProblem private
  use strict arg type, literal

  numeric digits max(9, literal~length + 2)

  select case type
     when 'NUM' then do
        if ¬literal~datatype('N') then return "must be a number, not '"literal"'"
     end
     when 'LENGTH', 'POS', 'WHOLE', 'WHOLE>0', 'WHOLE>=0' then do
        if ¬literal~datatype('W') then return "must be a whole number, not '"literal"'"
        select case type
           when 'LENGTH', 'WHOLE>=0' then if literal < 0 then return 'must not be negative (got' literal')'
           when 'POS', 'WHOLE>0' then if literal <= 0 then return 'must be greater than 0 (got' literal')'
           otherwise nop
        end
     end
     otherwise do
        if self~isLetterSet(type) then
           if literal~length > 0, type~pos(literal~left(1)~upper) == 0 then
              return "'"literal"' is not one of the option letters" type
     end
  end
  return ''

/* isLetterSet -- .True if an argument type from .Parser.BIFInfo is a set
 * of option letters: not a named type, and made only of A-Z and 9. */
::method isLetterSet class
  use strict arg type

  if self~NAMEDTYPES~wordpos(type) > 0 then return .False
  return type~verify('ABCDEFGHIJKLMNOPQRSTUVWXYZ9') = 0

::method isLetterSet
  use strict arg type
  return self~class~isLetterSet(type)

::method report private
  use strict arg diagnostics, name, text

  parse value name~from with lineNum colNum
  diagnostics~append(.Diagnostic~new(lineNum, colNum, text, self~name))
