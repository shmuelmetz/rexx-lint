# rexx-lint

A static analysis tool for Rexx source code.

## Purpose

- Checking a Rexx source file for errors and questionable idioms before running it
- Checking a file for dialect-specific issues before porting it to another Rexx environment
- Enforcing coding standards across a Rexx codebase
- Vetting AI-generated Rexx code before presenting it to the user

rexx-lint is a style and readability checker as much as a correctness
checker. Most of what it flags is legal Rexx that runs without error --
the point is to warn about code that is likely to confuse a human
reader or trip up a maintainer later, not just code that's outright
wrong.

## Status

Early development. The parser infrastructure is provided by Josep Maria Blasco's
[Rexx Parser](https://github.com/JosepMariaBlasco/rexx-parser) (also distributed
as part of [net-oo-rexx](https://github.com/RexxLA/net-oo-rexx)) -- an AST/element
parser for Rexx, ooRexx, and Executor, written in ooRexx itself.

Run the Rexx Parser's own `setenv` script (or otherwise add its `bin/` directory
to `PATH`) before running rexx-lint or its tests; run rexx-lint's own `setenv`
script too, so its `bin/`, `lib/`, and `checks/` directories resolve regardless
of current working directory.

Seven checks are implemented and tested -- see "Checks (implemented)" below;
every check originally planned is now in place. Suggestions for more are
welcome (see "Collaboration").

```
rexx bin/rexx-lint.rex [options] file.rex [file2.rex ...]
rexx tests/run-tests.rex
```

Options:

- `--dialect=DIALECT` -- target dialect (accepted, not yet used to vary
  check behavior -- see "Dialect support" below). Default: `oorexx`.
- `--checks=A,B,C` -- run only these checks, by name, ignoring the default
  full set.
- `--disable=A,B,C` -- run the default full set except these checks.
- `--config=PATH` -- read the active-check list from `PATH` instead of the
  default `.rexxlintrc`.

`--checks` and `--disable` are mutually exclusive with each other, but
either one on the command line overrides a config file. With neither
given, a config file is used if one is found -- an explicit `--config=`
path, or, failing that, a file named `.rexxlintrc` in the current
directory. With no CLI selection and no config file, every check runs.

`.rexxlintrc` format: one check name per line; blank lines and lines
starting with `#` are ignored.

## Dialect support

The `--dialect` option selects the target dialect: `classic`, `oorexx`, `regina`, `zvm`, `omvs`, `tso`, `netrexx`, `executor`.

## Checks (implemented)

- **`shadowed-special-vars`** -- flags any assignment-like use of `RESULT`,
  `RC`, or `SIGL` (plain assignment, PARSE targets, USE ARG, DO/LOOP control
  and COUNTER variables, EXPOSE/USE LOCAL/PROCEDURE EXPOSE/DROP), using the
  parser's own `isAssigned` element attribute.
- **`keyword-as-variable`** -- flags a simple variable whose name is also a
  Rexx/ooRexx keyword instruction, keyword clause, or common subkeyword
  (`class = 5`, `do to = 1 to 10`, etc.). Legal Rexx, since keywords aren't
  reserved words, but a style hazard for the reader. See
  `checks/KeywordAsVariable.cls` for the word list and how it was derived.
- **`signal-control-flow`** -- flags `SIGNAL` used as an unconditional jump
  (a label, `SIGNAL VALUE expr`, etc.) rather than to arm/disarm a condition
  trap (`SIGNAL ON`/`SIGNAL OFF`, not flagged). `SIGNAL` drops the entire
  active call stack, unlike `CALL` -- including `CALL ON`, which is not
  flagged, since it preserves the stack regardless of form.
- **`backslash-escape`** -- flags a backslash inside a string literal
  followed by a letter that looks like a C/Python/JS-style escape code
  (`\n`, `\t`, `\\`, etc.). Rexx has no string-escape mechanism in any
  dialect; a backslash in a string is always two literal characters, not
  an escape sequence -- a silent, easy-to-miss bug for anyone coming from
  a language where it is one.
- **`stem-paren-expression`** -- flags `stem.(expression)`, the classic
  mistaken attempt at indirect/computed stem-tail access. It isn't that in
  any dialect; it calls a routine literally named `STEM.` (trailing dot
  included), which either fails outright or silently calls the wrong
  thing. The correct forms are `stem.[expr]` (classic indirect tail) or a
  real collection object.
- **`stem-count-loop`** -- flags `DO var = ... TO stem.0` (and the `LOOP`
  synonym), a manually-counted stem simulating an array. Superseded by
  `.Array` with `do over` -- except when the stem was populated by
  `address ... with output stem`, which this purely syntactic check can't
  distinguish from the array-simulation case; see the check class's own
  docstring for that known limitation.
- **`nested-builtin-call`** -- flags a built-in function call whose first
  argument is itself an immediate built-in call (`translate(strip(x))`),
  as a candidate for ooRexx chained-method style (`x~strip~translate`).
  Deliberately narrow: only the immediately-nested case is flagged, not a
  nested call as a later argument or more than one level deep.

## Checks (planned)

None currently -- all originally-planned checks are implemented. Open to
suggestions; see "Collaboration" below.

## Platform

Developed on ArcaOS; Linux compatibility is a requirement from the start. Targets submission to RexxLA.

## Collaboration

Contributions and issue reports are welcome. If you have additional checks to suggest, or experience with Rexx dialects not yet covered, please open an issue or pull request, or incorporate whatever is useful into your own work.

## Author

Shmuel (Seymour J. Metz) (שְׁמוּאֵל בֵּן לייביש ולאה)
[smetz3@gmu.edu](mailto:smetz3@gmu.edu)
[mason.gmu.edu/~smetz3](https://mason.gmu.edu/~smetz3)
GitHub: [shmuelmetz](https://github.com/shmuelmetz)

## License

[MIT](LICENSE)
