% =============================================================================
% tests/test_q1.pl — P1, Department Assignment Puzzle
% Group 20
%
% Run from the 20/ directory:
%     swipl -q -f tests/test_q1.pl -g run_tests -t halt
%
% The constraints on the solution files (definitions only, no initialization
% directive, restricted libraries) apply to code/20_q1.pl, not to this file,
% so plunit and output are used freely here.
%
% The expected counts were computed independently, by brute-force enumeration
% of all 4! x 4! x 4! = 13824 assignments outside Prolog, and are not read off
% the implementation under test.
% =============================================================================

:- use_module(library(plunit)).
:- consult('../code/20_q1.pl').

:- begin_tests(q1).

% The three solutions of clues 1 to 8, in the order candidate/1 reaches them.
solution(a, [p('Alex',   design,      java,       'AI'),
             p('Ben',    development, javascript, web),
             p('Carla',  research,    'c++',      data),
             p('Dana',   testing,     python,     embedded)]).
solution(b, [p('Alex',   design,      java,       embedded),
             p('Ben',    development, javascript, web),
             p('Carla',  testing,     python,     'AI'),
             p('Dana',   research,    'c++',      data)]).
solution(c, [p('Alex',   testing,     python,     embedded),
             p('Ben',    development, javascript, web),
             p('Carla',  design,      java,       'AI'),
             p('Dana',   research,    'c++',      data)]).

% --- clue/2 ------------------------------------------------------------------

test(all_eight_clues_hold_of_each_solution) :-
    forall( ( solution(Which, S), member(N, [1,2,3,4,5,6,7,8]) ),
            ( clue(N, S)
            -> true
            ;  format(user_error, 'clue ~w failed of solution ~w~n', [N, Which]),
               fail
            ) ).

test(clue_3_false_when_tester_does_not_like_python, [fail]) :-
    clue(3, [p('Alex',  testing,     java,       'AI'),
             p('Ben',   research,    python,     web),
             p('Carla', design,      'c++',      embedded),
             p('Dana',  development, javascript, data)]).

test(clue_1_false_when_dana_prefers_ai, [fail]) :-
    clue(1, [p('Alex',  testing,     python,     web),
             p('Ben',   research,    java,       data),
             p('Carla', design,      'c++',      embedded),
             p('Dana',  development, javascript, 'AI')]).

test(clue_1_false_when_ai_friend_is_in_research, [fail]) :-
    clue(1, [p('Alex',  research,    python,     'AI'),
             p('Ben',   testing,     java,       web),
             p('Carla', design,      'c++',      embedded),
             p('Dana',  development, javascript, data)]).

test(clue_4_false_when_ben_does_not_prefer_web, [fail]) :-
    clue(4, [p('Alex',  testing,     python,     web),
             p('Ben',   research,    java,       'AI'),
             p('Carla', design,      'c++',      embedded),
             p('Dana',  development, javascript, data)]).

% Every clue must be semidet: a clue that can succeed twice for one assignment
% would make count_solutions/2 overcount with no visible error.
test(every_clue_is_semidet_on_a_solution) :-
    solution(a, S),
    forall( member(N, [1,2,3,4,5,6,7,8,9]),
            ( aggregate_all(count, clue(N, S), C),
              ( C =< 1 -> true
              ; format(user_error, 'clue ~w succeeded ~w times~n', [N, C]), fail )
            ) ).

% --- the generator -----------------------------------------------------------

test(candidate_yields_13824_assignments) :-
    aggregate_all(count, candidate(_), N),
    assertion(N =:= 13824).

test(candidate_yields_no_duplicates) :-
    findall(S, candidate(S), All),
    sort(All, Distinct),
    length(All, A),
    length(Distinct, B),
    assertion(A =:= B).

test(solve_finds_exactly_three_solutions) :-
    aggregate_all(count, solve(_), N),
    assertion(N =:= 3).

test(solve_finds_exactly_the_three_expected_solutions) :-
    findall(S, solve(S), Found),
    sort(Found, FoundSorted),
    findall(S, solution(_, S), Expected),
    sort(Expected, ExpectedSorted),
    assertion(FoundSorted == ExpectedSorted).

