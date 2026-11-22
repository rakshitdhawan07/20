% =============================================================================
% CS F301 Assignment 2 — P1: Department Assignment Puzzle, Reloaded
% Group 20 — file 20_q1.pl
%
% Representation
% --------------
% A Solution is a list of exactly four ground terms
%
%     [p(Name, Dept, Lang, Project), ...]
%
% in the fixed order Alex, Ben, Carla, Dana, where
%
%     Name    in ['Alex', 'Ben', 'Carla', 'Dana']
%     Dept    in [research, development, design, testing]
%     Lang    in [python, java, 'c++', javascript]
%     Project in ['AI', web, embedded, data]
%
% and each value of each attribute is used exactly once across the four
% friends. 'Alex', 'Ben', 'Carla', 'Dana', 'AI' and 'c++' are quoted atoms:
% unquoted AI would read as a variable and unquoted c++ as an operator
% application.
%
% Definitions only — no initialization directive, no halt/0, nothing printed
% at load time. The grader supplies its own goals.
% =============================================================================


%! clue(+N:integer, +Solution:list) is semidet.
%
%  True when clue number N holds of Solution. Solution must be a fully
%  filled-in, ground assignment of the kind described above; these clauses
%  are lookups, not generators, and are not meant to be called with an
%  unbound or partially instantiated Solution.
%
%  Read declaratively: "clue N is satisfied by this complete assignment."
%
%  Each clause locates the one friend the clue talks about with memberchk/2
%  and then tests that friend's other attributes. memberchk/2 is semidet, so
%  no clause leaves a choice point behind and no solution can be counted
%  twice by findall/3 downstream. It is the right primitive here precisely
%  because the puzzle's one-value-per-attribute invariant means the friend
%  being looked for is unique: the first match is the only match.
%
%  Negative conditions use \==/2 rather than \+/1 with unification. On a
%  ground Solution the two agree, but \==/2 cannot flounder if a caller ever
%  passes an unbound field, where \+ Dept = research would fail instead of
%  raising, silently discarding valid assignments.
%
%  Where a clue offers a choice of values ("research or testing", clue 7) the
%  disjunction is written as a memberchk/2 over the permitted values rather
%  than with ;/2. Both are correct, but ;/2 leaves a choice point behind on
%  the branch that succeeds, and keeping every clause semidet is what makes
%  count_solutions/2 safe from double counting.

% CLUE 1: The friend who prefers the AI project does not work in research
%         and is not Dana.
clue(1, Solution) :-
    memberchk(p(Name, Dept, _, 'AI'), Solution),
    Dept \== research,
    Name \== 'Dana'.

% CLUE 2: Alex does not work in development and does not prefer C++.
%         "Prefer" here is about the favourite language attribute, since c++
%         is a language value, not a project value.
clue(2, Solution) :-
    memberchk(p('Alex', Dept, Lang, _), Solution),
    Dept \== development,
    Lang \== 'c++'.

% CLUE 3: The friend working in the testing department likes Python.
%         Stated positively, so a single lookup settles it: the clue holds
%         exactly when some friend is both in testing and likes python.
%         Because testing is held by exactly one friend, that friend is the
%         one the clue is about, and if their language is anything else no
%         element matches and the clue fails.
clue(3, Solution) :-
    memberchk(p(_, testing, python, _), Solution).

% CLUE 4: Ben prefers web projects and does not work in testing.
%         The positive half is folded into the lookup pattern: if Ben's
%         project is not web, nothing matches and the clue fails before the
%         department is examined.
clue(4, Solution) :-
    memberchk(p('Ben', Dept, _, web), Solution),
    Dept \== testing.

% CLUE 5: The friend whose favorite language is Java works in the design
%         department. Stated positively and about two attributes of the same
%         friend, so one lookup decides it: java is held by exactly one
%         friend, and the clue holds precisely when that friend's department
%         is design.
clue(5, Solution) :-
    memberchk(p(_, design, java, _), Solution).

% CLUE 6: Carla's project preference is not embedded, and her department is
%         not development.
clue(6, Solution) :-
    memberchk(p('Carla', Dept, _, Project), Solution),
    Project \== embedded,
    Dept \== development.

