#lang racket/base

;; ============================================================================
;; CS F301 Assignment 2 — S1: Binary Tree Traversals
;; Group 20 — file 20_q3.rkt
;;
;; Representation
;; --------------
;; A binary tree is either the empty list '(), or a three-element list
;;
;;     (value left right)
;;
;; where left and right are themselves binary trees. A value is a number or a
;; single-character symbol, so nothing here may assume values are numbers: no
;; arithmetic and no ordering is ever applied to a value.
;;
;; The three parts of a non-empty tree are reached with
;;
;;     (car tree)     the value
;;     (cadr tree)    the left subtree
;;     (caddr tree)   the right subtree
;;
;; Conventions this file implements, from the problem statement:
;;
;;   * the height of '() is 0, and the height of a node is 1 plus the larger
;;     of its subtrees' heights, so a single node has height 1;
;;   * a leaf is a node whose left and right subtrees are both '(), and the
;;     empty tree has no leaves;
;;   * subtrees are always visited left first, then right.
;;
;; Allowed built-ins only, per the assignment's whitelist. In particular there
;; is no append, no length, no reverse, no map and no set!; lists are built by
;; threading an accumulator through the recursion, which is both the only way
;; available and the only way that stays linear.
;;
;; Definitions only. Running this file prints nothing; the grader appends its
;; own calls to the end.
;;
;; This unit of work covers S1.a. The preorder and postorder traversals, and
;; the height and leaf count, follow in later units.
;; ============================================================================


;; inorder-onto : tree list -> list
;;
;; The inorder values of tree, followed by acc. Inorder visits the left
;; subtree, then the node, then the right subtree.
;;
;; Recursive reading: the inorder listing of the empty tree, placed onto acc,
;; is acc itself. The inorder listing of a node, placed onto acc, is the
;; inorder listing of its left subtree placed onto the node's value consed
;; onto the inorder listing of its right subtree placed onto acc.
;;
;; The accumulator is what replaces append. The list is assembled from the
;; right-hand end backwards, so every value is consed exactly once and the
;; whole traversal is linear in the number of nodes. Building the same list
;; with append would be both forbidden and quadratic.
;;
;; Termination: each call descends into a proper subtree of its argument, and
;; the empty tree is the base case, so the recursion is bounded by the height
;; of the tree. The descent into the left subtree is a tail call; the descent
;; into the right subtree cannot be, because its result is needed as the tail
;; of the cons. That is the natural shape for this traversal, and no
;; rearrangement makes both calls tail calls without a reversal step, which
;; would need reverse.
(define (inorder-onto tree acc)
  (if (null? tree)
      acc
      (inorder-onto (cadr tree)
                    (cons (car tree)
                          (inorder-onto (caddr tree) acc)))))


;; print-inorder : tree -> prints one line
;;
;; S1.a. Prints the list of the values of tree in inorder, on one line, with
;; display, ending in a newline.
;;
;; The whole list is assembled first and handed to a single display, which is
;; what produces the parenthesised, space-separated form the examples show:
;; (1 2 3 4 5 6 7). The empty tree gives the empty list, which display writes
;; as (), matching the required output for '().
(define (print-inorder tree)
  (display (inorder-onto tree '()))
  (newline))
