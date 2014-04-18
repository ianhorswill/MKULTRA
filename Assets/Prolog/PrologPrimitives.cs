using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;

using UnityEngine;

namespace Prolog
{
    internal static class PrologPrimitives
    {
        /// <summary>
        /// The delegate type for closures in the primitives table that implement the different primitives
        /// </summary>
        internal delegate IEnumerable<CutState> PrimitiveImplementation(object[] args, PrologContext context);

        internal static Symbol PrimitiveName(PrimitiveImplementation impl)
        {
            foreach (var pair in Implementations)
                if (pair.Value == impl)
                    return pair.Key;
            return Symbol.Intern("unknown_primitive");
        }

        internal static IEnumerable<CutState> StackCall(PrimitiveImplementation primitive, int arity, PrologContext context)
        {
            return primitive(context.GetCallArgumentsAsArray(arity), context);
        }

            /// <summary>
        /// Adds primitvies to the primitives table
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Maintainability", "CA1502:AvoidExcessiveComplexity")
        ]
        internal static void InstallPrimitives()
        {
            DefinePrimitive(Symbol.Comma, AndImplementation, "flow control", "True if both goals are true.", ":goal1",
                            ":goal2");
            DefinePrimitive(";", OrImplementation, "flow control", "True if both goals are true.", ":goal1", ":goal2");
            DefinePrimitive("->", IfThenImplementation, "flow control", "Proves CONSEQUENT if TEST is true.", ":test",
                            ":consequent");
            DefinePrimitive("not", NotImplementation, "flow control", "True if GOAL is unprovable.  GOAL must be ground.", "*goal");
            DefinePrimitive("\\+", NotPlusImplementation, "flow control", "True if GOAL is unprovable", ":goal");
            DefinePrimitive("once", OnceImplementation, "flow control,meta-logical predicates",
                            "Attempts to prove GOAL, but suppresses backtracking for a second solution.", ":goal");
            DefinePrimitive(Symbol.Call, CallImplementation, "flow control,meta-logical predicates",
                            "Attempts to prove the specified GOAL, adding any additional arguments, if specified.",
                            ":goal", "?optionalArguments", "...");
            DefinePrimitive("apply", ApplyImplementation, "flow control,meta-logical predicates",
                            "Adds arguments in ARGLIST to end of GOAL and attempts to prove the resulting goal.", ":goal",
                            "+arglist");
            DefinePrimitive("randomize", RandomizeImplementation, "meta-logical predicates",
                            "Proves GOAL, while randomizing clause order for clauses declared randomizable.", ":goal");
            DefinePrimitive("begin", BeginImplementation, "flow control,meta-logical predicates",
                "Runs each goal in sequence, throwing an exception if any goal fails.  Cannot be backtracked.",
                ":goal", "...");
            DefinePrimitive(Symbol.Dot, MethodCallImplementation, "flow control",
                "Calls the specified method of the specified object.",
                "*object", "method(*arguments...)");
            DefinePrimitive("::", ModuleCallImplementation, "flow control",
                "Attempts to prove the specified goal in the specified module.",
                "*module", ":goal");
            DefinePrimitive("freeze", FreezeImplementation, "flow control,constraint programming",
                            "Runs GOAL when VAR becomes bound; unification will fail if GOAL fails.", "?var", ":goal");
            DefinePrimitive("frozen", FrozenImplementation, "flow control,constraint programming",
                            "Unifies GOAL with the goal frozen on TERM, if TERM is an unbound variable with a frozen goal; otherwise unifies GOAL with true.", "?term", "-goal");
            DefinePrimitive("dif", DifImplementation, "comparisons,constraint programming",
                            "Requires that TERM1 and TERM2 never be equal.  If they are, the predicate fails.  If they are not, it forces any future unifications that would make them equal to fail.", "?term1", "?term2");
            DefinePrimitive("maplist", MapListImplementation, "list predicates,meta-logical predicates",
                            "True if PREDICATE is true of all successive pairs of elements from LIST1 and LIST2.",
                            ":predicate", "?list1", "?list2");
            DefinePrimitive("randomizable",
                            MakeDeclarationPredicate((s, a, context) => context.KnowledgeBase.DeclareRandomizable(s, a)),
                            "flow control,declarations",
                            "Declares that the specified predicate is allowed to have its clauses explored in random order, when clause randomization is enabled.",
                            ":predicateIndicator", "...");
            DefinePrimitive("shadow",
                            MakeDeclarationPredicate((s, a, context) => context.KnowledgeBase.DeclareShadow(s, a)),
                            "flow control,declarations",
                            "Declares that declarations for the specified predicate are allowed in this knowledgebase and override any declarations in the parent.",
                            ":predicateIndicator", "...");
            DefinePrimitive("external",
                            MakeDeclarationPredicate((s, a, context) => context.KnowledgeBase.DeclareExternal(s, a)),
                            "flow control,declarations",
                            "Declares that the specified predicate is optional to define and/or defined elsewhere; thus, it should not generate undefined predicate warnings.",
                            ":predicateIndicator", "...");
            DefinePrimitive("public",
                            MakeDeclarationPredicate((s, a, context) => context.KnowledgeBase.DeclarePublic(s, a)),
                            "flow control,declarations",
                            "Declares that the specified predicate is expected to be called from elsewhere.  It should not generate unreferenced predicate warnings.",
                            ":predicateIndicator", "...");
            DefinePrimitive("higher_order",
                            DeclareHigherOrderImplementation,
                            "flow control,declarations",
                            "Declares that the specified predicate is may call its arguments as subgoals.  For example, higher_order(find_all(0,1,0)) means find_all/3 calls its second argument.  Used by the static checker to weed out unreferenced predicates.",
                            ":predicateIndicator", "...");
            DefinePrimitive("disassemble",
                MakeDeclarationPredicate((s, a, context) => context.KnowledgeBase.Disassemble(s, a)),
                "flow control",
                "Prints bytecode for a compiled predicate.",
                ":predicateIndicator", "...");
            DefinePrimitive("compile",
                MakeDeclarationPredicate((s, a, context) => context.KnowledgeBase.Compile(s, a)),
                "flow control",
                "Declares that the predicate should be byte compiled rather than interpreted.",
                ":predicateIndicator", "...");
            DefinePrimitive("findall", FindallImplementation, "all solutions predicates",
                            "Unifies SOLUTIONS with a list of every value of TEMPLATE for every possible solution of GOAL.",
                            "=template", ":goal", "-solutions");
            DefinePrimitive("sumall", SumallImplementation, "all solutions predicates",
                            "Unifies SUM with sum of the values of NUMBERVAR in every possible solution of GOAL.",
                            "-numberVar", ":goal", "-sum");
            DefinePrimitive("arg_min", ArgMinImplementation, "all solutions predicates",
                            "Find the value of TEMPLATE that gives the lowest SCORE among all solutions to GOAL.",
                            ">template", "-score", "+goal");
            DefinePrimitive("arg_max", ArgMaxImplementation, "all solutions predicates",
                            "Find the value of TEMPLATE that gives the highest SCORE among all solutions to GOAL.",
                            ">template", "-score", "+goal");
            DefinePrimitive("property", PropertyImplementation, ".net interoperation",
                            "Unifies VALUE with the value of OBJECT's property named PROPERTY_NAME.Always succeeds exactly once (unless it throws an exception).",
                            "*object", "*property_name", ">value");
            DefinePrimitive("set_property", SetPropertyImplementation, ".net interoperation",
                            "Sets OBJECT's property named PROPERTY_NAME to NEW_VALUE.  Always succeeds exactly once (unless it throws an exception).",
                            "*object", "*property_name", "*new_value");
            DefinePrimitive("call_method", CallMethodImplementation, ".net interoperation",
                            "Calls the specified method on OBJECT with the specified arguments and unifies RESULT with its return value.  Always succeeds exactly once (unless it throws an exception).",
                            "*object", "*method_and_args", ">result");
            DefinePrimitive("is_class", IsClassImplementation, ".net interoperation",
                            "True if OBJECT is of the specified CLASS.  If CLASS is a subclass of TwigGameComponent and OBJECT is uninstantiated, then it will enumerate objects if the specified type.",
                            "?object", "?class");
            DefinePrimitive("component_of_gameobject_with_type", ComponentOfGameObjectWithTypeImplementation, ".net interoperation",
                            "True if component is a component of gameobject with type class.",
                            "?component", "?gameobject", "+class");
            DefinePrimitive("discontiguous", TrueImplementation, "declarations",
                            "Declares that the specified predicate is allowed to be scattered through a file.  Currently unused but provided for compatibility with other Prolog implementation.",
                            ":predicateIndicator", "..."); // noop
            DefinePrimitive("multifile", TrueImplementation, "declarations",
                            "Declares that the specified predicate is allowed to be scattered through multiple files.  Currently unused but provided for compatibility with other Prolog implementation.",
                            ":predicateIndicator", "..."); // noop
            DefinePrimitive("dynamic", TrueImplementation, "declarations",
                            "Declares that the specified predicate is allowed be dynamically modified using assert.  Currently unused but provided for compatibility with other Prolog implementation.",
                            ":predicateIndicator", "..."); // noop
            DefinePrimitive("trace", MakeDeclarationPredicate((s, arity, context) => context.KnowledgeBase.DeclareTraced(s, arity)),
                            "flow control,declarations",
                            "Declares that the specified predicate should be traced when executing.",
                            ":predicateIndicator", "...");
            DefinePrimitive("notrace",
                            MakeDeclarationPredicate((s, arity, context) => context.KnowledgeBase.DeclareUntraced(s, arity)),
                            "flow control,declarations",
                            "Declares that the specified predicate should be traced when executing.",
                            ":predicateIndicator", "...");
            DefinePrimitive("set_prolog_flag", SetPrologFlagImplementation, "declarations", "Sets/gets value of the specified control parameter for the prolog system.",
                            "*flag", "?value");
            DefinePrimitive("check", CheckImplementation, "other predicates",
                            "Checks that Goal is true, and throws an exception if it fails.  Only succeeds once, so similar to once/1.",
                            ":goal");
            DefinePrimitive(Symbol.Cut, CutImplementation, "flow control,meta-logical predicates",
                            "Prohibits backtracking past this point for the current goal.");
            DefinePrimitive(Symbol.Fail, ((args, context) => FailImplementation), "flow control",
                            "Forces failure of the current goal.");
            DefinePrimitive("true", TrueImplementation, "flow control", "Always succeeds.");
            DefinePrimitive("repeat", RepeatImplementation, "flow control", "Always succeeds, and allows infinite backtracking.");
            DefinePrimitive("throw", ThrowImplementation, "flow control,meta-logical predicates",
                            "Throws the specified exception.",
                            "+exception"); 
            DefinePrimitive("catch", CatchImplementation, "flow control,meta-logical predicates",
                            "Attempts to prove the specified GOAL, catching exceptions.  If an exception is thrown, it is unified with EXCEPTION and RECOVER is run.",
                            ":goal", "=exception", ":recover");
            DefinePrimitive("is", IsImplementation, "arithmetic",
                            "Computes the value of FUNCTIONAL_EXPRESSION and unifies it with VARIABLE.  Expression must be fully instantiated, i.e. all variables in it must already have values.",
                            ">variable", "*functional_expression");
            DefinePrimitive("=", EqualsImplementation, "comparisons", "Succeeds if the two terms are unifiable.", "?x",
                            "?y");
            DefinePrimitive("unifiable", UnifiableImplementation, "comparisons",
                            "True if X and Y can be unified, but does not unify them.  Instead returns the most general unifier in UNIFIER.",
                            "?x", "?y", "-unifier");
            DefinePrimitive("\\=", NotEqualsImplementation, "comparisons",
                            "Succeeds if the two terms are not unifiable.", "?x", "?y");
            DefinePrimitive("==", EquivalentImplementation, "comparisons", "Succeeds if the two terms are already identical, as opposed to =, which tries to make them identical through unification.", "?x",
                            "?y");
            DefinePrimitive("\\==", NotEquivalentImplementation, "comparisons", "Succeeds if the two terms are not identical, as opposed to \\= which tests if it's possible to make them identical through unification.", "?x",
                            "?y");
            DefinePrimitive("copy_term", CopyTermImplementation, "term manipulation",
                            "Makes a new copy of ORIGINAL with fresh variables, and unifies it with COPY.", "=original", "-copy");
            DefinePrimitive("=..", UnivImplementation, "term manipulation,list predicates",
                            "If TERM is instantiated, explodes it into a list: [Functor | Arguments] and unifies it with LIST; if TERM uninstantiated, converts LIST to a term and unifies it with TERM.",
                            "?term", "?list");
            DefinePrimitive("functor", FunctorImplementation, "term manipulation",
                            "True if TERM has the specified FUNCTOR and ARITY.",
                            "?term", "?functor", "?arity");
            DefinePrimitive("arg", ArgImplementation, "term manipulation", "True if argument number ARG (counting from 1, not zero) of STRUCTURE is TERM.",
                            "*arg", "+structure", "?argumentValue");
            DefinePrimitive("list", ListImplementation, "list predicates", "True if X is a list.", "?x");
            DefinePrimitive("length", LengthImplementation, "list predicates",
                            "Unifies LENGTH with the length of LIST.  This is a true relation, so if LIST is uninstantiated, it will create lists with specified lengths.",
                            "?list", "?length");
            DefinePrimitive("member", MemberImplementation, "list predicates",
                            "True if ELEMENT is an element of LIST.  This is a true relation, so if necessary, it will create new LISTS.",
                            "?element", "?list");
            DefinePrimitive("memberchk", MemberChkImplementation, "list predicates",
                            "True if ELEMENT is an element of LIST, but will not backtrack different choices of the element.  This is a true relation, so if necessary, it will create new LISTS.",
                            "?element", "?list");
            DefinePrimitive("append", AppendImplementation, "list predicates",
                            "True if JOINED is a list that starts with the elements of START and is followed by the elements of END.  This is a true relation, so it can be used to compute any argument from the others.",
                            "?start", "?end", "?joined");
            DefinePrimitive("reverse", ReverseImplementation, "list predicates",
                            "True if the lists FORWARD and BACKWARD are reversed versions of one another.",
                            "?forward", "?backward");
            DefinePrimitive("flatten", FlattenImplementation, "list predicates",
                            "True if FLATLIST contains all the atoms of LISTOFLISTS, in order.",
                            "+listoflists", "?flatlist");
            DefinePrimitive("prefix", PrefixImplementation, "list predicates", "True if LIST starts with PREFIX.",
                            "?prefix", "?list");
            DefinePrimitive("suffix", SuffixImplementation, "list predicates", "True if LIST ends with SUFFIX.",
                            "?suffix", "?list");
            DefinePrimitive("select", SelectImplementation, "list predicates",
                            "True if X is an element of LIST_WITH and LIST_WITHOUT is LIST_WITH minus an occurance of X.",
                            "?x", "?list_with", "?list_without");
            DefinePrimitive("delete", DeleteImplementation, "list predicates", "True if HasNoXs is LIST without X.",
                            "?list", "?x", "?HasNoXs");
            DefinePrimitive("<", MakeComparisonPredicate("<", (a, b) => a < b), "comparisons",
                            "True if number X is less than Y.  Both must be ground.", "*x", "*y");
            DefinePrimitive(">", MakeComparisonPredicate(">", (a, b) => a > b), "comparisons",
                            "True if number X is greater than Y.  Both must be ground.", "*x", "*y");
            DefinePrimitive("=<", MakeComparisonPredicate("<=", (a, b) => a <= b), "comparisons",
                            "True if number X is less than or equal to Y.  Both must be ground.", "*x", "*y");
            DefinePrimitive(">=", MakeComparisonPredicate(">=", (a, b) => a >= b), "comparisons",
                            "True if number X is greater than or equal to Y.  Both must be ground.", "*x", "*y");
            DefinePrimitive("@<", MakeTermComparisonPredicate("@<", a => a < 0), "comparisons",
                "True if term X is less than Y given Prolog's ordering on terms.  X and Y need not be numbers.", "?x", "?y");
            DefinePrimitive("@>", MakeTermComparisonPredicate("@>", a => a > 0), "comparisons",
                            "True if term X is greater than Y given Prolog's ordering on terms.  X and Y need not be numbers.", "?x", "?y");
            DefinePrimitive("@=<", MakeTermComparisonPredicate("@<=", a => a <= 0), "comparisons",
                            "True if term X is less than or equal to Y given Prolog's ordering on terms.  X and Y need not be numbers.", "?x", "?y");
            DefinePrimitive("@>=", MakeTermComparisonPredicate("@>=", a => a >= 0), "comparisons",
                            "True if term X is greater than or equal to Y given Prolog's ordering on terms.  X and Y need not be numbers.", "?x", "?y");

            // ReSharper disable CompareOfFloatsByEqualityOperator
            DefinePrimitive("=\\=", MakeComparisonPredicate("=\\=", (a, b) => a != b), "comparisons",
                            "True if X and Y are different numbers.  Both must be ground.", "*x", "*y");
            // ReSharper restore CompareOfFloatsByEqualityOperator
            // ReSharper disable CompareOfFloatsByEqualityOperator
            DefinePrimitive("=:=", MakeComparisonPredicate("=:=", (a, b) => a == b), "comparisons",
                            "True if functional expressions X and Y have the same values.  Both must be ground.",
                            "*x", "*y");
            // ReSharper restore CompareOfFloatsByEqualityOperator
            DefinePrimitive("C", CPrimitiveImplementation, "definite clause grammars",
                            "Used in implementation of DGCs.  True if LIST starts with WORD and continues with TAIL.",
                            "?list", "?word", "?tail");
            DefinePrimitive("var", MakeNullFailingTypePredicate("var", (x => (x is LogicVariable))),
                            "meta-logical predicates", "True if X is an uninstantiated variable.", "?x");
                // ReSharper disable once RedundantComparisonWithNull
            DefinePrimitive("nonvar", MakeNullTestingTypePredicate("nonvar", (x => x==null || !(x is LogicVariable))),
                            "meta-logical predicates",
                            "True if X isn't an uninstantiated variable, that is, if it's instantiated to some term.",
                            "?x");
            DefinePrimitive("ground", MakeNullTestingTypePredicate("var", (Term.IsGround)),
                            "meta-logical predicates", "True if X is a ground term, i.e. contains no unbound variables.", "?x");
            DefinePrimitive("number", MakeNullFailingTypePredicate("number", (x => (x is float) || (x is int))), "type predicates",
                            "True if X is a number.", "?x");
            DefinePrimitive("integer", MakeNullFailingTypePredicate("integer", (x => (x is int))), "type predicates",
                            "True if X is an integer.", "?x");
            DefinePrimitive("float", MakeNullFailingTypePredicate("float", (x => ((x is float) || (x is double)))),
                            "type predicates", "True if X is a floating-point number.", "?x");
                // ReSharper disable once RedundantComparisonWithNull
            DefinePrimitive("atomic", MakeNullTestingTypePredicate("atomic", (x => x == null || !(x is Structure))),
                            "type predicates", "True if X is not a structured term, i.e. it's a number, symbol, etc..",
                            "?x");
            DefinePrimitive("string", MakeNullFailingTypePredicate("string", (x => (x is string))), "type predicates",
                            "True if X is a string.", "?x");
            DefinePrimitive("atom", MakeNullTestingTypePredicate("atom", (x => (x == null) || (x is Symbol))), "type predicates",
                            "True if X is a symbol.", "?x");
            DefinePrimitive("symbol", MakeNullFailingTypePredicate("symbol", (x => (x is Symbol))), "type predicates",
                            "True if X is a symbol.", "?x");
            DefinePrimitive("compound", MakeNullFailingTypePredicate("compound", (x => (x is Structure))),
                            "type predicates", "True if X is a structured term or list.", "?x");
            DefinePrimitive("consult", ConsultImplementation, "loading code",
                            "Reads the clauses in FILE and addds them to the database.", "*file");
            DefinePrimitive("reconsult", ReconsultImplementation, "loading code",
                            "Removes all clauses previously loaded from FILE, then reads the clauses in FILE and addds them to the database.",
                            "*file");
            DefinePrimitive("listing", ListingImplementation, "loading code,database manipulation", "Prints a listing of PREDICATE", "*predicate");
            DefinePrimitive("asserta", AssertaImplementation, "database manipulation", "Adds TERM (a rule or fact) to the database as the first clause for the predicate.", "+term");
            DefinePrimitive("assertz", AssertzImplementation, "database manipulation",
                            "Adds TERM (a rule or fact) to the database as the last clause for the predicate.", "+term");
            DefinePrimitive("assert", AssertzImplementation, "database manipulation",
                            "Adds TERM (a rule or fact) to the database as the last clause for the predicate.  Same as assertz.", "+term");
            DefinePrimitive("retractall", RetractAllImplementation, "database manipulation", "Removes all database entries whose heads unify with HEAD.", "+head");
            DefinePrimitive("retract", RetractImplementation, "database manipulation", "Removes first database entry that unifies with TERM.", "+term");
            DefinePrimitive("clause", ClauseImplementation, "database manipulation", "Unifies HEAD and BODY with entries in the database.", "+head", "?body");
            DefinePrimitive("step_limit", StepLimitImplementation, "other predicates",
                            "Gets/sets the maximum number of inference steps allowed.", "*maximum_steps");
            DefinePrimitive("benchmark", BenchmarkImplementation, "other predicates",
                            "Runs GOAL repeatedly, COUNT times.", "+goal", "*count");
            DefinePrimitive("word_list", WordListImplementation, "definite clause grammars",
                            "Parses/unparses STRING into a LIST of word.", "?string", "?list");
            DefinePrimitive("string_representation", StringRepresentationImplementation, "other predicates",
                            "Parses/unparses between TERM and STRING.", "?term", "?string");
            DefinePrimitive("set", KnowledgeBaseVariable.SetImplementation, "other predicates,meta-logical predicates",
                            "Forcibly asserts PREDICATE(VALUE) and retracts all other clauses for PREDICATE.",
                            "*predicate", "*value");
            DefinePrimitive("write", WriteImplementation, "other predicates",
                            "Prints the value of OBJECT to the console.", "?object");
            DefinePrimitive("writeln", WritelnImplementation, "other predicates",
                            "Prints the value of OBJECT to the console, along with a newline.", "?object");
            DefinePrimitive("nl", NLImplementation, "other predicates", "Prints a newline to the system console.");
            DefinePrimitive("op", DeclareOperator, "declarations",
                            "Declares the type and priority of an infix, prefix, or postfix operator.",
                            "*priority", "*type", "*operator");
            DefinePrimitive("open", OpenImplementation, "other predicates", "Opens a file for input or output.",
                            "*path", "*mode", "-stream");
            DefinePrimitive("close", CloseImplementation, "other predicates", "Closes an open file.", "*stream");
            DefinePrimitive("read", ReadImplementation, "other predicates", "Reads an expression from an open stream.",
                            "*stream", "-term");
            DefinePrimitive(ELProlog.NonExclusiveOperator, ELNonExclusiveQueryImplementation, "eremic logic",
                            "Succeeds if EXPRESSION can be matched against the EL knowledgebase.",
                            "*expression");
            DefinePrimitive(ELProlog.ExclusiveOperator, ELExclusiveQueryImplementation, "eremic logic",
                            "Succeeds if EXPRESSION can be matched against the EL knowledgebase.",
                            "*expression");
        }

