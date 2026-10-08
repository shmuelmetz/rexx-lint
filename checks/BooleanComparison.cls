/* BooleanComparison.cls -- flags a boolean compared with a constant:
 * `if flag = .false`, `if .true == done`, `if abbrev(a, b) = 0`,
 * `if a~hasIndex(k) <> 1`, `if (x > y) = '1'`, `if flag > 0`.
 *
 * A boolean is already a condition, so the comparison only adds noise
 * and, against .false or 0, an inverted test the reader must undo. Use
 * the boolean itself, or its negation with the NOT operator.
 *
 * Flagged, for every comparison operator (=, ==, <>, ><, >, <, >=, <=,
 * >>, <<, >>=, <<=, and ¬=, ¬==, ¬>, ¬<, ¬>>, ¬<< with any NOT
 * character):
 *   - either operand is .true or .false;
 *   - one operand is 0 or 1 (number or string) and the other is known
 *     to be boolean: a call to a built-in or RexxUtil function that
 *     returns a boolean (ABBREV, two-argument DATATYPE, SysFileExists,
 *     SysIsFile, SysIsFileDirectory, SysIsFileLink), a message to a
 *     method that returns one (hasIndex, isEmpty, startsWith, ...;
 *     DATATYPE only with an argument), or a parenthesized comparison or
 *     logical expression.
 *
 * A variable, a numeric expression or any other function compared
 * with 0 or 1 is not flagged: nothing says it holds a boolean, and
 * counts, positions, lengths and return codes are compared with 0 and 1
 * all the time. Assignments (`flag = .false`) and USE ARG defaults
 * (`use arg verbose = .false`) are not comparisons.
 * One finding per comparison, at the operator.
 */

::requires 'Diagnostic.cls'

::class BooleanComparison public

::method name
  return 'boolean-comparison'

::method run
  use strict arg parser

  /* Significant elements only; whitespace is not an operand. */
  sig = .Array~new
  element = parser~firstElement
  loop until element == .Nil
     current = element
     element = element~next
     if current < .EL.WHITESPACE then iterate
     sig~append(current)
  end

  diagnostics = .Array~new
  loop i = 2 to sig~items - 1
     op = sig[i]
     category = self~comparisonCategory(op)
     if category == .Nil then iterate
     /* A multi-character operator arrives as several elements of
      * the same category; handle it once, at its first element. */
     if sig[i - 1] < category then iterate
     /* In USE ARG, "name = value" gives a default, not a comparison. */
     if self~clauseKeyword(sig, i) = 'USE' then iterate

     j = i + 1
     loop while j <= sig~items, sig[j] < category
        j = j + 1
     end
     if j > sig~items then iterate
     left = sig[i - 1]
     right = sig[j]

     select
        when self~isBooleanConstant(left) then literal = left
        when self~isBooleanConstant(right) then literal = right
        when self~isZeroOrOne(right), self~endsBoolean(sig, i - 1) then literal = right
        when self~isZeroOrOne(left), self~startsBoolean(sig, j) then literal = left
        otherwise iterate
     end
     diagnostics~append(self~makeDiagnostic(op, literal))
  end
  return diagnostics

/* The first word of the clause holding sig[i], uppercased. */
::method clauseKeyword private
  use strict arg sig, i
  loop n = i - 1 to 1 by -1
     if sig[n] < .EL.END_OF_CLAUSE then leave
  end
  return sig[n + 1]~value~upper

/* The comparison-operator category op belongs to, or .Nil. */
::method comparisonCategory private
  use strict arg op
  do category over .Array~of(.EL.OP.EQUAL, .EL.OP.NOT_EQUAL, ,
        .EL.OP.STRICT.EQUAL, .EL.OP.STRICT.NOT_EQUAL, ,
        .EL.OP.LOWER_OR_GREATER_THAN, .EL.OP.GREATER_OR_LOWER_THAN, ,
        .EL.OP.GREATER_THAN, .EL.OP.LOWER_THAN, ,
        .EL.OP.GREATER_OR_EQUAL, .EL.OP.LOWER_OR_EQUAL, ,
        .EL.OP.NOT_GREATER_THAN, .EL.OP.NOT_LOWER_THAN, ,
        .EL.OP.STRICT.GREATER_THAN, .EL.OP.STRICT.LOWER_THAN, ,
        .EL.OP.STRICT.GREATER_OR_EQUAL, .EL.OP.STRICT.LOWER_OR_EQUAL, ,
        .EL.OP.STRICT.NOT_GREATER_THAN, .EL.OP.STRICT.NOT_LOWER_THAN)
     if op < category then return category
  end
  return .Nil

