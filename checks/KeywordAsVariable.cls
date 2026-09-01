/* KeywordAsVariable.cls -- flags a simple variable whose name is
 * also a Rexx/ooRexx keyword instruction, keyword clause, or common
 * subkeyword (e.g. `class = 5`, `do to = 1 to 10`).
 *
 * This is legal Rexx: keywords are not reserved words, and the
 * Rexx Parser correctly resolves each occurrence by context (an
 * EL.KEYWORD/EL.SUBKEYWORD element in keyword position, an
 * EL.SIMPLE_VARIABLE element anywhere a variable is expected --
 * verified directly against the parser, e.g. `do to = 1 to 3` tags
 * the first "TO" EL.SIMPLE_VARIABLE and the second EL.SUBKEYWORD).
 * It is nonetheless a style hazard for the human reader, so this is
 * a warning, not an error -- rexx-lint checks style, not just
 * correctness.
 *
 * The word list below is not a claim of completeness. It covers the
 * top-level instruction keywords (cross-checked against
 * rexx-parser's own bin/KeywordInstructions.cls), the keyword
 * clauses (IF/DO/SELECT/WHEN/OTHERWISE/END/ELSE/LOOP, verified
 * empirically as EL.KEYWORD), common loop/parse subkeywords, and the
 * ooRexx OO-directive keywords (CLASS/METHOD/etc., which are never
 * EL.KEYWORD outside of "::" position, so as bare variable names
 * they parse as ordinary EL.SIMPLE_VARIABLE -- also verified
 * directly). Extend as more are found.
 */

::requires 'Diagnostic.cls'

::class KeywordAsVariable public

::method watchedWords class
  return .Array~of( -
     'ADDRESS', 'ARG', 'CALL', 'DO', 'DROP', 'ELSE', 'END', 'EXIT', -
     'EXPOSE', 'FORWARD', 'GUARD', 'IF', 'INTERPRET', 'ITERATE', -
     'LEAVE', 'LOOP', 'NOP', 'NUMERIC', 'OPTIONS', 'OTHERWISE', -
     'PARSE', 'PROCEDURE', 'PULL', 'PUSH', 'QUEUE', 'RAISE', 'REPLY', -
     'RETURN', 'SAY', 'SELECT', 'SIGNAL', 'THEN', 'TRACE', 'UPPER', -
     'USE', 'WHEN', -
     'BY', 'FOR', 'FOREVER', 'TO', 'WHILE', 'UNTIL', 'WITH', -
     'ON', 'OFF', 'VALUE', 'CONDITION', 'DIGITS', 'FORM', 'FUZZ', -
     'CLASS', 'METHOD', 'ROUTINE', 'REQUIRES', 'ATTRIBUTE', -
     'CONSTANT', 'RESOURCE' -
     )

::method name
  return 'keyword-as-variable'

::method run
  use strict arg parser

  diagnostics = .Array~new
  words = self~class~watchedWords

  element = parser~firstElement
  loop until element == .Nil
     if element < .EL.SIMPLE_VARIABLE | element < .EL.EXPOSED_SIMPLE_VARIABLE then do
        matched = self~matchedWord(element~value, words)
        if matched \== .Nil then
           diagnostics~append(self~makeDiagnostic(element, matched))
     end
     element = element~next
  end

  return diagnostics

::method matchedWord private
  use strict arg symbolValue, words

  do candidate over words
     if symbolValue~caselessEquals(candidate) then
        return candidate
  end
  return .Nil

::method makeDiagnostic private
  use strict arg element, word

  parse value element~from with lineNum colNum

  msg = "variable '"word"' is also a Rexx keyword; consider a less ambiguous name"
  return .Diagnostic~new(lineNum, colNum, msg, self~name)