        #region Primitive table

        private static void DefinePrimitive(string name, PrimitiveImplementation implementationDelegate,
                                            string manualSections, string docstring, params object[] arglist)
        {
            Symbol s = Symbol.Intern(name);
            DefinePrimitive(s, implementationDelegate, manualSections, docstring, arglist);
        }

        private static void DefinePrimitive(Symbol name, PrimitiveImplementation implementationDelegate,
                                            string manualSections, string docstring, params object[] arglist)
        {
            Implementations[name] = implementationDelegate;
            if (arglist.Length > 0 && (arglist[arglist.Length - 1] as string) == "...")
            {
                MinimumArity[name] = arglist.Length - 2;
                MaximumArity[name] = int.MaxValue;
            }
            else
                MinimumArity[name] = MaximumArity[name] = arglist.Length;

            DelegateUtils.NameProcedure(implementationDelegate, name.Name);
            Manual.AddToSections(manualSections, implementationDelegate);

            for (int i = 0; i < arglist.Length; i++)
                if (arglist[i] is string)
                    arglist[i] = Symbol.Intern((string) arglist[i]);

            DelegateUtils.Arglists[implementationDelegate] = arglist;
            DelegateUtils.Docstrings[implementationDelegate] = docstring;
        }

        /// <summary>
        /// Table of implementations of different Prolog primitive predicates.
        /// </summary>
        internal static readonly Dictionary<Symbol, PrimitiveImplementation> Implementations =
            new Dictionary<Symbol, PrimitiveImplementation>();
        /// <summary>
        /// The smallest arity this primitive can accept
        /// </summary>
        internal static readonly Dictionary<Symbol,int> MinimumArity = new Dictionary<Symbol, int>();
        /// <summary>
        /// The largest it can accept.
        /// </summary>
        internal static readonly Dictionary<Symbol, int> MaximumArity = new Dictionary<Symbol, int>();

