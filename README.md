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

Three checks are implemented and tested -- see "Checks (implemented)" below.

```
rexx bin/rexx-lint.rex [--dialect=DIALECT] file.rex [file2.rex ...]
rexx tests/run-tests.rex
```

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

## Checks (planned)

- Use of `stem.(expression)` (invalid in all dialects; dialect-specific alternatives suggested)
- Compound variables as candidates for collection objects (ooRexx)
- Nested functions as candidates for chained methods (ooRexx)
- `\` used as an escape character (meaningless in all Rexx dialects)

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
