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
% The file is organised in the order it was built: generation (splits and
% expression trees), then evaluation, then the canonical printed form, then
% the three predicates the assignment names — generate_equation/2,
% all_equations/2 and count_equations/2.
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


% -----------------------------------------------------------------------------
% The canonical printed form
% -----------------------------------------------------------------------------

%! precedence(+Op:atom, -Prec:integer) is semidet.
%
%  Prec is the binding strength of Op: 2 for * and /, 1 for + and -, so that
%  * and / bind tighter, as the specification requires.
%
%  The two levels are all the rule needs. Associativity is not represented
%  here as a separate property: the operators are all left-associative, and
%  that is expressed by the asymmetry between the left and right tests in
%  parens_needed/3 rather than by any data.
precedence(plus,   1).
precedence(minus,  1).
precedence(times,  2).
precedence(divide, 2).

%! op_symbol(+Op:atom, -Symbol:atom) is semidet.
%
%  Symbol is the character Op is written with. The atoms are quoted: '+', '-',
%  '*' and '/' are all operator atoms in Prolog and must not be written bare
%  in an argument position.
op_symbol(plus,   '+').
op_symbol(minus,  '-').
op_symbol(times,  '*').
op_symbol(divide, '/').

%! parens_needed(+Side:atom, +ParentPrec:integer, +Operand) is semidet.
%
%  True when Operand, appearing on Side of an operator of precedence
%  ParentPrec, must be written in parentheses. Side is left or right.
%
%  This is the specification's rule, stated directly:
%
%    * a left operand is parenthesised only if its top operator has strictly
%      lower precedence than its parent's;
%    * a right operand is parenthesised if its top operator has the same or
%      lower precedence than its parent's.
%
%  The asymmetry is what encodes left-associativity. 1-2-3 is the tree
%  expr(minus, expr(minus,1,2), 3): the left operand has equal precedence, so
%  strictly-lower is false and no parentheses appear, which is right, because
%  reading 1-2-3 back gives that same tree. 1-(2-3) is the mirror tree, where
%  the right operand has equal precedence, same-or-lower is true, and the
%  parentheses are needed to stop it reading as the first tree.
%
%  "A single number is never in parentheses" needs no clause and no test: both
%  clauses require an expr/3 operand, so a num/1 operand matches neither and
%  parens_needed/3 simply fails for it.
parens_needed(left, ParentPrec, expr(Op, _, _)) :-
    precedence(Op, Prec),
    Prec < ParentPrec.
parens_needed(right, ParentPrec, expr(Op, _, _)) :-
    precedence(Op, Prec),
    Prec =< ParentPrec.

%! operand_string(+Side:atom, +ParentPrec:integer, +Operand, -String:string)
%!     is det.
%
%  String is Operand written out, in parentheses if and only if its position
%  requires them.
operand_string(Side, ParentPrec, Operand, String) :-
    expr_string(Operand, Inner),
    (   parens_needed(Side, ParentPrec, Operand)
    ->  format(string(String), "(~w)", [Inner])
    ;   String = Inner
    ).

%! expr_string(+Expr, -String:string) is det.
%
%  String is the canonical written form of Expr: an SWI-Prolog string, with no
%  spaces, numbers in decimal, and parentheses exactly where the rule above
%  puts them.
%
%  Read declaratively: "String is how Expr is written."
%
%  Recursive reading, and the termination argument: a leaf is written as its
%  number. A node is written as its left operand, then its operator symbol,
%  then its right operand, each operand written by the same rule and
%  parenthesised according to its side and the node's precedence. Each call
%  descends into a strictly smaller sub-tree, so it terminates.
%
%  The result is a string and not an atom. number_string/2 and format/3 with
%  a string(String) sink both produce strings, and nothing here goes near
%  atom_concat/3 or atomic_list_concat/3, which would produce an atom and fail
%  the specification's requirement that an equation be a string.
%
%  This rule is injective: the specification notes that it gives every
%  different expression tree a different string. That is what allows
%  all_equations/2 to deduplicate with sort/2 over strings without any risk of
%  collapsing two genuinely different trees into one answer. It is also why
%  1+(2+3) and 1+2+3 both appear among the answers for a list that admits
%  them: they are different trees, so they are different equations.
%
%  det for any well-formed Expr: the two clauses are indexed on num/1 against
%  expr/3, and the if-then-else in operand_string/4 commits.
expr_string(num(N), String) :-
    number_string(N, String).
expr_string(expr(Op, Left, Right), String) :-
    precedence(Op, ParentPrec),
    op_symbol(Op, Symbol),
    operand_string(left,  ParentPrec, Left,  LeftString),
    operand_string(right, ParentPrec, Right, RightString),
    format(string(String), "~w~w~w", [LeftString, Symbol, RightString]).

