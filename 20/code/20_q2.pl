% =============================================================================
% CS F301 Assignment 2 — P2: Form a Valid Arithmetic Equation
% Group 20 — file 20_q2.pl
%
% Representation of expressions
% -----------------------------
% An expression is a term built from
%
%     num(Integer)              a single number, a leaf
%     expr(Op, Left, Right)     two expressions joined by one operator
%
% where Op is one of the atoms
%
%     plus  minus  times  divide
%
% Named atoms are used for the operators rather than +, -, * and /. The
% arithmetic symbols are operator atoms in Prolog, so writing them bare in an
% argument position invites parse ambiguity and writing them quoted invites
% confusion with evaluable terms. Named atoms cannot be mistaken for something
% Prolog might evaluate on its own, which matters here because P2 forbids
% building a term or a string and handing it back to the system to evaluate.
% Everything about these trees — their value and their printed form — is
% computed by explicit recursion over this representation.
%
% Two properties of the problem statement hold structurally, by construction,
% and so need no checking anywhere else in the file:
%
%   * There is no unary minus. Every expr/3 node has exactly two operands, and
%     the only other kind of expression is a number, so no operator can ever
%     be applied to a single operand. Sub-expressions may still evaluate to
%     negative numbers, as 3-5 does.
%
%   * Digits of different numbers are never joined. Each number of the input
%     list becomes exactly one num/1 leaf, and nothing in the generator
%     concatenates or re-reads them.
%
% Definitions only — no initialization directive, no halt/0, nothing printed
% at load time, nothing asserted or retracted.
%
% This unit of work covers generation: the splits and the expression trees.
% Evaluation, the canonical printed form, and the equation predicates follow
% in later units.
% =============================================================================


% -----------------------------------------------------------------------------
% Operators
% -----------------------------------------------------------------------------

%! operator(-Op:atom) is multi.
%
%  Op is one of the four permitted binary operators.
%
%  Read declaratively: "Op is an operator that may join two expressions."
%  Enumerates all four on backtracking, in this order, and each exactly once.
operator(plus).
operator(minus).
operator(times).
operator(divide).


% -----------------------------------------------------------------------------
% Splitting a list of numbers
% -----------------------------------------------------------------------------

%! split(+List:list, -Front:list, -Back:list) is nondet.
%
%  Front and Back are both non-empty, Front followed by Back is List, and the
%  original order is preserved.
%
%  Read declaratively: "List divides into a non-empty Front and a non-empty
%  Back at some position." For a list of k elements there are exactly k-1 such
%  divisions, and split/3 yields each one exactly once, so no caller can
%  receive the same division twice.
%
%  split/3 serves both of the problem's two kinds of division: the one that
%  separates the left-hand side of the equation from the right-hand side, and
%  the one that separates the two operands of a single operator inside an
%  expression. They are the same operation on the same invariant — every
%  number used once, in the given order.
%
%  It fails for a list of fewer than two elements, which is where the required
%  failure of generate_equation/2 on lists of length 0 and 1 ultimately comes
%  from: there is no position at which to put the = sign.
%
%  append/3 with a bound third argument enumerates the k+1 ways to cut List,
%  including the two that put everything on one side; the two tests discard
%  exactly those.
split(List, Front, Back) :-
    append(Front, Back, List),
    Front = [_|_],
    Back = [_|_].


% -----------------------------------------------------------------------------
% Expression trees
% -----------------------------------------------------------------------------

%! expr_tree(+Numbers:list, -Expr) is nondet.
%
%  Expr is an expression over exactly the numbers in Numbers, each used once,
%  in the order given.
%
%  Read declaratively: "Expr is a way of combining this run of numbers, in
%  order, into one expression."
%
%  Recursive reading, and the termination argument: a single number is an
%  expression in exactly one way, itself. A run of two or more numbers is an
%  expression whenever it divides into a non-empty front and a non-empty back,
%  each of which is itself an expression, joined by one of the four operators.
%  split/3 guarantees both parts are non-empty, so each part is strictly
%  shorter than Numbers, and the recursion descends on a measure that cannot
%  fall below one. expr_tree/2 therefore terminates on every proper list, and
%  fails outright on the empty list: the first clause does not match it and
%  split/3 has no division to offer.
%
%  Each distinct tree is produced exactly once. split/3 yields each division
%  once, operator/1 yields each operator once, and the two recursive calls are
%  independent, so no combination of shape and operators can be reached by two
%  different derivations. This is what lets all_equations/2 in a later unit
%  rely on sort/2 for ordering rather than for hiding duplicates it should
%  never have generated.
%
%  For reference, the number of expressions over m numbers is 1, 4, 32, 320,
%  3584 for m = 1 to 5: Catalan many tree shapes, times four operator choices
%  per internal node.
expr_tree([N], num(N)).
expr_tree(Numbers, expr(Op, Left, Right)) :-
    split(Numbers, LeftNums, RightNums),
    operator(Op),
    expr_tree(LeftNums, Left),
    expr_tree(RightNums, Right).