        /// <summary>
        /// True if there is a primitive with this functor and arity.
        /// </summary>
        internal static bool IsDefined(Symbol functor, int arity)
        {
            int min;
            return MinimumArity.TryGetValue(functor, out min)
                   && arity >= min && arity <= MaximumArity[functor];
        }

        #endregion

        #region Primitive implementations

        /// <summary>
        /// Internal implementation of Cut
        /// </summary>
        private static IEnumerable<CutState> CutImplementation(object[] args, PrologContext context)
        {
            yield return CutState.Continue;
            yield return CutState.ForceFail;
        }

        static IEnumerable<CutState> IgnoreCuts(IEnumerable<CutState> iterator)
        {
            foreach (var cutstate in iterator)
            {
                if (cutstate == CutState.ForceFail)
                    yield break;
                yield return CutState.Continue;
            }
        } 

        private static readonly object[] NoArgs = new object[0];

        private static IEnumerable<CutState> BeginImplementation(object[] args, PrologContext context)
        {
            foreach (var goal in args)
            {
                var goalStructure = Term.Structurify(goal, "Argument to begin is not a valid goal.");
                if (goalStructure.IsFunctor(Symbol.Dot, 2))
                    FunctionalExpression.Eval(goalStructure, context);
                else
                {
                    var enumerator = context.Prove(goalStructure).GetEnumerator();
                    if (!enumerator.MoveNext() || enumerator.Current == CutState.ForceFail)
                        throw new GoalException(goal, "Goal failed");
                }
            }
            yield return CutState.Continue;
        }

        private static IEnumerable<CutState> MethodCallImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2)
                throw new ArgumentCountException("method calll", args, "*object", "method(*arguments, ...)");
            var result = FunctionalExpression.EvalMemberExpression(args[0], args[1], context);
            return CutStateEnumerator(!(result is bool) || ((bool)result));
        }

        private static IEnumerable<CutState> ModuleCallImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2)
                throw new ArgumentCountException("::", args, "*module", ":goal");
            var module = FunctionalExpression.Eval(args[0], context);
            var kb = module as KnowledgeBase;
            if (kb == null)
            {
                var o = module as GameObject;
                if (o != null)
                    kb = o.KnowledgeBase();
                else
                {
                    var component = module as Component;
                    if (component != null)
                        kb = component.KnowledgeBase();
                    else
                    {
                        throw new ArgumentTypeException("::", "module", module, typeof(GameObject));
                    }
                }
            }
            Structure goal = Term.Structurify(args[1], "Invalid goal in :: expression.");
            return IgnoreCuts(kb.Prove(goal.Functor, goal.Arguments, context, context.CurrentFrame));
        }

        private static IEnumerable<CutState> CallImplementation(object[] args, PrologContext context)
        {
            switch (args.Length)
            {
                case 0:
                    throw new ArgumentCountException("call", args, "goal", "optionalAdditionalArguments", "...");

                case 1:
                    return IgnoreCuts(context.Prove(args[0], "Argument to call must be a valid subgoal."));

                default:
                    // More than 1 argument - add other arguments to the end of the predicate
                    {
                        object goal = Term.Deref(args[0]);
                        var t = goal as Structure;

                        if (t != null)
                        {
                            var goalArgs = new object[t.Arguments.Length + args.Length - 1];
                            t.Arguments.CopyTo(goalArgs, 0);
                            Array.Copy(args, 1, goalArgs, t.Arguments.Length, args.Length - 1);

                            return IgnoreCuts(context.KnowledgeBase.Prove(t.Functor, goalArgs, context, context.CurrentFrame));
                        }
                        var s = goal as Symbol;
                        if (s != null)
                        {
                            var goalArgs = new object[args.Length - 1];
                            Array.Copy(args, 1, goalArgs, 0, args.Length - 1);

                            return IgnoreCuts(context.KnowledgeBase.Prove(s, goalArgs, context, context.CurrentFrame));
                        }
                        throw new ArgumentException("Argument to call must be a valid subgoal.");
                    }
            }
        }

        private static IEnumerable<CutState> ApplyImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("apply", args, "goal", "argumentList");
            object goal = Term.Deref(args[0]);
            object[] argList = Prolog.PrologListToArray(args[1]);
            var t = goal as Structure;
            if (t != null)
            {
                var newArgs = new object[t.Arguments.Length + argList.Length];
                t.Arguments.CopyTo(newArgs, 0);
                Array.Copy(argList, 0, newArgs, t.Arguments.Length, argList.Length);
                return IgnoreCuts(context.KnowledgeBase.Prove(t.Functor, newArgs, context, context.CurrentFrame));
            }
            var s = goal as Symbol;
            if (s != null)
                return IgnoreCuts(context.KnowledgeBase.Prove(s, argList, context, context.CurrentFrame));
            throw new ArgumentException("Argument to apply is not a valid Prolog goal: " + goal);
        }

        private static IEnumerable<CutState> RandomizeImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1) throw new ArgumentCountException("randomize", args, "goal");
            object goal = Term.Deref(args[0]);
            var t = goal as Structure;
            if (t != null)
                return RandomizeInternal(context.KnowledgeBase, context, t);
            var s = goal as Symbol;
            if (s != null)
                return IgnoreCuts(context.KnowledgeBase.Prove(s, NoArgs, context, context.CurrentFrame));
            throw new ArgumentException("Argument to randomize must be a valid subgoal.");
        }

        private static IEnumerable<CutState> ThrowImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1) throw new ArgumentCountException("throw", args, "exception");
            throw new PrologException(Term.CopyInstantiation(args[0]));
        }

        private static IEnumerable<CutState> CatchImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3) throw new ArgumentCountException("catch", args, "goal", "exception", "recover");
            Structure goal = Term.Structurify(args[0], "Goal argument must be a valid goal.");
            Structure recover = Term.Structurify(args[2], "Recover argument must be a valid goal.");
            IEnumerator<CutState> prover =
                context.KnowledgeBase.Prove(goal.Functor, goal.Arguments, context, context.CurrentFrame).GetEnumerator();
            bool alive = true;
            Exception exception = null;
            while (alive)
            {
                try
                {
                    alive = prover.MoveNext();
                }
                catch (Exception e)
                {
                    exception = e;
                    alive = false;
                }
                if (alive)
                    yield return CutState.Continue;
            }
            if (exception != null)
            {
                object isoexception;
                if (exception is InstantiationException)
                    isoexception = Symbol.Intern("instantiation_error");
                else
                {
                    var predicateException = exception as UndefinedPredicateException;
                    if (predicateException != null)
                        isoexception = new Structure(Symbol.Intern("existence_error"), Symbol.Intern("procedure"),
                            predicateException.Predicate);
                    else
                    {
                        var goalException = exception as GoalException;
                        if (goalException != null)
                            isoexception = new Structure(Symbol.Intern("type_error"), Symbol.Intern("callable"), goalException.Goal);
                        else
                        {
                            var procedureException = exception as BadProcedureException;
                            if (procedureException != null)
                                isoexception = new Structure(Symbol.Intern("type_error"), Symbol.Intern("evaluable"), procedureException.Procedure);
                            else
                            {
                                var prologException = exception as PrologException;
                                if (prologException != null)
                                    isoexception = prologException.ISOException;
                                else if (exception is ArgumentTypeException)
                                {
                                    var ate = exception as ArgumentTypeException;
                                    object type = ate.ExpectedType;
                                    // ReSharper disable RedundantCast
                                    if (type == (object)typeof(int))
                                        type = Symbol.Intern("integer");
                                    else if (type == (object)typeof(float) || type == (object)typeof(double))
                                        type = Symbol.Intern("float");
                                    else if (type == (object)typeof(Symbol))
                                        type = Symbol.Intern("atom");
                                    else if (type == (object)typeof(Structure))
                                        type = Symbol.Intern("compound");
                                    // ReSharper restore RedundantCast
                                    isoexception = new Structure(Symbol.Intern("type_error"), type, ate.Value);
                                }
                                else
                                    isoexception = Symbol.Intern("system_error");
                            }
                        }
                    }
                }
                // ReSharper disable UnusedVariable
#pragma warning disable 414, 168, 219
                foreach (var ignore in Term.Unify(args[1], new Structure(Symbol.Intern("error"), isoexception, null)))
                    foreach (var ignore2 in context.KnowledgeBase.Prove(recover.Functor, recover.Arguments, context, context.CurrentFrame))
#pragma warning restore 414, 168, 219
                    // ReSharper restore UnusedVariable
                    {
                        yield return CutState.Continue;
                        yield break;
                    }
            }
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage",
            "CA2208:InstantiateArgumentExceptionsCorrectly")]
        private static IEnumerable<CutState> FreezeImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("freeze", args, "variable", "goal");
            Structure goal = Term.Structurify(args[1], "Goal argument to freeze must be a valid Prolog goal.");
            var v = args[0] as LogicVariable;
            if (v == null) throw new ArgumentTypeException("freeze", "variable", args[0], typeof (LogicVariable));
            object canon = Term.Deref(v);
            var canonv = canon as LogicVariable;
            if (canonv == null)
                // Variable is already instantiated - run the goal
                return context.Prove(goal);
            // Variable is uninstantiated; tag it with a suspension of goal.
            return canonv.MetaUnify(new Suspension(null, goal, context));
        }

        private static IEnumerable<CutState> FrozenImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("frozen", args, "@variable", "-goal");
            var variable = Term.Deref(args[0]) as LogicVariable;
            object goal = Symbol.True;
            if (variable != null && variable.MetaBinding is Suspension)
            {
                var suspension = variable.MetaBinding as Suspension;
                if (suspension.FrozenGoal != null)
                    goal = suspension.FrozenGoal;
            }
            return Term.UnifyAndReturnCutState(goal, args[1]);
        }

        private static readonly Symbol SDif = Symbol.Intern("dif");

        private static IEnumerable<CutState> DifImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("dif", args, "term1", "term2");
            List<LogicVariable> vars = null;
            List<object> values = null;
            if (Term.Unifiable(args[0], args[1], ref vars, ref values))
            {
                if (vars == null)
                    // The terms are already equal
                    return FailDriver();
                // Unifying them would require binding a variable; delay this call to Dif on that variable.
                return vars[0].MetaUnify(new Suspension(new Structure(SDif, args), null, context));
            }
            // Nothing can make these terms equal
            return TrueImplementation(null, null);
        }

        private static IEnumerable<CutState> AndImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException(", (and)", args, "goal1", "goal2");
            foreach (var status1 in context.Prove(args[0], "Arguments to , (and) must be valid subgoals."))
            {
                if (status1==CutState.ForceFail)
                {
                    yield return status1;
                    yield break;
                }
                foreach (var status2 in context.Prove(args[1], "Arguments to , (and) must be a valid subgoals."))
                {
                    if (status2 == CutState.ForceFail)
                    {
                        yield return status2;
                        yield break;
                    }
                    yield return CutState.Continue;
                }
            }
        }

        readonly static Symbol IfSymbol = Symbol.Intern("->");
        private static IEnumerable<CutState> OrImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("; (or)", args, "goal1", "goal2");
            var first = Term.Deref(args[0]) as Structure;
            if (first != null && first.IsFunctor(IfSymbol, 2))
                // Kluge
                return IfThenElseImplementation(first.Argument(0), first.Argument(1), Term.Deref(args[1]),
                                                context);
            return RealOrImplementation(args, context);
        }

        private static IEnumerable<CutState> RealOrImplementation(object[] args, PrologContext context)
        {
            foreach (var status1 in context.Prove(args[0], "Arguments to ; (or) must be valid subgoals."))
            {
                if (status1 == CutState.ForceFail)
                {
                    //yield return status1;
                    yield break;
                }
                yield return CutState.Continue;
            }
            foreach (var status2 in context.Prove(args[1], "Arguments to ; (or) must be valid subgoals."))
            {
                if (status2 == CutState.ForceFail)
                {
                    //yield return status2;
                    yield break;
                }
                yield return CutState.Continue;
            }
        }

        private static IEnumerable<CutState> IfThenElseImplementation(object test, object consequent, object alternative, PrologContext context)
        {
#pragma warning disable 414, 168, 219
            // ReSharper disable UnusedVariable
            foreach (var ignore in context.Prove(test, "Arguments to -> must be valid subgoals."))
                // ReSharper restore UnusedVariable
            {
                // ReSharper disable UnusedVariable
                foreach (var ignore2 in context.Prove(consequent, "Arguments to -> must be valid subgoals."))
                    // ReSharper restore UnusedVariable
                {
                    yield return CutState.Continue;
                }
                yield break;
            }
            // ReSharper disable UnusedVariable
            foreach (var ignore in context.Prove(alternative, "Arguments to -> must be valid subgoals."))
                // ReSharper restore UnusedVariable
            {
                yield return CutState.Continue;
            }
#pragma warning restore 414, 168, 219
        }

        private static IEnumerable<CutState> IfThenImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("->", args, "if_condition", "then_result");