::method isBooleanConstant private
  use strict arg e
  if e < .EL.ENVIRONMENT_SYMBOL then
     return '.TRUE .FALSE'~wordPos(e~value~upper) > 0
  return .False

::method isZeroOrOne private
  use strict arg e
  if e < .EL.STRING | e < .EL.INTEGER_NUMBER then
     return e~value == '0' | e~value == '1'
  return .False

::method booleanFunctions private
  return 'ABBREV DATATYPE SYSFILEEXISTS SYSISFILE SYSISFILEDIRECTORY SYSISFILELINK'

::method booleanMethods private
  return 'ABBREV CANREAD CANWRITE CASELESSABBREV CASELESSCONTAINS' ,
     'CASELESSCONTAINSWORD CASELESSENDSWITH CASELESSMATCH CASELESSMATCHCHAR' ,
     'CASELESSSTARTSWITH CONTAINS CONTAINSWORD DATATYPE ENDSWITH EXISTS' ,
     'HASENTRY HASINDEX HASITEM HASMETHOD ISA ISDIRECTORY ISEMPTY ISFILE' ,
     'ISINSTANCEOF ISSUBCLASSOF MATCH MATCHCHAR STARTSWITH'

/* Does the operand ending at sig[k] evaluate to a boolean? */
::method endsBoolean private
  use strict arg sig, k
  last = sig[k]

  /* x~isEmpty, with no argument list */
  if last < .EL.TAKEN_CONSTANT then do
     if k > 1, sig[k - 1] < .EL.OP.MESSAGE then
        return self~booleanMethods~wordPos(last~value~upper) > 0 ,
           & last~value~upper <> 'DATATYPE'
     return .False
  end

  if last < .EL.RIGHT_PARENTHESIS then do
     m = self~matchLeft(sig, k)
     if m = 0 then return .False
     return self~groupIsBoolean(sig, m, k, 'left')
  end
  return .False

/* Does the operand starting at sig[j] evaluate to a boolean? */
::method startsBoolean private
  use strict arg sig, j
  first = sig[j]

  /* receiver~method[(args)] */
  if j + 2 <= sig~items, sig[j + 1] < .EL.OP.MESSAGE, sig[j + 2] < .EL.TAKEN_CONSTANT then do
     name = sig[j + 2]~value~upper
     if self~booleanMethods~wordPos(name) = 0 then return .False
     after = j + 3
     if after <= sig~items, sig[after] < .EL.LEFT_PARENTHESIS then do
        p = self~matchRight(sig, after)
        if p = 0 then return .False
        if name = 'DATATYPE', p = after + 1 then return .False
        after = p + 1
     end
     else if name = 'DATATYPE' then return .False
     return self~operandEndsAt(sig, after)
  end

  /* function(args) or (expression) */
  open = j
  if first < .EL.TAKEN_CONSTANT then open = j + 1
  if open > sig~items then return .False
  if sig[open] < .EL.LEFT_PARENTHESIS then do
     p = self~matchRight(sig, open)
     if p = 0 then return .False
     return self~groupIsBoolean(sig, open, p, 'right') & self~operandEndsAt(sig, p + 1)
  end
  return .False

/* sig[m] is '(' and sig[k] its ')'. True when the group is a call to a
 * boolean function or method, or a parenthesized expression whose top
 * level is a comparison or logical operation. side is 'left' when the
 * group ends the left operand: then a preceding arithmetic operator or
 * abuttal means the group is only part of that operand. */
::method groupIsBoolean private
  use strict arg sig, m, k, side

  if m > 1, sig[m - 1] < .EL.TAKEN_CONSTANT then do
     name = sig[m - 1]~value~upper
     hasArgs = k > m + 1
     if m > 2, sig[m - 2] < .EL.OP.MESSAGE then do
        if self~booleanMethods~wordPos(name) = 0 then return .False
        if name = 'DATATYPE' then return hasArgs
        return .True
     end
     if self~booleanFunctions~wordPos(name) = 0 then return .False
     isBoolean = name <> 'DATATYPE' | self~hasTopLevelComma(sig, m, k)
     return isBoolean & self~startsOperand(sig, m - 1, side)
  end

  return self~hasTopLevelLogic(sig, m, k) & self~startsOperand(sig, m, side)

