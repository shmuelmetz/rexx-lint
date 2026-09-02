/*------------------------------------------------------------------------------
Real-world sample gathered for rexx-lint validation (not written for this
project).
Source: https://prino.neocities.org/zOS/esymsort.exec.html
Project: Robert AH Prins' "EHI"/ISPF-edit-macro suite for z/OS, part of his
         zOS-Tools page (https://prino.neocities.org/zOS/zOS-Tools) -- ISPF
         edit macro to generate DFSORT sort symbols. Copyright (c) Robert AH
         Prins, 2007-2017. The source page renders it as syntax-highlighted
         HTML (via the author's own EHIREXX.rex converter, one of this same
         suite) rather than serving plain text -- the HTML wrapper and <em
         class="..."> highlighting spans were stripped mechanically to
         recover this plain source, with the recovered text verified to
         contain no leftover markup or HTML entities before being saved
         here.
License: GNU General Public License v3 (or later), per the license notice
         embedded in the file's own header comment below and confirmed
         against the source site's separate GPL-3.0 license page
         (https://www.gnu.org/licenses/gpl-3.0.html). Retained here under
         those terms (verbatim redistribution) as part of rexx-lint's own
         real-world validation corpus; see samples/real-world/README.md.
------------------------------------------------------------------------------*/


/* REXX edit macro to generate sort symbols for DFSORT                */
/*** trace ?r ***************************************************** \| *
*               (C) Copyright Robert AH Prins, 2007-2017               *
************************************************************************
*  ------------------------------------------------------------------  *
* | Date       | By   | Remarks                                      | *
* |------------+------+----------------------------------------------| *
* |            |      |                                              | *
* |------------+------+----------------------------------------------| *
* | 2017-01-01 | RAHP | Put under GPL V3                             | *
* |------------+------+----------------------------------------------| *
* | 2015-05-18 | RAHP | Move generated output before .zfrange        | *
* |------------+------+----------------------------------------------| *
* | 2009-09-02 | RAHP | Use 'SPACE' to compress input                | *
* |------------+------+----------------------------------------------| *
* | 2007-07-30 | RAHP | Make 'HELP' consistent with all macros       | *
* |------------+------+----------------------------------------------| *
* | 2007-07-25 | RAHP | Use 'MSG' lines in help                      | *
* |------------+------+----------------------------------------------| *
* | 2007-06-14 | RAHP | Initial version - based on ESORT             | *
* |------------+------+----------------------------------------------| *
************************************************************************
* ESYMSORT is an edit macro to generate sort symbols for DFSORT from   *
* PL/I %include members. The generated statement will contain one line *
* for each field in the record.                                        *
************************************************************************
* Possible to-do's:                                                    *
*                                                                      *
*  - cater for 'L' items (length is total of all children)             *
*  - use '*' for position after first element                          *
*  - use 'POSITION' keyword for unions                                 *
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
"isredit macro (parm) NOPROCESS"
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

"isredit process range SY SYM"

if rc \= 0 then
  do
    type.  = 'MSG'
    i      = 1

    line.i = '  'center('The' moi 'edit macro requires a SYMnn or two',
             'SYMM linecommand(s)', 68)

    i      = i + 1
    line.i = '  'center('Enter "'moi' ?" for more help', 68)
    line.0 = i

    call message
    exit
  end

"isredit (MEM) = member"
"isredit (LF)  = linenum .zfrange"
"isredit (LL)  = linenum .zlrange"

"isredit label .zfrange = .SYM 0"

call parse_and_extract
call qualify_names
call process_include

line.0 = i
type.  = 'note'
dest   = lf - 1
call message
exit

/***********************************************************************
* Parse_and_extract:                                                   *
*                                                                      *
* This procedure calls the %INCLUDE book parser and extracts the data  *
* returned by it into a number of arrays.                              *
***********************************************************************/
parse_and_extract:
  head = x2c(00ffd9d7)
  tail = reverse(head)
  sep  = x2c(ff)
  rsep = x2c(01d9d701)

  compress = ''

  do li = lf + 0 to ll + 0
    "isredit (LINE) = line" li
    compress = compress || sep || space(substr(line, 2, 71))
  end

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

  sort. = 0

  do until tmp = tail
    vi = vi + 1
    parse value tmp with sort.vi.lev (sep),
                         sort.vi.nam (sep),
                         sort.vi.len (sep),
                         sort.vi.prc (sep),
                         sort.vi.typ (rsep) tmp
    sort.vi.nam = strip(sort.vi.nam,, ',')
  end

  sort.0 = vi
return