#pragma warning disable 414, 168, 219
            // ReSharper disable UnusedVariable
            foreach (var ignore in context.Prove(args[0], "Arguments to -> must be valid subgoals."))
                // ReSharper restore UnusedVariable
            {
                // ReSharper disable UnusedVariable
                foreach (var ignore2 in context.Prove(args[1], "Arguments to -> must be valid subgoals."))
                // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                {
                    yield return CutState.Continue;
                }
                yield break;
            }
        }

        private static IEnumerable<CutState> NotImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1) throw new ArgumentCountException("not", args, "goal");
            LogicVariable v = Term.FindUninstantiatedVariable(args[0]);
            if (v != null)
                throw new InstantiationException(v, "Argument to not must be a ground literal (i.e. contain no unbound variables).");
            IEnumerator<CutState> e =
                context.Prove(args[0], "Argument to not must be a valid term to prove.").GetEnumerator();
            if (!e.MoveNext() || e.Current == CutState.ForceFail)
                yield return CutState.Continue;
        }

        private static IEnumerable<CutState> NotPlusImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1) throw new ArgumentCountException("\\+", args, "goal");
            IEnumerator<CutState> e =
                context.Prove(args[0], "Argument to \\+ must be a valid term to prove.").GetEnumerator();
            if (!e.MoveNext() || e.Current == CutState.ForceFail)
                yield return CutState.Continue;
        }

        private static IEnumerable<CutState> OnceImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1) throw new ArgumentCountException("once", args, "goal");
#pragma warning disable 414, 168, 219
            // ReSharper disable UnusedVariable
            foreach (var ignore in context.Prove(args[0], "Argument to once/1 must be a valid subgoal."))
#pragma warning restore 414, 168, 219
            {
                // ReSharper restore UnusedVariable
                yield return CutState.Continue;
                yield break;
            }
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage",
            "CA2208:InstantiateArgumentExceptionsCorrectly")]
        private static IEnumerable<CutState> MapListImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3)
                throw new ArgumentCountException("maplist", args, "predicate", "list1", "list2");
            object predicate = Term.Deref(args[0]);
            var functor = predicate as Symbol;
            object[] arguments;
            if (functor != null)
            {
                arguments = NoArgs;
            }
            else
            {
                var t = predicate as Structure;
                if (t != null)
                {
                    functor = t.Functor;
                    arguments = t.Arguments;
                }
                else
                    throw new ArgumentTypeException("maplist", "predicate", predicate, typeof (Symbol));
            }
            return MapListInternal(functor, arguments, args[1], args[2], context);
        }

        // ReSharper disable InconsistentNaming
        private static readonly Symbol SX = Symbol.Intern("X");
        private static readonly Symbol SXt = Symbol.Intern("XT");
        private static readonly Symbol SY = Symbol.Intern("Y");
        private static readonly Symbol SYt = Symbol.Intern("YT");
        // ReSharper restore InconsistentNaming
        
        private static IEnumerable<CutState> MapListInternal(Symbol functor, object[] args, object list1, object list2,
                                                             PrologContext context)
        {
            // maplist(_, [], []).
            // ReSharper disable UnusedVariable
#pragma warning disable 414, 168, 219
            foreach (var ignore in Term.Unify(null, list1))
                foreach (var ignore2 in Term.Unify(null, list2))
#pragma warning restore 414, 168, 219
                    // ReSharper restore UnusedVariable
                    yield return CutState.Continue;
            // maplist(P, [X | XT], [Y | YT]) :- call(P, X, Y), maplist(P, XT, YT).
            var x = new LogicVariable(SX);
            var xT = new LogicVariable(SXt);
            var y = new LogicVariable(SY);
            var yT = new LogicVariable(SYt);
            // ReSharper disable UnusedVariable
#pragma warning disable 414, 168, 219
            foreach (var ignore in Term.Unify(list1, new Structure(Symbol.PrologListConstructor, x, xT)))
                foreach (var ignore2 in Term.Unify(list2, new Structure(Symbol.PrologListConstructor, y, yT)))
#pragma warning restore 414, 168, 219
                {
                    // call(P, X, Y)
                    var realArgs = new object[args.Length + 2];
                    args.CopyTo(realArgs, 0);
                    realArgs[realArgs.Length - 2] = x;
                    realArgs[realArgs.Length - 1] = y;
#pragma warning disable 414, 168, 219
                    foreach (
                        var ignore3 in context.KnowledgeBase.Prove(functor, realArgs, context, context.CurrentFrame))
                        // maplist(P, XT, YT)
                        foreach (var ignore4 in MapListInternal(functor, args, xT, yT, context))
#pragma warning restore 414, 168, 219
                            // ReSharper restore UnusedVariable
                            yield return CutState.Continue;
                }
        }

        private static IEnumerable<CutState> FlattenImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2)
                throw new ArgumentCountException("flatten", args, "listoflists", "flatlist");
            return FlattenInternal(args[0], null, args[1]);
        }

        private static readonly Symbol SStack = Symbol.Intern("Stack");

        private static IEnumerable<CutState> FlattenInternal(object list1, object stack, object list2)
        {
            var x = new LogicVariable(SX);
            var xT = new LogicVariable(SXt);
            var s = new LogicVariable(SStack);
            var yT = new LogicVariable(SYt);
            // ReSharper disable once InconsistentNaming
            var xBarXT = new Structure(Symbol.PrologListConstructor, x, xT);
            // flatten([X, XT], S, YT) : list(X), flatten(X, [XT | X], YT).
            // ReSharper disable UnusedVariable
#pragma warning disable 414, 168, 219
            foreach (var ignore in Term.Unify(list1, xBarXT))
                foreach (var ignore2 in ListInternal(x))
                    foreach (
                        var ignore3 in FlattenInternal(x, new Structure(Symbol.PrologListConstructor, xT, stack), list2)
                        )
#pragma warning restore 414, 168, 219
                        yield return CutState.Continue;
            // flatten([X | XT], S, [X|YT]) : constant(X), X \= [], flatten(XT, S, YT).
#pragma warning disable 414, 168, 219
            foreach (var ignore in Term.Unify(list1, xBarXT))
#pragma warning restore 414, 168, 219
            {
                object xValue = x.Value;
                var t = xValue as Structure;
                if (x.IsBound && xValue != null && (t == null || !t.IsFunctor(Symbol.PrologListConstructor, 2)))
                    // It's a constant
#pragma warning disable 414, 168, 219
                    foreach (var ignore2 in Term.Unify(list2, new Structure(Symbol.PrologListConstructor, x, yT)))
                        foreach (var ignore3 in FlattenInternal(xT, stack, yT))
                            yield return CutState.Continue;
            }
            // flatten([], [X | S], YT) :- flatten(X,S, YT).
            foreach (var ignore in Term.Unify(list1, null))
                foreach (var ignore2 in Term.Unify(stack, new Structure(Symbol.PrologListConstructor, x, s)))
                    foreach (var ignore3 in FlattenInternal(x, s, list2))
                        yield return CutState.Continue;
            // flatten([], [], []).
            foreach (var ignore in Term.Unify(list1, null))
                foreach (var ignore2 in Term.Unify(stack, null))
                    foreach (var ignore3 in Term.Unify(list2, null))
                        yield return CutState.Continue;
#pragma warning restore 414, 168, 219
            // ReSharper restore UnusedVariable
        }

        private static IEnumerable<CutState> PrefixImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2)
                throw new ArgumentCountException("prefix", args, "prefix", "list");
            return PrefixInternal(args[0], args[1]);
        }

        private static IEnumerable<CutState> PrefixInternal(object prefix, object list)
        {
            // ReSharper disable UnusedVariable
            // prefix([], _).
#pragma warning disable 414, 168, 219
            foreach (var ignore in Term.Unify(prefix, null))
#pragma warning restore 414, 168, 219
                yield return CutState.Continue;
            // prefix([X|XT], [X | YT]) :- prefix(XT, YT).
            var x = new LogicVariable(SX);
            var xT = new LogicVariable(SXt);
            var yT = new LogicVariable(SYt);
#pragma warning disable 414, 168, 219
            foreach (var ignore in Term.Unify(prefix, new Structure(Symbol.PrologListConstructor, x, xT)))
                foreach (var ignore2 in Term.Unify(list, new Structure(Symbol.PrologListConstructor, x, yT)))
                    foreach (var ignore3 in PrefixInternal(xT, yT))
                        yield return CutState.Continue;
            // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
        }

        private static IEnumerable<CutState> SuffixImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2)
                throw new ArgumentCountException("suffix", args, "suffix", "list");
            return SuffixInternal(args[0], args[1]);
        }

        private static IEnumerable<CutState> SuffixInternal(object suffix, object list)
        {
            // ReSharper disable UnusedVariable
            // suffix(X, X).
#pragma warning disable 414, 168, 219
            foreach (var ignore in Term.Unify(suffix, list))
#pragma warning restore 414, 168, 219
                yield return CutState.Continue;
            // suffix(XT, [X | YT]) :- suffix(XT, YT).
            var x = new LogicVariable(SX);
            var yT = new LogicVariable(SYt);
#pragma warning disable 414, 168, 219
            foreach (var ignore in Term.Unify(list, new Structure(Symbol.PrologListConstructor, x, yT)))
                foreach (var ignore3 in SuffixInternal(suffix, yT))
#pragma warning restore 414, 168, 219
                    // ReSharper restore UnusedVariable
                    yield return CutState.Continue;
        }

        private static IEnumerable<CutState> SelectImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3)
                throw new ArgumentCountException("select", args, "element", "list_with_element",
                                                 "list_without_element");
            return SelectInternal(args[0], args[1], args[2]);
        }

        private static IEnumerable<CutState> SelectInternal(object x, object listWith, object listWithout)
        {
            // ReSharper disable UnusedVariable
            var xT = new LogicVariable(SXt);
            // select(X, [X|XT], XT).
#pragma warning disable 414, 168, 219
            foreach (var ignore in Term.Unify(listWith, new Structure(Symbol.PrologListConstructor, x, xT)))
                foreach (var ignore2 in Term.Unify(listWithout, xT))
#pragma warning restore 414, 168, 219
                    yield return CutState.Continue;
            // select(X, [Y | XT], [Y|YT]) :- select(X, XT, YT).
            var y = new LogicVariable(SY);
            var yT = new LogicVariable(SYt);
#pragma warning disable 414, 168, 219
            foreach (var ignore in Term.Unify(listWith, new Structure(Symbol.PrologListConstructor, y, xT)))
                foreach (var ignore2 in Term.Unify(listWithout, new Structure(Symbol.PrologListConstructor, y, yT)))
                    foreach (var ignore3 in SelectInternal(x, xT, yT))
#pragma warning restore 414, 168, 219
                        yield return CutState.Continue;
            // ReSharper restore UnusedVariable
        }

        private static IEnumerable<CutState> DeleteImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3)
                throw new ArgumentCountException("delete", args, "list", "x", "has_no_xs");
            return DeleteInternal(args[0], args[1], args[2]);
        }

        private static IEnumerable<CutState> DeleteInternal(object list, object x, object hasNoX)
        {
            list = Term.Deref(list);
            var offendingVariable = list as LogicVariable;
            if (offendingVariable != null)
                throw new InstantiationException(offendingVariable, "first argument to delete must be a list");
            // ReSharper disable UnusedVariable
            var xT = new LogicVariable(SXt);
            // delete([X | XT], X, YT) :- delete(XT, X, YT).
#pragma warning disable 414, 168, 219
            foreach (var ignore in Term.Unify(list, new Structure(Symbol.PrologListConstructor, x, xT)))
                foreach (var ignore2 in DeleteInternal(xT, x, hasNoX))
                    yield return CutState.Continue;
#pragma warning restore 414, 168, 219
            // delete([Y | XT], X, [Y | YT]) :- X \= Y, delete(XT, X, YT)
            var y = new LogicVariable(SY);
            var yT = new LogicVariable(SYt);
#pragma warning disable 414, 168, 219
            foreach (var ignore in Term.Unify(list, new Structure(Symbol.PrologListConstructor, y, xT)))
                foreach (var ignore2 in Term.Unify(hasNoX, new Structure(Symbol.PrologListConstructor, y, yT)))
#pragma warning restore 414, 168, 219
                {
                    bool equal = false;
#pragma warning disable 414, 168, 219
                    foreach (var ignore3 in Term.Unify(x, y))
                        equal = true;
                    if (!equal)
                        foreach (var ignore3 in DeleteInternal(xT, x, yT))
                            yield return CutState.Continue;
                }
            // delete([], _, []).
            foreach (var ignore in Term.Unify(list, null))
                foreach (var ignore2 in Term.Unify(hasNoX, null))
#pragma warning restore 414, 168, 219
                    yield return CutState.Continue;
            // ReSharper restore UnusedVariable
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Performance", "CA1804:RemoveUnusedLocals",
            MessageId = "ignore")]
        private static IEnumerable<CutState> FindallImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3) throw new ArgumentCountException("findall", args, "template", "goal", "bag");
            object template = Term.Deref(args[0]);
            //object bag = null;
            var bag = new List<object>();