/* For the left operand, sig[s] must start it: a preceding arithmetic
 * operator or abutting term means the group is only part of it. */
::method startsOperand private
  use strict arg sig, s, side
  if side = 'left', s > 1 then return self~isOperandBoundary(sig[s - 1])
  return .True

/* Something that can come right before an operand that is compared:
 * not an arithmetic or concatenation operator, and not a term that
 * would abut it. */
::method isOperandBoundary private
  use strict arg e
  do category over .Array~of(.EL.OP.PLUS, .EL.OP.MINUS, .EL.OP.MULTIPLICATION, ,
        .EL.OP.DIVISION, .EL.OP.INTEGER_DIVISION, .EL.OP.REMAINDER, .EL.OP.POWER, ,
        .EL.OP.CONCATENATION, .EL.OP.MESSAGE, .EL.SIMPLE_VARIABLE, .EL.STRING, ,
        .EL.INTEGER_NUMBER, .EL.RIGHT_PARENTHESIS)
     if e < category then return .False
  end
  return .True

/* The right operand ends at sig[after]: nothing there extends it. */
::method operandEndsAt private
  use strict arg sig, after
  if after > sig~items then return .True
  e = sig[after]
  do category over .Array~of(.EL.OP.PLUS, .EL.OP.MINUS, .EL.OP.MULTIPLICATION, ,
        .EL.OP.DIVISION, .EL.OP.INTEGER_DIVISION, .EL.OP.REMAINDER, .EL.OP.POWER, ,
        .EL.OP.CONCATENATION, .EL.OP.MESSAGE, .EL.OP.CASCADING_MESSAGE, .EL.LEFT_BRACKET)
     if e < category then return .False
  end
  return .True

::method hasTopLevelComma private
  use strict arg sig, m, k
  depth = 0
  loop n = m + 1 to k - 1
     e = sig[n]
     select
        when e < .EL.LEFT_PARENTHESIS then depth = depth + 1
        when e < .EL.RIGHT_PARENTHESIS then depth = depth - 1
        when depth = 0, e < .EL.COMMA then return .True
        otherwise nop
     end
  end
  return .False

::method hasTopLevelLogic private
  use strict arg sig, m, k
  depth = 0
  loop n = m + 1 to k - 1
     e = sig[n]
     select
        when e < .EL.LEFT_PARENTHESIS then depth = depth + 1
        when e < .EL.RIGHT_PARENTHESIS then depth = depth - 1
        when depth > 0 then nop
        when self~isLogicOrComparison(e) then return .True
        otherwise nop
     end
  end
  return .False

::method isLogicOrComparison private
  use strict arg e
  do category over .Array~of(.EL.OP.AND, .EL.OP.OR, .EL.OP.XOR, .EL.OP.NEGATION)
     if e < category then return .True
  end
  return self~comparisonCategory(e) <> .Nil

/* Index of the '(' matching the ')' at sig[k], or 0. */
::method matchLeft private
  use strict arg sig, k
  depth = 0
  loop n = k to 1 by -1
     if sig[n] < .EL.RIGHT_PARENTHESIS then depth = depth + 1
     else if sig[n] < .EL.LEFT_PARENTHESIS then do
        depth = depth - 1
        if depth = 0 then return n
     end
     else if sig[n] < .EL.END_OF_CLAUSE then return 0
  end
  return 0

/* Index of the ')' matching the '(' at sig[j], or 0. */
::method matchRight private
  use strict arg sig, j
  depth = 0
  loop n = j to sig~items
     if sig[n] < .EL.LEFT_PARENTHESIS then depth = depth + 1
     else if sig[n] < .EL.RIGHT_PARENTHESIS then do
        depth = depth - 1
        if depth = 0 then return n
     end
     else if sig[n] < .EL.END_OF_CLAUSE then return 0
  end
  return 0

::method makeDiagnostic private
  use strict arg op, literal
  parse value op~from with lineNum colNum
  msg = "comparing a boolean with the constant" literal~source ,
     || "; use the boolean itself, or its negation with the NOT operator," ,
     || " as the condition"
  return .Diagnostic~new(lineNum, colNum, msg, self~name)
