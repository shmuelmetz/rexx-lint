/* Fixture: the two real, documented, still-open gaps in
 * BackslashEscape's structural path detection -- see
 * checks/BackslashEscape.cls's docstring, "Known remaining gaps in
 * those 3". Both were found running the check against the real
 * 111-file corpus (local-test-data/utility-cmd/, not committed) and
 * are EXPECTED findings, not accidental ones: this fixture pins that
 * expectation so a future change to the heuristics can't silently
 * shift it, in either direction, without the test noticing.
 *
 * 1. A path fragment with trailing prose after it never reaches an
 *    extension-shaped ending, so none of the four structural tests
 *    catch it.
 * 2. A single-backslash drive-letter-shaped fragment preceded by a
 *    doubled letter (e.g. a repeated command-line flag) trips the
 *    anti-false-positive guard meant to reject "etc:\"-style
 *    matches, and has too few segments for the word-count test to
 *    catch it either. */

say '\backup.log is older than'
say '-ww:\temp'
