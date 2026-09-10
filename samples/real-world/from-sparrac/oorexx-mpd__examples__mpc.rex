#!/usr/bin/env rexx
/*----------------------------------------------------------------------------
Real-world sample gathered for rexx-lint validation (not written for this
project).
Source: https://github.com/sparrac/oorexx-mpd/blob/master/examples/mpc.rex
Project: oorexx-mpd (Salvador Parra Camacho) -- a personal ooRexx library
         announced on the rexxla-members mailing list, September 2026.
License: Apache License 2.0 (Apache-2.0) -- see the source repo's LICENSE.
         Retained as part of rexx-lint's real-world validation corpus;
         see samples/real-world/README.md.
----------------------------------------------------------------------------*/
-- mpc.rex
-- Incomplete implementation of mpc
-- mpc: https://github.com/MusicPlayerDaemon/mpc

m = .MPD~new()
m~connect

args = .SysCArgs
command = args[1]

select
when command = 'play' then
  m~play
when command = 'stop' then
  m~stop
when command = 'pause' then
  m~pause
when command = 'next' then
  m~next
when command = 'prev' then
  m~previous
when command = 'version' then
  say 'mpd version:' m~protocol
otherwise
  nop
end

stat = m~status
csong = m~currentsong

if csong <> .nil, csong~items <> 0 then do
  say csong~artist '-' csong~title

  songs = m~playlist~items
  song_pos = stat~song + 1
  
  elapsed  = stat~elapsed
  duration = csong~time
  if duration <> 0 then
    pct = format(elapsed/duration*100, , 0)
  else
    pct = 0
  
  say '['to_ing(stat~state)'] #'song_pos'/'songs'   'to_min(elapsed)'/'to_min(duration) '('pct'%)'

  end
  
vol = m~volume
if vol = .nil then
  vol = 'n/a'
else
  vol = vol'%'

say 'volume:' vol'   '||,
    'repeat:' onoff(stat~repeat)'   '||,
    'random:' onoff(stat~random)'   '||,
    'single:' onoff(stat~single)'   '||,
    'consume:' onoff(stat~consume)

m~disconnect()

exit

to_ing: procedure
  parse arg str
  select
  when str = 'play' then
    ret = 'playing'
  when str = 'pause' then
    ret = 'paused'
  otherwise
    ret = str
  end
  
  return ret

to_min: procedure
  parse arg secs
  min = secs%60
  secs = secs//60
  return min':'right(format(secs, ,0), 2, 0)

onoff: procedure
  parse arg s
  return word('off on', s + 1)
  
::requires 'MPD'
