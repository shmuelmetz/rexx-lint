/* Fixture: strings with no backslash, a backslash not followed by a
 * tracked letter, or -- the important regression case -- a tracked
 * letter immediately continuing into a longer word, which is a
 * Windows/OS/2 path fragment rather than an escape attempt. These
 * exact shapes (backup/temp/unzip/vendors path segments) are drawn
 * from real false positives found running an earlier version of
 * this check against 72 genuine Rexx files from an actual ArcaOS-era
 * script collection -- see the check class's own docstring. */

say "line one" || '0a'x || "line two"
say 'plain text, no backslash at all'
path = "C:\Program Files\App"
say drive'\backup.log is older than' adrive'\backup.log'
global.unzipexe = 'H:\Vendors\Hobbes\unz600\32-bit\unzip.exe'
say 'PARAMETERS=I:\comm\FaxWorks\nstall;'
