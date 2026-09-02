/*------------------------------------------------------------------------------
Real-world sample gathered for rexx-lint validation (not written for this
project).
Source: https://prino.neocities.org/zOS/esort.exec.html
Project: Robert AH Prins' "EHI"/ISPF-edit-macro suite for z/OS, part of his
         zOS-Tools page (https://prino.neocities.org/zOS/zOS-Tools) -- ISPF
         edit macro to generate DFSORT FIELDS= statements from include
         members. Copyright (c) Robert AH Prins, 1993-2017. The source page
         renders it as syntax-highlighted HTML (via the author's own
         EHIREXX.rex converter, one of this same suite) rather than serving
         plain text -- the HTML wrapper and <em class="..."> highlighting
         spans were stripped mechanically to recover this plain source, with
         the recovered text verified to contain no leftover markup or HTML
         entities before being saved here.
License: GNU General Public License v3 (or later), per the license notice
         embedded in the file's own header comment below and confirmed
         against the source site's separate GPL-3.0 license page
         (https://www.gnu.org/licenses/gpl-3.0.html). Retained here under
         those terms (verbatim redistribution) as part of rexx-lint's own
         real-world validation corpus; see samples/real-world/README.md.
------------------------------------------------------------------------------*/


/* REXX edit macro to generate SORT FIELDS= from include members      */
/*** trace ?r ***************************************************** \| *
*               (C) Copyright Robert AH Prins, 1993-2017               *
************************************************************************
*  ------------------------------------------------------------------  *
* | Date       | By   | Remarks                                      | *
* |------------+------+----------------------------------------------| *
* |            |      |                                              | *
* |------------+------+----------------------------------------------| *
* | 2017-01-01 | RAHP | Put under GPL V3                             | *
* |------------+------+----------------------------------------------| *
* | 2012-10-19 | RAHP | Move generated output before .zfrange        | *
* |------------+------+----------------------------------------------| *
* | 2007-07-30 | RAHP | Make 'HELP' consistent with all macros       | *
* |------------+------+----------------------------------------------| *
* | 2007-07-25 | RAHP | Use 'MSG' lines in help                      | *
* |------------+------+----------------------------------------------| *
* | 2007-06-14 | RAHP | Correct HELP 'panel'                         | *
* |------------+------+----------------------------------------------| *
* | 2007-05-31 | RAHP | Label line of first linecommand with .SOR    | *
* |------------+------+----------------------------------------------| *
* | 2005-03-31 | RAHP | Support (impossible) CHAR length > 9999      | *
* |------------+------+----------------------------------------------| *
* | 2003-02-25 | RAHP | Remove hardcoded userid for RAHP             | *
* |------------+------+----------------------------------------------| *
* | 2001-06-21 | RAHP | Add support for S/370 floating point         | *
* |------------+------+----------------------------------------------| *
* | 1997-11-12 | RAHP | Allow for variable length files              | *
* |------------+------+----------------------------------------------| *
* | 1993-02-13 | RAHP | Initial version                              | *
* |------------+------+----------------------------------------------| *
************************************************************************
* ESORT is an edit macro to generate 'SORT FIELDS=' statements from    *
* PL/I %include members. The generated statement will contain one line *
* for each field in the record, and it is up to the user to            *
*                                                                      *
* 1) remove the ones that are not required, and                        *
*                                                                      *
* 2) sort the remaining ones in the required order.                    *
************************************************************************
* Send questions, suggestions and/or bug reports to:                   *
*                                                                      *
* robert@prino.org / robert.ah.prins@gmail.com                         *
*                                                                      *
* Robert AH Prins                                                      *
* Taboralaan 46                                                        *
* 8400 Oostende                                                        *
* Belgium                                                              *
************************************************************************
* This program is free software: you can redistribute it and/or        *
* modify it under the terms of the GNU General Public License as       *
* published by the Free Software Foundation, either version 3 of       *
* the License, or (at your option) any later version.                  *
*                                                                      *
* This program is distributed in the hope that it will be useful,      *
* but WITHOUT ANY WARRANTY; without even the implied warranty of       *
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the         *
* GNU General Public License for more details.                         *
*                                                                      *
* You should have received a copy of the GNU General Public License    *
* along with this program. If not, see <https://www.gnu.org/licenses/> *
***********************************************************************/
"ISREDIT MACRO (PARM) NOPROCESS"
parse source source
parse value source with . . moi .
parm  = translate(parm)

