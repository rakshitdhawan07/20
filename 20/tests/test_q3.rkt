;; S1 test driver. No #lang line: this file is appended to code/20_q3.rkt,
;; exactly the way the grader appends its own calls.
;; Run via: bash tests/run_tests.sh q3
(define t1 '(4 (2 (1 () ()) (3 () ())) (6 (5 () ()) (7 () ()))))
(define t2 '(1 () (2 () (3 () ()))))
(define t3 '(a (b () ()) (c () ())))

(print-inorder t1)             ;; (1 2 3 4 5 6 7)
(print-all-traversals t1)      ;; (1 2 3 4 5 6 7) (4 2 1 3 6 5 7) (1 3 2 5 7 6 4)
(print-height-and-leaves t1)   ;; (3 4)
(print-all-traversals t2)      ;; (1 2 3) (1 2 3) (3 2 1)
(print-height-and-leaves t2)   ;; (3 1)
(print-all-traversals t3)      ;; (b a c) (a b c) (b c a)
(print-height-and-leaves t3)   ;; (2 2)
(print-inorder '())            ;; ()
(print-all-traversals '())     ;; () () ()
(print-height-and-leaves '())  ;; (0 0)
