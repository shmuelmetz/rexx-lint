/*----------------------------------------------------------------------------
Real-world sample gathered for rexx-lint validation (not written for this
project).
Source: https://github.com/sparrac/oorexx-ranges/blob/master/Ranges.rex
Project: oorexx-ranges (Salvador Parra Camacho) -- a personal ooRexx library
         announced on the rexxla-members mailing list, September 2026.
License: Apache License 2.0 (Apache-2.0) -- see the source repo's LICENSE.
         Retained as part of rexx-lint's real-world validation corpus;
         see samples/real-world/README.md.
----------------------------------------------------------------------------*/
/*

  Ranges.rex
  
  oorexx-ranges: A lightweight library designed for Array manipulation in Open Object Rexx. It provides functions for Python-style Array generation (range, linspace, fill, zeros, ones, repeat), functional transformation (apply, filter) and reduction (sum, prod).
  
  Copyright (c) 2026 Salvador Parra Camacho
  
  License: Apache License 2.0
  Version: 0.1.0

 */

::routine range public
  use arg start, stop, step

  ran = .Array~new()

  args = arg()

  select
  when args = 0 then
  	return ran
  when args = 1 then do
  	stop  = start
  	start = 0
  	step  = 1
    end
  when args = 2 then
    step = 1
  when args = 3 then do
    if step = 0 then
      return ran
    end
  otherwise
    nop
  end

  if step > 0 then do
    if start >= stop then
      return ran
      
    do item = start to stop - 1 by step
      ran~append(item)
    end
  end
  else do
    if start <= stop then
      return ran
    
    do item = start to stop + 1 by step
      ran~append(item)
    end
  end

  return ran

::routine linspace public
  use strict arg base, limit, n = 100

  ret = .Array~new()
  
  if n <= 0 then
    return ret
  
  if n = 1 then do
    ret~append(base)
    return ret
    end
  
  h = (limit - base)/(n - 1)
  
  do i = 1 to n - 1
    elemento = base + (i - 1) * h
    ret~append(elemento)
  end
  
  ret~append(limit)
  
  return ret
  
::routine fill public
  use strict arg n, val
  ret = .Array~new(n)
  
  if n <= 0 then
    return ret
    
  do n
    ret~append(val)
  end
  
  return ret
  
::routine sum public
  use strict arg arr
  
  sum = 0
  
  do item over arr
    sum = sum + item
  end
  
  return sum

::routine prod public
  use strict arg arr
  
  prod = 1
  
  do item over arr
    prod = prod * item
  end
  
  return prod
  
::routine repeat public
  use strict arg val, n
  return fill(n, val)
  
::routine zeros public
  use strict arg n
  return fill(n, 0)

::routine ones public
  use strict arg n
  return fill(n, 1)
  
::routine apply public
  use arg arr, rou
  out_arr = .Array~new()
  do item over arr
    out_arr~append(rou~call(item))
  end
  return out_arr

::routine filter public
  use arg arr, predicate
  out_arr = .Array~new()
  do item over arr
    if predicate~call(item) then
    out_arr~append(item)
  end
  return out_arr