/***********************************************************************
* QUALIFY_NAMES:                                                       *
*                                                                      *
* This procedure fully qualifies all names of the structure, up to the *
* highest - 1 level, ie the level-1 name will not be included. It also *
* translates all parentheses and commas into '-' and all '.'s in '$'   *
* to make the output compatible with the requirements of DFSORT's      *
* symbol features.                                                     *
***********************************************************************/
qualify_names:
  lev.  = 0
  max   = -1
  level = ''

  /*********************************************************************
  * Find the maximum level in the structure                            *
  *********************************************************************/
  do i = 1 to sort.0
    l     = +sort.i.lev
    lev.l = l

    max   = max(max, l)
  end

  /*********************************************************************
  * Build a string of all levels in use in the structure               *
  *********************************************************************/
  do i = 1 to max
    if lev.i \= 0 then
      level = level lev.i
  end

  do while level \= ''
    do i = 1 to sort.0
      /*****************************************************************
      * Find element on the lowest level                               *
      *****************************************************************/
      if sort.i.lev = word(level, words(level)) then
        do
          /*************************************************************
          * Get the level of the parent - the 'sort.' stem was set to  *
          * '0' so eventually everything will end up on level 0        *
          *************************************************************/
          blev = value('sort.'i - 1'.lev')

          /*************************************************************
          * Get the name of the parent on the higher level and add a   *
          * '.' to it to fully qualify the name. Zap any '0.' names    *
          * resulting from fast that the 'sort.' stem was set to 0.    *
          *************************************************************/
          bnam = strip(value('sort.'i - 1'.nam'),, ',')'.'

          if bnam = '0.' then
            bnam = ''

          /*************************************************************
          * Re-level and rename the lower level                        *
          *************************************************************/
          do j = i by 1 while sort.j.lev = word(level, words(level))
            sort.j.lev = blev
            sort.j.nam = bnam || sort.j.nam
          end
        end
    end

    /*******************************************************************
    * Remove the now re-leveled lowest level                           *
    *******************************************************************/
    level = strip(delword(level, words(level)))
  end

  /*********************************************************************
  * Determine if there is a common top-level qualifier                 *
  *********************************************************************/
  if sort.0 > 1 then
    do
      parse value sort.1.nam with top '.' .

      do i = 2 to sort.0 while top \= ''
        parse value sort.i.nam with tmp '.' .

        if tmp \= top then
          top = ''
      end
    end
  else
    top = ''

  s    = 0
  sym. = ''

  /*********************************************************************
  * Copy the data to a new stem for further processing, stripping out  *
  * all fields that do not contain attributes. If all elements have    *
  * the same top-level qualifier, this is also removed.                *
  *********************************************************************/
  do i = 1 to sort.0
    if parm \= 'RAW' then
      do
        if sort.i.typ = 'L' then
          iterate i

        if i    > 1 &,
           top \= '' then
          parse value sort.i.nam with . '.' sort.i.nam
      end

    s         = s + 1
    line.s    = sort.i.lev sort.i.nam sort.i.len sort.i.prc sort.i.typ
    sym.s.lev = sort.i.lev
    sym.s.nam = sort.i.nam
    sym.s.len = sort.i.len
    sym.s.prc = sort.i.prc
    sym.s.typ = sort.i.typ

    if parm \= 'RAW' then
      do
        sym.s.nam = space(translate(sym.s.nam, ' ', ')'), 0)
        sym.s.nam = strip(translate(sym.s.nam, '$--', '.(,'),, '-')
      end
  end

  sym.0 = s
return

/***********************************************************************
* PROCESS_INCLUDE:                                                     *
*                                                                      *
* This procedure processes the %include book.                          *
***********************************************************************/
process_include:
  line. = ''
  type. = 'NOTE'
  i     = 2

  if parm = 'V' then
    pos = 5
  else
    pos = 1

  line.1 = '* DFSORT symbols for' mem
  line.2 = '* Generated by' userid() 'on' translate(date()) 'at' time()

  do j = 1 to sym.0
    if sym.j.typ = 'L' then
      iterate j

    i = i + 1

    line.i = sym.j.nam','right(pos, 5, '0')','

    select
      when sym.j.typ = 'A' then
        do
          line.i = line.i || right(sym.j.len, 4, '0') || ',BI'
        end

      when sym.j.typ = 'B' then
        do
          line.i = line.i || right(sym.j.len, 4, '0') || ',FI'
        end

      when sym.j.typ = 'C' then
        do
          line.i = line.i || right(sym.j.len, 4, '0') || ',CH'
        end

      when sym.j.typ = 'I' then
        do
          line.i = line.i || right(sym.j.len, 4, '0') || ',BI'
        end

      when sym.j.typ = 'D' then
        do
          line.i = line.i || right(sym.j.len, 4, '0') || ',FL'
        end

      when sym.j.typ = 'P' then
        do
          line.i = line.i || right(sym.j.len, 4, '0') || ',ZD'
        end

      when sym.j.typ = 'F' then
        do
          sym.j.len = sym.j.len % 2 + 1
          line.i     = line.i || right(sym.j.len, 4, '0') ||,
                       ',PD'
        end

      when sym.j.typ = 'V' then
        do
          sym.j.len = sym.j.len + 2
          line.i     = line.i || right(sym.j.len, 4, '0') ||,
                       ',CH'
        end

      otherwise
        i = i - 1
    end

    pos = pos + sym.j.len
  end
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
  line.i = '  The' moi 'edit macro can be used to generate DFSORT',
           'symbol files'
  i      = i + 1
  line.i = '  from PL/I record structures.'
  i      = i + 2
  line.i = '  User instructions:'
  type.i = 'MSG'
  i      = i + 2
  line.i = '  1) Mark the lines for which you want to generate a',
           '"DFSORT symbols'
  i      = i + 1
  line.i = '     file with either '
  i      = i + 2
  line.i = '     - a SYMnnn line command on the first line, with',
           'nnn the number of'
  i      = i + 1
  line.i = '       fields to be included, OR'
  i      = i + 1
  line.i = '     - SYMM line commands on the first and last lines',
           'containing the'
  i      = i + 1
  line.i = '       fields to be included.'
  i      = i + 2
  line.i = '     It is of course fairly important to make sure that',
           'the SYMnnn or '
  i      = i + 1
  line.i = '     the first SYMM are right at the beginning of the',
           'record, in order'
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
   
