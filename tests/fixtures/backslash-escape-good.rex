/* Fixture: strings with no backslash, a backslash not followed by a
 * tracked letter, or -- the important regression case -- a string
 * that structurally looks like a Windows/OS/2 path (drive-letter
 * prefix, UNC prefix, multi-segment word-like backslashes, or an
 * extension-shaped ending) rather than an escape attempt. These
 * exact shapes (backup/temp/unzip/vendors path segments) are drawn
 * from real false positives found running an earlier version of
 * this check against 72 genuine Rexx files from an actual ArcaOS-era
 * script collection -- see the check class's own docstring.
 *
 * A close relative of the `\backup.log` case here -- the same
 * fragment with trailing prose after it, `\backup.log is older
 * than` -- does NOT structurally end in an extension and so is a
 * real, documented, still-open gap rather than a clean pass; that
 * case lives in backslash-escape-known-limitation.rex instead of
 * here, so this fixture stays honestly all-clean. */

say "line one" || '0a'x || "line two"
say 'plain text, no backslash at all'
path = "C:\Program Files\App"
say adrive'\backup.log'
global.unzipexe = 'H:\Vendors\Hobbes\unz600\32-bit\unzip.exe'
say 'PARAMETERS=I:\comm\FaxWorks\nstall;'
