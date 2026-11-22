---
name: scheme-dev
description: Conventions, run/test commands, a pre-answer self-review checklist and known AI failure modes for the Racket 8.x problems (S1, S2) of CS F301 Assignment 2, group 20. Load this before writing, editing or reviewing any .rkt file in this repository.
---

# scheme-dev

Scope: the two Scheme problems of CS F301 Assignment 2 — `20/code/20_q3.rkt`
(binary tree traversals) and `20/code/20_q4.rkt` (conditional insert into a
nested list), plus their tests in `20/tests/`.

## 1. Environment and the allowed-builtin whitelist

- Language: **Racket 8.x**, dialect `#lang racket/base`. Check with
  `racket --version`; expect `Racket v8.17`.
- Line 1 of every solution file is exactly `#lang racket/base`. Not
  `#lang racket`, not `#lang scheme`.
- The file contains **definitions only**. The grader appends its own calls to
  the end of your file, so no top-level call, no test invocation, no
  `(module+ main ...)`, and nothing printed when the file is loaded.

This problem set works from a **whitelist**, not a blacklist. Only these are
permitted:

```
define  lambda  let  let*  letrec  named let  if  cond (with else)
and  or  not  begin  quote (')
cons  car  cdr  list
car/cdr compositions up to four levels (cadr, cddr, caddr, cdddr, cadddr, cddddr, ...)
null?  pair?  eq?  assq  assoc
+  -  *  <  >  <=  >=  =  max
display  newline
```

`read` is additionally allowed in S2 (`20_q4.rkt`) only.

Everything else in `racket/base` is forbidden. The ones that will tempt you:

| Forbidden | Write instead |
| --- | --- |
| `length` | `my-length` |
| `append` | thread an accumulator |
| `reverse` | `my-reverse` |
| `map` | `my-map` |
| `filter`, `member`, `memq` | your own recursion |
| `list-ref`, `list-tail` | your own recursion |
| `equal?` | `eq?` for symbols, `=` for numbers |
| `set!` and relatives | pass state through arguments |
| vectors, hash tables, strings | lists |
| `do`, `for`, `for/list`, … | recursion or named `let` |
| `printf`, `format`, `write`, `print`, `~a` | `display` + `newline` |
| `apply`, `error`, `void`, `else` outside `cond` | — |
| `length`-based division, `quotient`, `remainder`, `/` | not needed; not listed |

Note that `equal?` is **not** on the whitelist even though `assoc` is. Compare
symbols with `eq?` and numbers with `=`.

## 2. Coding conventions

**Naming.** `kebab-case` for everything: `print-inorder`,
`print-height-and-leaves`, `make-inserter`. Predicates end in `?`. A
reimplementation of a forbidden built-in is prefixed `my-`: `my-length`,
`my-map`, `my-reverse`. Never shadow a built-in name — `my-length` makes the
substitution visible to the grader, a local `length` hides it.

**Accumulators.** The accumulator parameter is named `acc`. Tail-recursive
loops use a named `let` with the loop variable named `loop`:

```racket
(let loop ((rest lst) (acc 0))
  (if (null? rest) acc (loop (cdr rest) (+ acc 1))))
```

**Header comment.** Every function, including helpers, carries a contract line,
a one-line description, and a **recursive reading** that names what decreases
and why it terminates:

```racket
;; my-length : list -> integer
;; Number of top-level elements of lst.
;; Recursive reading: the length of () is 0; the length of a non-empty list
;; is 1 more than the length of its cdr. The argument shrinks by one cons
;; cell per call, so it terminates. Tail-recursive via acc.
(define (my-length lst)
  (let loop ((rest lst) (acc 0))
    (if (null? rest) acc (loop (cdr rest) (+ acc 1)))))
```

For S1 the reading is stated over the tree: which subtree the call descends
into, and that both subtrees are strictly smaller than the node.

**Layout.** Two-space indent. Closing parens stay on the last line of the
expression — never a line containing only `)`. One blank line between
definitions, none inside a definition.

**State.** S1 requires all state to pass through function arguments. No
mutation anywhere in either file.

**What counts as a list.** An element is a list if it is `'()` **or** a pair:

```racket
(or (null? e) (pair? e))
```

`pair?` alone is the single most common bug in S2, because `'()` must be
treated as a list of length 0 and become `(x)` when `0 < n`.

## 3. How to run and test

All commands run from the `20/` directory.

**The load check.** A correct solution file prints nothing at all:

