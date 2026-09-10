/*----------------------------------------------------------------------------
Real-world sample gathered for rexx-lint validation (not written for this
project).
Source: https://github.com/sparrac/oorexx-math-sequences/blob/master/Math/Sequences.rex
Project: oorexx-math-sequences (Salvador Parra Camacho) -- a personal ooRexx library
         announced on the rexxla-members mailing list, September 2026.
License: Apache License 2.0 (Apache-2.0) -- see the source repo's LICENSE.
         Retained as part of rexx-lint's real-world validation corpus;
         see samples/real-world/README.md.
----------------------------------------------------------------------------*/
/*
 * File:        Math/Sequences.rex
 * Description: Object-oriented mathematical sequence library for Open Object Rexx.
 *
 * Author:      Salvador Parra Camacho
 * Version:     0.1.0
 * Date('S'):   20260724
 * License:     Apache 2.0
 * Repository:  https://github.com/sparrac/oorexx-math-sequences
 */
 
::class Sequence public

::method init
  use arg rule =.nil, terms=.nil
  
::method term
  use arg n
  return self[n]
  
::method firstTerm
  return self[1]
  
::method first
  use arg n
  arr = .Array~new(n)
  do i = 1 to n
    arr~append(self[i])
  end
  return arr
  
::method makearray
  use arg n
  return self~first(n)

::method sum
  use arg n
  
  sum = 0
  
  do i = 1 to n
    sum += self[i]
  end
  
  return sum

::method prod
  use arg n
  
  prod = 1
  
  do i = 1 to n
    prod *= self[i]
  end
  
  return prod
  
::method average
  use arg n
  return self~sum(n)/n
  
::method '+'
  use arg s
  if \ s~isA(.Sequence) then s = .ConstantSequence~new(s)
  return .CombinedSequence~new(self, s, '+')
  
::method '-'
  use arg s
  if \ s~isA(.Sequence) then s = .ConstantSequence~new(s)
  return .CombinedSequence~new(self, s, '-')
  
::method '*'
  use arg s
  if \ s~isA(.Sequence) then s = .ConstantSequence~new(s)
  return .CombinedSequence~new(self, s, '*')

::method '/'
  use arg s
  if \ s~isA(.Sequence) then s = .ConstantSequence~new(s)
  return .CombinedSequence~new(self, s, '/')

::method '//'
  use arg s
  if \ s~isA(.Sequence) then s = .ConstantSequence~new(s)
  return .CombinedSequence~new(self, s, '//')

::method '%'
  use arg s
  if \ s~isA(.Sequence) then s = .ConstantSequence~new(s)
  return .CombinedSequence~new(self, s, '%')

::method '**'
  use arg s
  if \ s~isA(.Sequence) then s = .ConstantSequence~new(s)
  return .CombinedSequence~new(self, s, '**')
  
::method toString
  preview = self~first(5)~makestring(, ', ')
  return self~class~id '('preview', ...)'
  
::method map
  use arg m
  return .MappedSequence~new(self, m)

::method filter
  use arg f
  return .FilteredSequence~new(self, f)
  
::class CombinedSequence public subclass Sequence

::method init
  expose s1 s2 msg
  use arg s1, s2, msg
  
::method '[]'
  expose s1 s2 msg
  use arg n
  return s1[n]~send(msg, s2[n])
  
::method sum
  expose s1 s2 msg
  use arg n
  if msg = '+' then
    return s1~sum(n) + s2~sum(n)
  if msg = '-' then
    return s1~sum(n) - s2~sum(n)
    
  return forward class(super)

::method prod
  expose s1 s2 msg
  use arg n
  if msg = '*' then
    return s1~prod(n) * s2~prod(n)
  if msg = '/' then
    return s1~prod(n) / s2~prod(n)
    
  return forward class(super)
  
::class FilteredSequence public subclass Sequence

::method init
  expose seq filter filtered sourceIndex
  use arg seq, filter
  
  if \ filter~hasmethod("CALL") then
    raise syntax 93.900 array("Second argument must be callable, received" filter~class~id)
  
  filtered = .Array~new
  sourceIndex = 0
  
