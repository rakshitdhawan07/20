---
name: prolog-dev
description: Conventions, run/test commands, a pre-answer self-review checklist and known AI failure modes for the SWI-Prolog 9.x problems (P1, P2) of CS F301 Assignment 2, group 20. Load this before writing, editing or reviewing any .pl file in this repository.
---

# prolog-dev

Scope: the two Prolog problems of CS F301 Assignment 2 — `20/code/20_q1.pl`
(department puzzle) and `20/code/20_q2.pl` (arithmetic equation), plus their
tests in `20/tests/`.

## 1. Environment and hard bans

- Language: **SWI-Prolog 9.x**, nothing else. Check with `swipl --version`
  before the first run of a session.
- Allowed libraries, both problems: `lists`, `apply`, `yall`, `aggregate`.
  Nothing else. These are autoloaded in SWI 9, so do not add
  `:- use_module(library(...))` unless a real run proves a predicate is not
  autoloaded.
- The solution files contain **definitions only**. The grader adds its own
  goals.

Banned outright. Each of these costs marks even if the code is correct:

| Banned | Why |
| --- | --- |
| `assert/1`, `asserta/1`, `assertz/1`, `retract/1` | Assignment constraint |
| `b_setval/2`, `nb_setval/2`, `b_getval/2`, `nb_getval/2` | Assignment constraint |
| any `:- initialization(...)` directive | Assignment constraint |
| your own call to `halt/0` | Assignment constraint |
| a top-level goal or any output produced at load time | "definitions only" |
| printing anything beyond what the task specifies | Assignment constraint |
| building a string/atom and parsing it back (`term_to_atom/2`, `term_string/2`, `read_term_from_atom/3`) to evaluate an expression | P2 constraint |

Evaluate P2 expressions **structurally**, by recursion over the expression
term you built. Never round-trip through text.

## 2. Coding conventions

**Naming.** Predicates and atoms `snake_case`. Variables `CamelCase` and
meaningful (`Dept`, `Lhs`, `Acc`), never `X1`, `X2`, `T3`. Unused variables are
written `_` or `_Name`; a singleton warning at load time is a defect, not a
warning to ignore.

**Header comment.** Every predicate, including helpers, gets a PlDoc-style
header giving the mode, the determinism, and a one-line declarative reading:

```prolog
%! clue(+N:integer, +Solution:list) is semidet.
%
%  True when clue number N holds of the fully instantiated Solution.
%  Read declaratively: "clue N is satisfied by this complete assignment".
%  Solution must be ground before this is called.
clue(3, S) :-
    member(p(_, testing, python, _), S).
```

Mode prefixes: `+` must be bound on call, `-` is produced, `?` either.
Determinism: `det` (exactly one solution), `semidet` (zero or one),
`nondet` (zero or more), `multi` (one or more). Getting this wrong in the
comment is a defect — the viva asks about it.

**Clause layout.** Base cases first. One goal per line once a clause body has
more than two goals, 4-space continuation indent. Cuts are rare; when you use
one, the header comment must say which choice point it removes.

**Recursive / declarative reading.** Each recursive predicate carries one
extra comment line stating the induction: what decreases on every call, and
why that guarantees termination. For a generator, state the finite set it
enumerates.

**Comments.** Explain the logic, not the syntax. In `20_q1.pl` the English
sentence of clue 9 goes on the line directly above `clue(9, Solution)` and
starts with `% CLUE 9:` — this is graded, and the clue must not name any
friend.

## 3. How to run and test

All commands are run from the `20/` directory of the repository.

Syntax and warning check (load the file, print nothing, exit):

```bash
swipl -q -g "consult('code/20_q1.pl')" -t halt 2>&1 | tee /tmp/load_q1.log
```

A clean load prints nothing. Any `Warning:` or `Singleton variables:` line
must be fixed before the answer is considered done.

P1 — the specified entry point:

```bash
timeout 20 swipl -q -f code/20_q1.pl -g main -t halt
```

P1 — any other predicate (this is how the grader reaches them):

```bash
timeout 20 swipl -q -f code/20_q1.pl \
  -g "count_solutions([1,2,3,4,5,6,7,8],N), format('~w~n',[N])" -t halt
```

P2 — single and all-solutions forms:

