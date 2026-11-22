# CS F301 Principles of Programming Languages — Assignment 2

Group **20**. Logic and functional programming: two Prolog problems (P1, P2)
and two Scheme problems (S1, S2).

## Prerequisites

`swipl` and `racket` on your `PATH`. Check:

```bash
swipl --version
racket --version
```

Target versions per the assignment brief: **SWI-Prolog 9.x** and **Racket 8.x**.

Everything here was written and verified on WSL Ubuntu 20.04 with the
distribution packages, **SWI-Prolog 7.6.4** and **Racket 7.2**. The code is
deliberately held to the intersection of those and the target versions — no
predicate or form newer than 7.6 / 7.2 is used — so it runs unchanged on
9.x / 8.x. Nothing depends on a version-sensitive default; in particular no
expression relies on what `/` returns for integers.

## Quick start

```bash
git clone <repo-url> && cd <repo>
bash 20/tests/run_tests.sh
```

Expect `failed 0`. Problems not yet implemented report `[SKIP]`, not a failure.

## Layout

```
20/
  code/     20_q1.pl  20_q2.pl  20_q3.rkt  20_q4.rkt
  tests/    run_tests.sh  test_q3.rkt  test_q4.rkt
  skills/   prolog-dev/SKILL.md  scheme-dev/SKILL.md
  prompts/  P1.md  P2.md  S1.md  S2.md  SETUP.md
  P1_REPORT.md
README.md  .gitignore  .gitattributes
```

`skills/` holds the instruction packs given to the AI assistant; `prompts/`
holds every prompt used, word for word, one file per problem. `P1_REPORT.md`
carries the solution count asked for in P1.b.

## How the grader runs each file

Run these from `20/code/`:

```bash
cd 20/code
```

**P1 — `20_q1.pl`.** `main/0` prints one solution as four lines:

```bash
swipl -q -f 20_q1.pl -g main -t halt
```

Any other predicate is reached by goal:

```bash
swipl -q -f 20_q1.pl -g "count_solutions([1,2,3,4,5,6,7,8],N), format('~w~n',[N])" -t halt
swipl -q -f 20_q1.pl -g "count_solutions([1,2,3,4,5,6,7,8,9],N), format('~w~n',[N])" -t halt
```

**P2 — `20_q2.pl`.** No entry point; everything is called by goal:

```bash
swipl -q -f 20_q2.pl -g "generate_equation([4,2,5,3],E), format('~w~n',[E])" -t halt
swipl -q -f 20_q2.pl -g "all_equations([4,2,5,3],Es), format('~q~n',[Es])" -t halt
swipl -q -f 20_q2.pl -g "count_equations([4,2,5,3],N), format('~w~n',[N])" -t halt
```

Both Prolog files contain definitions only — no `initialization` directive, no
`halt/0` of our own.

**S1 — `20_q3.rkt`** and **S2 — `20_q4.rkt`.** Both are `#lang racket/base` and
contain definitions only, so running them directly prints nothing:

```bash
racket 20_q3.rkt     # no output
racket 20_q4.rkt     # no output
```

The grader appends its own calls to the end of the file. To reproduce that,
concatenate a driver of call lines (which is what `tests/test_q3.rkt` and
`tests/test_q4.rkt` are — they have no `#lang` line):

```bash
cat 20_q3.rkt ../tests/test_q3.rkt > /tmp/run_q3.rkt && racket /tmp/run_q3.rkt
```

S2 reads `x`, `lst` and `n` from standard input with `read`, so each case is
piped in:

```bash
cat 20_q4.rkt ../tests/test_q4.rkt > /tmp/run_q4.rkt
printf '42 ((1 2) (3 4 5) (6) ()) 3\n' | racket /tmp/run_q4.rkt
# ((42 1 2) (3 4 5) (42 6) (42))
```

## Running the tests

```bash
bash 20/tests/run_tests.sh          # all four problems, plus deliverable check
bash 20/tests/run_tests.sh q1       # one problem: q1 | q2 | q3 | q4
```

Runnable from any directory — the script locates `20/` from its own path. It
checks toolchain versions, scans both languages for constructs the brief bans,
confirms each file loads silently, and compares every worked example in the
assignment PDF byte for byte. Exit status is 0 only when nothing failed.

Prolog hangs are a defect, not a retry: on this assignment a loop almost always
means a predicate that was required to fail. `timeout` is used where available
(WSL); in Git Bash it is absent and the script runs without it.

## Changing the group ID

The ID `20` appears in exactly two places — the top-level directory name and
the four code filenames. It appears nowhere inside any source file, so a rename
is mechanical. From the repository root, with `NEW` set to the new ID:

```bash
NEW=99
git mv 20 "$NEW"
for q in 1 2; do git mv "$NEW/code/20_q${q}.pl"  "$NEW/code/${NEW}_q${q}.pl"; done
for q in 3 4; do git mv "$NEW/code/20_q${q}.rkt" "$NEW/code/${NEW}_q${q}.rkt"; done
grep -rn '20_q' "$NEW" README.md   # update the paths this reports
bash "$NEW/tests/run_tests.sh"
```

`run_tests.sh` and both `SKILL.md` files name the code files explicitly, so the
`grep` above is what tells you which lines still need editing.