```bash
racket code/20_q3.rkt
racket code/20_q4.rkt
```

Any output here means a stray top-level call. Any error here means a syntax
problem or a forbidden identifier. This is the first thing to run after every
edit.

**Testing mirrors the grader.** The grader appends its calls to the end of your
file, so reproduce exactly that: keep the call lines in a test file with **no**
`#lang` line, concatenate, and run the result.

`20/tests/test_q3.rkt` contains only calls and expected output as comments:

```racket
;; S1 tests — appended to code/20_q3.rkt by the run command in SKILL.md
;; expected: (1 2 3 4 5 6 7)
(define t1 '(4 (2 (1 () ()) (3 () ())) (6 (5 () ()) (7 () ()))))
(define t2 '(1 () (2 () (3 () ()))))
(define t3 '(a (b () ()) (c () ())))

(print-inorder t1)              ;; (1 2 3 4 5 6 7)
(print-all-traversals t1)       ;; (1 2 3 4 5 6 7) / (4 2 1 3 6 5 7) / (1 3 2 5 7 6 4)
(print-height-and-leaves t1)    ;; (3 4)
(print-all-traversals t2)       ;; (1 2 3) / (1 2 3) / (3 2 1)
(print-height-and-leaves t2)    ;; (3 1)
(print-all-traversals t3)       ;; (b a c) / (a b c) / (b c a)
(print-height-and-leaves t3)    ;; (2 2)
(print-inorder '())             ;; ()
(print-all-traversals '())      ;; () / () / ()
(print-height-and-leaves '())   ;; (0 0)
```

Run it, bash:

```bash
cat code/20_q3.rkt tests/test_q3.rkt > run_q3.rkt && racket run_q3.rkt
```

Run it, PowerShell:

```powershell
Get-Content code\20_q3.rkt, tests\test_q3.rkt | Set-Content run_q3.rkt
racket run_q3.rkt
```

Add `run_q*.rkt` to `.gitignore` — the generated file is not a deliverable.

**S2 reads from standard input**, so `tests/test_q4.rkt` holds the single call
`(print-insert-result)` plus the cases as comments, and each case is piped in:

```bash
cat code/20_q4.rkt tests/test_q4.rkt > run_q4.rkt
printf '42 ((1 2) (3 4 5) (6) ()) 3\n' | racket run_q4.rkt   # ((42 1 2) (3 4 5) (42 6) (42))
printf '0 (((1) 2) (3) ((4 5 6) ())) 3\n' | racket run_q4.rkt # ((0 (0 1) 2) (0 3) (0 (4 5 6) (0)))
printf '7 () 3\n' | racket run_q4.rkt                         # (7)
printf '7 () 0\n' | racket run_q4.rkt                         # ()
```

PowerShell:

```powershell
'42 ((1 2) (3 4 5) (6) ()) 3' | racket run_q4.rkt
'7 () 0'                      | racket run_q4.rkt
```

**Scale tests, because the hidden tests use them.** Nesting depth 100 and lists
of 10,000 elements. Generate the input rather than typing it:

```bash
python -c "print('9', '(' + ' '.join(str(i) for i in range(10000)) + ')', 3)" | racket run_q4.rkt | head -c 120
python -c "print('9', '('*100 + ')'*100, 2)" | racket run_q4.rkt | head -c 120
```

If either hangs for more than a couple of seconds, you have an O(n²) walk —
almost always `my-length` being recalled per element instead of once per list.

## 4. Self-review checklist — apply before every answer

1. **Scope.** Exactly one unit of work — one function, one test file, or one
   review. If the answer spans more, deliver only the first unit.
2. **Whitelist.** Read every identifier in the answer and confirm it appears in
   the section 1 whitelist. Specifically search your own output for `length`,
   `append`, `reverse`, `map`, `filter`, `member`, `memq`, `list-ref`,
   `list-tail`, `equal?`, `set!`, `for`, `do`, `printf`, `format`, `apply`,
   `vector`, `string`. Zero hits outside `my-`-prefixed definitions.
3. **Dialect.** Line 1 is `#lang racket/base`.
4. **Definitions only.** No top-level call, nothing printed on load. Verified
   by running `racket code/20_qN.rkt` and seeing no output.
5. **Headers.** Every function has its contract, description and recursive
   reading, and the termination argument is actually true.
6. **Empty-list handling.** Every walk handles `'()` as an input, as an
   element, and as a subtree. `(or (null? e) (pair? e))` where "is it a list"
   is asked.