#pragma warning disable 414, 168, 219
            // ReSharper disable UnusedVariable
            foreach (var ignore in context.Prove(args[1], "goal argument to findall must be a valid Prolog goal."))
            // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
            {
                object instance = Term.CopyInstantiation(template);
                // It's more efficient to build the list here
                // But it returns the answers in the reverse order of an Assert-based implementation
                // Since the ISO compliance suite assumes that order, we'll use it here on the
                // assumption that legacy code might also assume it.
                //bag = new Structure(Symbol.PrologListConstructor, instance, bag);
                bag.Add(instance);
            }
            return Term.UnifyAndReturnCutState(args[2], Prolog.IListToPrologList(bag));
        }

        private static IEnumerable<CutState> SumallImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3) throw new ArgumentCountException("sumall", args, "numberVar", "generator", "sum");
            var numberVar = Term.Deref(args[0]) as LogicVariable;
            if (numberVar == null)
                throw new ArgumentTypeException("sumall", "numberVar", args[0], typeof(LogicVariable));
            //object bag = null;
            double sum = 0;
#pragma warning disable 414, 168, 219
            // ReSharper disable UnusedVariable
            foreach (var ignore in context.Prove(args[1], "goal argument to findall must be a valid Prolog goal."))
            // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
            {
                sum += Convert.ToDouble(numberVar.Value);
            }
            return Term.UnifyAndReturnCutState(args[2], sum);
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Performance", "CA1804:RemoveUnusedLocals",
            MessageId = "ignore")]
        private static IEnumerable<CutState> ArgMaxImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3) throw new ArgumentCountException("arg_min", args, "template", "score", "goal");
            object template = Term.Deref(args[0]);
            object score = Term.Deref(args[1]);
            float bestScore = 0;
            object bestObj = null;
            bool gotOne = false;
#pragma warning disable 414, 168, 219
            // ReSharper disable UnusedVariable
            foreach (var ignore in context.Prove(args[2], "Goal argument to arg_max must be a valid Prolog goal."))
            // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
            {
                float newScore = Convert.ToSingle(Term.Deref(score));
                if (!gotOne || newScore > bestScore)
                {
                    gotOne = true;
                    bestScore = newScore;
                    bestObj = Term.CopyInstantiation(template);
                }
            }
            if (gotOne)
            {
#pragma warning disable 414, 168, 219
                // ReSharper disable UnusedVariable
                foreach (var ignore in Term.Unify(score, bestScore))
                    foreach (var ignore2 in Term.Unify(template, bestObj))
#pragma warning restore 414, 168, 219
                        // ReSharper restore UnusedVariable
                        yield return CutState.Continue;
            }
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Performance", "CA1804:RemoveUnusedLocals",
            MessageId = "ignore")]
        private static IEnumerable<CutState> ArgMinImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3) throw new ArgumentCountException("arg_min", args, "template", "score", "goal");
            object template = Term.Deref(args[0]);
            object score = Term.Deref(args[1]);
            float bestScore = 0;
            object bestObj = null;
            bool gotOne = false;