% CLUE 7: Dana's favorite language is not Java, and she works in research or
%         testing.
clue(7, Solution) :-
    memberchk(p('Dana', Dept, Lang, _), Solution),
    Lang \== java,
    memberchk(Dept, [research, testing]).

% CLUE 8: The friend who prefers data projects works in research and does not
%         use JavaScript. The research half is folded into the lookup pattern,
%         so if the data friend is in any other department nothing matches and
%         the clue fails before the language is examined.
clue(8, Solution) :-
    memberchk(p(_, research, Lang, data), Solution),
    Lang \== javascript.


% -----------------------------------------------------------------------------
% The attribute domains
% -----------------------------------------------------------------------------

%! names(-Names:list) is det.
%
%  The four friends, in the order every Solution uses and every answer is
%  printed in.
names(['Alex', 'Ben', 'Carla', 'Dana']).

%! depts(-Depts:list) is det.
depts([research, development, design, testing]).

%! langs(-Langs:list) is det.
langs([python, java, 'c++', javascript]).

%! projects(-Projects:list) is det.
projects(['AI', web, embedded, data]).


% -----------------------------------------------------------------------------
% Candidate generation
% -----------------------------------------------------------------------------

%! zip_friends(+Names:list, +Depts:list, +Langs:list, +Projects:list,
%!             -Solution:list) is det.
%
%  Pairs the four lists element by element into Solution, so that the Nth
%  friend gets the Nth department, the Nth language and the Nth project.
%
%  Recursive reading: zipping four empty lists gives the empty solution;
%  zipping four non-empty lists gives p/4 built from the four heads, followed
%  by the zip of the four tails. Every call removes one element from each
%  list, so it terminates, and it is det because the four lists have equal
%  length by construction.
zip_friends([], [], [], [], []).
zip_friends([N|Ns], [D|Ds], [L|Ls], [P|Ps], [p(N, D, L, P)|Rest]) :-
    zip_friends(Ns, Ds, Ls, Ps, Rest).

%! candidate(-Solution:list) is nondet.
%
%  Enumerates every fully filled-in assignment: one permutation of the
%  departments, one of the languages and one of the projects, laid against
%  the fixed name order. Each attribute's four values are therefore used
%  exactly once, which is the puzzle's standing invariant and the reason a
%  single memberchk/2 in clue/2 is enough to identify "the friend the clue is
%  about".
%
%  Read declaratively: "Solution is a complete, consistent assignment of the
%  three attributes to the four friends."
%
%  There are 4! x 4! x 4! = 13824 candidates, and permutation/2 yields each
%  permutation of a list of distinct elements exactly once, so candidate/1
%  yields each assignment exactly once and never twice. That matters: a
%  generator that repeated a candidate would inflate count_solutions/2 just as
%  surely as a nondet clue would.
%
%  Generating a complete assignment first and only then testing the clues is
%  deliberate rather than merely simple. The specification requires clue/2 to
%  succeed exactly when a clue holds of a fully filled-in Solution, so clue/2
%  must stay a pure test and cannot double as a constraint that prunes during
%  search. At 13824 candidates the cost of not pruning is irrelevant.
candidate(Solution) :-
    names(Names),
    depts(Depts),
    langs(Langs),
    projects(Projects),
    permutation(Depts, DeptPerm),
    permutation(Langs, LangPerm),
    permutation(Projects, ProjectPerm),
    zip_friends(Names, DeptPerm, LangPerm, ProjectPerm, Solution).


% -----------------------------------------------------------------------------
% Solving
% -----------------------------------------------------------------------------

%! clues_hold(+Active:list, +Solution:list) is semidet.
%
%  True when every clue number in Active holds of Solution. Solution must be
%  ground. Clue numbers not in Active are ignored entirely, which is what
%  count_solutions/2 needs in the next unit.
%
%  Recursive reading: the empty list of clues holds of any solution; a
%  non-empty list holds when its first clue holds and the rest hold. The list
%  shrinks by one on every call, so it terminates. Each clue/2 call is
%  semidet, so clues_hold/2 is semidet and leaves no choice point for
%  findall/3 to turn into a duplicate.
clues_hold([], _Solution).
clues_hold([N|Ns], Solution) :-
    clue(N, Solution),
    clues_hold(Ns, Solution).

