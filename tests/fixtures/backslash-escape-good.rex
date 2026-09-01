/* Fixture: strings with no backslash, or a backslash not followed by
 * a letter that looks like an escape code -- should find nothing. */

say "line one" || '0a'x || "line two"
say 'plain text, no backslash at all'
path = "C:\Program Files\App"
