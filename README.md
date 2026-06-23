# rexx-lint

A static analysis tool for Rexx source code.

## Purpose

- Checking a Rexx source file for errors and questionable idioms before running it
- Checking a file for dialect-specific issues before porting it to another Rexx environment
- Enforcing coding standards across a Rexx codebase
- Vetting AI-generated Rexx code before presenting it to the user

## Status

Early development. The parser infrastructure is provided by Josep Maria Blasco's work in net-oo-rexx ([github.com/RexxLA/net-oo-rexx](https://github.com/RexxLA/net-oo-rexx)).

## Dialect support

The `--dialect` option selects the target dialect: `classic`, `oorexx`, `regina`, `zvm`, `omvs`, `tso`, `netrexx`, `executor`.

## Checks (planned)

- Use of `stem.(expression)` (invalid in all dialects; dialect-specific alternatives suggested)
- Compound variables as candidates for collection objects (ooRexx)
- Nested functions as candidates for chained methods (ooRexx)
- `\` used as an escape character (meaningless in all Rexx dialects)
- `signal` used as control flow (flushes call stack)
- Variables shadowing special variables (`result`, `rc`, `sigl`)
- Keywords used as variable names (warning)

## Platform

Developed on ArcaOS; Linux compatibility is a requirement from the start. Targets submission to RexxLA.

## Collaboration

Contributions and issue reports are welcome. If you have additional checks to suggest, or experience with Rexx dialects not yet covered, please open an issue or pull request, or incorporate whatever is useful into your own work.

## Author

Shmuel (Seymour J. Metz) (שְׁמוּאֵל בֵּן ל״ביש)
[smetz3@gmu.edu](mailto:smetz3@gmu.edu)
[mason.gmu.edu/~smetz3](https://mason.gmu.edu/~smetz3)
GitHub: [shmuelmetz](https://github.com/shmuelmetz)

## License

[MIT](LICENSE)
