% =============================================================================
% tests/test_q2.pl — P2, Form a Valid Arithmetic Equation
% Group 20
%
% Run from the 20/ directory:
%     swipl -q -f tests/test_q2.pl -g run_tests -t halt
%
% The constraints on the solution files apply to code/20_q2.pl, not to this
% file, so plunit and output are used freely here.
%
% The expected counts were computed independently, outside Prolog, by
% enumerating every expression tree over the given lists; they are not read
% off the implementation under test.
% =============================================================================

:- use_module(library(plunit)).
:- consult('../code/20_q2.pl').

:- begin_tests(q2).

% --- split/3 -----------------------------------------------------------------

test(split_of_four_numbers_has_three_divisions) :-
    aggregate_all(count, split([4,2,5,3],_,_), N),
    assertion(N =:= 3).

test(split_preserves_order_and_covers_the_list) :-
    forall( split([4,2,5,3], Front, Back),
            ( append(Front, Back, [4,2,5,3]),
              Front = [_|_],
              Back  = [_|_] ) ).

test(split_fails_on_a_single_element, [fail]) :-
    split([7], _, _).

test(split_fails_on_the_empty_list, [fail]) :-
    split([], _, _).

% --- expr_tree/2 -------------------------------------------------------------

% Catalan-many shapes times four operator choices per internal node.
expected_trees(1, 1).
expected_trees(2, 4).
expected_trees(3, 32).
expected_trees(4, 320).
expected_trees(5, 3584).

test(expression_counts_match_independent_enumeration) :-
    forall( expected_trees(M, Want),
            ( numlist(1, M, List),
              aggregate_all(count, expr_tree(List,_), Got),
              ( Got =:= Want -> true
              ; format(user_error, '~w numbers: got ~w, want ~w~n',
                       [M, Got, Want]),
                fail )
            ) ).

test(expr_tree_yields_no_duplicates) :-
    findall(E, expr_tree([4,2,5,3],E), All),
    sort(All, Distinct),
    length(All, A),
    length(Distinct, B),
    assertion(A =:= B).

test(expr_tree_fails_on_the_empty_list, [fail]) :-
    expr_tree([], _).

test(expr_tree_of_one_number_is_that_number) :-
    findall(E, expr_tree([7],E), Es),
    assertion(Es == [num(7)]).

test(equation_sides_of_four_numbers_has_80_candidates) :-
    aggregate_all(count, equation_sides([4,2,5,3],_,_), N),
    assertion(N =:= 80).

test(equation_sides_fails_on_one_number, [fail]) :-
    equation_sides([7], _, _).

% --- apply_op/4, the division rules -----------------------------------------

test(exact_division_positive) :-
    apply_op(divide, 6, 3, V), assertion(V =:= 2).

test(exact_division_negative_dividend) :-
    apply_op(divide, -6, 3, V), assertion(V =:= -2).

test(exact_division_negative_divisor) :-
    apply_op(divide, 6, -3, V), assertion(V =:= -2).

test(exact_division_both_negative) :-
    apply_op(divide, -6, -3, V), assertion(V =:= 2).

test(zero_dividend_divides_exactly) :-
    apply_op(divide, 0, 5, V), assertion(V =:= 0).

test(inexact_division_fails, [fail]) :-
    apply_op(divide, 7, 2, _).

test(inexact_negative_division_fails, [fail]) :-
    apply_op(divide, -7, 2, _).

test(inexact_division_with_negative_dividend_fails, [fail]) :-
    apply_op(divide, -6, 4, _).

% Must FAIL, not raise: A mod 0 is an evaluation error, so the guard on the
% divisor has to come before the exactness test.
test(division_by_zero_fails_without_raising) :-
    catch( ( apply_op(divide, 5, 0, _) -> Result = succeeded ; Result = failed ),
           Error,
           Result = error(Error) ),
    assertion(Result == failed).

test(division_results_are_integers) :-
    apply_op(divide, 6, 3, V),
    assertion(integer(V)).

% --- eval_expr/2 -------------------------------------------------------------

test(leaf_evaluates_to_its_number) :-
    eval_expr(num(42), V), assertion(V =:= 42).

test(subexpressions_may_be_negative) :-
    eval_expr(expr(minus,num(3),num(5)), V), assertion(V =:= -2).

% The division rules apply to every division, not only the outermost one.
test(inner_division_by_zero_fails, [fail]) :-
    eval_expr(expr(divide, num(4), expr(minus,num(2),num(2))), _).

test(inner_inexact_division_fails, [fail]) :-
    eval_expr(expr(times, expr(divide,num(7),num(2)), num(2)), _).

test(evaluable_tree_count_matches_independent_enumeration) :-
    aggregate_all(count, ( expr_tree([4,2,5,3],E), eval_expr(E,_) ), N),
    assertion(N =:= 176).

% --- the canonical printed form ---------------------------------------------