%! solve(-Solution:list) is nondet.
%
%  Solution is a complete assignment satisfying all of clues 1 to 8.
%
%  Read declaratively: "Solution is an answer to the puzzle as stated."
%  Nondet because the eight stated clues do not pin the puzzle down to one
%  assignment; enumerating solve/1 is how P1.b counts them and how P1.c
%  checks that a ninth clue is true of exactly one of them.
solve(Solution) :-
    candidate(Solution),
    clues_hold([1, 2, 3, 4, 5, 6, 7, 8], Solution).


% -----------------------------------------------------------------------------
% P1.a — printing one solution
% -----------------------------------------------------------------------------

%! print_friend(+Friend:compound) is det.
%
%  Prints one p/4 term as a single line in the layout the assignment
%  specifies:
%
%      Alex = [research, python, AI]
%
%  The three attributes are formatted as three separate ~w fields rather than
%  by handing the list [Dept, Lang, Project] to a single ~w. That is not a
%  stylistic choice: write/1 of a list prints [research,python,AI] with no
%  space after the commas, which does not match the required layout.
%
%  ~w is also required over ~q and ~p. ~w writes without quoting, so the
%  atoms 'c++' and 'AI' print as c++ and AI; ~q and ~p would print them as
%  'c++' and 'AI', quotes included, and the output would not match.
print_friend(p(Name, Dept, Lang, Project)) :-
    format("~w = [~w, ~w, ~w]~n", [Name, Dept, Lang, Project]).

%! main is det.
%
%  Prints one solution of clues 1 to 8, as four lines in the order Alex, Ben,
%  Carla, Dana.
%
%  Read declaratively: "main prints a single answer to the puzzle as stated."
%
%  The name order needs no sorting: candidate/1 lays the attribute
%  permutations against names/1, so every Solution already lists the friends
%  in that order, and printing the list in order prints the names in order.
%
%  once/1 makes main det. solve/1 is nondet because the eight stated clues
%  admit more than one assignment, and the task asks for one solution, so
%  committing to the first is correct. Note that main/0 answers P1.a and so
%  stays on clues 1 to 8: the ninth clue of P1.c constrains count_solutions/2,
%  not this predicate.
%
%  No halt/0 here and no initialization directive anywhere in the file: the
%  grader supplies -g main -t halt itself.
main :-
    once(solve(Solution)),
    maplist(print_friend, Solution).


% -----------------------------------------------------------------------------
% P1.b — counting solutions under a chosen subset of the clues
% -----------------------------------------------------------------------------

%! count_solutions(+Active:list, -N:integer) is det.
%
%  N is the number of complete assignments that satisfy every clue whose
%  number appears in Active. Clue numbers absent from Active are ignored
%  outright: they are not required and not negated.
%
%  Read declaratively: "N is how many ways the friends can be arranged so
%  that exactly the clues in Active come out true."
%
%  Examples of the intended reading:
%      count_solutions([], N)                  gives N = 13824, every
%                                              candidate, since no clue is
%                                              required of any of them
%      count_solutions([1,2,3,4,5,6,7,8], N)   gives the number of solutions
%                                              of the puzzle as stated
%
%  aggregate_all/3 with the count template counts the successes of the goal,
%  which is the number of satisfying assignments only because the two parts
%  of that goal were built to make it so: candidate/1 yields each assignment
%  exactly once, and clues_hold/2 is semidet, so no assignment can succeed
%  twice and be counted twice. The equivalent
%
%      findall(S, (candidate(S), clues_hold(Active, S)), L), length(L, N)
%
%  gives the same answer; aggregate_all/3 is preferred here only because it
%  does not build a list of up to 13824 solutions just to measure it.
%
%  det: aggregate_all/3 with count always succeeds exactly once, giving 0 for
%  a goal with no solutions rather than failing.
count_solutions(Active, N) :-
    aggregate_all(count, ( candidate(Solution),
                           clues_hold(Active, Solution)
                         ), N).