#pragma warning disable 414, 168, 219
            // ReSharper disable UnusedVariable
            foreach (var ignore in context.Prove(args[2], "Goal argument to arg_min must be a valid Prolog goal."))
            // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
            {
                float newScore = Convert.ToSingle(Term.Deref(score));
                if (!gotOne || newScore < bestScore)
                {
                    gotOne = true;
                    bestScore = newScore;
                    bestObj = Term.CopyInstantiation(template);
                }
            }
            if (gotOne)
            {
#pragma warning disable 414, 168, 219
                // ReSharper disable UnusedVariable
                foreach (var ignore in Term.Unify(score, bestScore))
                    foreach (var ignore2 in Term.Unify(template, bestObj))
                        // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                        yield return CutState.Continue;
            }
        }

        private static IEnumerable<CutState> PropertyImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3)
                throw new ArgumentCountException("property", args, "object", "property_name", "value");
            object objectArg = Term.Deref(args[0]);
            if (objectArg is LogicVariable)
                throw new UninstantiatedVariableException((LogicVariable) args[0],
                                                          "First argument of property/3 must be instantiated to an object from which to get the property value.");
            object nameObject = Term.Deref(args[1]);
            var nameArg = nameObject as string;
            if (nameArg == null)
            {
                var s = nameObject as Symbol;
                if (s == null)
                {
                    var l = nameObject as LogicVariable;
                    if (l == null)
                        throw new ArgumentException(
                            "Second argument (the name of the property to get) must be a string or symbol.");
                    throw new UninstantiatedVariableException(l,
                                                              "Second argument to property/3 must be instantiated to a string or symbol.");
                }
                nameArg = s.Name;
            }
            return Term.UnifyAndReturnCutState(objectArg.GetPropertyOrField(nameArg), args[2]);
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming",
            "CA2204:Literals should be spelled correctly", MessageId = "setproperty")]
        private static IEnumerable<CutState> SetPropertyImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3)
                throw new ArgumentCountException("set_property", args, "object", "property_name", "new_value");
            object objectArg = Term.Deref(args[0]);
            if (objectArg is LogicVariable)
                throw new UninstantiatedVariableException((LogicVariable) args[0],
                                                          "First argument of property/3 must be instantiated to an object from which to get the property value.");
            object nameObject = Term.Deref(args[1]);
            var nameArg = nameObject as string;
            if (nameArg == null)
            {
                var s = nameObject as Symbol;
                if (s == null)
                {
                    var l = nameObject as LogicVariable;
                    if (l == null)
                        throw new ArgumentException(
                            "Second argument (the name of the property to get) must be a string or symbol.");
                    throw new UninstantiatedVariableException(l,
                                                              "Second argument to property/2 must be instantiated to a string or symbol.");
                }
                nameArg = s.Name;
            }
            object newValue = Term.Deref(args[2]);
            var offendingVariable = newValue as LogicVariable;
            if (offendingVariable != null)
                throw new InstantiationException(offendingVariable,
                                                 "New value argument of set_property must be instantiated to a constant.");
            objectArg.SetPropertyOrField(nameArg, newValue);
            yield return CutState.Continue;
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming",
            "CA2204:Literals should be spelled correctly", MessageId = "callmethod")]
        private static IEnumerable<CutState> CallMethodImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3)
                throw new ArgumentCountException("call_method", args, "object", "method_and_argumenbts", "result");
            object objectArg = Term.Deref(args[0]);
            if (objectArg is LogicVariable)
                throw new UninstantiatedVariableException((LogicVariable) args[0],
                                                          "First argument to call_method must be instantiated to an object of which to call the method.");
            Structure method = Term.Structurify(args[1], "Invalid method argument in call_method");
            string nameArg = method.Functor.Name;
            var methodArgs = new object[method.Arguments.Length];
            for (int i = 0; i < methodArgs.Length; i++)
                methodArgs[i] = Term.Deref(method.Arguments[i]);
            return Term.UnifyAndReturnCutState(args[2], objectArg.InvokeMethod(nameArg, methodArgs));
        }

        private static IEnumerable<CutState> DeclareHigherOrderImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1)
                throw new ArgumentCountException("higher_order", args, "*predicate");
            var predicate = Term.Deref(args[0]) as Structure;
            if (predicate == null)
                throw new ArgumentTypeException("higher_order", "predicate", args[0], typeof(Structure));
            var higherOrderArguments = new List<int>();
            for (int argumentIndex=0; argumentIndex<predicate.Arity; argumentIndex++)
            {
                int indicator = Convert.ToInt32(predicate.Argument(argumentIndex));
                if (indicator > 0)
                    higherOrderArguments.Add(argumentIndex);
            }
            context.KnowledgeBase.DeclareHigherOrderArguments(predicate.Functor, predicate.Arity, higherOrderArguments.ToArray());
            yield return CutState.Continue;
        }

        private static PrimitiveImplementation MakeDeclarationPredicate(DeclarationHandler handler)
        {
            return (args, context) => DeclarationDriver(handler, args, context);
        }

        private delegate void DeclarationHandler(Symbol functor, int arity, PrologContext context);

        // ReSharper disable once ParameterTypeCanBeEnumerable.Local
        private static IEnumerable<CutState> DeclarationDriver(DeclarationHandler handler, object[] args,
                                                               PrologContext context)
        {
            foreach (var arg in args)
            {
                object indicator = Term.Deref(arg);
                var t = indicator as Structure;
                if (t != null && t.IsFunctor(Symbol.Comma, 2))
                {
#pragma warning disable 168
                    // ReSharper disable UnusedVariable
                    foreach (var ignore1 in DeclarationDriver(handler, new[] {t.Argument(0)}, context))
                        foreach (var ignore2 in DeclarationDriver(handler, new[] {t.Argument(1)}, context))
                            // ReSharper restore UnusedVariable
#pragma warning restore 168
                            yield return CutState.Continue;
                }
                else if (t != null && t.IsFunctor(Symbol.PrologListConstructor, 2))
                {
                    // List argument
                    while (t != null)
                    {
                        indicator = t.Argument(0);
                        Symbol s = Term.PredicateIndicatorFunctor(indicator);
                        int arity = Term.PredicateIndicatorArity(indicator); 
                        if (s != null)
                            handler(s, arity, context);
                        else
                            throw new ArgumentException("Argument must be a symbol or list of symbols.");
                        object rest = t.Argument(1);
                        if (rest == null)
                            t = null;
                        else
                        {
                            t = rest as Structure;
                            if (t == null || !t.IsFunctor(Symbol.PrologListConstructor, 2))
                                throw new ArgumentException("Argument is an improper list.");
                        }
                    }
                }
                else
                {
                    Symbol s = Term.PredicateIndicatorFunctor(indicator);
                    int arity = Term.PredicateIndicatorArity(indicator);
                    if (s != null)
                    {
                        handler(s, arity, context);
                        yield return CutState.Continue;
                    }
                    else
                        throw new ArgumentException("Argument must be a symbol or list of symbols.");
                }
            }
        }

        private static IEnumerable<CutState> SetPrologFlagImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2)
                throw new ArgumentCountException("set_prolog_flag", args, "flag", "value");

            var flag = Term.Deref(args[0]) as Symbol;
            if (flag == null) throw new ArgumentTypeException("set_prolog_flag", "flag", Term.Deref(args[0]), typeof(Symbol));
            var value = Term.Deref(args[1]) as Symbol;
            if (value == null) throw new ArgumentTypeException("set_prolog_flag", "value", Term.Deref(args[1]), typeof(Symbol));
            switch (flag.Name)
            {
                case "unknown":
                    switch (value.Name)
                    {
                        case "fail":
                        case "warning":
                            KnowledgeBase.ErrorOnUndefined = false;
                            break;

                        case "error":
                            KnowledgeBase.ErrorOnUndefined = true;
                            break;

                        default:
                            throw new ArgumentException(value.Name+" is not an acceptable value for the prolog flag 'unknown'; should be fail or error.");
                    }
                    break;

                default:
                    throw new ArgumentException("Unknown prolog flag: "+flag.Name);
            }
            return TrueImplementation(args, context);
        }

        private static IEnumerable<CutState> CheckImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1)
                throw new ArgumentCountException("check", args, "goal");
            if (context.Prove(args[0], "Goal to check is not a valid Prolog goal.").GetEnumerator().MoveNext())
                yield return CutState.Continue;
            else
                throw new InvalidOperationException("Check failed: "+ ISOPrologWriter.WriteToString(args[0]));
        }

        private static IEnumerable<CutState> RandomizeInternal(KnowledgeBase kb, PrologContext context, Structure t)
        {
            bool savedRandomize = context.Randomize;
            context.Randomize = true;
            foreach (var state in kb.Prove(t.Functor, t.Arguments, context, context.CurrentFrame))
                if (state==CutState.ForceFail)
                    yield break;
                else
                    yield return state;
            context.Randomize = savedRandomize;
        }

        private static IEnumerable<CutState> ConsultImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1) throw new ArgumentCountException("consult", args, "filename");
            var s = args[0] as string;
            if (s != null)
                context.KnowledgeBase.Consult(s);
            else
            {
                var symbol = args[0] as Symbol;
                if (symbol != null)
                    context.KnowledgeBase.Consult(symbol.Name);
                else
                    // ReSharper disable NotResolvedInText
                    throw new ArgumentException("Filename should be a string or symbol.", "filename");
            }
            // ReSharper restore NotResolvedInText
            yield return CutState.Continue;
        }

        private static IEnumerable<CutState> ReconsultImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1) throw new ArgumentCountException("consult", args, "filename");
            var s = args[0] as string;
            if (s != null)
                context.KnowledgeBase.Reconsult(s);
            else
            {
                var symbol = args[0] as Symbol;
                if (symbol != null)
                    context.KnowledgeBase.Reconsult(symbol.Name);
                else
                    // ReSharper disable NotResolvedInText
                    throw new ArgumentException("Filename should be a string or symbol.", "filename");
            }
            // ReSharper restore NotResolvedInText
            yield return CutState.Continue;
        }

        private static IEnumerable<CutState> ListingImplementation(object[] args, PrologContext context)
        {
            switch (args.Length)
            {
                case 0:
                    context.Output.Write(context.KnowledgeBase.Source);
                    break;
                case 1:
                    object indicator = Term.Deref(args[0]);
                    Symbol s = Term.PredicateIndicatorFunctor(indicator);
                    int arity = Term.PredicateIndicatorArity(indicator);
                    if (s == null)
                        throw new ArgumentTypeException("listing", "name", args[0], typeof (Symbol));
                    context.Output.Write(context.KnowledgeBase.SourceFor(s, arity));
                    break;

                default:
                    throw new ArgumentCountException("listing", args, "name");
            }
            yield return CutState.Continue;
        }

        private static IEnumerable<CutState> AssertzImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1) throw new ArgumentCountException("assertz", args, "term");
            if (ELProlog.IsELTerm(args[0]))
                ELProlog.Update(args[0], context);
            else
                context.KnowledgeBase.AssertZ(Term.CopyInstantiation(args[0]));
            return TrueImplementation(args, context);
        }

        private static IEnumerable<CutState> AssertaImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1) throw new ArgumentCountException("asserta", args, "term");
            context.KnowledgeBase.AssertA(Term.CopyInstantiation(args[0]));
            return TrueImplementation(args, context);
        }

        private static IEnumerable<CutState> RetractAllImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1) throw new ArgumentCountException("retractall", args, "head");
            var term = args[0];
            if (ELProlog.IsELTerm(term))
                ELProlog.RetractAll(term, context);
            else
                context.KnowledgeBase.RetractAll(term);
            return SucceedDriver();
        }

        private static IEnumerable<CutState> RetractImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1) throw new ArgumentCountException("retract", args, "term");
            var term = args[0];
            if (ELProlog.IsELTerm(term))
                return ELProlog.Retract(term, context);
            return context.KnowledgeBase.Retract(term);
        }

        private static IEnumerable<CutState> ClauseImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("clause", args, "head", "body");

            object h = Term.Deref(args[0]);
            var v = h as LogicVariable;
            if (v != null)
                throw new InstantiationException(v, "First argument of clause/2 cannot be a variable.");
            Structure head = Term.Structurify(h, "Head argument to clause is not a valid term.");
            if (Implementations.ContainsKey(head.Functor))
                throw new PrologException(new Structure("error",
                                                        new Structure("permission_error", Symbol.Intern("access"),
                                                                      Symbol.Intern("private_procedure"),
                                                                      new Structure("/", head.Functor,
                                                                                    head.Arguments.Length))));
            object body = Term.Deref(args[1]);
            if (!(body is Structure) && !(body is Symbol) && !(body is bool) && !(body is LogicVariable))
                throw new GoalException(body, "Body argument of clause/2 must be a valid goal or a variable:");

            return context.KnowledgeBase.FindClauses(head, body);
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Globalization", "CA1305:SpecifyIFormatProvider",
            MessageId = "System.Convert.ToInt32(System.Object)")]
        private static IEnumerable<CutState> StepLimitImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1) throw new ArgumentCountException("step_limit", args, "max_steps");
            object arg = Term.Deref(args[0]);
            var v = arg as LogicVariable;
            if (v != null)
                return Term.UnifyAndReturnCutState(v, context.StepLimit);
            context.StepLimit = Convert.ToInt32(arg);
            return TrueImplementation(args, context);
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Performance", "CA1804:RemoveUnusedLocals",
            MessageId = "ignore")]
        private static IEnumerable<CutState> BenchmarkImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("benchmark", args, "goal", "count");
            object goal = Term.Deref(args[0]);
            Structure sGoal = Term.Structurify(goal, "Invalid goal.");
            var count = (int) Term.Deref(args[1]);
            for (int i = 0; i < count; i++)
            {
                bool gotOne = false;
                var s = (Structure) Term.CopyInstantiation(sGoal);
#pragma warning disable 414, 168, 219
                // ReSharper disable UnusedVariable
                foreach (
                    var ignore in context.KnowledgeBase.Prove(s.Functor, s.Arguments, context, context.CurrentFrame))
                    // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                    gotOne = true;
                if (!gotOne)
                    throw new ArgumentException("Goal is unsatisfiable.");
            }
            return TrueImplementation(args, context);
        }

        private static IEnumerable<CutState> IsImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("is", args, "-result", "+expression");
            return Term.UnifyAndReturnCutState(args[0], FunctionalExpression.Eval(args[1], context));
        }

        private static IEnumerable<CutState> IsClassImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("is_class", args, "object", "+class");
            object valueArg = Term.Deref(args[0]);
            object typeArg = Term.Deref(args[1]);
            if (typeArg == null) throw new ArgumentNullException("args", "type argument cannot be null.");
            var type = typeArg as Type;
            if (type == null) throw new ArgumentTypeException("is_class", "type", typeArg, typeof (Type));
            var v = valueArg as LogicVariable;
            if (v == null)
            {
                // They're testing an object to see if it's the right type.
                if (type.IsInstanceOfType(valueArg))
                    yield return CutState.Continue;
                else
// ReSharper disable RedundantJumpStatement
                    yield break;
// ReSharper restore RedundantJumpStatement
            }
            else
            {
                if (type.IsSubclassOf(typeof(UnityEngine.Object)))
                    foreach (var o in UnityEngine.Object.FindObjectsOfType(type))
#pragma warning disable 414, 168, 219
                        // ReSharper disable once UnusedVariable
                        foreach (var ignore in v.Unify(o))
#pragma warning restore 414, 168, 219
                            yield return CutState.Continue;
                else
                    // ReSharper disable once NotResolvedInText
                    throw new ArgumentException("Cannot enumerate instances of type " + type.Name, "type");
                // ReSharper restore NotResolvedInText
            }
        }

        private static IEnumerable<CutState> ComponentOfGameObjectWithTypeImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3) throw new ArgumentCountException("component_of_gameobject_with_type", args, "component", "gameobject", "+class");
            object componentArg = Term.Deref(args[0]);
            object gameobjectArg = Term.Deref(args[1]);
            var typeArg = Term.Deref(args[2]);
            var type = typeArg as Type;
            if (type == null) throw new ArgumentTypeException("component_of_gameobject_with_type", "type", typeArg, typeof(Type));
            var v = componentArg as LogicVariable;
            if (v == null)
            {
                // Component is known; solve for the gameobject.
                if (!type.IsInstanceOfType(componentArg))
                    return FailDriver();
                return Term.UnifyAndReturnCutState(((Component)componentArg).gameObject, gameobjectArg);
            }
            var gameObject = gameobjectArg as GameObject;
            if (gameObject != null)
                return EnumerateComponents(v, gameObject, type);
            var gov = gameobjectArg as LogicVariable;
            if (gov != null)
                return EnumerateGameObjectsAndComponents(v, gov, type);
            throw new ArgumentTypeException("component_of_gameobject_with_type", "gameobject", gameobjectArg, typeof(GameObject));
        }

        private static IEnumerable<CutState> EnumerateGameObjectsAndComponents(LogicVariable v, LogicVariable gov, Type type)
        {
            foreach (var component in UnityEngine.Object.FindObjectsOfType(type))
            {
#pragma warning disable 414, 168, 219
                // ReSharper disable UnusedVariable
                foreach (var ignore in v.Unify(component))
                    foreach (var ignore2 in gov.Unify(((Component)component).gameObject))
                        // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                        yield return CutState.Continue;
            }
        }

        private static IEnumerable<CutState> EnumerateComponents(LogicVariable v, GameObject gameObject, Type type)
        {
            foreach (var c in gameObject.GetComponents(type))
            {
#pragma warning disable 414, 168, 219
                // ReSharper disable once UnusedVariable
                foreach (var ignore in v.Unify(c))
#pragma warning restore 414, 168, 219
                    yield return CutState.Continue;
            }
        }


        private static IEnumerable<CutState> EqualsImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("=", args, "term1", "term2");
            return Term.UnifyAndReturnCutState(args[0], args[1]);
        }

        private static readonly Symbol SEquals = Symbol.Intern("=");

        private static IEnumerable<CutState> UnifiableImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3)
                throw new ArgumentCountException("unifiable", args, "term1", "term2", "unifier");
            List<LogicVariable> vars = null;
            List<object> values = null;
            if (!Term.Unifiable(args[0], args[1], ref vars, ref values))
                // Fail
                return FailDriver();
            object unifier = null;
            if (vars != null)
            {
                for (int i = vars.Count - 1; i >= 0; i--)
                    unifier = new Structure(Symbol.PrologListConstructor, new Structure(SEquals, vars[i], values[i]),
                                            unifier);
            }
            return Term.UnifyAndReturnCutState(args[2], unifier);
        }

        private static IEnumerable<CutState> NotEqualsImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("\\=", args, "term1", "term2");