```bash
timeout 20 swipl -q -f code/20_q2.pl \
  -g "generate_equation([4,2,5,3],E), format('~w~n',[E])" -t halt

timeout 20 swipl -q -f code/20_q2.pl \
  -g "all_equations([4,2,5,3],Es), format('~q~n',[Es])" -t halt
```

Always wrap exploratory runs in `timeout 20`. A non-terminating Prolog goal
otherwise eats the terminal, and on this assignment a loop where a failure was
required is itself a defect.

**Test files.** One per problem: `20/tests/test_q1.pl`, `20/tests/test_q2.pl`.
Use `library(plunit)`. The bans in section 1 apply to the four solution files,
not to the test files, so a test file may load and may print.

Skeleton:

```prolog
:- use_module(library(plunit)).
:- consult('../code/20_q1.pl').

:- begin_tests(q1).

test(clue3_holds_for_known_solution) :-
    clue(3, [p('Alex',testing,python,'AI'), p('Ben',design,java,web),
             p('Carla',research,'c++',data), p('Dana',development,javascript,embedded)]).

test(count_all_eight, [true(N =:= 1)]) :-
    count_solutions([1,2,3,4,5,6,7,8], N).

:- end_tests(q1).
```

Run them:

```bash
timeout 60 swipl -q -f tests/test_q1.pl -g run_tests -t halt
```

In SWI a relative path in a load directive resolves against the directory of
the file containing it, so `'../code/20_q1.pl'` is correct from `tests/`. If
that ever fails, run from `20/` and use `'code/20_q1.pl'` instead — verify
once, then keep it consistent.

Every example in the assignment PDF must appear as a test, plus your own edge
cases. For P2 the mandatory ones are: `[4,2,5,3]` gives exactly the seven
listed equations; `[2,3,4]` fails and yields `[]`; `[2,4,8]` yields
`["2*4=8"]`; `[]` and `[7]` make `generate_equation/2` **fail**, not error.

## 4. Self-review checklist — apply before every answer

The AI must walk this list and state the result of each relevant item. If an
item fails, fix the code before answering; do not hand over code with a known
failure.

1. **Scope.** Does this answer contain exactly one unit of work — one
   predicate, one test file, or one review? If it spans more, stop and deliver
   only the first unit. This assignment forbids prompts that ask for a whole
   problem, and the commit history must mirror the decomposition.
2. **Bans.** Grep your own output for `assert`, `retract`, `nb_setval`,
   `b_setval`, `initialization`, `halt`, `term_to_atom`, `term_string`,
   `read_term_from_atom`. Zero hits.
3. **Definitions only.** No goal at the top level of a solution file, no output
   at load time.
4. **Headers.** Every predicate has the `%!` header with modes, determinism,
   and a one-line declarative reading. The determinism claimed matches reality.
5. **Arithmetic.** `is/2` for evaluation, `=:=/2` for numeric comparison,
   `=/2` for unification — never mixed. No `is/2` with an unbound right side.
   Every division guarded for a zero divisor **and** for exactness.
6. **Quoting.** `'Alex'`, `'Ben'`, `'Carla'`, `'Dana'`, `'AI'`, `'c++'` are
   quoted everywhere. Unquoted `AI` is a variable; unquoted `c++` is an
   operator parse, not an atom.
7. **Negation.** `\+/1` and `dif/2` are applied only to sufficiently
   instantiated terms. Clue checks assume a complete, ground assignment.
8. **Termination.** Every recursion has an argument that strictly decreases,
   and every generator enumerates a finite set. No left recursion.
9. **Fail, do not error.** Degenerate inputs (empty list, single element, no
   solution) make the predicate fail silently. No uncaught
   `instantiation_error` or `type_error`.
10. **Duplicates and order.** `sort/2` sorts and removes duplicates;
    `msort/2` sorts and keeps them. Use the one the task names. `findall/3`
    copies its results, so bindings do not escape it.
11. **Output byte-for-byte.** Compare against the PDF character by character:
    spacing, capitalisation, line count, trailing newline. `~w` writes
    unquoted; `~q` and `~p` quote. Nothing extra is printed.
12. **Did you actually run it?** Paste the exact command used and its real
    output. If you could not run it, say so in one explicit sentence rather
    than implying the output is real.
13. **No invented predicates.** Every built-in used exists in SWI-Prolog 9 and
    lives in `lists`, `apply`, `yall` or `aggregate`.

## 5. Known failure modes of AI tools on Prolog

Watch for these specifically; they are the ones that recur.

