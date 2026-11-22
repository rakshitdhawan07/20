;; S2 test driver. No #lang line: appended to code/20_q4.rkt like the grader.
;; print-insert-result reads x, lst and n from stdin, so each case is piped in
;; by tests/run_tests.sh:
;;   42 ((1 2) (3 4 5) (6) ()) 3  ->  ((42 1 2) (3 4 5) (42 6) (42))
;;   0 (((1) 2) (3) ((4 5 6) ())) 3 -> ((0 (0 1) 2) (0 3) (0 (4 5 6) (0)))
;;   7 () 3                       ->  (7)
;;   7 () 0                       ->  ()
(print-insert-result)