#pragma warning disable 414, 168, 219
            // ReSharper disable UnusedVariable
            foreach (var ignore in Term.Unify(args[0], args[1]))
                // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                yield break;
            yield return CutState.Continue;
        }

        private static IEnumerable<CutState> EquivalentImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("==", args, "term1", "term2");
            return CutStateEnumerator(Term.Identical(args[0], args[1]));
        }

        private static IEnumerable<CutState> NotEquivalentImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("\\==", args, "term1", "term2");
            return Term.Identical(args[0], args[1]) ?  FailDriver() : TrueImplementation(args, context);
        }

        private static IEnumerable<CutState> CopyTermImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("copy_term", args, "original", "copy");
            return Term.UnifyAndReturnCutState(Term.CopyInstantiation(args[0]), args[1]);
        }

        private static IEnumerable<CutState> UnivImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("=..", args, "term", "list");
            object objectArg = Term.Deref(args[0]);
            object listArg = Term.Deref(args[1]);
            if (listArg == null) throw new ArgumentException("List argument may not be empty");
            var l = objectArg as LogicVariable;
            if (l != null)
            {
                var t = listArg as Structure;
                if (t == null)
                {
                    if (listArg is LogicVariable)
                        throw new UninstantiatedVariableException((LogicVariable) args[0],
                                                                  "Cannot perform X =.. Y with both variables uninstantiated.");
                    throw new ArgumentException("Second argument must be a list or uninstantiated variable.");
                }
                // Need to build term from list
                return Term.UnifyAndReturnCutState(l, Structure.FromList(t));
            }
            else
            {
                var t = objectArg as Structure;
                if (t != null)
                    return Term.UnifyAndReturnCutState(t.ToPrologList(), listArg);
                return Term.UnifyAndReturnCutState(new Structure(Symbol.PrologListConstructor, objectArg, null), listArg);
            }
        }

        private static readonly Symbol XSymbol = Symbol.Intern("X");
        private static IEnumerable<CutState> FunctorImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3) throw new ArgumentCountException("functor", args, "term", "functor", "arity");
            object termArg = Term.Deref(args[0]);
            object functorArg = Term.Deref(args[1]);
            object arityArg = Term.Deref(args[2]);
            var l = termArg as LogicVariable;
            if (l != null)
            {
                // have to build term from functor and arity.
                if (arityArg is int)
                {
                    var arity = (int) arityArg;
                    if (arity == 0)
#pragma warning disable 414, 168, 219
                        // ReSharper disable UnusedVariable
                        foreach (var ignore5 in Term.Unify(functorArg, termArg))
                            // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                            yield return CutState.Continue;
                    else if (arity >= 0)
                    {
                        var functor = functorArg as Symbol;
                        if (functor == null)
                        {
                            var fv = functorArg as LogicVariable;
                            if (fv == null)
                                throw new ArgumentTypeException("functor", "functor", functorArg, typeof(Symbol));
                            throw new InstantiationException(fv, "Arguments are insufficiently instantiated.");
                        }
                        var blankArgs = new object[arity];
                        for (int i = 0; i < blankArgs.Length; i++)
                            blankArgs[i] = new LogicVariable(XSymbol);
#pragma warning disable 414, 168, 219
                        // ReSharper disable UnusedVariable
                        foreach (var ignore6 in Term.Unify(termArg, new Structure(functor, blankArgs)))
                            // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                            yield return CutState.Continue;
                    }
                    else throw new IndexOutOfRangeException("Arity must be >= 0");
                }
                else
                {
                    var arg = arityArg as LogicVariable;
                    if (arg != null)
                    {
                        throw new InstantiationException(arg, "Arguments are not sufficiently instantiated");
                    }
                    throw new ArgumentTypeException("functor", "arity", arityArg, typeof(int));
                }
            }
            else
            {
                var s = termArg as Structure;
                if (s == null)
                {
#pragma warning disable 414, 168, 219
                    // ReSharper disable UnusedVariable
                    foreach (var ignore1 in Term.Unify(termArg, functorArg))
                        foreach (var ignore2 in Term.Unify(arityArg, 0))
                            yield return CutState.Continue;
                }
                else
                {
                    // Getting functor and arity from an existing term.
                    foreach (var ignore3 in Term.Unify(functorArg, s.Functor))
                        foreach (var ignore4 in Term.Unify(arityArg, s.Arguments.Length))
                            // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                            yield return CutState.Continue;
                }
            }
        }

        static IEnumerable<CutState> ArgImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3) throw new ArgumentCountException("arg", args, "arg_number", "structure", "arg_value");
            if (!(args[0] is int))
            {
                var v = args[0] as LogicVariable;
                if (v != null)
                    throw new InstantiationException(v, "Argument number must be an integer.");
                throw new ArgumentTypeException("arg", "argument_number", args[0], typeof(int));
            }
            var argNumber = (int) args[0];
            var s = args[1] as Structure;
            if (s == null)
            {
                var v = args[1] as LogicVariable;
                if (v != null)
                    throw new InstantiationException(v, "Structure argument was not instantiated.");
                throw new ArgumentTypeException("arg", "structure", args[1], typeof(Structure));
            }
            if (argNumber < 0)
                throw new IndexOutOfRangeException("The specified argument number is invalid.");
            if (argNumber == 0 || argNumber > s.Arguments.Length)
                return FailDriver();
            return Term.UnifyAndReturnCutState(s.Arguments[argNumber-1], args[2]);
        }

        private static IEnumerable<CutState> ListImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1) throw new ArgumentCountException("list", args, "arg");
            return ListInternal(args[0]);
        }

        private static IEnumerable<CutState> ListInternal(object o)
        {
            o = Term.Deref(o);
#pragma warning disable 414, 168, 219
            // ReSharper disable UnusedVariable
            foreach (var ignore in Term.Unify(o, null))
                yield return CutState.Continue;
            var head = new LogicVariable(SHead);
            var tail = new LogicVariable(STail);
            foreach (var ignore2 in Term.Unify(o, new Structure(Symbol.PrologListConstructor, head, tail)))
                foreach (var ignore3 in ListInternal(tail))
                    // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                    yield return CutState.Continue;
        }

        private static readonly Symbol SElement = Symbol.Intern("E");

        private static IEnumerable<CutState> LengthImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("length", args, "list", "number");
            object numArg = Term.Deref(args[1]);
            object listArg = Term.Deref(args[0]);
            int elementsSeen = 0;
            object currentElement = listArg;
            var currentPair = currentElement as Structure;
            while (currentPair != null)
            {
                if (!currentPair.IsFunctor(Symbol.PrologListConstructor, 2))
                    throw new ArgumentException("The list passed to the length predicate was not a well-formed list.");
                elementsSeen++;
                currentElement = currentPair.Argument(1);
                currentPair = currentElement as Structure;
            }
            // We've gotten to the end of the normal elements.
            if (currentElement == null)
                // It was a real list with all its elements, just return the length
                return Term.UnifyAndReturnCutState(numArg, elementsSeen);
            // It ends with some object that isn't a term structure; hopefully it's a logic variable.
            var l = currentElement as LogicVariable;
            if (l == null)
                throw new ArgumentException("The list passed to the length predicate was not a well-formed list.");
            // It ends with a logic variable.
            if (numArg is int)
            {
                // User is testing to see if the list has a specific length.
                var num = (int) numArg;
                if (num < elementsSeen)
                    // Too many elements.  Fail right now.
                    return FailImplementation;
                // They've specified a length so we need to make the list be that length.
                Structure listTail = null;
                for (int i = elementsSeen; i < num; i++)
                    listTail = new Structure(Symbol.PrologListConstructor, new LogicVariable(SElement), listTail);
                return Term.UnifyAndReturnCutState(l, listTail);
            }
            var numVar = numArg as LogicVariable;
            if (numVar == null)
                throw new ArgumentException(
                    "The length argument of the length predicate must either be an uninstantiated variable or a number.");
            // If we get here, then the user didn't specify a length and only specified a partial list, if anything.
            // So we have to enumerate possible list extensions of the list they specified, and also return the resulting length.
            return EnumerateListExtensions(numVar, elementsSeen, l);
        }

        // Called from Length to generate successively longer tails for the list.
        private static IEnumerable<CutState> EnumerateListExtensions(LogicVariable lengthVar, int elementsProvided,
                                                                     LogicVariable tailVar)
        {
            Structure listTail = null;
            for (int i = elementsProvided;; i++)
            {
#pragma warning disable 414, 168, 219
                // ReSharper disable UnusedVariable
                foreach (var ignore in Term.Unify(lengthVar, i))
                    foreach (var ignore2 in Term.Unify(tailVar, listTail))
                        // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                        yield return CutState.Continue;
                listTail = new Structure(Symbol.PrologListConstructor, new LogicVariable(SElement), listTail);
            }
            // ReSharper disable FunctionNeverReturns
        }

        // ReSharper restore FunctionNeverReturns

        private static readonly Symbol SHead = Symbol.Intern("Head");
        private static readonly Symbol STail = Symbol.Intern("Tail");

        private static IEnumerable<CutState> MemberImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("member", args, "element", "list");
            object objectArg = Term.Deref(args[0]);
            object listArg = Term.Deref(args[1]);
            var iList = listArg as IList;
            if (iList != null)
            {
                var variable = objectArg as LogicVariable;
                if (variable != null)
                    return EnumerateIList(iList, variable);
                // Simple check for whether a known element appears in an IList.
                if (Term.IsGround(objectArg))
                {
                    return CutStateEnumerator(iList.Contains(objectArg));
                }
                throw new ArgumentException("member(o, l) not implemented for non-ground o when l is an IList rather than a Prolog list.");
            }
            return MemberOfPrologList(listArg, objectArg);
        }

        static IEnumerable<CutState> EnumerateIList(IList listArg, LogicVariable objectArg)
        {
            foreach (var e in listArg)
            {
#pragma warning disable 414, 168, 219
                // ReSharper disable once UnusedVariable
                foreach (var ignore in objectArg.Unify(e))
#pragma warning restore 414, 168, 219
                    yield return CutState.Continue;
            }
        }

        private static IEnumerable<CutState> MemberOfPrologList(object listArg, object objectArg)
        {
            while (listArg != null)
            {
                var t = listArg as Structure;
                if (t == null)
                {
                    var l = listArg as LogicVariable;
                    if (l == null)
                    {
                        throw new ArgumentException("List argument is not a proper list");
                    }
                    var tail = new Structure(Symbol.PrologListConstructor, objectArg, new LogicVariable(STail));
                    while (true)
                    {
#pragma warning disable 414, 168, 219
                        // ReSharper disable UnusedVariable
                        foreach (var ignore in Term.Unify(l, tail))
                        {
                            // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                            yield return CutState.Continue;
                        }
                        tail = new Structure(Symbol.PrologListConstructor, new LogicVariable(SElement), tail);
                    }
                    // Loop never exits.
                }
                if (!t.IsFunctor(Symbol.PrologListConstructor, 2))
                {
                    throw new ArgumentException("List argument is not a proper list");
                }
#pragma warning disable 414, 168, 219
                // ReSharper disable UnusedVariable
                foreach (var ignore in Term.Unify(objectArg, t.Arguments[0]))
                {
                    // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                    yield return CutState.Continue;
                }
                listArg = t.Argument(1);
            }
        }

        private static IEnumerable<CutState> MemberChkImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("memberchk", args, "element", "list");
            object objectArg = Term.Deref(args[0]);
            object listArg = Term.Deref(args[1]);
            while (listArg != null)
            {
                var t = listArg as Structure;
                if (t == null)
                {
                    var l = listArg as LogicVariable;
                    if (l == null) throw new ArgumentException("List argument is not a proper list");
                    var tail = new Structure(Symbol.PrologListConstructor, objectArg, new LogicVariable(STail));
#pragma warning disable 414, 168, 219
                    // ReSharper disable UnusedVariable
                    foreach (var ignore in Term.Unify(l, tail))
                        // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                        yield return CutState.Continue;
                    yield break;
                }
                if (!t.IsFunctor(Symbol.PrologListConstructor, 2))
                    throw new ArgumentException("List argument is not a proper list");
#pragma warning disable 414, 168, 219
                // ReSharper disable UnusedVariable
                foreach (var ignore in Term.Unify(objectArg, t.Arguments[0]))
                {
                    // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                    yield return CutState.Continue;
                    // Only returns once
                    yield break;
                }
                listArg = t.Argument(1);
            }
        }

        private static IEnumerable<CutState> AppendImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3)
                throw new ArgumentCountException("append", args, "before_list", "after_list", "combined_list");
            return AppendInternal(args[0], Term.Deref(args[1]), args[2]);
        }

        // Not super efficient, but more efficient than user code.
        private static IEnumerable<CutState> AppendInternal(object before, object after, object together)
        {
            // Base case
#pragma warning disable 414, 168, 219
            // ReSharper disable UnusedVariable
            foreach (var ignore in Term.Unify(before, null))
                foreach (var ignore2 in Term.Unify(after, together))
                    // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                    yield return CutState.Continue;
            // Recursive case
            var elt = new LogicVariable(SElement);
            var beforeTail = new LogicVariable(STail);
            var togetherTail = new LogicVariable(STail);
            var beforePattern = new Structure(Symbol.PrologListConstructor, elt, beforeTail);
            var togetherPattern = new Structure(Symbol.PrologListConstructor, elt, togetherTail);

#pragma warning disable 414, 168, 219
            // ReSharper disable UnusedVariable
            foreach (var ignore in Term.Unify(before, beforePattern))
                foreach (var ignore2 in Term.Unify(together, togetherPattern))
                    foreach (var ignore3 in AppendInternal(beforeTail, after, togetherTail))
                        // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                        yield return CutState.Continue;
        }

        static IEnumerable<CutState>  ReverseImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2)
                throw new ArgumentCountException("reverse", args, "forward_list", "backward_list");
            return ReverseAppend(args[0], null, Term.Deref(args[1]));
        }

        static IEnumerable<CutState>  ReverseAppend(object before, object after, object together)
        {
            // Base case
#pragma warning disable 414, 168, 219
            // ReSharper disable UnusedVariable
            foreach (var ignore in Term.Unify(before, null))
                foreach (var ignore2 in Term.Unify(after, together))
                    // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                    yield return CutState.Continue;
            // Recursive case
            var elt = new LogicVariable(SElement);
            var beforeTail = new LogicVariable(STail);
            var beforePattern = new Structure(Symbol.PrologListConstructor, elt, beforeTail);
            var afterPattern = new Structure(Symbol.PrologListConstructor, elt, after);

#pragma warning disable 414, 168, 219
            // ReSharper disable UnusedVariable
            foreach (var ignore in Term.Unify(before, beforePattern))
                    foreach (var ignore2 in ReverseAppend(beforeTail, afterPattern, together))
                        // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                        yield return CutState.Continue;            
        }

        private static PrimitiveImplementation MakeComparisonPredicate(string name,
                                                                       Func<double, double, bool> comparison)
        {
            return ((args, context) => ComparisonPredicateDriver(name, context, comparison, args));
        }

        private static IEnumerable<CutState> ComparisonPredicateDriver(string name,
                                                                       PrologContext context,
                                                                       Func<double, double, bool> comparison,
                                                                       object[] args)
        {
            if (args.Length != 2) throw new ArgumentCountException(name, args, "+expression1", "+expression2");
            if (comparison(Convert.ToDouble(FunctionalExpression.Eval(args[0], context)), Convert.ToDouble(FunctionalExpression.Eval(args[1], context))))
                yield return CutState.Continue;
        }




        // NEW STUFF
        private static PrimitiveImplementation MakeTermComparisonPredicate(string name,
                                                                               Func<int, bool> comparison)
        {
            return ((args, context) => TermComparisonPredicateDriver(name, comparison, args));
        }

        private static IEnumerable<CutState> TermComparisonPredicateDriver(string name,
                                                                       Func<int, bool> test,
                                                                       object[] args)
        {
            if (args.Length != 2) throw new ArgumentCountException(name, args, "+expression1", "+expression2");
            if (test(Term.Compare(args[0], args[1])))
                yield return CutState.Continue;
        }





        private static PrimitiveImplementation MakeNullFailingTypePredicate(string name, Func<object, bool> predicate)
        {
            return ((args, context) => NullFailingTypePredicateDriver(name, predicate, args));
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Globalization", "CA1305:SpecifyIFormatProvider",
            MessageId = "System.String.Format(System.String,System.Object)"),
         System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Globalization", "CA1305:SpecifyIFormatProvider",
             MessageId = "System.String.Format(System.String,System.Object[])")]
        private static IEnumerable<CutState> NullFailingTypePredicateDriver(string name, Func<object, bool> predicate,
                                                                            object[] args)
        {
            if (args.Length != 1) throw new ArgumentCountException(name, args, "+object");
            object arg = Term.Deref(args[0]);
            //if (arg is LogicVariable)
            //    throw new UninstantiatedVariableException((LogicVariable) args[0], "Argument must be bound to value.");
            return CutStateEnumerator(arg != null && predicate(arg));
        }

        private static PrimitiveImplementation MakeNullTestingTypePredicate(string name, Func<object, bool> predicate)
        {
            return ((args, context) => NullTestingTypePredicateDriver(name, predicate, args));
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Globalization", "CA1305:SpecifyIFormatProvider",
            MessageId = "System.String.Format(System.String,System.Object)"),
         System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Globalization", "CA1305:SpecifyIFormatProvider",
             MessageId = "System.String.Format(System.String,System.Object[])")]
        private static IEnumerable<CutState> NullTestingTypePredicateDriver(string name, Func<object, bool> predicate,
                                                                            object[] args)
        {
            if (args.Length != 1) throw new ArgumentCountException(name, args, "+object");
            object arg = Term.Deref(args[0]);
            if (arg is LogicVariable)
                //throw new UninstantiatedVariableException((LogicVariable) args[0], "Argument must be bound to value.");
                return FailImplementation;
            return CutStateEnumerator(predicate(arg));
        }

        internal static IEnumerable<CutState> FailDriver()
        {
            yield break;
        }

        internal static IEnumerable<CutState> SucceedDriver()
        {
            yield return CutState.Continue;
        }

        internal static IEnumerable<CutState> FailImplementation = FailDriver();

        internal static IEnumerable<CutState> TrueImplementation(object[] args, PrologContext context)
        {
            return SucceedDriver();
        }

        internal static IEnumerable<CutState> RepeatImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 0) throw new ArgumentCountException("repeat", args);
            while (true)
                yield return CutState.Continue;
        }

        /// <summary>
        /// The 'C' primitive used in definite clause grammars.
        /// </summary>
        private static IEnumerable<CutState> CPrimitiveImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3)
                throw new ArgumentCountException("C", args, "list", "word", "list_tail");
            return Term.UnifyAndReturnCutState(args[0], new Structure(Symbol.PrologListConstructor, args[1], args[2]));
        }

        private static IEnumerable<CutState> WordListImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException("word_list", args, "string", "list_of_words");
            object arg0 = Term.Deref(args[0]);
            var s = arg0 as string;
            if (s == null)
            {
                object arg1 = Term.Deref(args[1]);
                if (arg1 == null)
                    return Term.UnifyAndReturnCutState(arg0, "");
                var t = arg1 as Structure;
                if (t != null && t.IsFunctor(Symbol.PrologListConstructor, 2))
                    return Term.UnifyAndReturnCutState(arg0, Prolog.WordListToString(t));
                throw new ArgumentException(
                    "First argument must be a string (or uninstantiated) and second argument must be a list of words (or uninstantiated).");
            }
            return Term.UnifyAndReturnCutState(Prolog.StringToWordList(s), args[1]);
        }

        private static IEnumerable<CutState> StringRepresentationImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2)
                throw new ArgumentCountException("string_representation", args, "object", "string");
            object objectArg = Term.Deref(args[0]);
            object stringArg = Term.Deref(args[1]);
            LogicVariable objectVar = (objectArg != null) ? (objectArg as LogicVariable) : null;
            var stringVar = stringArg as LogicVariable;
            if (objectVar != null)
            {
                // Object unbound - need to parse string.
                if (stringVar == null)
                    return Term.UnifyAndReturnCutState(objectVar,
                                                       ISOPrologReader.Read(stringArg as string));
                return Term.UnifyAndReturnCutState(Term.ToStringInPrologFormat(objectArg), stringVar);
            }
            return Term.UnifyAndReturnCutState(Term.ToStringInPrologFormat(objectArg), stringArg);
        }

        private static IEnumerable<CutState> WriteImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1)
                throw new ArgumentCountException("write", args, "object");
            context.Output.Write(Term.ToStringInPrologFormat(args[0]));
            yield return CutState.Continue;
        }

        private static IEnumerable<CutState> WritelnImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1)
                throw new ArgumentCountException("writeln", args, "object");
            context.Output.WriteLine(Term.ToStringInPrologFormat(args[0]));
            yield return CutState.Continue;
        }

        // ReSharper disable once InconsistentNaming
        private static IEnumerable<CutState> NLImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 0)
                throw new ArgumentCountException("nl", args);
            context.Output.WriteLine();
            yield return CutState.Continue;
        }

        private static IEnumerable<CutState> DeclareOperator(object[] args, PrologContext context)
        {
            if (args.Length != 3)
                throw new ArgumentCountException("op", args, "priority", "type", "operator");
            if (!(args[0] is int))
                throw new ArgumentTypeException("op", "priority", args[0], typeof (int));
            if (!(args[1] is Symbol))
                throw new ArgumentTypeException("op", "type", args[1], typeof (Symbol));
            if (!(args[2] is Symbol))
                throw new ArgumentTypeException("op", "operator", args[2], typeof (Symbol));
            ISOPrologReader.DeclareOperator((int) args[0], (Symbol) args[1], (Symbol) args[2]);
            yield return CutState.Continue;
        }

        private static IEnumerable<CutState> OpenImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 3)
                throw new ArgumentCountException("open", args, "path", "mode", "stream");
            object p = Term.Deref(args[0]);
            var path = p as string;
            if (path == null)
            {
                var s = p as Symbol;
                if (s == null)
                    throw new ArgumentTypeException("open", "path", args[0], typeof(string));
                path = s.Name;
            }
            var mode = Term.Deref(args[1]) as Symbol;
            if (mode == null) throw new ArgumentTypeException("open", "mode", args[1], typeof (Symbol));
            FileMode m;
            switch (mode.Name)
            {
                case "read":
                    m = FileMode.Open;
                    break;

                case "write":
                    m = FileMode.Create;
                    break;

                default:
                    throw new ArgumentException("Invalid file mode: " + mode.Name);
            }
            FileStream stream = File.Open(path, m);
