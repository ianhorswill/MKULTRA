%%%
%%% Simple unit test system based loosely on Jan Wielemaker's paper Prolog Unit Tests
%%%

:- public test/2, test/1, test_options/2.
:- public run_tests/0, run_tests/1.

:- indexical test_name=null, test_options=null, test_body=null, running_tests=false.

running_tests :-
   X = $running_tests,
   X.

%% test(*Name, +Options)
%  Body of this rule is a test that should be run with the specified options.

%% run_tests
%  Run all defined tests
run_tests :-
   run_tests(_).

%% run_tests(*TestName)
%  Run all tests with name TestName
run_tests(Name) :-
   ensure_tests_loaded(Name),
   bind(running_tests, true),
   forall(test_body(Name, Options, Body),
	  begin(all_test_options(Name, Options, AllOptions),
		run_test(Name, AllOptions, Body))),
   displayln("Tests complete").

%% test_body(+Name, -Options, -Body)
%  There is a test with Name, Options, and Body.
test_body(Name, Options, Body) :-
   clause(test(Name, Options), Body).
test_body(Name, [ ], Body) :-
   clause(test(Name), Body).

%% run_test(+Name, +Options, +Body)
%  Runs the specified test, printing out any failures.  Always succeeds.
run_test(Name, Options, Body) :-
   begin(bind(test_name, Name),
	 bind(test_options, Options),
	 copy_term(Body, Copy),
	 bind(test_body, Copy),
	 %displayln("Running ", Name),
	 setup_test(Name, Options),
	 (catch(run_test_body(Options, Body), Exception, true) ->
	     print_test_results(Name, Options, Exception)
	     ;
	     displayln("Test ", Name, " was unsatisfiable."))).

run_test_body(Options, Body) :-
   test_has_option(trace, Options),
   !,
   trace,
   % Run Body, but turn off tracing regardless of whether it succeeds.
   (Body -> notrace ; (notrace, fail)).
run_test_body(_, Body) :-
   Body.

print_test_results(Name, Options, Exception) :-
   test_has_option(throws(ExpectedException), Options) ->
      print_exception_test_results(Name, ExpectedException, Exception)
      ;
      print_nonexception_test_results(Name, Options, Exception).

print_exception_test_results(_Name, ExpectedException, ActualException) :-
   ExpectedException == ActualException,
   !.
print_exception_test_results(Name, ExpectedException, ActualException) :-
   var(ActualException) ->
      displayln("Test ", Name, " should have thrown ", ExpectedException, " but did not.")
      ;
      displayln("Test ", Name, " should have thrown ", ExpectedException, " but instead threw ", ActualException, ".").

print_nonexception_test_results(Name, _Options, Exception) :-
   nonvar(Exception),
   !,
   displayln("Test ", Name, " threw the exception ", Exception, ".").
print_nonexception_test_results(Name, Options, _) :-
   check_test_success(Name, Options),
   !,
   check_test_determinism(Name, Options).
print_nonexception_test_results(Name, _, _) :-
   displayln("Test ", Name, " failed its success test.").

check_test_determinism(_Name, Options) :-
   test_has_option(nondet, Options),
   !.
check_test_determinism(_Name, _Options) :-
   % $test_body is a copy of the body (doesn't share variables with the one that was run previously)
   deterministic($test_body), !.
check_test_determinism(Name, _) :-
   displayln("Test ", Name, " succeeded but is non-deterministic.").
      
setup_test(Name, Options) :-
   % Call P for every setup(P) that appears in the test's options.
   % Throw an exception if P fails.
   call_on_list(setup(_),
		Options,
		do_test_setup(Name)).
:- public do_test_setup/2.
do_test_setup(_Name, setup(P)) :-
   P.
do_test_setup(Name, setup(P)) :-
   displayln("Test setup operation for ", Name, " failed: ", P).

check_test_success(Name, Options) :-
   % Call P for every true(P) that appears in the test's options.
   % Succeeds iff all true(P)'s exist.
   call_on_list(true(_),
		Options,
		run_success_test(Name)),
   !.

:- public run_success_test/2.
run_success_test(_Name, true(P)) :-
   P.
run_success_test(Name, true(P)) :-
   displayln("Success test for ", Name, " failed: ", P).


%%%
%%% Utilities
%%%

%% test_has_option(+OptionPattern, +Options) is det.
%  The specified test has the specified pattern.
test_has_option(OptionPattern, Options) :-
   memberchk(OptionPattern, Options).

%% all_test_options(Name, Options, AllOptions)
%  AllOptions is the Options followed by all options satisfying test_options(Name, OptionList).
all_test_options(Name, Options, AllOptions) :-
   all(OptionList,
       test_options(Name, OptionList),
       AllOptionLists),
   flatten([Options | AllOptionLists], AllOptions).

%% call_on_list(+ElementPattern, +List, +Predicate)
%  True if Predicate is true of every element of List that matches ElementPattern.
call_on_list(_, [ ], _).
call_on_list(OptionPattern, [ Option | MoreOptions ], Predicate) :-
   % This succeeds of the two are equal, but doesn't keep any variable bindings.
   (\+ \+ (OptionPattern = Option)),
   !,
   call(Predicate, Option),
   call_on_list(OptionPattern, MoreOptions, Predicate).
call_on_list(OptionPattern, [ _ | MoreOptions ], Predicate) :-
   call_on_list(OptionPattern, MoreOptions, Predicate).

%% deterministic(:Goal)
%  Goal has exactly one solution by attempting to solve for a second solution.
deterministic(Goal) :-
   findnsols(2, _, Goal, [_]).

%% nonempty_instantiated_atom_list(+List)
%  List is a non_empty list of atoms.

:- public nonempty_instantiated_atom_list/1.

nonempty_instantiated_atom_list(X) :-
   var(X),
   !,
   fail.
nonempty_instantiated_atom_list([A | B]) :-
   atom(A),
   ground(B),
   forall(member(X, B),
	  atom(X)).


%% test_file(+TestName, *File)
%  File should be loaded before running TestName.

:- external test_file/2.

%% ensure_tests_loaded(+TestName)
%  Loads any test files associated with TestName that have not
%  already been loaded.  Uses test_file/2 to determine files
%  to load.

ensure_tests_loaded(TestName) :-
   forall(test_file(TestName, File),
	  ensure_test_file_loaded(File)).

ensure_test_file_loaded(File) :-
   consult(File),
   asserta( (ensure_test_file_loaded(File) :- !) ).