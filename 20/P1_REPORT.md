# P1_REPORT.md — Department Assignment Puzzle, Reloaded

Group 20. Report for P1.b and P1.c of CS F301 Assignment 2.

## P1.b — the value of N

```
count_solutions([1,2,3,4,5,6,7,8], N)   gives   N = 3
```

### What it tells us about the puzzle

The puzzle as stated is **under-determined**. Eight clues are not enough to fix
a unique assignment: three different arrangements of the four friends satisfy
all of them simultaneously, so the puzzle has no single correct answer. A
reader asked to "solve" it cannot do so uniquely, which is exactly the defect
P1.c asks us to repair.

The shortfall is not caused by a wasted or redundant clue. Dropping any one of
the eight **increases** the count, so every clue is doing work that none of the
others does:

| Clue removed | Solutions remaining |
| --- | --- |
| none | 3 |
| 1 | 4 |
| 2 | 6 |
| 3 | 13 |
| 4 | 12 |
| 5 | 9 |
| 6 | 7 |
| 7 | 5 |
| 8 | 16 |

So no clue is implied by the rest, and the problem is genuinely missing
information rather than carrying dead weight. Clue 8 is the most constraining
single clue (removing it costs the most) and clue 1 the least.

Constraint accumulates steeply from a search space of 4! × 4! × 4! = 13824
complete assignments:

| Active clues | Solutions |
| --- | --- |
| (none) | 13824 |
| 1 | 7776 |
| 1–2 | 4320 |
| 1–3 | 1128 |
| 1–4 | 208 |
| 1–5 | 76 |
| 1–6 | 36 |
| 1–7 | 16 |
| 1–8 | 3 |

### The three solutions

```
S1   Alex=[design, java, AI]        Ben=[development, javascript, web]
     Carla=[research, c++, data]    Dana=[testing, python, embedded]

S2   Alex=[design, java, embedded]  Ben=[development, javascript, web]
     Carla=[testing, python, AI]    Dana=[research, c++, data]

S3   Alex=[testing, python, embedded] Ben=[development, javascript, web]
     Carla=[design, java, AI]       Dana=[research, c++, data]
```

Ben is `[development, javascript, web]` in all three, and the pairing
`research–c++–data` holds in all three, so the residual ambiguity is confined
to how the remaining attribute triples are distributed among Alex, Carla and
Dana.

## P1.c — the repair

```prolog
% CLUE 9: The friend who works in the testing department prefers the AI
%         project.
clue(9, Solution) :-
    memberchk(p(_, testing, _, 'AI'), Solution).
```

```
count_solutions([1,2,3,4,5,6,7,8,9], N)   gives   N = 1
```

The kept solution is **S2**:

```
Alex  = [design, java, embedded]
Ben   = [development, javascript, web]
Carla = [testing, python, AI]
Dana  = [research, c++, data]
```

Clue 9 names no friend. Like clue 5, it relates two attribute values to each
other — a department to a project preference — and so refers to the friends
only through what is true of them. It is true in S2, where the friend in
testing prefers AI, and false in S1 and S3, where the friend in testing
prefers embedded.

### Why S2 is the only solution a legal clue could keep

This is the substantive point of the repair, and it is a constraint the
assignment's own rule imposes.

Discard the names from each solution and look only at which `(department,
language, project)` triples occur:

| | triples |
| --- | --- |
| S1 | `design-java-AI`, `development-javascript-web`, `research-c++-data`, `testing-python-embedded` |
| S2 | `design-java-embedded`, `development-javascript-web`, `research-c++-data`, `testing-python-AI` |
| S3 | `design-java-AI`, `development-javascript-web`, `research-c++-data`, `testing-python-embedded` |

**S1 and S3 are identical as attribute assignments.** They are the same four
triples; they differ only in which friend holds which one — in S1 Alex has
`design-java-AI` and Dana has `testing-python-embedded`, while in S3 Carla has
the first and Alex the second.

A clue that may not mention a friend by name is, by definition, a property of
that unordered set of triples alone. Two solutions with the same set are
therefore indistinguishable to every such clue: any clue true in S1 is true in
S3 and vice versa. Adding a name-free clue can only ever cut the three
solutions down to S2 alone, or to {S1, S3}, or to nothing — never to S1 alone
and never to S3 alone.

So `N = 1` is reachable under the stated restriction in exactly one way: by
keeping S2. Had we wanted to keep S1, the clue would have had to name a friend,
which the task forbids.

This also explains why some natural-sounding ninth clues cannot work. "The
friend in the design department prefers the AI project" is true in both S1 and
S3, so it leaves `N = 2`. An equally valid alternative to the clue we chose is
"the friend whose favourite language is Java prefers the embedded project",
which likewise keeps only S2.

### A note on `main/0`

`main/0` answers P1.a, which asks for one solution of clues **1 to 8**, so it
prints the first solution the generator reaches, S1. That is not the solution
clue 9 keeps, and by the argument above it could not have been: no legal ninth
clue singles out S1. The two tasks are consistent — S1 satisfies clues 1 to 8,
which is all P1.a requires, and S2 is the unique solution of clues 1 to 9.

## How to reproduce every number in this report

From `20/code`:

```bash
swipl -q -f 20_q1.pl -g main -t halt
swipl -q -f 20_q1.pl -g "count_solutions([1,2,3,4,5,6,7,8],N), format('~w~n',[N])" -t halt
swipl -q -f 20_q1.pl -g "count_solutions([1,2,3,4,5,6,7,8,9],N), format('~w~n',[N])" -t halt

# the cumulative table
swipl -q -f 20_q1.pl -g "forall(between(1,8,K), (numlist(1,K,A), count_solutions(A,N), format('clues 1-~w: ~w~n',[K,N])))" -t halt

# the leave-one-out table
swipl -q -f 20_q1.pl -g "forall(between(1,8,D), (numlist(1,8,All), exclude(==(D), All, A), count_solutions(A,N), format('without clue ~w: ~w~n',[D,N])))" -t halt

# the three solutions of clues 1-8
swipl -q -f 20_q1.pl -g "forall(solve(S), (maplist(print_friend,S), nl))" -t halt
```
