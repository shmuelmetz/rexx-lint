# Real-world validation corpus

Real-world Rexx source, gathered to run rexx-lint against code this
project didn't write itself -- useful both as a sanity check that the
parser/checks survive genuine legacy style (fixed-column comment
boxes, `extproc`/edit-macro conventions, decades-old idioms) and as a
source of real check hits to look at, beyond the synthetic
`tests/fixtures/` cases built to exercise one rule at a time.

Every file here has a short provenance header (source URL, project,
license) prepended as its own comment block, ahead of the file's own
original header.

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

## Reproducing this corpus

```
# from-prino-neocities/: prino.neocities.org/zOS/<name>.exec.html (served as
#   syntax-highlighted HTML -- strip the <body>...</body> tags and any
#   remaining <em class="..."> markup/entities to recover plain source)
```

The original relative path/filename within the source site is
recorded in each file's own provenance header comment.
