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
 * genuine Rexx files from a real ArcaOS-era script collection
 * (local-test-data/utility-cmd/, not committed), an earlier version
 * of this check found 74 hits, every one sampled a Windows/OS/2 path
 * fragment, not a genuine mistake: "\backup.log", "H:\Vendors\...",
 * "W:\temp\...", "\comm\mail\...\news\...".
 *
 * First fix attempt (superseded): only flag a tracked letter when
 * the next character isn't itself a letter, reasoning that a real
 * escape mistake is an isolated two-character unit while a path
 * segment keeps extending into a longer word. This happened to clear
 * every case actually observed in that one corpus, but it's an
 * overfit proxy, not a real test of "is this a path" -- it was tuned
 * to the specific letters and words that corpus happened to contain,
 * and would not reliably generalize (e.g. it does nothing to
 * recognize an actual path *as* a path; it just happens to
 * distinguish "backup"/"temp"/"news" from single letters by luck of
 * which letter follows).
 *
 * Current approach: test the string's actual structure for path-like
 * properties instead of any specific vocabulary -- a drive-letter
 * prefix (`X:\` anywhere in the string, not just at position 1,
 * since paths are often embedded mid-string after a command word,
 * with a guard against a false match like "etc:\" by requiring the
 * character before the drive letter not itself be a letter), a UNC
 * prefix (`\\server\share`), two or more backslashes each followed
 * by a real word -- 2+ letters in a row, not just "a letter" -- since
 * that is what actually separates a multi-segment path
 * ("\comm\mail\news\...") from a string with several genuine escape
 * mistakes ("\t1\t2\t3", each backslash followed by exactly one
 * letter then a digit; counting raw backslashes without the word-
 * shape requirement would wrongly gate this as a path too, verified
 * by hitting exactly that regression while testing this class's own
 * fixtures), or a file-extension-shaped ending (`.log`, `.exe`,
 * `.zip` -- a dot followed by 2-4 letters and nothing else). If the
 * whole string matches any of these, no escape-letter scan runs on
 * it at all. Verified this drops the real-world corpus from 74 hits
 * to 3, resting throughout on structural properties any Windows/OS/2
 * path or any genuine escape sequence actually has -- not on which
 * specific words happened to appear in one collection of files.
 *
 * Known remaining gaps in those 3, honestly not solved:
 * - A path built by concatenating a variable with a short literal
 *   fragment, e.g. `drive'\backup.log is older than'`, only has that
 *   literal fragment visible to this check -- one backslash, no
 *   drive letter, and (in this specific real example) trailing text
 *   after the extension-like part means even the ending-pattern test
 *   doesn't match. Judging a string fragment in isolation from the
 *   concatenation it's part of has this kind of limit inherently.
 * - A command-line-flag style fragment like `-ww:\temp` has a real
 *   drive-letter shape (`w:\`) immediately preceded by another
 *   letter (the doubled flag character), which trips the same guard
 *   meant to reject "etc:\"-style false matches -- correctly
 *   rejecting one thing costs rejecting the other, since both have
 *   the identical local shape (letter, letter, colon, backslash).
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
        value = element~value
        if \self~looksLikePath(value) then do
           letter = self~findEscapeLikeSequence(value)
           if letter \== .Nil then
              diagnostics~append(self~makeDiagnostic(element, letter))
        end
     end
     element = element~next
  end

  return diagnostics

/* looksLikePath -- does this whole string structurally resemble a
 * Windows/OS/2 path, independent of which specific letters or words
 * it contains? True if any of: a drive-letter prefix (a single
 * letter, colon, backslash) anywhere in the string; a UNC prefix
 * (leading double backslash); two or more backslashes total; or an
 * ending that looks like a file extension (a dot followed by 2-4
 * letters and nothing else). */
::method looksLikePath private
  use strict arg text

  if self~hasDriveLetterPrefix(text) then return .True
  if text~left(2) == '\\' then return .True
  if self~countWordLikeSegments(text) >= 2 then return .True
  if self~hasExtensionLikeEnding(text) then return .True
  return .False

::method hasDriveLetterPrefix private
  use strict arg text

  pos = text~pos(':\')
  loop while pos > 1
     letterBefore = text~substr(pos - 1, 1)
     if self~isLetter(letterBefore) then do
        /* Confirm it's a single-letter drive, not the tail end of a
           longer word ending in a letter right before ":\" (e.g.
           "etc:\" would be a false structural match otherwise) --
           the character before the letter, if any, must not itself
           be a letter. Position 0 doesn't exist (SUBSTR requires a
           positive start), so "the letter is at the very start of
           the string" (pos - 2 < 1) means there's nothing before it
           to check -- treat that as "no letter before", same as an
           empty result would. */
        if pos - 2 < 1 then charBeforeThat = ''
        else charBeforeThat = text~substr(pos - 2, 1)
        if \self~isLetter(charBeforeThat) then return .True
     end
     pos = text~pos(':\', pos + 1)
  end
  return .False

::method hasExtensionLikeEnding private
  use strict arg text

  dotPos = text~lastPos('.')
  if dotPos == 0 then return .False
  suffix = text~substr(dotPos + 1)
  if suffix~length < 2 | suffix~length > 4 then return .False
  do i = 1 to suffix~length
     if \self~isLetter(suffix~substr(i, 1)) then return .False
  end
  return .True

/* countWordLikeSegments -- how many backslashes in text are each
 * followed by a real word (2+ letters in a row), as opposed to a
 * digit, punctuation, another backslash, or a single character
 * before something else? This is what actually separates a
 * multi-segment path ("\comm\mail\news\...", each backslash
 * followed by a whole word) from a string with several genuine
 * escape-sequence mistakes ("\t1\t2\t3", where each backslash is
 * followed by exactly one letter and then a digit) -- counting raw
 * backslashes conflates the two, since both can have several. An
 * escape code is structurally a fixed one-character unit; a path
 * segment is a variable-length word. Requiring 2+ *letters* (not
 * just "a letter follows") is what makes this a test of word-shape
 * rather than a repeat of the single-letter escape-code check. */
::method countWordLikeSegments private
  use strict arg text

  count = 0
  pos = text~pos('\')
  loop while pos > 0
     first = text~substr(pos + 1, 1)
     second = text~substr(pos + 2, 1)
     if self~isLetter(first), self~isLetter(second) then
        count = count + 1
     pos = text~pos('\', pos + 1)
  end
  return count

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