#pragma warning disable 414, 168, 219
            // ReSharper disable UnusedVariable
            foreach (var ignore in Term.Unify(args[2], (m==FileMode.Open)?new ISOPrologReader(new StreamReader(stream)):((object)new StreamWriter(stream))))
                // ReSharper restore UnusedVariable
#pragma warning restore 414, 168, 219
                yield return CutState.Continue;
            stream.Close();
        }

        private static IEnumerable<CutState> CloseImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 1)
                throw new ArgumentCountException("close", args, "stream");
            var s = Term.Deref(args[0]) as ISOPrologReader;
            if (s == null) throw new ArgumentTypeException("close", "stream", args[0], typeof(ISOPrologReader));
            s.Close();
            return TrueImplementation(args, context);
        }

        private static IEnumerable<CutState> ReadImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2)
                throw new ArgumentCountException("read", args, "stream", "term");
            var s = Term.Deref(args[0]) as ISOPrologReader;
            if (s == null) throw new ArgumentTypeException("close", "stream", args[0], typeof (ISOPrologReader));
            //ISOPrologReader pr = new ISOPrologReader(s, context.Environment);
            object term = s.ReadTerm();
            return Term.UnifyAndReturnCutState(args[1], term);
        }

        private static IEnumerable<CutState> ELNonExclusiveQueryImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException(ELProlog.NonExclusiveOperator, args, "parent_expression", "key");
            ELNode node;
            ELNodeEnumerator enumerator;
            if (ELProlog.TryQuery(out node, out enumerator, Term.Deref(args[0]), Term.Deref(args[1]), false, context))
            {
                if (node != null)
                    yield return CutState.Continue;
                else
                {
                    while (enumerator.MoveNext())
                        yield return CutState.Continue;
                }
            }
        }

        private static IEnumerable<CutState> ELExclusiveQueryImplementation(object[] args, PrologContext context)
        {
            if (args.Length != 2) throw new ArgumentCountException(ELProlog.ExclusiveOperator, args, "parent_expression", "key");
            ELNode node;
            ELNodeEnumerator enumerator;
            var tryQuery = ELProlog.TryQuery(out node, out enumerator, Term.Deref(args[0]), Term.Deref(args[1]), true, context);
            if (tryQuery)
            {
                if (node != null)
                    yield return CutState.Continue;
                else
                {
                    while (tryQuery && enumerator.MoveNext())
                        yield return CutState.Continue;
                }
            }
        } 
        #endregion

        #region Utilities

        static IEnumerable<CutState> CutStateEnumerator(bool truthValue)
        {
            return truthValue ? TrueImplementation(null, null) : FailDriver();
        }
        #endregion
    }
}
