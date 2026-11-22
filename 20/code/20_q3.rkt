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
;; The file is organised in the order it was built: the inorder traversal and
;; S1.a, then the other two traversals and S1.b, then the height and leaf
;; count and S1.c.
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


;; preorder-onto : tree list -> list
;;
;; The preorder values of tree, followed by acc. Preorder visits the node,
;; then the left subtree, then the right subtree.
;;
;; Recursive reading: the preorder listing of the empty tree onto acc is acc.
;; The preorder listing of a node onto acc is the node's value consed onto the
;; preorder listing of its left subtree, which is itself placed onto the
;; preorder listing of its right subtree onto acc.
;;
;; The two subtrees are threaded right before left through the accumulator,
;; which is what puts them left before right in the finished list: the list is
;; built from its right-hand end, so the subtree whose values come last is
;; accumulated first. Visiting order and threading order are opposites here,
;; and getting that backwards is the easiest way to silently produce a
;; mirrored traversal.
;;
;; Termination: each call descends into a proper subtree, with the empty tree
;; as base case.
(define (preorder-onto tree acc)
  (if (null? tree)
      acc
      (cons (car tree)
            (preorder-onto (cadr tree)
                           (preorder-onto (caddr tree) acc)))))


;; postorder-onto : tree list -> list
;;
;; The postorder values of tree, followed by acc. Postorder visits the left
;; subtree, then the right subtree, then the node.
;;
;; Recursive reading: the postorder listing of the empty tree onto acc is acc.
;; The postorder listing of a node onto acc is the postorder listing of its
;; left subtree, placed onto the postorder listing of its right subtree,
;; placed onto the node's value consed onto acc. The node's value is consed
;; first because it comes last in the output and the list is built backwards.
;;
;; Termination: as above. The descent into the left subtree is a tail call.
(define (postorder-onto tree acc)
  (if (null? tree)
      acc
      (postorder-onto (cadr tree)
                      (postorder-onto (caddr tree)
                                      (cons (car tree) acc)))))


;; print-all-traversals : tree -> prints three lines
;;
;; S1.b. Prints the inorder list, then the preorder list, then the postorder
;; list, one per line, each with display and each ending in a newline.
;;
;; The order of the three lines is the order the problem statement gives, and
;; it is not the order the three traversals are usually listed in; inorder
;; comes first. For the empty tree all three lines are ().
(define (print-all-traversals tree)
  (display (inorder-onto tree '()))
  (newline)
  (display (preorder-onto tree '()))
  (newline)
  (display (postorder-onto tree '()))
  (newline))


;; tree-height : tree -> integer
;;
;; The height of tree: 0 for the empty tree, and otherwise 1 more than the
;; larger of its two subtrees' heights.
;;
;; Recursive reading exactly as the convention states it, which is worth being
;; literal about: the base case is the empty tree at 0, not a leaf at 0. A
;; single node therefore has height 1, because its two empty subtrees are 0
;; and it adds one. Taking a leaf as the base case would count edges instead
;; of levels and make every height one too small.
;;
;; Termination: each call descends into a proper subtree.
(define (tree-height tree)
  (if (null? tree)
      0
      (+ 1 (max (tree-height (cadr tree))
                (tree-height (caddr tree))))))


;; leaf-count : tree -> integer
;;
;; The number of leaves of tree, a leaf being a node whose left and right
;; subtrees are both empty.
;;
;; Recursive reading: the empty tree has no leaves. A node with two empty
;; subtrees is itself one leaf. Any other node has as many leaves as its two
;; subtrees have between them.
;;
;; The three cases must be tried in this order, and the middle one requires
;; both subtrees to be empty. A node with exactly one empty subtree is not a
;; leaf, and it is handled by the third case, where the empty side contributes
;; 0 and the other side is counted. The empty tree contributing 0 rather than
;; 1 is the reason the first case cannot be merged into the second.
;;
;; Termination: each call descends into a proper subtree.
(define (leaf-count tree)
  (cond ((null? tree) 0)
        ((and (null? (cadr tree)) (null? (caddr tree))) 1)
        (else (+ (leaf-count (cadr tree))
                 (leaf-count (caddr tree))))))


;; print-height-and-leaves : tree -> prints one line
;;
;; S1.c. Prints the two-element list (height leaf-count) on one line with
;; display, ending in a newline.
;;
;; list is used to build the pair so that a single display renders it in the
;; required form, (3 4); the empty tree gives (0 0).
(define (print-height-and-leaves tree)
  (display (list (tree-height tree) (leaf-count tree)))
  (newline))