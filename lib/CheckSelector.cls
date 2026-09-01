/* CheckSelector.cls -- applies --checks=/--disable=/config-file
 * filtering to the full set of available checks. Pulled out of
 * bin/rexx-lint.rex into its own class so it can be unit-tested
 * directly, rather than only through a CLI subprocess invocation
 * (per AI-Priming/CONVENTIONS.md, "New ooRexx code: split general
 * from specific" -- reusable logic belongs in a class).
 *
 * Precedence: --checks, then --disable, then a config file (an
 * explicit path, or the default .rexxlintrc if present in the
 * current directory), then -- if none of those were given -- every
 * check.
 */

::class CheckSelector public

::method select class
  use strict arg allChecks, onlyList, disableList, configPath

  if onlyList \== '' then
     return self~checksNamedIn(allChecks, self~splitNames(onlyList))

  if disableList \== '' then
     return self~checksNotNamedIn(allChecks, self~splitNames(disableList))

  effectiveConfigPath = configPath
  if effectiveConfigPath == '' then do
     if SysFileExists('.rexxlintrc') then
        effectiveConfigPath = '.rexxlintrc'
  end

  if effectiveConfigPath \== '' then
     return self~checksNamedIn(allChecks, self~readConfigNames(effectiveConfigPath))

  return allChecks

::method splitNames class
  use strict arg commaList

  names = .Array~new
  do piece over commaList~makeArray(',')
     trimmed = piece~strip
     if trimmed \== '' then names~append(trimmed)
  end
  return names

::method readConfigNames class
  use strict arg path

  names = .Array~new
  do while LINES(path) > 0
     line = LINEIN(path)~strip
     if line == '' then iterate
     if line~left(1) == '#' then iterate
     names~append(line)
  end
  call STREAM path, 'C', 'CLOSE'
  return names

::method checksNamedIn class
  use strict arg allChecks, names

  selected = .Array~new
  do check over allChecks
     do name over names
        if check~name~caselessEquals(name) then do
           selected~append(check)
           leave
        end
     end
  end
  return selected

::method checksNotNamedIn class
  use strict arg allChecks, names

  selected = .Array~new
  do check over allChecks
     excluded = .False
     do name over names
        if check~name~caselessEquals(name) then do
           excluded = .True
           leave
        end
     end
     if \excluded then selected~append(check)
  end
  return selected
