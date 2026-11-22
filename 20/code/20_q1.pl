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