dest  = '.zcsr'
line. = ''
type. = 'NOTE'

"isredit (DSN) = dataset"

select
  when parm = '?' then
    do
      call help
      exit
    end

  otherwise
end

"isredit process range SO SOR"

if rc \= 0 then
  do
    type.  = 'MSG'
    i      = 1

    line.i = '  'center('The' moi 'edit macro requires a SORnn or two',
             'SORR linecommand(s)', 68)

    i      = i + 1
    line.i = '  'center('Enter "'moi' ?" for more help', 68)
    line.0 = i

    call message
    exit
  end

"isredit (MEM) = member"
"isredit (LF)  = linenum .zfrange"
"isredit (LL)  = linenum .zlrange"

"isredit label .zfrange = .SOR 0"

head = x2c(00ffd9d7)
tail = reverse(head)
sep  = x2c(ff)
rsep = x2c(01d9d701)

compress = ''

do li = lf + 0 to ll + 0
  "isredit (LINE) = line" li
  compress = compress || sep || strip(substr(line, 2, 71))
end

call parse_and_extract
call process_include

line.0 = i
dest   = lf - 1
call message
exit

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
  line. = '              '
  type. = 'NOTE'
  comma = ','
  i     = 2

  if parm = 'V' then
    pos = 5
  else
    pos = 1

  line.1 = '* SORT FIELDS FOR' mem
  line.2 = '* GENERATED BY' userid() 'ON' translate(date()) 'AT' time()

  do j = 1 to sort.0
    i = i + 1
    if i = 3 then
      line.i = ' SORT FIELDS=('

    if j = sort.0 then
      comma = ')'

    if sort.j.typ \= 'L' then
      line.i = line.i || right(pos, 4, '0')','

    select
      when sort.j.typ = 'A' then
        do
          line.i = line.i || right(sort.j.len, 4, '0') || ',BI,A'comma
        end

      when sort.j.typ = 'B' then
        do
          line.i = line.i || right(sort.j.len, 4, '0') || ',FI,A'comma
        end

      when sort.j.typ = 'C' then
        do
          line.i = line.i || right(sort.j.len, 4, '0') || ',CH,A'comma
        end

      when sort.j.typ = 'I' then
        do
          line.i = line.i || right(sort.j.len, 4, '0') || ',BI,A'comma
        end

      when sort.j.typ = 'D' then
        do
          line.i = line.i || right(sort.j.len, 4, '0') || ',FL,A'comma
        end

      when sort.j.typ = 'P' then
        do
          line.i = line.i || right(sort.j.len, 4, '0') || ',ZD,A'comma
        end

      when sort.j.typ = 'F' then
        do
          sort.j.len = sort.j.len % 2 + 1
          line.i     = line.i || right(sort.j.len, 4, '0') ||,
                       ',PD,A'comma
        end

      when sort.j.typ = 'V' then
        do
          sort.j.len = sort.j.len + 2
          line.i     = line.i || right(sort.j.len, 4, '0') ||,
                       ',CH,A'comma
        end

      otherwise
        i = i - 1
    end

    if sort.j.typ \= 'L' then
      line.i = left(line.i, 35) sort.j.nam

    if length(sort.j.len) > 4 then
      line.i = line.i '** Too long' sort.j.len

    pos = pos + sort.j.len
  end
return