::method '[]'
  expose seq filter filtered sourceIndex
  use arg n
  
  if n <= filtered~items then
    return filtered[n]
    
  do while n > filtered~items
    sourceIndex += 1
    s = seq[sourceIndex]
    if filter~call(s) then
      filtered~append(s)
  end
  
  return filtered[n]
  
::class MappedSequence public subclass Sequence

::method init
  expose seq map
  use arg s, m

  if \ m~hasmethod("CALL") then
    raise syntax 93.900 array("Second argument must be callable, received" m~class~id)

  seq = s
  map = m
  
::method '[]'
  expose seq map
  use arg n
  return map~call(seq[n])
  
::class MemoizedSequence public subclass Sequence

::method init
  expose seq cache
  use arg s
  
  seq = s
  cache = .Array~new()

::method '[]'
  expose seq cache
  use arg n
  
  if n <= cache~items then
    return cache[n]
  
  do while n > cache~items
    cache~append(seq[cache~items + 1])
  end
  
  return cache[n]
  
::class ArithmeticSequence public subclass Sequence

::method new class
  use arg a1, d
  if d = 0 then return .ConstantSequence~new(a1)
  
  forward class(super)

::method init
  expose a1 d
  use arg a1, d
  
::method difference
  expose d
  return d
  
::method firstTerm
  expose a1
  return a1
  
::method '[]'
  expose a1 d
  use arg n
  return a1 + (n - 1) * d
  
::method sum
  expose a1 d
  use arg n
  return n*(2*a1 + (n - 1)*d)/2
  
::method average
  use arg n
  return (self[1] + self[n]) / 2
  
::class GeometricSequence public subclass Sequence

::method new class
  use arg a1, r
  if r = 1 then return .ConstantSequence~new(a1)
  forward class(super)

::method init
  expose a1 r
  use arg a1, r
  
::method ratio
  expose r
  return r
  
::method firstTerm
  expose a1
  return a1
  
::method '[]'
  expose a1 r
  use arg n
  return a1 * r ** (n - 1)
  
::method sum
  expose a1 r
  use arg n
  if r = 1 then return a1 * n
  return a1*(r**n - 1)/(r - 1)
  
::method sumAll
  expose a1 r
  
  if abs(r) >= 1 then
    raise syntax 93.900 array("Infinite geometric series does not converge.")

  return a1/(1 - r)
  
::method prod
  expose a1 r
  use arg n
  return a1**n * r**((n**2 - n)/2)

::class ConstantSequence public subclass Sequence

::method init
  expose a
  use arg a
 
::method firstTerm
  expose a
  return a
  
::method term
  expose a
  return a
  
::method '[]'
  expose a
  return a
  
::method sum
  expose a
  use arg n
  return n*a

::method prod
  expose a
  use arg n
  return a**n

::class FixedExponentPowerSequence public subclass Sequence

::method init
  expose exponent
  use arg exponent
  
::method '[]'
  expose exponent
  use arg n
  return n**exponent
  
::class FixedBasePowerSequence public subclass GeometricSequence

::method init
  use arg base
  forward class(super) arguments(1, base)

::class PeriodicSequence public subclass Sequence

::method init
  expose pattern
  use arg p
  
  pattern = p

::method '[]'
  expose pattern
  use arg n
  items = pattern~items
  index = n // items
  if index = 0 then index = items
  return pattern[index]
  
::method period
  expose pattern
  return pattern~items

::class PrimeSequence public subclass Sequence metaclass Singleton

::method init
  expose primes
  primes = .Array~of(2)

::method firstTerm
  return 2
  
::method '[]'
  expose primes
  use arg n
  
  if n <= primes~items then
    return primes[n]
  
  candidate = primes~lastItem
  
  do while n > primes~items

    isPrime = .true
    
    select
      when candidate = 2 then
        candidate = 3
      when candidate // 6 = 1 then
        candidate += 4
      otherwise
        candidate += 2
    end
    
    do p over primes
      if p * p > candidate then
        leave
      if candidate//p = 0 then do
        isPrime = .false
        leave
      end
    end
    
    if isPrime then primes~append(candidate)
  end
  
  return primes[n]
