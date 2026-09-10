/*----------------------------------------------------------------------------
Real-world sample gathered for rexx-lint validation (not written for this
project).
Source: https://github.com/sparrac/oorexx-dotenv/blob/master/dotEnv.rex
Project: oorexx-dotenv (Salvador Parra Camacho) -- a personal ooRexx library
         announced on the rexxla-members mailing list, September 2026.
License: Apache License 2.0 (Apache-2.0) -- see the source repo's LICENSE.
         Retained as part of rexx-lint's real-world validation corpus;
         see samples/real-world/README.md.
----------------------------------------------------------------------------*/
/*
 * Library:     oorexx-dotenv: dotEnv for ooRexx
 * File:        dotEnv.rex
 * Description: A minimal Open Object Rexx library for loading `.env`
 *              files without extra dependencies.
 *
 *              Inspired by: https://github.com/mcjkula/lua-dotenv/
 *
 * Author:      Salvador Parra Camacho
 * Version:     0.1.0
 * Date('S'):   20260810
 * License:     Apache 2.0
 * Repository:  https://github.com/sparrac/oorexx-dotenv
 */

/**
 * @class dotEnv
 * @description Loads variables from .env files and provides access to
 *              loaded values and system environment variables.
 *
 *              Values loaded from .env files are stored as strings.
 *              Multiple files may be loaded; later values overwrite
 *              earlier values.
 */
 
::class dotEnv public

/**
 * @constant VERSION Current library version.
 * @constant LIBRARY Library name.
 */
 
::constant VERSION "0.1.0"
::constant LIBRARY "oorexx-dotenv"

/**
 * @method new
 * @param file Path to .env file. By default, `.env` in the current directory.
 */

::method init
  expose envDir
  use arg file = '.env'
  
  envDir = .Directory~new
  
  self~load(file)

/**
 * @method load
 * @param file Path to .env file. By default, `.env` in the current directory.
 * @description Loads environment variables from the specified file.
 *              Variables loaded by previous calls are preserved.
 *              If a variable already exists, its value is overwritten.
 *              Invalid lines and invalid variable names are ignored.
 * @return The current DotEnv instance.
 */
  
::method load
  expose envDir
  use arg file = '.env'
  
  s = .Stream~new(file)
  
  lines = s~makearray
  
  do line over lines
    line = line~strip('B')
    
    -- empty line (ignore)
    if line = '' then iterate
    
    -- comment (ignore)
    if line~substr(1, 1) = '#' then iterate
    
    parse var line key '=' val
    key = key~strip('B')
    
    select
      -- just one key word: OK
      when key~words = 1 then nop
      -- var with "export" prefix is valid
      when key~words = 2 & key~word(1) = 'export' then
        key = key~subword(2)~strip
      -- other prefixes or too many keywords are not
      otherwise
         iterate
    end

    -- first character after is # -> it's the value
    if val~substr(1, 1) = '#' then
      parse var val val .
    else do
      val = val~strip('B')
      select
      -- no value
      when val~substr(1, 1) = '#' then
        val = ''
      -- single quotes
      when val~substr(1, 1) = "'" then
        parse var val "'" val "'" . -- leave
      -- double quotes
      when val~substr(1, 1) = '"' then
        parse var val '"' val '"' . -- leave
      otherwise
      -- no quotes, strip comment
        parse var val val '#' .
        val = val~strip('B')
      end
    end

    if \self~validateKey(key) then iterate
    
    envDir[key] = val    
  end

  return self
  
/**
 * @method get
 * @param key Environment variable name.
 * @param [default] Optional value returned when the variable is not defined.
 * @return The loaded value, the system environment value, the default, or .nil.
 */
  
::method get
  expose envDir
  use arg key, default
  
  if envDir~hasIndex(key) then
    return envDir[key]
  if value(key, ,'ENVIRONMENT') \= '' then
    return value(key, , 'ENVIRONMENT')
  if arg(2, 'E') then
    return default
  else
    return .nil

/**
 * @method set
 * @param key Environment variable name.
 * @param value Value to assign. If omitted, an empty string is assigned.
 *              If .nil is supplied, the variable is removed.
 * @return The current dotEnv instance.
 */
    
::method set
  expose envDir
  use arg key, value
  
  if \self~validateKey(key) then
    return self
  
  if arg(2, 'O') then
    envDir[key] = ''
  else if value = .nil then
    envDir~remove(key)
  else
    envDir[key] = value

  return self

/**
 * @method reset
 * Clears all variables loaded or set in this instance.
 * Does not modify the process environment.
 * @return The current DotEnv instance.
 */
  
::method reset
  expose envDir
  envDir = .Directory~new
  return self
  
/**
 * @method has
 * @param key Environment variable name.
 * @return .true if the variable is loaded in this instance; otherwise .false.
 */
  
::method has
  expose envDir
  use arg key
  return envDir~hasIndex(key)

/**
 * @method toDirectory
 * @return Directory containing the loaded environment variables.
 */
  
::method toDirectory
  expose envDir
  return envDir

/**
 * @method fromDirectory
 * @param dir Directory containing environment variable values. It overwrites existing keys.
 * @return The current DotEnv instance.
 */
  
::method fromDirectory
  expose envDir
  use arg dir
  
  if \dir~isA(.Directory) then
    raise syntax 93.900 array('fromDirectory requires a Directory')
  
  do key over dir
    if self~validateKey(key) then
      envDir[key] = dir[key]
  end
  
  return self
  
::method validateKey private
  use arg key
  
  if key = '' then return .false
  
  verify_str = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' || -
               'abcdefghijklmnopqrstuvwxyz' || -
               '0123456789_'
  
  return  key~verify(verify_str) = 0