%! equation_string(+Left, +Right, -Equation:string) is det.
%
%  Equation is the canonical form of the equation whose sides are the
%  expressions Left and Right: the two sides written out and joined by a
%  single = sign, with no spaces anywhere.
%
%  The = sign itself needs no precedence handling. It is not an operator of
%  the expression language, there is exactly one of it, and it sits between
%  two complete expressions, so neither side is ever parenthesised on its
%  account.
equation_string(Left, Right, Equation) :-
    expr_string(Left, LeftString),
    expr_string(Right, RightString),
    format(string(Equation), "~w=~w", [LeftString, RightString]).


% -----------------------------------------------------------------------------
% P2.a and P2.b — the equation predicates
% -----------------------------------------------------------------------------

%! valid_equation(+Numbers:list, -Equation:string) is nondet.
%
%  Equation is the canonical form of a valid equation over Numbers: the
%  numbers divide into two expressions, one on each side of the = sign, both
%  sides have a value, and the two values are the same.
%
%  Read declaratively: "Numbers can be read as this equation, and it is true."
%
%  Both sides are evaluated into the same variable Value, so the requirement
%  that they be equal is discharged by unification rather than by a separate
%  comparison: eval_expr/2 called with its second argument already bound acts
%  as a test rather than a computation, and the right-hand side simply fails
%  unless its value matches. Writing eval_expr(Right, V2), Value =:= V2 would
%  be equivalent here, since every value these expressions can take is an
%  integer.
%
%  An expression with no value — one containing a division by zero or an
%  inexact division anywhere inside it — fails at eval_expr/2 and is passed
%  over, so no such candidate ever reaches the printer.
%
%  This is the predicate the three exported ones are built from. It is kept
%  separate so that all_equations/2 can enumerate it and generate_equation/2
%  can commit to its first answer, without either repeating the other's logic.
valid_equation(Numbers, Equation) :-
    equation_sides(Numbers, Left, Right),
    eval_expr(Left, Value),
    eval_expr(Right, Value),
    equation_string(Left, Right, Equation).

%! generate_equation(+List:list, -Equation:string) is semidet.
%
%  Equation is one valid equation over List, as an SWI-Prolog string. Any
%  valid equation is an acceptable answer; this gives the first one the
%  generator reaches.
%
%  Read declaratively: "List can be read as the equation Equation."
%
%  Fails, rather than looping or raising, when no valid equation exists. Three
%  distinct cases all end in plain failure:
%
%    * the empty list and single-element lists, because split/3 has no
%      position at which to place the = sign;
%    * lists like [2,3,4] where every division is well defined but no
%      arrangement balances;
%    * lists where candidates exist but each one contains a division by zero
%      or an inexact division.
%
%  Termination is inherited rather than argued afresh: expr_tree/2 recurses on
%  strictly shorter lists, so the candidate space is finite, and every
%  predicate below this one is semidet or det.
%
%  once/1 makes this semidet, which matches "one valid equation". It wraps the
%  whole goal including the unification of Equation, so the predicate behaves
%  correctly whichever way it is called: with Equation unbound it commits to
%  the first valid equation found, and with Equation bound it searches for
%  that equation among the valid ones and succeeds at most once.
generate_equation(List, Equation) :-
    once(valid_equation(List, Equation)).

%! all_equations(+List:list, -Equations:list) is det.
%
%  Equations is the list of every valid equation over List, without
%  duplicates, in the standard order of terms. Equations = [] when there is
%  none, which includes lists of length 0 and 1.
%
%  Read declaratively: "Equations is everything List can be read as."
%
%  sort/2 is the specification's own choice and does both jobs at once: it
%  orders by the standard order of terms and removes duplicates. msort/2 would
%  order without deduplicating and would be wrong here if duplicates were
%  possible.
%
%  In fact no duplicates are generated. expr_tree/2 yields each tree exactly
%  once, the canonical form is injective, and the position of the = sign is
%  recoverable from the printed string, so distinct candidates always print
%  differently. sort/2 is therefore doing the ordering the specification asks
%  for, not covering for a generator that repeats itself — which is worth
%  checking rather than assuming, by comparing the length of the findall/3
%  result against the length of the sorted one.
%
%  det: findall/3 always succeeds, with [] when its goal has no solutions, and
%  sort/2 is det.
all_equations(List, Equations) :-
    findall(Equation, valid_equation(List, Equation), Unsorted),
    sort(Unsorted, Equations).

%! count_equations(+List:list, -N:integer) is det.
%
%  N is how many distinct valid equations List admits: the length of the list
%  all_equations/2 gives.
%
%  Read declaratively: "List can be read as N different true equations."
%
%  Defined through all_equations/2 rather than by counting solutions of
%  valid_equation/2 directly, because the two would disagree if the generator
%  ever produced the same equation twice: the specification defines N as the
%  length of the deduplicated list, so that is what is measured.
count_equations(List, N) :-
    all_equations(List, Equations),
    length(Equations, N).