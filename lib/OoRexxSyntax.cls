/* OoRexxSyntax.cls -- finds syntax that exists only in ooRexx (and its
 * Executor fork): the message operators ~ and ~~, brackets [ ], ::
 * directives, and environment symbols such as .Array or .true.
 *
 * Used two ways. When a file names no dialect at all, rexx-lint assumes
 * classic Rexx unless this finds ooRexx syntax, in which case the file
 * is treated as ooRexx. And the dialect-mismatch check uses it to flag
 * ooRexx syntax in a file explicitly marked as some other dialect.
 *
 * Environment symbols are evidence of ooRexx but not an error elsewhere:
 * in classic Rexx a symbol starting with a period is just a constant
 * symbol (.TRUE is the string '.TRUE'). So callers can leave them out.
 *
 * signs returns one entry per kind found, at its first occurrence, in
 * source order: a .Directory with KIND (a short description), TEXT (the
 * source text), LINE, COLUMN and COUNT (occurrences of that kind).
 */

::class OoRexxSyntax public

::method signs class
  use strict arg parser, includeEnvironmentSymbols = .True

  found = .Directory~new
  order = .Array~new
  previous = .Nil
  element = parser~firstElement
  loop until element == .Nil
     kind = ''
     select
        /* ~~ arrives as two elements; count it once. */
        when element < .EL.OP.CASCADING_MESSAGE then
           if previous == .Nil then kind = 'cascading message operator'
           else if (previous < .EL.OP.CASCADING_MESSAGE) = .False then
              kind = 'cascading message operator'
        when element < .EL.OP.MESSAGE then kind = 'message operator'
        when element < .EL.LEFT_BRACKET then kind = 'bracket'
        when element < .EL.DIRECTIVE_START then kind = 'directive'
        when element < .EL.ENVIRONMENT_SYMBOL then
           if includeEnvironmentSymbols then kind = 'environment symbol'
        otherwise nop
     end
     if kind <> '' then do
        if found~hasIndex(kind) then
           found[kind]~count = found[kind]~count + 1
        else do
           parse value element~from with lineNum colNum
           entry = .Directory~new
           entry~kind = kind
           entry~text = element~value
           if kind = 'cascading message operator' then entry~text = '~~'
           if kind = 'bracket' then entry~text = '[]'
           entry~line = lineNum
           entry~column = colNum
           entry~count = 1
           found[kind] = entry
           order~append(kind)
        end
     end
     previous = element
     element = element~next
  end

  inOrder = .Array~new
  do kind over order
     inOrder~append(found[kind])
  end
  return inOrder
