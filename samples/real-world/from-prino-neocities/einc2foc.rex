/*------------------------------------------------------------------------------
Real-world sample gathered for rexx-lint validation (not written for this
project).
Source: https://prino.neocities.org/zOS/einc2foc.exec.html
Project: Robert AH Prins' "EHI"/ISPF-edit-macro suite for z/OS, part of his
         zOS-Tools page (https://prino.neocities.org/zOS/zOS-Tools) -- ISPF
         edit macro to generate a Focus FFile from a %INCLUDE member.
         Copyright (c) Robert AH Prins, 1992-2017. The source page renders
         it as syntax-highlighted HTML (via the author's own EHIREXX.rex
         converter, one of this same suite) rather than serving plain text
         -- the HTML wrapper and <em class="..."> highlighting spans were
         stripped mechanically to recover this plain source, with the
         recovered text verified to contain no leftover markup or HTML
         entities before being saved here.
License: GNU General Public License v3 (or later), per the license notice
         embedded in the file's own header comment below and confirmed
         against the source site's separate GPL-3.0 license page
         (https://www.gnu.org/licenses/gpl-3.0.html). Retained here under
         those terms (verbatim redistribution) as part of rexx-lint's own
         real-world validation corpus; see samples/real-world/README.md.
------------------------------------------------------------------------------*/


/* REXX edit macro to create Focus FFile from an %include member      */
/*** trace ?r ***************************************************** \| *
*               (C) Copyright Robert AH Prins, 1992-2017               *
************************************************************************
*  ------------------------------------------------------------------  *
* | Date       | By   | Remarks                                      | *
* |------------+------+----------------------------------------------| *
* |            |      |                                              | *
* |------------+------+----------------------------------------------| *
* | 2017-01-24 | RAHP | Change "help" screen                         | *
* |------------+------+----------------------------------------------| *
* | 2009-09-02 | RAHP | Use 'SPACE' to compress input                | *
* |------------+------+----------------------------------------------| *
* | 2009-06-03 | RAHP | Use BLKSIZE(0)                               | *
* |------------+------+----------------------------------------------| *
* | 2007-07-25 | RAHP | Use 'MSG' lines in help                      | *
* |------------+------+----------------------------------------------| *
* | 1998-10-12 | RAHP | Add support for FIXED BINs                   | *
* |------------+------+----------------------------------------------| *
* | 1997-05-24 | RAHP | Use GETVAR for some variables                | *
* |------------+------+----------------------------------------------| *
* | 1997-05-22 | RAHP | Blocksizes changed for 3390                  | *
* |------------+------+----------------------------------------------| *
* | 1992-01-12 | RAHP | Initial version                              | *
* |------------+------+----------------------------------------------| *
************************************************************************
* EINC2FOC is an edit macro to generate a Focus FFILE definition from  *
* an %include member.                                                  *
***********************************************************************/
parse source source
parse value source with . . moi .

"isredit macro (parm) NOPROCESS"
parm = translate(parm)

dest  = '.zcsr'
line. = ''
type. = 'NOTE'

select
  when parm = '?' then
    do
      call help
      exit
    end

  otherwise
end

"isredit process range FOC"

if rc \= 0 then
  do
    type.  = 'MSG'
    i      = 1

    line.i = '  'center('The' moi 'edit macro requires an FOC999',
             'linecommand', 68)

    i      = i + 1
    line.i = '  'center('Enter "'moi '?" for more help', 68)
    line.0 = i

    call message
    exit
  end

head = x2c(00ffd9d7)
tail = reverse(head)
sep  = x2c(ff)
rsep = x2c(01d9d701)

"isredit (LF) = linenum .zfrange"
"isredit (LL) = linenum .zlrange"

compress = ''

do li = lf + 0 to ll + 0
  "isredit (LINE) = line" li
  compress = compress || sep || space(substr(line, 2, 71))
end

call process_include
"isredit cancel"
"ispexec edit dataset('"userid().ffile"')"
exit

