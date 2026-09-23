**Subject:** Re: rexx-lint — a static-analysis linter built on your Rexx Parser

Hi Josep Maria,

No rush at all — whenever the EPBCN and Rony deadlines ease up. Nothing
on my end is time-sensitive.

There's no separate download page, I'm afraid, just the repository:
https://github.com/shmuelmetz/rexx-lint. Clone it and you have
everything — `bin/rexx-lint.rex` is the CLI, `checks/` holds the
individual checks, and `tests/run-tests.rex` runs them against
fixtures. It expects your Rexx Parser alongside it; the README covers
pointing it there.

Since you asked in spirit what prompted it: I've been leaning heavily
on an AI assistant (Claude) for Rexx work, and it kept producing code
with style problems and the occasional outright syntax error. I wanted
a linter in the loop so I wasn't flagging the same thing by hand over
and over. So the checks lean toward the mistakes a fluent-but-careless
writer makes — `RC` / `RESULT` / `SIGL` reused as ordinary variables,
keywords used as variable names, `SIGNAL` as a plain GOTO, `\n` written
as though Rexx had C escapes.

rxcheck — thank you, I didn't know it. Targetless SIGNAL is exactly one
of mine (`signal-control-flow`), and "BIF with the wrong signature" is
a good check I don't have yet. I'll look at it and work out where the
two overlap and where rexx-lint might still be adding something.

Two other Rexx things in flight, since you might find them of
interest: ooRexx and PL/I lexers for Pygments are up as pull request
#3310 (github.com/pygments/pygments/pull/3310) — still open, no
reviews yet. And *Safe REXX in the Enterprise and on the Desktop* — a
merged, updated edition of two old papers of mine on writing REXX
that holds up against its own pitfalls — now covers ooRexx alongside
Classic REXX, OREXX, TSO/E, CMS, and Regina, and is sitting in its own
repo (github.com/shmuelmetz/Safe-REXX) while I sort out where it'll
actually get published. It does not currently support the
experimental projects under development over the last few years, and
I would welcome collaborators.

And yes — the Parser has been a real pleasure to build on. Thank you
for it.

Shmuel (Seymour J.) Metz
