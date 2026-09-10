/*----------------------------------------------------------------------------
Real-world sample gathered for rexx-lint validation (not written for this
project).
Source: https://github.com/sparrac/oorexx-tinylog/blob/master/TinyLog.rex
Project: oorexx-tinylog (Salvador Parra Camacho) -- a personal ooRexx library
         announced on the rexxla-members mailing list, September 2026.
License: Apache License 2.0 (Apache-2.0) -- see the source repo's LICENSE.
         Retained as part of rexx-lint's real-world validation corpus;
         see samples/real-world/README.md.
----------------------------------------------------------------------------*/
/*
 * Library:     oorexx-tinylog: a tiny logging library for Open Object Rexx
 * File:        TinyLog.rex
 * Description: A lightweight logging library providing six log levels,
 *              optional colored console output, optional file logging,
 *              and extensible formatting and output.
 *
 * Author:      Salvador Parra Camacho
 * Version:     1.0.0
 * Date('S'):   20260806
 * License:     Apache 2.0
 * Repository:  https://github.com/sparrac/oorexx-tinylog
 */

::class Logger public

-- Version
::constant VERSION "1.0.0"
::constant LIBRARY "oorexx-tinylog"

-- Levels
::constant LEVELS (.Directory~of( -
         ("TRACE", 1), -
         ("DEBUG", 2), -
         ("INFO", 3), -
         ("WARN", 4), -
         ("ERROR", 5), -
         ("FATAL", 6)))

-- Attributes
::attribute level get
::attribute level set
  expose level
  parse upper arg level

  if \self~LEVELS~hasIndex(level) then
    raise syntax 97.1 array (self, level)

::attribute usecolors
::attribute output
::attribute formatter

-- Methods
::method init
  use arg out = .nil

  -- Defaults
  self~level     = 'TRACE'
  self~usecolors = .true
  self~output    = .output
  self~formatter = .nil

  -- No args -> .output
  if out == .nil then return

  -- String -> Stream~new(string)
  if out~isA(.String) then do
    self~output = .Stream~new(out)~~open()
    return
  end

  -- Monitor -> Monitor
  if out~isA(.Monitor) then do
    self~output = out
    return
  end

  -- Object responding to SAY -> Output
  if out~hasmethod('SAY') then do
    self~output = out
    return
  end

  raise syntax 93.900 array ("Argument 'out' must be a String, a Monitor, or an object responding to SAY.")

::method unknown
  use arg level, args

  LEVELS   = self~LEVELS -- Directory of valid levels
  level    = level~upper -- log level name
  minLevel = self~level  -- Minimal log level name

  -- Unknown message -> raise error
  if \LEVELS~hasIndex(level) then
    raise syntax 97.1 array (self, level)

  -- Below configured level -> ignore
  if LEVELS[level] < LEVELS[minLevel] then
    return

  output    = self~output
  formatter = self~formatter

  record = .Directory~new()

  parse value (date("S") time()) with logDate logTime
  record~date      = logDate
  record~time      = logTime

  caller_context = .context~stackframes[2]~context
  caller_package = caller_context~package

  if caller_package \== .nil then
    source = .File~new(caller_package~name)~name
  else
    source = ''

  line = caller_context~line

  record~context          = caller_context
  record~source           = source
  record~line             = line

  record~level            = level
  record~level_number     = LEVELS[level]
  record~args             = args
  record~message          = args~toString

  record~usecolors        = self~usecolors

  hasSecondary = (output \= .output)

  if formatter == .nil then do
    console_str = self~consoleFormat(record)
    log_str     = self~defaultFormat(record)
    end
  else do
    if hasSecondary then do
      console_str = self~consoleFormat(record)
      log_str     = formatter~call(record)
      end
    else
      console_str = formatter~call(record)
  end

  .output~say(console_str)

  if output \= .output then
    output~say(log_str)

::method consoleFormat private
  use arg record

  ANSI_COLORS = ('1B'x'[34m', '1B'x'[36m', '1B'x'[32m',,
                 '1B'x'[33m', '1B'x'[31m', '1B'x'[35m')
  ANSI_RESET = '1B'x'[0m'

  level_str = left(record~level, 5)
  logTime = record~time
  message = record~message
  source  = record~source
  line    = record~line
  idx     = self~LEVELS[record~level]

  if self~usecolors then do
    color = ANSI_COLORS[idx]
    reset = ANSI_RESET
  end
  else do
    color = ''
    reset = ''
  end

  log_str = color || '['level_str logTime']' || reset
  log_str = log_str source':'line record~message

  return log_str

::method defaultFormat private
  use arg record

  level_str = left(record~level, 5)

  log_str = '['level_str record~date record~time']',
            record~source':'record~line record~message

  return log_str