7. **Output shape.** `display` of the assembled list, then `newline`. Compare
   against the PDF character by character: parentheses, single spaces, one
   line per traversal, trailing newline present. Nothing extra printed.
8. **Counting conventions (S1).** Height of `()` is 0 and of a single node is
   1, not 0. The empty tree has 0 leaves. Left subtree always before right.
9. **Length semantics (S2).** Lengths are measured on the **original** list
   before any insertion, the top-level list is treated like any other, and
   `n = 0` inserts nothing anywhere because no length is `< 0`.
10. **Single definition (S2.c).** The final file defines `insert-if-short`
    exactly once, via `make-inserter`. The intermediate S2.b version is
    deleted, not commented out below it.
11. **Complexity.** `my-length` is called once per list, not once per element.
    No quadratic walk. Recursion depth 100 and width 10,000 both run.
12. **Did you actually run it?** Paste the exact concatenate-and-run command
    and its real output. If you could not run it, say so in one explicit
    sentence.

## 5. Known failure modes of AI tools on Scheme/Racket

1. **`#lang racket` instead of `#lang racket/base`.** The default in nearly
   every Racket snippet online.
2. **Reaches for forbidden built-ins reflexively.** `length`, `append`,
   `reverse`, `map`, `filter`, `member` are so idiomatic that they appear even
   after being told not to. `append` in traversal code and `length` in S2 are
   the two near-certainties. Re-read the identifiers, do not trust intent.
3. **Writes `my-length` then calls `length` in the next function.** Mixed
   compliance is common; check every function, not just the ones named `my-`.
4. **`equal?`.** Not on the whitelist. Appears whenever atoms are compared.
5. **Builds traversals with `append`.** Both forbidden and O(n²). Thread an
   accumulator through the recursion instead, building the list right-to-left.
6. **`pair?` without `null?`.** So `'()` is classified as an atom, and
   `7 () 3` returns `()` instead of `(7)`, and the inner `()` in
   `((4 5 6) ())` is left alone instead of becoming `(0)`.
7. **`n = 0` edge case.** Returns `(7)` for `7 () 0`. Length 0 is not less
   than 0, so nothing is inserted — the answer is `()`.
8. **Measures length after inserting.** Inserts into children first, then
   measures the parent, so the parent's length is off by the number of
   insertions. Compute the original length first, then recurse.
9. **Forgets the top-level list.** Inserts at every nested level but leaves the
   outermost list untouched.
10. **Height off by one.** Returns 0 for a single node, having implemented
    height as edge count. The spec says a single node has height 1.
11. **Counts the empty tree as one leaf**, or counts internal nodes with one
    empty subtree as leaves. A leaf has **both** subtrees `()`.
12. **Visits right before left**, or emits preorder where postorder was asked.
    Check all three traversals of `t1` against the PDF, not just inorder.
13. **Assumes values are numbers.** `t3` holds symbols `a`, `b`, `c`. Any
    arithmetic or ordering on node values is wrong.
14. **`printf`/`format`/`write` instead of `display`.** Also `(display "...")`
    uses a string literal, and strings are forbidden.
15. **Adds top-level calls or a `main` submodule** so the file prints on load.
    Often added "to demonstrate" the code.
16. **Leaves two definitions of `insert-if-short`** after S2.c — the direct one
    from S2.b and the `make-inserter` one. The spec requires exactly one.
17. **`make-inserter` captures the wrong thing.** Closes over `n` and compares
    internally rather than calling the supplied `len-ok?` predicate, so it is
    no longer higher-order and `insert-if-short` cannot be expressed through
    it.
18. **`read` misuse.** Reads a line, reads once expecting three values, calls
    `read-line` or `string->number`, or prints a prompt. It is three bare
    `(read)` calls, in the order x, lst, n, and no prompt.
19. **Quadratic `my-length`.** Calls `my-length` inside the per-element
    recursion, so a 10,000-element list does 10⁸ operations and the hidden
    test times out.
20. **`cond` with no `else`** falling through to an unprintable void result.
21. **Claims output it never produced.** Demand the concatenate-and-run command
    and its real stdout, then re-run it yourself.

## 6. Process rules this repository enforces

- One prompt = one unit of work. One commit per unit, message naming the unit
  (`S2.b: my-length and my-map`).
- Every prompt goes into `20/prompts/S1.md` or `20/prompts/S2.md` **word for
  word**, in order, before the commit holding the resulting code.
- All four group members author commits under their own name and email.
- `run_q*.rkt` is generated and stays out of git.
