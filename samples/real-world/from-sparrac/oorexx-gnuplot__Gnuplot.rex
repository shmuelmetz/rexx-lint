/*----------------------------------------------------------------------------
Real-world sample gathered for rexx-lint validation (not written for this
project).
Source: https://github.com/sparrac/oorexx-gnuplot/blob/master/Gnuplot.rex
Project: oorexx-gnuplot (Salvador Parra Camacho) -- a personal ooRexx library
         announced on the rexxla-members mailing list, September 2026.
License: Apache License 2.0 (Apache-2.0) -- see the source repo's LICENSE.
         Retained as part of rexx-lint's real-world validation corpus;
         see samples/real-world/README.md.
----------------------------------------------------------------------------*/
/*
 * Library:     oorexx-gnuplot: gnuplot for ooRexx
 * File:        Gnuplot.rex
 * Description: An object-oriented wrapper for Gnuplot in Open Object Rexx.
 *              Provides a simple interface to generate 2D/3D plots from data
 *              series (functions, arrays, files), configure output terminals
 *              and export to graphic formats.
 *
 * Author:      Salvador Parra Camacho
 * Version:     0.1.1
 * Date('S'):   20260831
 * License:     Apache 2.0
 * Repository:  https://github.com/sparrac/oorexx-gnuplot
 */
 
::class Gnuplot public

::constant VERSION "0.1.1"
::constant LIBRARY "oorexx-gnuplot"

::method terminals attribute class
::method persist attribute private class
::method iswindows attribute private class

::method init class
  t = .Directory~new
  t~png  = 'pngcairo enhanced'
  t~svg  = 'svg dashed enhanced'
  t~pdf  = 'pdfcairo linewidth 4 rounded fontscale 1.0'
  t~wxt  = 'wxt enhanced'
  t~qt   = 'qt enhanced'
  t~html = 'canvas'
  self~terminals = t
  
  p = .Directory~new
  p~wxt = .true
  p~qt  = .true
  self~persist = p

  parse source opsys . .
  self~iswindows = opsys~upper~abbrev('WINDOWS')
  
::method bin attribute       -- gnuplot executable path
::method plots attribute     -- array of plots
::method debug attribute     -- debug option
::method constants attribute -- array of constants
::method persist attribute   -- gnuplot persist option
::method title attribute     -- figure title
::method key attribute       -- figure key
::method grid attribute      -- figure grid
::method width attribute     -- figure width
::method height attribute    -- figure height
::method xlabel attribute    -- figure x label (bottom)
::method x2label attribute   -- figure x label (top)
::method ylabel attribute    -- figure y label (left)
::method y2label attribute   -- figure y label (right)
::method terminal attribute

::method init
	self~bin       = 'gnuplot'
	self~plots     = .Array~new
	self~debug     = .false
	self~constants = .Directory~new
	self~persist   = .true
	self~title     = .nil
	self~key       = 'top left'
	self~grid      = .nil
	self~width     = .nil
	self~height    = .nil
	self~xlabel    = .nil
	self~x2label   = .nil
	self~ylabel    = .nil
	self~y2label   = .nil
	self~terminal  = .nil
	self~output    = .nil

::method output
  expose output
  return output

::method 'output='
  expose output
  use arg out
  output = out

  if out = .nil then return

  dot_pos = out~lastpos('.')
  
  if dot_pos > 1 then do
    out_extension = out~substr(out~lastpos('.') + 1)~upper

    if self~class~terminals~hasindex(out_extension) then do
	  	self~terminal = self~class~terminals~at(out_extension)
	  	self~persist  = self~class~persist~at(out_extension)
	  end
  end
    
::method add

  series = .Directory~new

  series~function = .nil
  series~data     = .nil
  series~file     = .nil
  series~using    = .nil

  select
  when arg(1)~isInstanceOf(.String) then
	series~function = arg(1)
  when arg(1)~isInstanceOf(.Array) then do
	series~data     = arg(1, 'A')
	series~using    = '1:2'
	end
  when arg(1)~isInstanceOf(.Stream) then
	series~file = arg(1)~string
  when arg(1)~isInstanceOf(.File) then
	series~file = arg(1)~absolutePath
  otherwise
	nop
  end

  series~title    = .nil
  series~width    = .nil
  series~with     = .nil
  series~color    = .nil
  
  index = self~plots~append(series)

  return self~plots[index]

::method script private
  use arg cmd

  s = .Array~new
  s~append('# start of gnuplot script')

  quote_opt = .Directory~new
  quote_opt['title']    = .true
  quote_opt['key']      = .false
  quote_opt['grid']     = .false
  quote_opt['width']    = .false
  quote_opt['height']   = .false
  quote_opt['xlabel']   = .true
  quote_opt['x2label']  = .true
  quote_opt['ylabel']   = .true
  quote_opt['y2label']  = .true
  quote_opt['terminal'] = .false
  quote_opt['output']   = .true

  -- Add gnuplot constants
  do i over self~constants
  	s~append(i '=' self~constants~at(i))
  end

  -- Add plot options
  do opt over quote_opt
  	val = self~send(opt)
  	if val = .nil then iterate
    
  	if quote_opt~at(opt) then
  		s~append('set' opt quote(val)) -- quoted
  	else
  		s~append('set' opt val) -- non quoted
  end

  -- Add plot command
  do p over self~plots
  	select
  	when p~data <> .nil then
  		cmd = cmd '"-" using' p~using
  	when p~function <> .nil then
  		cmd = cmd p~function
  	when p~file <> .nil then
  		cmd = cmd quote(translate(p~file, '/', '\'))
  	otherwise
  		nop
  	end

  	if p~title <> .nil then
  		cmd = cmd 'title' quote(p~title)
  		
  	if p~width <> .nil then
  	  cmd = cmd 'lw' p~width

  	if p~with <> .nil then
  		cmd = cmd 'w' p~with

  	if p~color <> .nil then
  		cmd = cmd 'lc' p~color

  	cmd = cmd || ','

  end

  cmd = cmd~strip('T', ',')

  s~append(cmd)
  
  -- Add data (if any)

  plots = self~plots

  do p over plots
    if p~data = .nil then iterate
  
    s~append('# start of data')
    do i = 1 to p~data[1]~items
      line = ''
      do column over p~data
	line = line column[i]
      end
      s~append(line)
    end
    s~append('e # end of data')
  
  end

  s~append('# end of gnuplot script' || .endofline)

  return s~makestring -- return string with contents of script

::method plot
  if \arg(1, 'O') then self~output = arg(1)
  return self~runplot('plot')

::method splot
  if \arg(1, 'O') then self~output = arg(1)
  return self~runplot('splot')

::method runplot private
  parse arg cmd
  
  if self~class~iswindows then
    path = value('TEMP', , 'ENVIRONMENT') || '\'
  else
    path = ''
  
  scriptname = SysTempFileName(path || 'gnuplot.???')

  script = self~script(cmd)

  if self~debug then
  	.error~charout(script)

  call lineout scriptname, script 
  call lineout scriptname

  if self~persist = .true then persist = '-persist'
  else persist = ''

  quoted_script = '"' || scriptname || '"'

  if self~class~iswindows then
    start = 'start /B'
  else
    start = ''
    
  start self~bin persist quoted_script

  if \ self~class~iswindows then
    call SysFileDelete scriptname
  return rc

::routine quote
  use arg s
  return "'" || s || "'"
