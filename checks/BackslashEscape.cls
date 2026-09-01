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
 *
 * Real-world false-positive finding, 2026-09-01: run against 72
 * genuine Rexx files from an actual ArcaOS-era personal script
 * collection (local-test-data/utility-cmd/, not committed), an
 * earlier version of this check (no letter-continuation guard) found
 * 74 hits -- and every single one sampled, across every tracked
 * letter including \n and \r, turned out to be a Windows/OS/2 path
 * fragment, not a genuine escape-sequence mistake: "\backup.log",
 * "H:\Vendors\...", "\unz600\...", "W:\temp\...", "I:\comm\
 * FaxWorks\nstall;" (\n from "\nstall"), "\comm\mail\...\news\..."
 * (\n from "\news"), "...\ibmworks\readme;" (\r from "\readme").
 * Windows/OS/2 Rexx source is saturated with literal backslash paths,
 * and a path segment starting with any of the tracked letters (b for
 * "backup"/"bin", t for "temp", u for "unzip"/"users", v for
 * "vendors"/"var", n for "news"/"nstall", r for "readme", etc.) is
 * essentially indistinguishable from a genuine escape attempt by the
 * two characters alone. Fix: a genuine escape-sequence mistake is
 * written as an isolated two-character unit -- the author intends
 * "\n" to mean one thing (a newline), so real text continues after
 * it with a new word/separator, not by extending the letter itself
 * into a longer run of letters. A path fragment does the opposite:
 * "\nstall" keeps going as "n-s-t-a-l-l". So this version only flags
 * a tracked letter when the *next* character is not itself a
 * lowercase letter -- eliminating the observed real-world noise at
 * the cost of missing a real mistake in the specific case where
 * ordinary prose text happens to resume immediately with a lowercase
 * letter (e.g. "line one\nline two" -- the "l" of "line" suppresses
 * it). That trade-off is deliberate: a check with near-total false
 * positives on real code erodes trust in the whole tool faster than
 * an occasional missed true positive does.
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
     if nextCh \== '', letters~pos(nextCh) > 0 then do
        /* The character after that must NOT itself be a letter, or
           this is a path fragment continuing as a longer word
           ("\backup", "\temp", "\nstall"), not an isolated two-
           character escape attempt -- see the class docstring's
           real-world false-positive finding. */
        followingCh = text~substr(pos + 2, 1)
        if \self~isLetter(followingCh) then
           return '\' || nextCh
     end
     pos = text~pos('\', pos + 1)
  end
  return .Nil

::method isLetter private
  use strict arg ch

  if ch == '' then return .False
  return ch~datatype('U') | (ch >= 'a' & ch <= 'z')

::method makeDiagnostic private
  use strict arg element, sequence

  parse value element~from with lineNum colNum

  msg = "'"sequence"' inside a string literal is two literal characters" ,
        || " in Rexx, not an escape sequence -- there is no string-escape" ,
        || " mechanism in any Rexx dialect"
  return .Diagnostic~new(lineNum, colNum, msg, self~name)