/***********************************************************************
* Parse_and_extract:                                                   *
*                                                                      *
* This procedure calls the %INCLUDE book parser and extracts the data  *
* returned by it into a number of arrays.                              *
***********************************************************************/
parse_and_extract:
  call rap00110 compress, e, nopli

  tmp = result

  /*********************************************************************
  * Check that the parser has returned a valid string                  *
  *********************************************************************/
  if substr(tmp, 1, 4) \= head |,
     substr(tmp, length(tmp) - 3, 4) \= tail then
    do
      zedsmsg = 'PARSER error, press HELP'
      zedlmsg = "The parser returned an invalid string, contact RAHP"
      "ispexec setmsg msg(ISRZ001)"
      exit
    end

  /*********************************************************************
  * Parse the returned string into the its parts                       *
  *********************************************************************/
  vi  = 0
  tmp = substr(tmp, 5)

  do until tmp = tail
    vi = vi + 1
    parse value tmp with sort.vi.lev (sep),
                         sort.vi.nam (sep),
                         sort.vi.len (sep),
                         sort.vi.prc (sep),
                         sort.vi.typ (rsep) tmp
  end

  sort.0 = vi
return

/***********************************************************************
* HELP:                                                                *
*                                                                      *
* HELP is a general "help" screen displaying routine                   *
***********************************************************************/
help:
  arg parm

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
  line.i = '  The' moi 'edit macro can be used as a simple',
           'replacement for OLS. It'
  i      = i + 1
  line.i = '  may not have the full functionality of OLS, but if a',
           'simple "SORT '
  i      = i + 1
  line.i = '  FIELDS=" statement is all you want, this macro is a',
           'lot easier to use'
  i      = i + 1
  line.i = '  than going through all the steps required to do so in',
           'OLS. Of course'
  i      = i + 1
  line.i = '  'moi' is not (yet) a full blown replacement for OLS,',
           'because it does'
  i      = i + 1
  line.i = '  no allow selection of individual fields in a record,',
           'it will simply '
  i      = i + 1
  line.i = '  add a field statement for each field in the record,',
           'and it is up to '
  i      = i + 1
  line.i = '  you, dear user, to remove the ones that you do not',
           'require.'
  i      = i + 2
  line.i = '  User instructions:'
  type.i = 'MSG'
  i      = i + 2
  line.i = '  1) Mark the lines for which you want to generate a',
           '"SORT FIELDS=" '
  i      = i + 1
  line.i = '     statement with either '
  i      = i + 2
  line.i = '     - a SORnnn line command on the first line, with',
           'nnn the number of'
  i      = i + 1
  line.i = '       fields to be included, OR'
  i      = i + 1
  line.i = '     - SORR line commands on the first and last lines',
           'containing the'
  i      = i + 1
  line.i = '       fields to be included.'
  i      = i + 2
  line.i = '     It is of course fairly important to make sure that',
           'the SORnnn or '
  i      = i + 1
  line.i = '     the first SORR are right at the beginning of the',
           'member, in order'
  i      = i + 1
  line.i = '     to calculate the offsets. Also note that 'moi,
           'will assume that'
  i      = i + 1
  line.i = '     the record does not contain any padding.'
  i      = i + 2
  line.i = '  2) Enter "'moi'" on the command line and press ENTER.'
  i      = i + 2
  line.i = '  3) Use the "MD" line command to convert the generated',
           '"=NOTE=" lines'
  i      = i + 1
  line.i = '     into actual data lines. '
  i      = i + 2
  line.i = '  4) Use two "MM" linecommands and a "CREATE" primary',
           'command to move '
  i      = i + 1
  line.i = '     the load definition generated by this wonderful',
           'piece of magic '
  i      = i + 1
  line.i = '     into a member of its own.'
  i      = i + 2
  line.i = center(' End of HELP information ', 72, '*')
  type.i = 'MSG'
  line.0 = i

  call message
return
   
