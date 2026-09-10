#!/usr/bin/env rexx
/*----------------------------------------------------------------------------
Real-world sample gathered for rexx-lint validation (not written for this
project).
Source: https://github.com/sparrac/oorexx-tinylog/blob/master/examples/syslog.rex
Project: oorexx-tinylog (Salvador Parra Camacho) -- a personal ooRexx library
         announced on the rexxla-members mailing list, September 2026.
License: Apache License 2.0 (Apache-2.0) -- see the source repo's LICENSE.
         Retained as part of rexx-lint's real-world validation corpus;
         see samples/real-world/README.md.
----------------------------------------------------------------------------*/
-- syslog.rex
-- Example sending log messages to a Syslog server.
-- It uses `logger`.

log = .Logger~new()

log~formatter = .SysLogFormatter~new()
log~output    = .SyslogOutput~new()

log~info("oorexx-tinylog example!")

exit

::requires 'TinyLog'

::class SysLogFormatter

::method call
  use arg record

  return "[" || record~source ||":" || record~line "]" record~message

::class SyslogOutput

::method say
  use arg line
  clear_line = line~changestr('"', '\"')
  address system 'logger -t oorexx-tinylog "' || line || '"'
  return rc