1. **Adds `:- initialization(main).`** The usual SWI script idiom, and banned
   here. Also drops `halt.` at the end of `main/0`. Delete both.
2. **`=` vs `is` vs `=:=`.** Writes `X = 2+3` and expects `5`, or `X is Y`
   with `Y` unbound. Also writes `=:=` between atoms, which raises a type
   error.
3. **Prints the list instead of the fields.** `format("~w = ~w~n", [Name, [Dept,Lang,Proj]])`
   gives `Alex = [research,python,AI]` — no spaces after the commas. The
   required layout is `Alex = [research, python, AI]`, so the three fields must
   be formatted individually:
   `format("~w = [~w, ~w, ~w]~n", [Name, Dept, Lang, Proj])`.
4. **Quotes leak into output.** Uses `~q`, `~p`, `print/1` or `writeq/1`, so
   `'c++'` and `'AI'` print with quotes and the output no longer matches. Use
   `~w` or `write/1`.
5. **Unquoted atoms in the source.** Writes `AI` (a variable, so the clue
   silently matches anything) or `c++` (a parse error). Both appear often
   because the PDF prose writes them unquoted in English sentences.
6. **Floundering negation.** Encodes "does not work in research" as
   `\+ Dept = research` while `Dept` is still unbound, which fails
   immediately and silently drops valid solutions. Either generate a complete
   ground assignment before testing the clues, or use `dif/2`.
7. **Hard-codes the puzzle answer.** Asked for `main/0`, it emits four
   `format/2` calls with the solution baked in. Explicitly banned: the answer
   must be derived from `clue/2`.
8. **`clue/2` that works on partial solutions.** The spec is: succeeds exactly
   when clue N holds in a *fully filled-in* Solution. A clue that also succeeds
   on partially instantiated terms makes `count_solutions/2` wrong.
9. **Counting with `findall/3` + `length/2` but forgetting duplicates**, or
   reaching for `aggregate_all(count, ...)` while believing it deduplicates. It
   does not.
10. **Division assumptions.** Assumes `X is 6/3` yields the integer `2`. In SWI
    `/` on integers may give a float or a rational depending on the
    `prefer_rationals` flag, so `2.0 =:= 2` holds but `2.0 == 2` does not, and
    a float silently poisons later comparisons. Test exactness first
    (`B =\= 0, 0 =:= A mod B`) and then divide with `//`.
11. **Unguarded division in P2.** Checks exactness only at the top level, not
    inside every sub-expression, and lets `X/0` raise instead of fail.
12. **Strings vs atoms.** P2 requires an SWI **string**. The AI returns an atom
    from `atom_concat/3` or `atomic_list_concat/3`, or a code list. Build with
    `format(string(S), ...)`, `string_concat/3` or `number_string/2`, and check
    with `string(E)`.
13. **Round-trips through text to evaluate.** `term_to_atom(T, A), X is T` is
    the first thing it reaches for on P2, and it is banned. Evaluate the term
    by recursion.
14. **Wrong parenthesisation rule.** Implements standard pretty-printing
    instead of the PDF's rule, so `1+(2+3)` collapses to `1+2+3`. Those are
    different trees and both must appear. Right operands are parenthesised on
    *equal or lower* precedence; left operands only on strictly lower.
15. **Invented built-ins**, or ones outside the allowed four libraries. Common
    inventions: `list_to_set/2` used as if it sorted, `sumlist/2`,
    `string_format/3`.
16. **Silent library additions.** Adds `:- use_module(library(clpfd)).` and
    rewrites the puzzle with `ins`/`all_different`. Not an allowed library.
17. **Left recursion or an unbounded generator.** `between(1, inf, N)` or a
    recursive clause with no decreasing argument, so the goal loops where the
    spec requires failure.
18. **Claims output it never produced.** Presents plausible invented results.
    Demand the command and its real output, and re-run it yourself.

## 6. Process rules this repository enforces

- One prompt = one unit of work. One commit per unit, message naming the unit
  (`P1.a: clue/2 for clues 1-4`).
- Every prompt goes into `20/prompts/P1.md` or `20/prompts/P2.md` **word for
  word**, in order, before the commit that contains the resulting code.
- All four group members author commits under their own name and email.
- `20/P1_REPORT.md` records the value of N from `count_solutions/2` for clues
  1 to 8 and what that says about the puzzle.
