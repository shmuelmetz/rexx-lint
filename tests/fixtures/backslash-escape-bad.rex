/* Fixture: backslash sequences that look like escapes but aren't,
 * chosen so the tracked letter is NOT immediately followed by
 * another letter (see checks/BackslashEscape.cls's docstring on why
 * that distinction matters -- it's what tells these apart from a
 * Windows/OS/2 path fragment like "\backup" or "\temp"). */

say "Error occurred\n"
say "columns:\t1\t2\t3"
say 'quote next:\" end'
