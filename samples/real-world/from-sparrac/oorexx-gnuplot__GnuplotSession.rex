/*----------------------------------------------------------------------------
Real-world sample gathered for rexx-lint validation (not written for this
project).
Source: https://github.com/sparrac/oorexx-gnuplot/blob/master/GnuplotSession.rex
Project: oorexx-gnuplot (Salvador Parra Camacho) -- a personal ooRexx library
         announced on the rexxla-members mailing list, September 2026.
License: Apache License 2.0 (Apache-2.0) -- see the source repo's LICENSE.
         Retained as part of rexx-lint's real-world validation corpus;
         see samples/real-world/README.md.
----------------------------------------------------------------------------*/
/*
 * Library:     oorexx-gnuplot: gnuplot for ooRexx
 * File:        GnuplotSession.rex
 * Description: Provides an interactive, persistent IPC session manager for
 *              Gnuplot in Open Object Rexx. Enables real-time,
 *              command streaming via Unix FIFOs (named pipes) and Windows OLE
 *              automation without generating temporary script files.
 *
 * Author:      Salvador Parra Camacho
 * Version:     0.1.1
 * Date('S'):   20260831
 * License:     Apache 2.0
 * Repository:  https://github.com/sparrac/oorexx-gnuplot
 */
 
::class GnuplotSession public

::constant VERSION "0.1.1"
::constant LIBRARY "oorexx-gnuplot"

::method init

  parse source opsys . .
  self~iswindows = opsys~upper~abbrev('WINDOWS')

  self~gpbin  = 'gnuplot'
  self~isopen = .false

  if \ self~iswindows then do
    self~pipe   = self~getPipeName()
    self~stream = .Stream~new(self~pipe)
    end
  else do
    self~pipe   = .nil
    self~stream = .nil
    end

::method gpbin attribute
::method pipe attribute private
::method isopen attribute private
::method stream attribute private
::method iswindows attribute private

::method open
  if \ self~iswindows then do
    'mkfifo "' || self~pipe || '"'
    '"'self~gpbin'" -p < "'self~pipe'" &'
    self~stream~open("read")
    if rc = 0 then self~isopen = .true
    end
  else do
    gp = .OLEObject~New("wscript.shell")~exec(self~gpbin '-p')
    self~pipe = gp~stdin
    self~isopen = .true
    rc = 0
    end
  return rc

::method close
  self~command('quit')
  if \ self~iswindows then do
    self~stream~close
    ret = SysFileDelete(self~pipe)
    end
  else
    ret = 1

  return ret

::method uninit
  if self~isopen = .true then self~close
  
::method command

  if self~isopen = .false then self~open

  parse arg command
  if \ self~iswindows then do
    self~stream~charout(command '0a'x)
    self~stream~flush
    ret = result
    end
  else do  
    self~pipe~writeline(command)
    ret = 1
    end
  return ret

::method set
  parse arg command
  return self~command('set' command)

::method unset
  parse arg command
  return self~command('unset' command)

::method reset
  parse arg command
  return self~command('reset' command)

::method plot
  parse arg command
  return self~command('plot' command)

::method splot
  parse arg command
  return self~command('splot' command)

::method replot
  parse arg command
  return self~command('replot' command)
  
::method getPipeName private

  if self~iswindows then
    path = value('TEMP', , 'ENVIRONMENT') || '\'
  else
    path = ''

  return SysTempFileName(path || 'gnuplotfifo.???')
  
::method "[]="
  use arg val, key
  key = key~lower
  if val = .nil then return self~command('unset' key)
  return self~command('set' key val)
  
::method unknown
  use arg msg, args
  
  msg = msg~lower
  
  select
  when msg~endsWith('='), args[1] \= .nil then
    command = 'set' msg~left(msg~length - 1) args~tostring
  when msg~endsWith('='), args[1] = .nil then
    command = 'unset' msg~left(msg~length - 1)
  otherwise
    command = msg args~tostring
  end

  return self~command(command)

::method data
  expose counter
  
  if \datatype(counter, 'W') then
    counter = 0
  
  -- Second argument exists and is an Array
  if arg(2, 'E'), arg(2)~isA(.Array) then do
    x = arg(1)
    y = arg(2)
    name = arg(3)
    
    block = .Array~new
    minLen = min(x~items, y~items)
    do i = 1 to minLen
      block~append(x[i] y[i])
    end
  end
  else do
    block = arg(1)
    name = arg(2)
  end
  
  -- Third argument omitted
  if arg(3, 'O') & (var('name') = 0  | name = '' | name = .nil) then do
    counter += 1
    name = '$data' || counter
  end
  else if \name~startsWith('$') then do
    name = '$' || name
  end
  
  -- Send data to gnuplot
  self~command(name '<< EOD')
  
  -- The data block is an array
  if block~isA(.Array) then do
    do e over block
      if e~isA(.Array) then -- Each element is an array
        self~command(e~makearray~makestring(, ' '))
      else
        self~command(e)
    end
  end
    
  -- The data block is a string
  else do
    self~command(block)
  end

  -- End Of Data
  self~command('EOD')
  
  return name