% --- P1.b, count_solutions/2 -------------------------------------------------

test(no_active_clues_admits_every_assignment) :-
    count_solutions([], N),
    assertion(N =:= 13824).

% The cumulative table, computed independently.
expected_cumulative(1, 7776).
expected_cumulative(2, 4320).
expected_cumulative(3, 1128).
expected_cumulative(4, 208).
expected_cumulative(5, 76).
expected_cumulative(6, 36).
expected_cumulative(7, 16).
expected_cumulative(8, 3).

test(cumulative_counts_match_independent_enumeration) :-
    forall( expected_cumulative(K, Want),
            ( numlist(1, K, Active),
              count_solutions(Active, Got),
              ( Got =:= Want -> true
              ; format(user_error, 'clues 1-~w: got ~w, want ~w~n', [K, Got, Want]),
                fail )
            ) ).

test(eight_clues_admit_three_solutions) :-
    count_solutions([1,2,3,4,5,6,7,8], N),
    assertion(N =:= 3).

% No clue is redundant: dropping any one of the eight raises the count.
expected_without(1, 4).
expected_without(2, 6).
expected_without(3, 13).
expected_without(4, 12).
expected_without(5, 9).
expected_without(6, 7).
expected_without(7, 5).
expected_without(8, 16).

test(no_clue_is_implied_by_the_others) :-
    forall( expected_without(Drop, Want),
            ( numlist(1, 8, All),
              exclude(==(Drop), All, Active),
              count_solutions(Active, Got),
              ( Got =:= Want -> true
              ; format(user_error, 'without clue ~w: got ~w, want ~w~n',
                       [Drop, Got, Want]),
                fail )
            ) ).

% --- P1.c, the repair --------------------------------------------------------

test(nine_clues_admit_exactly_one_solution) :-
    count_solutions([1,2,3,4,5,6,7,8,9], N),
    assertion(N =:= 1).

test(clue_9_is_true_of_exactly_one_solution_of_clues_1_to_8) :-
    findall(Which, ( solution(Which, S), clue(9, S) ), Kept),
    assertion(Kept == [b]).

test(the_kept_solution_is_the_expected_one) :-
    findall(S, ( candidate(S), clues_hold([1,2,3,4,5,6,7,8,9], S) ), [Kept]),
    solution(b, Expected),
    assertion(Kept == Expected).

% --- P1.a, main/0 ------------------------------------------------------------

test(main_prints_four_lines_in_name_order) :-
    with_output_to(string(Out), main),
    split_string(Out, "\n", "", Parts),
    exclude(==(""), Parts, Lines),
    assertion(length(Lines, 4)),
    nth1(1, Lines, L1), nth1(2, Lines, L2),
    nth1(3, Lines, L3), nth1(4, Lines, L4),
    assertion(string_concat("Alex = [",  _, L1)),
    assertion(string_concat("Ben = [",   _, L2)),
    assertion(string_concat("Carla = [", _, L3)),
    assertion(string_concat("Dana = [",  _, L4)).

% The printed layout has a space after each comma, which printing the list of
% attributes as a single ~w would not produce.
test(main_output_has_a_space_after_each_comma) :-
    with_output_to(string(Out), main),
    split_string(Out, "\n", "", Parts),
    exclude(==(""), Parts, Lines),
    forall( member(Line, Lines),
            ( sub_string(Line, _, _, _, ", ")
            -> true
            ;  format(user_error, 'no ", " in: ~w~n', [Line]), fail )
            ).

% Unquoted output: 'c++' and 'AI' must print without their quotes.
test(main_output_is_unquoted) :-
    with_output_to(string(Out), main),
    assertion(\+ sub_string(Out, _, _, _, "'")).

% Whatever main prints must satisfy clues 1 to 8, which is all P1.a requires.
test(main_prints_a_solution_of_clues_1_to_8) :-
    once(solve(S)),
    clues_hold([1,2,3,4,5,6,7,8], S).

:- end_tests(q1).
