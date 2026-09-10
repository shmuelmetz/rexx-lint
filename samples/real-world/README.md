# Real-world validation corpus

Real-world Rexx source, gathered to run rexx-lint against code this
project didn't write itself -- useful both as a sanity check that the
parser/checks survive genuine legacy style (fixed-column comment
boxes, `extproc`/edit-macro conventions, decades-old idioms) and as a
source of real check hits to look at, beyond the synthetic
`tests/fixtures/` cases built to exercise one rule at a time.

Every file here has a short provenance header (source URL, project,
license) as its own comment block, ahead of the file's own original
header -- or, on a file that opens with `#!/usr/bin/env rexx`,
immediately after that shebang line (ooRexx only accepts `#!` as the
literal first line).

## What's committed here, and why

### `from-prino-neocities/` (13 files, ~11,600 lines)

Robert AH Prins' "EHI" family of ISPF edit macros, from his zOS-Tools
page (<https://prino.neocities.org/zOS/zOS-Tools>) -- real,
maintained mainframe tooling: per-language source-to-HTML converters
(`ehiasm`, `ehicobol`, `ehijcl`, `ehinone`, `ehipan`, `ehipli`,
`ehirexx`, `ehisupc`), their shared support library (`ehisupp`) and
help screen (`ehihelp`), and three smaller unrelated edit macros
(`einc2foc`, `esort`, `esymsort`, for DFSORT/Focus-related member
generation). All GPLv3-or-later, per the license notice embedded in
each file's own header (confirmed, not assumed, against the actual
license text). Each source page renders the macro as
syntax-highlighted HTML via the author's own `ehirexx.rex` (one of
this same suite) rather than serving plain text -- the HTML wrapper
and highlighting spans were stripped mechanically, verified to leave
no residual markup or entities, before saving here.

Genuine ISPF-edit-macro style throughout: heavy `ADDRESS ISREDIT`,
fixed-column boxed comment headers, decades of incremental dated
changelog entries in the header itself (1992-2024 depending on the
file) -- a different real-world flavor than the OO-heavy or
from-scratch code rexx-lint has otherwise been tested against.

### `from-sparrac/` (10 files)

A slice of Salvador Parra Camacho's personal ooRexx libraries
(`oorexx-gnuplot`, `oorexx-dotenv`, `oorexx-math-sequences`,
`oorexx-mpd`, `oorexx-ranges`, `oorexx-tinylog`), published to GitHub
and announced on the rexxla-members list in September 2026 -- all
Apache-2.0. Present-day OO Rexx written from scratch: `::class` /
`::method` / `::constant` directives, doc-comment blocks, compound
assignment, `self[n]` indexing -- a different flavour again from the
ISPF-macro style of `from-prino-neocities/`.

rexx-lint parses all 10 with no crash and no parse failure, and the
run surfaces 12 findings across 6 files, every one a genuine construct
in the source: `keyword-as-variable` on `value` (`oorexx-dotenv`),
`digits` (`chess_problem`) and `forward` (`Sequences`);
`shadowed-special-vars` on `RC` (`GnuplotSession`) and `RESULT`
(`testArithmeticSequence`); `nested-builtin-call` on `RIGHT(FORMAT(...))`
(`mpc`); and one `backslash-escape` hit on `changestr('"', '\"')` in
`oorexx-tinylog/examples/syslog.rex` -- kept deliberately as a
borderline case: the check's statement is correct (`'\"'` is two
characters, not an escape) but here the two-character result is what
the author actually wants, so it reads more as a style nudge than a
bug. The other four checks (`signal-control-flow`, `stem-count-loop`,
`stem-paren-expression`, `backslash-escape` proper) simply have
nothing to flag in this code; `from-prino-neocities/` exercises those.

## Reproducing this corpus

```
# from-prino-neocities/: prino.neocities.org/zOS/<name>.exec.html (served as
#   syntax-highlighted HTML -- strip the <body>...</body> tags and any
#   remaining <em class="..."> markup/entities to recover plain source)
# from-sparrac/: raw.githubusercontent.com/sparrac/<repo>/master/<path>
```

The original relative path/filename within the source site is
recorded in each file's own provenance header comment.