% The eight examples the problem statement gives for the parenthesisation rule.
printed(expr(times, expr(plus,num(4),num(2)), num(3)),   "(4+2)*3").
printed(expr(plus,  num(4), expr(times,num(2),num(3))),  "4+2*3").
printed(expr(times, expr(divide,num(8),num(4)), num(2)), "8/4*2").
printed(expr(divide, num(8), expr(times,num(4),num(2))), "8/(4*2)").
printed(expr(minus, expr(minus,num(1),num(2)), num(3)),  "1-2-3").
printed(expr(minus, num(1), expr(minus,num(2),num(3))),  "1-(2-3)").
printed(expr(plus,  num(1), expr(plus,num(2),num(3))),   "1+(2+3)").
printed(expr(plus,  expr(plus,num(1),num(2)), num(3)),   "1+2+3").

test(parenthesisation_matches_every_worked_example) :-
    forall( printed(Expr, Want),
            ( expr_string(Expr, Got),
              ( Got == Want -> true
              ; format(user_error, 'got ~q, want ~q~n', [Got, Want]), fail )
            ) ).

test(printed_form_is_a_string_not_an_atom) :-
    expr_string(expr(plus,num(1),num(2)), S),
    assertion(string(S)),
    assertion(\+ atom(S)).

test(a_single_number_is_never_parenthesised) :-
    expr_string(num(7), S),
    assertion(S == "7").

% Different trees must print differently: all_equations/2 deduplicates on the
% printed form, so a collision would lose a valid answer.
test(printed_form_is_injective_over_four_numbers) :-
    findall(S, ( expr_tree([1,2,3,4],E), expr_string(E,S) ), Strings),
    sort(Strings, Distinct),
    length(Strings, A),
    length(Distinct, B),
    assertion(A =:= B).

test(equation_string_joins_with_one_equals_and_no_spaces) :-
    equation_string(expr(times,num(4),num(2)), expr(plus,num(5),num(3)), Eq),
    assertion(Eq == "4*2=5+3").

% --- P2.b, all_equations/2 and count_equations/2 -----------------------------

test(all_equations_of_the_worked_example) :-
    all_equations([4,2,5,3], Es),
    assertion(Es == ["4*2-5=3","4*2=5+3","4-2=5-3","4/2=5-3",
                     "4=2*(5-3)","4=2+(5-3)","4=2+5-3"]).

test(all_equations_is_empty_when_none_balance) :-
    all_equations([2,3,4], Es),
    assertion(Es == []).

test(all_equations_of_a_single_answer) :-
    all_equations([2,4,8], Es),
    assertion(Es == ["2*4=8"]).

test(all_equations_is_empty_for_short_lists) :-
    all_equations([], A),  assertion(A == []),
    all_equations([7], B), assertion(B == []).

test(all_equations_is_sorted_and_duplicate_free) :-
    all_equations([4,2,5,3], Es),
    sort(Es, Sorted),
    assertion(Es == Sorted).

test(no_duplicates_are_generated_in_the_first_place) :-
    findall(Eq, valid_equation([4,2,5,3],Eq), Raw),
    sort(Raw, Sorted),
    length(Raw, A),
    length(Sorted, B),
    assertion(A =:= B).

test(count_equations_is_the_length_of_all_equations) :-
    count_equations([4,2,5,3], N),
    all_equations([4,2,5,3], Es),
    length(Es, Len),
    assertion(N =:= 7),
    assertion(N =:= Len).

test(count_equations_is_zero_when_none_exist) :-
    count_equations([2,3,4], N),
    assertion(N =:= 0).

% --- P2.a, generate_equation/2 ----------------------------------------------

test(generate_equation_gives_one_of_the_valid_answers) :-
    generate_equation([4,2,5,3], E),
    all_equations([4,2,5,3], Es),
    assertion(memberchk(E, Es)).

test(generate_equation_result_is_a_string) :-
    generate_equation([4,2,5,3], E),
    assertion(string(E)).

test(generate_equation_succeeds_at_most_once) :-
    aggregate_all(count, generate_equation([4,2,5,3],_), N),
    assertion(N =:= 1).

test(generate_equation_accepts_a_bound_equation) :-
    generate_equation([4,2,5,3], "4=2+5-3").

test(generate_equation_rejects_an_invalid_bound_equation, [fail]) :-
    generate_equation([4,2,5,3], "4+2=5+3").

test(generate_equation_fails_on_the_empty_list, [fail]) :-
    generate_equation([], _).

test(generate_equation_fails_on_one_number, [fail]) :-
    generate_equation([7], _).

test(generate_equation_fails_when_nothing_balances, [fail]) :-
    generate_equation([2,3,4], _).

% Failure, not an exception, in every degenerate case.
test(degenerate_inputs_fail_without_raising) :-
    forall( member(List, [[], [7], [2,3,4]]),
            ( catch( ( generate_equation(List,_)
                     -> Result = succeeded
                     ;  Result = failed ),
                     Error,
                     Result = error(Error) ),
              ( Result == failed -> true
              ; format(user_error, '~w gave ~w~n', [List, Result]), fail )
            ) ).

:- end_tests(q2).