/***********************************************************************
* HELP:                                                                *
*                                                                      *
* HELP is a general "help" screen displaying routine                   *
***********************************************************************/
help:
  arg parm

  type.  = 'NOTE'
  i      = 1
  text   = 'The' moi 'edit macro'
  line.i = center(text, 72)
  type.i = 'MSG'
  i      = i + 1
  line.i = center(left('~', length(text), '~'), 72)
  type.i = 'MSG'
  i      = i + 1
  line.i = center(' Use DOWN to read all "HELP"',
           'screens ', 72, '*')
  type.i = 'MSG'

  i      = i + 2
  line.i = '  The' moi 'edit macro generates a Focus FFILE',
           'definition from the'
  i      = i + 1
  line.i = '  .INC member currently being edited. The Focus FFILE',
           'definition will'
  i      = i + 1
  line.i = '  be inserted into the current member a series of',
           '"=NOTE=" lines.'

  i      = i + 2
  line.i = '  Usage:'
  type.i = 'MSG'

  i      = i + 2
  line.i = '  1) Enter "FOC999" on the first line of the %include',
           'member being,'

  i      = i + 1
  line.i = '     edited, OR, "FOCC" on the first and last lines to be',
           'included in'

  i      = i + 1
  line.i = '     the to be generated FFILE dataset.'

  i      = i + 2
  line.i = '  2) Enter "'moi'" on the command line and press ENTER.'

  i      = i + 2
  line.i = '  3) Use two "MM" linecommands and a "CREATE" primary',
           'command to move'
  i      = i + 1
  line.i = '     the FFILE definition generated by this wonderful',
           'piece of magic'
  i      = i + 1
  line.i = '     into a member of its own.'

  i      = i + 2
  line.i = center(' End of HELP information ', 72, '*')
  type.i = 'MSG'
  line.0 = i

  call message
return

/***********************************************************************
* MESSAGE is a general purpose edit message insertion routine          *
***********************************************************************/
message:
  "isredit (STATE) = user_state"
  "isredit caps = off"
  do i = line.0 to 1 by -1
    lin = line.i
    "isredit line_after "dest" = "type.i"line (LIN)"
  end
  "isredit user_state = (STATE)"
  "isredit locate" dest
return

/***********************************************************************
* Process_include:                                                     *
*                                                                      *
* This procedure processes the %include book.                          *
***********************************************************************/
process_include:
  call rap00110 compress, e, nopli
  tmp = result

  /*********************************************************************
  * Check that the parser has returned a valid string                  *
  *********************************************************************/
  if substr(tmp, 1, 4) \= head |,
     substr(tmp, length(tmp) - 3, 4) \= tail then
    do
      type.  = 'MSG'
      i      = 1
      line.i = ' /'left('*', 70, '*')
      i      = i + 1
      line.i = ' * The parser has returned an invalid string. Contact',
               'RAHP ('getvar('xRAHP')')'
      line.i = left(line.i, 71)'*'
      i      = i + 1
      line.i = ' 'left('*', 70, '*')'/'
      return
    end

  /*********************************************************************
  * Parse the returned string into the its parts                       *
  *********************************************************************/
  vi  = 0
  tmp = substr(tmp, 5)

  do until tmp = tail
    vi = vi + 1
    parse value tmp with foc.vi.lev (sep),
                         foc.vi.nam (sep),
                         foc.vi.len (sep),
                         foc.vi.prc (sep),
                         foc.vi.typ (rsep) tmp
  end

  foc.0 = vi

  "isredit (MEM) = member"

  type.  = 'NOTE'

  line.1 = 'FILE='mem',SUFFIX=FIX'
  line.2 = 'SEGNAME='mem',SEGTYPE=S1'
  i      = 2

  do j = 1 to foc.0
    if foc.j.typ \= 'L' then
      do
        i      = i + 1
        line.i = ' FIELD='
        line.i = line.i substr(foc.j.nam, 1, 12) || '     ,ALIAS='
        line.i = line.i || strip(substr(foc.j.nam, 1, 4))
        line.i = line.i ||,
                 substr(foc.j.nam, max(length(foc.j.nam) - 2, 1))
        line.i = left(line.i, 44) || ',USAGE='

        select
          when foc.j.typ = 'C' then
            do
              line.i = line.i || 'A' || foc.j.len
              act    = 'A' || foc.j.len
            end

          when foc.j.typ = 'F' then
            do
              if foc.j.prc \= 0 then
                line.i = line.i || 'P' || foc.j.len || '.' || foc.j.prc
              else
                line.i = line.i || 'P' || foc.j.len

              act = 'P' || ((foc.j.len + 1) % 2)
            end

          when foc.j.typ = 'P' then
            do
              if foc.j.prc \= 0 then
                line.i = line.i || 'D' || foc.j.len || '.' || foc.j.prc
              else
                line.i = line.i || 'D' || foc.j.len

              act  = 'A' || foc.j.len
            end

          when foc.j.typ = 'B' then
            do
              line.i = line.i || 'I4'

              act  = 'A' || foc.j.len
            end

          otherwise
            do
              line.i = line.i || '?'
              act  = ''
            end
        end

        line.i = left(line.i, 58) || ',ACTUAL=' || act
        line.i = left(line.i, 70) || ',$'
      end
  end

  line.0 = i

  dynlib = 'dyn'random(99999)
  "alloc f("dynlib") del space(1,1) recfm(f b) lrecl(80) blksize(0) reu"

  'execio * diskw' dynlib '( stem line. finis'

  "ispexec lminit dataid(mydsn) ddname("dynlib") enq(exclu)"
  "ispexec view dataid("mydsn")"
  "ispexec lmfree dataid("mydsn")"

  "free f("dynlib")"
return
   
