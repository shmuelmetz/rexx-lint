/* BackslashEscape.cls -- flags a backslash inside a string literal
 * that looks like a C/Python/JS-style escape sequence (\n, \t, \\,
 * \", etc.).
 *
 * Rexx has no escape-sequence mechanism in string literals at all,
 * in any dialect. A backslash inside a string is just a literal
 * backslash character -- verified directly against the parser: the
 * EL.STRING element's ~value for "hello\nworld" is the ten-character
 * string h-e-l-l-o-\-n-w-o-r-l-d, not a string containing a real
 * newline. Someone coming from C, Python, or JavaScript who writes
 * "line one\nline two" expecting a newline gets a literal backslash
 * and the letter n instead -- a silent, easy-to-miss bug rather than
 * a parse error, since the string is syntactically valid either way.
 * (This is unrelated to Rexx's own doubled-quote escape for embedding
 * the string's own delimiter, e.g. "she said ""hi""", which the
 * parser already handles and which this check does not touch.)
 */

::requires 'Diagnostic.cls'

::class BackslashEscape public

::method escapeLetters class
  /* n t r 0 a b f v x u, plus backslash, double-quote, and single-
   * quote themselves. Each odd character built via concatenation of
   * whichever framing delimiter avoids escaping it, per
   * AI-Priming/CONVENTIONS.md's string-literal framing rule -- no
   * doubled quotes to puzzle over here. */
  return 'ntr0abfvxu' || '\' || '"' || "'"

::method name
  return 'backslash-escape'

::method run
  use strict arg parser

  diagnostics = .Array~new

  element = parser~firstElement
  loop until element == .Nil
     if element < .EL.STRING then do
        letter = self~findEscapeLikeSequence(element~value)
        if letter \== .Nil then
           diagnostics~append(self~makeDiagnostic(element, letter))
     end
     element = element~next
  end

  return diagnostics

::method findEscapeLikeSequence private
  use strict arg text

  letters = self~class~escapeLetters
  pos = text~pos('\')
  loop while pos > 0
     nextCh = text~substr(pos + 1, 1)
     if nextCh \== '', letters~pos(nextCh) > 0 then
        return '\' || nextCh
     pos = text~pos('\', pos + 1)
  end
  return .Nil

::method makeDiagnostic private
  use strict arg element, sequence

  parse value element~from with lineNum colNum

  msg = "'"sequence"' inside a string literal is two literal characters" ,
        || " in Rexx, not an escape sequence -- there is no string-escape" ,
        || " mechanism in any Rexx dialect"
  return .Diagnostic~new(lineNum, colNum, msg, self~name)
