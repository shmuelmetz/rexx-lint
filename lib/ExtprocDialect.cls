/* ExtprocDialect.cls -- infers a source file's Rexx dialect, or
 * detects that it isn't Rexx at all, from its own extproc/shebang
 * line, so rexx-lint doesn't have to be told --dialect= by hand for
 * every file in a mixed real-world collection.
 *
 * OS/2 and its descendants (eCS, ArcaOS) treat a .cmd file as Rexx
 * by default; a leading "extproc <interpreter> [args...]" line is
 * the documented escape hatch a script uses to route itself to a
 * *different* interpreter instead. A POSIX "#!<path> [args...]"
 * shebang line serves the same purpose on Unix-like systems,
 * sometimes present as a second line right after "extproc" so both
 * conventions cooperate on the same file -- verified against real
 * files in local-test-data/utility-cmd/ (not committed), e.g.
 * "extproc perl -STw" on line 1 followed by "#!/usr/bin/perl -Tw"
 * on line 2.
 *
 * Genuine Rexx files in that same real-world corpus have NEITHER
 * line -- the default interpreter (whichever Rexx is registered for
 * .cmd on that system) applies with no declaration at all, so "no
 * extproc/shebang found" is itself evidence FOR Rexx, not against
 * it, and is treated that way below (no dialect override, no
 * non-Rexx flag).
 *
 * Two-tier name resolution, deliberately:
 * 1. A table of interpreter basenames actually confirmed to mean
 *    something specific -- either a distinct Rexx dialect (regina,
 *    brexx, ...) or a well-known non-Rexx interpreter (perl,
 *    python, a POSIX shell, ...). A bare "rexx" is deliberately NOT
 *    in this table: that literal name is used by classic REXX,
 *    ooRexx, and others alike, so it cannot be resolved from the
 *    name alone.
 * 2. For any name the table doesn't recognize, a narrow heuristic:
 *    if "rexx" appears anywhere in the interpreter's own basename,
 *    it's very likely *some* Rexx implementation this table just
 *    doesn't have a specific entry for, so fall back to rexx-lint's
 *    own existing default dialect rather than a specific guess this
 *    can't actually justify. If "rexx" does NOT appear, stay
 *    silent -- an unfamiliar name is genuinely unknown, not
 *    evidence either way, so the parser's own attempt (and its
 *    SIGNAL ON SYNTAX trap in bin/rexx-lint.rex) is left to decide,
 *    exactly as it already does for a file with no extproc/shebang
 *    line at all. This check tests each file's own extproc/shebang
 *    text, never assumes from one collection's naming habits.
 */

::class ExtprocDialect public

::method dialectTable class
  /* interpreter basename (lowercase, no path, no .exe) -> one of
   * rexx-lint's own --dialect= values (classic/oorexx/regina/zvm/
   * omvs/tso/netrexx/executor). Not exhaustive -- only names with an
   * actual, specific meaning. */
  table = .Directory~new
  table~put('regina',       'regina')
  table~put('regina',       'rxregina')
  table~put('classic',      'brexx')
  table~put('zvm',          'rexxvm')
  table~put('oorexx',       'oorexx')
  table~put('netrexx',      'netrexx')
  table~put('netrexx',      'nrx')
  table~put('executor',     'rexxexecutor')
  table~put('executor',     'executor')
  return table

::method knownNonRexxInterpreters class
  /* Common shebang/extproc targets that are definitely not any Rexx
   * dialect. Space-separated, checked with WORDPOS (whole-word,
   * not substring) so e.g. "sh" doesn't false-match inside "bash". */
  return 'perl perl5 python python2 python3 bash sh ksh csh tcsh zsh' ,
      || ' awk gawk nawk tclsh wish ruby jruby node nodejs lua php' ,
      || ' pwsh powershell'

/* detect -- read up to the first two lines of `file` and look for an
 * extproc or shebang line. Returns a Directory with:
 *   INTERPRETER  the raw interpreter token found, or '' if none
 *   DIALECT      an inferred --dialect= value, or '' if none inferred
 *   ISNONREXX    .True if the interpreter is a known non-Rexx one
 *   SOURCE       'extproc', 'shebang', or 'none'
 * Never raises on a missing/unreadable file -- returns the all-empty
 * default instead, since the caller's own parse attempt is what
 * actually needs to handle that case. */
::method detect class
  use strict arg file

  info = .Directory~new
  info~put('',      'INTERPRETER')
  info~put('',      'DIALECT')
  info~put(.False,  'ISNONREXX')
  info~put('none',  'SOURCE')

  lines = self~firstLines(file)

  interpreter = ''
  source = 'none'
  do line over lines
     trimmed = line~strip
     if trimmed~word(1)~caselessEquals('extproc') then do
        interpreter = trimmed~word(2)
        source = 'extproc'
        leave
     end
     if trimmed~left(2) == '#!' then do
        rest = trimmed~substr(3)~strip
        firstToken = rest~word(1)
        if self~basename(firstToken)~caselessEquals('env') then
           interpreter = rest~word(2)
        else
           interpreter = firstToken
        source = 'shebang'
        leave
     end
  end

  if interpreter == '' then return info

  info~put(interpreter, 'INTERPRETER')
  info~put(source,      'SOURCE')

  base = self~basename(interpreter)~lower

  table = self~dialectTable
  if table~hasIndex(base) then do
     info~put(table~at(base), 'DIALECT')
     return info
  end

  if wordPos(base, self~knownNonRexxInterpreters) > 0 then do
     info~put(.True, 'ISNONREXX')
     return info
  end

  if base~pos('rexx') > 0 then
     info~put('oorexx', 'DIALECT')

  return info

::method firstLines class
  use strict arg file

  lines = .Array~new
  str = .Nil
  signal on syntax name Done
  signal on notready name Done

  str = .stream~new(file)
  if str~lines > 0 then lines~append(str~linein)
  if str~lines > 0 then lines~append(str~linein)

Done:
  if str \== .Nil then str~close
  return lines

::method basename class
  use strict arg path

  normalized = path~changeStr('/', '\')
  pos = normalized~lastPos('\')
  base = normalized~substr(pos + 1)
  if base~length > 4, base~right(4)~caselessEquals('.exe') then
     base = base~left(base~length - 4)
  return base