%! equation_sides(+Numbers:list, -Left, -Right) is nondet.
%
%  Left is an expression over a non-empty prefix of Numbers and Right is an
%  expression over the remaining, non-empty suffix. Together they use every
%  number exactly once, in order, which is precisely the shape of a candidate
%  equation L=R before anything is known about its value.
%
%  Read declaratively: "Numbers can be read as these two expressions, one on
%  each side of the equals sign."
%
%  Nondet, and fails for lists shorter than two elements because split/3 does.
%  For a list of four numbers it has 80 solutions; for [4,2,5,3] those 80 are
%  the candidates from which the seven valid equations are later selected.
equation_sides(Numbers, Left, Right) :-
    split(Numbers, LeftNums, RightNums),
    expr_tree(LeftNums, Left),
    expr_tree(RightNums, Right).


% -----------------------------------------------------------------------------
% Evaluation
% -----------------------------------------------------------------------------

%! apply_op(+Op:atom, +A:integer, +B:integer, -Value:integer) is semidet.
%
%  Value is the result of applying Op to A and B, or apply_op/4 fails if the
%  operation is not permitted. Only division can fail: it is allowed solely
%  when the divisor is non-zero and the division leaves no remainder.
%
%  Read declaratively: "applying Op to A and B is defined, and gives Value."
%
%  semidet by first-argument indexing: the four clauses have distinct atoms in
%  the first argument, so a call with Op bound tries one clause and leaves no
%  choice point. That is not cosmetic — a choice point here would survive into
%  findall/3 in all_equations/2 and produce the same equation twice.
%
%  The division clause is ordered deliberately and no part of it is
%  rearrangeable:
%
%    1. B =\= 0 comes first. A mod B with B = 0 raises an evaluation error,
%       and the specification calls for failure, not an exception.
%    2. 0 =:= A mod B tests exactness. In SWI-Prolog mod/2 takes the sign of
%       its divisor, and A mod B is zero exactly when B divides A, so this is
%       correct for negative operands too: 6 mod -3 and -6 mod 3 are both 0,
%       while -6 mod 4 is 2 and the clause fails as it should.
%    3. Only then is the quotient taken, with //, integer division. The / of
%       arithmetic is never used anywhere in this file. On integers it may
%       yield a float or a rational depending on the prefer_rationals flag,
%       and a float silently poisons every later comparison because 2.0 =:= 2
%       holds while 2.0 == 2 does not. // is flag-independent. It truncates
%       toward zero, which is immaterial here: the exactness test has already
%       established there is nothing to round.
%
%  An equivalent exactness test is to compute Value is A // B and then check
%  Value * B =:= A, which relies on no property of mod/2 at all. Either is
%  defensible; this one states the intent directly.
apply_op(plus,   A, B, Value) :- Value is A + B.
apply_op(minus,  A, B, Value) :- Value is A - B.
apply_op(times,  A, B, Value) :- Value is A * B.
apply_op(divide, A, B, Value) :-
    B =\= 0,
    0 =:= A mod B,
    Value is A // B.

%! eval_expr(+Expr, -Value:integer) is semidet.
%
%  Value is the integer value of Expr, or eval_expr/2 fails if any division
%  anywhere inside Expr is by zero or inexact.
%
%  Read declaratively: "Expr has a value, and it is Value."
%
%  Recursive reading, and the termination argument: a leaf num(N) has the
%  value N. A node expr(Op, Left, Right) has a value when both operands have
%  values and applying Op to them is defined. Each call descends into a
%  strictly smaller sub-tree, and leaves are the base case, so it terminates
%  on every finite expression.
%
%  The specification's requirement that the division rules apply to every
%  division inside an expression and not only the last one needs no separate
%  check: an inexact or zero-divisor division makes apply_op/4 fail at the
%  node where it occurs, that failure propagates up through the conjunction,
%  and the whole expression simply has no value. There is nothing to catch and
%  nothing to repair.
%
%  Values of sub-expressions may be negative, as in 3-5, and are handled like
%  any other integer; Prolog's unbounded integers mean no intermediate result
%  can overflow.
%
%  semidet by first-argument indexing on num/1 versus expr/3.
%
%  For reference: of the 320 expressions over [4,2,5,3], 176 have a value and
%  144 are rejected by the division rules.
eval_expr(num(N), N).
eval_expr(expr(Op, Left, Right), Value) :-
    eval_expr(Left, A),
    eval_expr(Right, B),
    apply_op(Op, A, B, Value).