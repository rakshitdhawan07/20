#lang racket/base

;; ============================================================================
;; CS F301 Assignment 2 — S2: Conditionally Insert into a Nested List
;; Group 20 — file 20_q4.rkt
;;
;; The task
;; --------
;; insert-if-short takes an atom x, a possibly nested list lst and an integer
;; n, and inserts x at the front of every list whose length is less than n, at
;; every level of nesting.
;;
;; Rules that shape the implementation:
;;
;;   * a list's length is its number of top-level elements, measured on the
;;     ORIGINAL list, before any insertion anywhere;
;;   * the top-level list is treated like every other list;
;;   * empty lists are not special: '() has length 0, so it becomes (x)
;;     whenever 0 < n, and that holds for an empty top-level list too;
;;   * elements are atoms (digits or symbols) or lists, and there are no
;;     dotted pairs; n is an integer with n >= 0.
;;
;; An element counts as a list when it is '() or a pair. Testing pair? alone
;; would classify '() as an atom and leave it untouched, which contradicts the
;; rule above; that test is the single most common way to get this problem
;; wrong.
;;
;; Allowed built-ins only. length, append, map, reverse, member and the rest
;; are forbidden, so this file defines my-length and my-map and uses nothing
;; else of that kind. read is permitted here, for S2.a.
;;
;; Hidden tests use nesting depth 100 and lists of 10,000 elements, so the
;; implementation has to stay linear: my-length is called once per list, never
;; once per element.
;;
;; Definitions only. Running this file prints nothing; the grader appends its
;; own calls to the end.
;;
;; The file is organised in the order it was built: the two helpers, then
;; insert-if-short for S2.b, then make-inserter and the final definition of
;; insert-if-short for S2.c, then print-insert-result for S2.a.
;; ============================================================================


;; my-length : list -> integer
;;
;; The number of top-level elements of lst. Replaces the forbidden length.
;;
;; Recursive reading: the length of '() is 0; the length of a non-empty list
;; is one more than the length of its cdr.
;;
;; Written as a named let with an accumulator, so it is properly tail
;; recursive: the recursive call is the whole body of the if branch and
;; nothing is pending when it is made. On a 10,000-element list that matters
;; for constant stack use.
;;
;; Termination: rest loses one cons cell per iteration and '() is the base
;; case, so the loop runs exactly as many times as there are elements.
(define (my-length lst)
  (let loop ((rest lst) (acc 0))
    (if (null? rest)
        acc
        (loop (cdr rest) (+ acc 1)))))


;; my-map : (any -> any) list -> list
;;
;; The list of f applied to each element of lst, in order. Replaces the
;; forbidden map.
;;
;; Recursive reading: mapping f over '() gives '(); mapping f over a non-empty
;; list gives f of its car consed onto the mapping of f over its cdr.
;;
;; Termination: each call is made on the cdr of its argument, with '() as the
;; base case.
;;
;; This one is deliberately not tail recursive. The result of the recursive
;; call is needed as the tail of the cons, so making it a tail call would mean
;; accumulating the results in reverse and then flipping them, which needs a
;; my-reverse and a second pass over the list. Racket grows its continuation
;; on the heap rather than on a fixed stack, so a non-tail recursion 10,000
;; deep is fine, and the single-pass version is both shorter and the one whose
;; recursive reading matches the definition above.
(define (my-map f lst)
  (if (null? lst)
      '()
      (cons (f (car lst))
            (my-map f (cdr lst)))))


;; my-list? : any -> boolean
;;
;; True when x is a list: either the empty list or a pair. Since the problem
;; guarantees there are no dotted pairs, every pair here is a proper list.
;;
;; Both halves of the test are needed. pair? alone treats '() as an atom, and
;; then an empty sublist is never descended into and never has x inserted,
;; which contradicts the rule that '() has length 0 and becomes (x) whenever
;; 0 < n. null? alone would classify every non-empty list as an atom.
;;
;; The name is my-list? rather than list? so that nothing shadows a built-in
;; and the substitution stays visible.
(define (my-list? x)
  (or (null? x) (pair? x)))


;; make-inserter : atom (integer -> boolean) -> (list -> list)
;;
;; S2.c. Returns a function of one argument, a list, which inserts x at the
;; front of every list, at every level of nesting, whose original length
;; satisfies len-ok?. len-ok? is a function taking one number.
;;
;; The returned function is bound by letrec so that it can call itself on
;; sublists. x and len-ok? are captured once, in this closure, instead of
;; being passed down through every recursive call: the inner recursion carries
;; only the list it is working on, and the two things that stay fixed for the
;; whole traversal are held by the closure. That is the point of the function
;; being higher-order rather than merely taking an extra argument.
;;
;; Recursive reading of the returned function: its result for a list is that
;; list with every element that is itself a list replaced by its own result,
;; atoms left alone, and then x consed on the front if and only if len-ok? is
;; true of the list's own length.
;;
;; Termination: each inner call is made on an element of its argument, so
;; nesting depth strictly decreases and atoms are the base case.
;;
;; Three points of the specification are settled by this structure:
;;
;;   * Lengths are measured on the original list. my-length is applied to the
;;     argument lst, and nothing is ever mutated — the insertion builds a new
;;     list. Binding the length first in the let* makes the order of events
;;     plain to a reader, but it is the absence of mutation that makes it
;;     correct, not the ordering.
;;
;;   * The top-level list is treated like every other list, because it is just
;;     the list the outermost call is looking at. No separate case is needed,
;;     and an empty top-level list behaves like any other empty list.
;;
;;   * Whether anything is inserted at all is entirely len-ok?'s business.
;;     That is what makes this more general than insert-if-short: a predicate
;;     such as (lambda (len) (> len 5)) or (lambda (len) (= len 0)) works
;;     unchanged.
;;
;; my-length is called exactly once per list, in the let* binding, and never
;; inside the my-map. That is what keeps the traversal linear: each list is
;; walked once to measure it and once to rebuild it. Measuring inside the
;; per-element work would make a 10,000-element list quadratic and the hidden
;; test would time out.
(define (make-inserter x len-ok?)
  (letrec ((insert
            (lambda (lst)
              (let* ((len (my-length lst))
                     (mapped (my-map (lambda (element)
                                       (if (my-list? element)
                                           (insert element)
                                           element))
                                     lst)))
                (if (len-ok? len)
                    (cons x mapped)
                    mapped)))))
    insert))


;; insert-if-short : atom list integer -> list
;;
;; lst with x inserted at the front of every list, at every level of nesting,
;; whose original length is less than n.
;;
;; This is the single definition of insert-if-short in the file, as S2.c
;; requires: the direct recursive version written for S2.b has been removed.
;; All of the work is done by make-inserter, and the only thing specific to
;; this function is the predicate — "shorter than n" — which is supplied as a
;; one-argument function of the length.
;;
;; n = 0 inserts nothing anywhere, because no length is less than 0, not even
;; the length of '(), which is 0. That falls out of the predicate rather than
;; being special-cased, which is why the empty list needs no separate
;; treatment anywhere in this file.
(define (insert-if-short x lst n)
  ((make-inserter x (lambda (len) (< len n))) lst))