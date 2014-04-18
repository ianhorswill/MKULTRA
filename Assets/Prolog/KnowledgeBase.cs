using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;

using UnityEngine;

namespace Prolog
{
    internal enum CutState { ForceFail, Continue };

    /// <summary>
    /// Stores a collection of KnowledgeBaseEntries, indexed by predicate functor.
    /// </summary>
    [DebuggerDisplay("KnowledgeBase {Name}"),System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1702:CompoundWordsShouldBeCasedCorrectly", MessageId = "KnowledgeBase")]
    public sealed class KnowledgeBase
    {
        #region Global KB
        /// <summary>
        /// Global KB that other KBs inherit from.
        /// </summary>
        [Documentation("Global KB that other KBs inherit from.")]
        public static KnowledgeBase Global { get; private set; }
        #endregion

        #region Constructors
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Performance", "CA1810:InitializeReferenceTypeStaticFieldsInline")]
        static KnowledgeBase()
        {
            Global = new KnowledgeBase("global", null, null);
            PrologPrimitives.InstallPrimitives();
        }

        /// <summary>
        /// Creates a new KB that inherits from the global knowledgebase.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "KBs")]
        [Documentation("Creates a new KB that inherits from the global knowledgebase.")]
        public KnowledgeBase(string kbName, GameObject gameObject)
            : this(kbName, gameObject, Global)
        { }

        /// <summary>
        /// Creates a new KB that inherits from the specified KBs.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "KBs")]
        [Documentation("Creates a new KB that inherits from the specified KBs.")]
        public KnowledgeBase(string kbName, GameObject gameObject, KnowledgeBase parent, params KnowledgeBase[] otherImports)
        {
            if (kbName == null) throw new ArgumentNullException("kbName");
            Name = kbName;
            this.Parent = parent;
            this.GameObject = gameObject;
            this.ELRoot = new ELNode(null, Symbol.Intern("root"));
            //if (parent == null) throw new ArgumentNullException("parent");
            if (otherImports == null) throw new ArgumentNullException("otherImports");
            foreach (var import in otherImports)
                if (import == null) throw new ArgumentNullException("otherImports");
            if (parent != null)
                imports.Add(parent);
            imports.AddRange(otherImports);
        }
        #endregion

        #region Fields and properties

        public readonly KnowledgeBase Parent;

        public readonly GameObject GameObject;

        public readonly ELNode ELRoot;

        readonly SourceFileTracker sourceFiles = new SourceFileTracker();
        
        /// <summary>
        /// The actual database of KnowledgeBaseEntry objects, indexed by functor
        /// </summary>
        readonly Dictionary<Symbol, PredicateInfo[]> db = new Dictionary<Symbol, PredicateInfo[]>();

        /// <summary>
        /// List of other knowledge bases this KB should consult when trying to prove goals
        /// </summary>
        readonly List<KnowledgeBase> imports = new List<KnowledgeBase>();

        /// <summary>
        /// Generate debugging output when set
        /// </summary>
        public bool Trace { get; set; }

        /// <summary>
        /// Name (for debugging purposes)
        /// </summary>
        public string Name { get; private set; }
        #endregion

        public override string ToString()
        {
            return string.Format("<KnowledgeBase {0}>", Name);
        }

        #region Proving goals
        /// <summary>
        /// Attempts to prove the specified goal.
        /// WARNING: THIS WILL LEAK A PROLOG CONTEXT UNLESS ENUMERATED TO COMPLETION.
        /// </summary>
        internal IEnumerable<bool> Prove(Structure t)
        {
            var prologContext = PrologContext.GetFreePrologContext(this, null);
            var enumerator = Prove(t.Functor, t.Arguments, prologContext, 0).GetEnumerator();
            bool done = false;
            while (!done)
            {
                try
                {
                    done = !enumerator.MoveNext() || enumerator.Current == CutState.ForceFail;
                }
                catch
                {
                    PrologContext.LastExceptionContext = prologContext;
                    throw;
                }
                if (!done)
                    yield return false;
            }
            PrologContext.ReleaseContext(prologContext);
        }

        /// <summary>
        /// True if the specified goal is provable within this KnowledgeBase.
        /// </summary>
        /// <param name="goal">Goal to attempt to prove</param>
        /// <param name="thisValue">The value to give ot the $this indexical while running the goal</param>
        /// <returns>Success</returns>
        public bool IsTrue(object goal, object thisValue=null)
        {
            var t = Term.Structurify(goal, "Argument to IsTrue() should be a valid Prolog goal.");
            var prologContext = PrologContext.GetFreePrologContext(this, thisValue);
            var result = Prove(t.Functor, t.Arguments, prologContext, 0).GetEnumerator().MoveNext();
            PrologContext.ReleaseContext(prologContext);
            return result;
        }

        /// <summary>
        /// True if the specified goal is provable within this KnowledgeBase.
        /// </summary>
        /// <param name="result">Value of variable to return</param>
        /// <param name="goal">Goal to attempt to prove</param>
        /// <param name="throwOnFailure">If true, SolveFor will throw a GoalException if the goal fails</param>
        /// <param name="thisValue">Value to give ot the indexical $this during execution</param>
        /// <returns>Success</returns>
        public object SolveFor(LogicVariable result, object goal, object thisValue, bool throwOnFailure = true)
        {
            if (this.IsTrue(Term.Structurify(goal, "Argument to SolveFor() should be a valid Prolog goal."), thisValue))
                return Term.CopyInstantiation(result);
            if (throwOnFailure)
                throw new GoalException(goal, "Goal is unsatisfiable");
            return null;
        }

        /// <summary>
        /// Attempts to prove the specified goal.
        /// </summary>
        internal IEnumerable<CutState> Prove(Symbol functor, object[] args, PrologContext context, ushort parentFrame)
        {
            context.PushGoalStack(functor, args, parentFrame);
            context.NewStep();
            PrologPrimitives.PrimitiveImplementation prim;
            if (PrologPrimitives.Implementations.TryGetValue(functor, out prim))
            {
                return CallPrimitive(functor, prim, args, context);
            }
            return ProveFromDB(functor, args, context);
        }

        IEnumerable<CutState> CallPrimitive(Symbol functor, PrologPrimitives.PrimitiveImplementation handler, object[] args, PrologContext context)
        {
            if (Trace)
                context.TraceOutput("Goal: {0}", new Structure(functor, args));
            foreach (var state in handler(args, context))
            {
                if (Trace)
                context.TraceOutput((state == CutState.Continue) ? "Succeed: {0}" : "Cut: {0}", new Structure(functor, args));
                yield return state;
                if (Trace) 
                    context.TraceOutput("Retry: {0}", new Structure(functor, args));
            }
            if (Trace)
                context.TraceOutput("Fail: {0}", new Structure(functor, args));
            context.PopGoalStack();
        }

        internal static bool ErrorOnUndefined = true;
        IEnumerable<CutState> ProveFromDB(Symbol functor, object[] args, PrologContext context)
        {
            ushort myFrame = context.PushClause();
            PredicateInfo info = GetPredicateInfo(this, functor, args.Length);
            if (info == null)
            {
                if (ErrorOnUndefined)
                    throw new UndefinedPredicateException(functor, args.Length);
                return PrologPrimitives.FailImplementation;
            }
            return info.Prove(args, context, myFrame);
        }
        #endregion
        
        #region Database search
        /// <summary>
        /// True if the specified functor/arity is undefined.
        /// </summary>
        public bool Undefined(Symbol functor, int arity)
        {
            if (PrologPrimitives.IsDefined(functor, arity))
                return false;
            if (CheckForPredicateInfoInThisKB(functor, arity) != null)
                return false;
            foreach (KnowledgeBase import in imports)
                if (!import.Undefined(functor, arity))
                    return false;
            return true;
        }

        static PredicateInfo GetPredicateInfo(KnowledgeBase kb, Symbol functor, int arity)
        {
            PredicateInfo result;
            if ((result = kb.CheckForPredicateInfoInThisKB(functor, arity)) != null)
                return result;
            foreach (KnowledgeBase import in kb.imports)
                if ((result = GetPredicateInfo(import, functor, arity)) != null)
                    return result;
            return null;
        }

        PredicateInfo CheckForPredicateInfoInThisKB(Symbol functor, int arity)
        {
            PredicateInfo[] entries;
            if (!db.TryGetValue(functor, out entries))
                return null;
            if (arity+1 > entries.Length)
                return null;
            return entries[arity];
        }

        internal PredicateInfo CheckForPredicateInfo(Symbol functor, int arity)
        {
            PredicateInfo info = CheckForPredicateInfoInThisKB(functor, arity);
            if (info != null)
                return info;
            foreach (KnowledgeBase import in imports)
                if ((info = import.CheckForPredicateInfo(functor, arity)) != null)
                    return info;
            return null;
        }

        internal PredicateInfo EntryForStoring(Symbol functor, int arity)
        {
            PredicateInfo[] entries;
            if (!db.TryGetValue(functor, out entries))
            {
                db[functor] = entries = new PredicateInfo[arity+1];
            }
            else if (arity+1>entries.Length)
            {
                var newEntries = new PredicateInfo[arity+1];
                entries.CopyTo(newEntries, 0);
                db[functor] = entries = newEntries;
            }
            return entries[arity] ?? (entries[arity] = new PredicateInfo(functor, arity, this));
        }

        internal List<KnowledgeBaseEntry> EntryListForStoring(Symbol functor, int arity)
        {
            return EntryForStoring(functor, arity).Entries;
        }

        internal IEnumerable<CutState> FindClauses(Structure head, object body)
        {
            PredicateInfo i = CheckForPredicateInfo(head.Functor, head.Arguments.Length);
            return (i==null)?PrologPrimitives.FailDriver():i.FindClauses(head, body);
        }

        /// <summary>
        /// Walk through all the rules of all the predicates defined in this KB.
        /// </summary>
        internal IEnumerable<KnowledgeBaseRule> Rules
        {
            get
            {
                foreach (var pair in db)
                    foreach (PredicateInfo info in pair.Value)
                        if (info != null && info.Entries != null)
                            foreach (var kbEntry in info.Entries)
                            {
                                var rule = kbEntry as KnowledgeBaseRule;
                                if (rule != null)
                                    yield return rule;
                            }
            }
        }

        /// <summary>
        /// Walk through all the predicates defined in this KB.
        /// </summary>
        internal IEnumerable<PredicateInfo> Predicates
        {
            get
            {
                foreach (var pair in db)
                    foreach (PredicateInfo info in pair.Value)
                        yield return info;
            }
        }

        #endregion

        #region Database modification
        /// <summary>
        /// Add a term (fact or rule) to the KB.
        /// </summary>
        public void Assert(Structure structure, bool atEnd, bool checkSingletons)
        {
            if (structure == null) throw new ArgumentNullException("structure", "Term to add to KB may not be null.");
            //structure = structure.Expand();

            if (structure == null) throw new ArgumentNullException("structure");
            Structure head = structure.IsFunctor(Symbol.Implication, 2)
                                 ? Term.Structurify(structure.Argument(0),
                                                    "Head of :- must be a valid proposition or predicate.")
                                 : structure;
            if (PrologPrimitives.Implementations.ContainsKey(head.Functor))
                throw new PrologException(new Structure("error",
                                                        new Structure("permission_error", Symbol.Intern("modify"),
                                                                      Symbol.Intern("static_procedure"),
                                                                      Term.PredicateIndicator(head))));

            KnowledgeBaseRule assertion = KnowledgeBaseRule.FromTerm(structure, checkSingletons, Prolog.CurrentSourceFile, Prolog.CurrentSourceLineNumber);
            PredicateInfo info = EntryForStoring(head.Functor, head.Arguments.Length);
            PredicateInfo parentInfo;
            if (!info.Shadow
                && this.Parent != null
                && (parentInfo = this.Parent.CheckForPredicateInfoInThisKB(head.Functor, head.Arguments.Length)) != null
                && !parentInfo.External)
                throw new PrologException(new Structure("error",
                                                        new Structure("permission_error",
                                                                      Symbol.Intern("shadow"),
                                                                      Term.PredicateIndicator(head))));

            info.Assert(assertion, atEnd);
        }

        /// <summary>
        /// Add a term (fact or rule) to the KB.
        /// </summary>
        public void Assert(object term, bool atEnd, bool checkSingletons)
        {
            if (term == null)
                throw new ArgumentNullException("term", "Term to assert in KB cannot be null.");
            Assert(Term.Structurify(term, "Assertion is not a valid proposition or predicate."), atEnd, checkSingletons);
        }

        /// <summary>
        /// Add a term (fact or rule) to the KB.
        /// </summary>
        public void AssertZ(Structure structure)
        {
            Assert(structure, true, false);
        }

        /// <summary>
        /// Add a term (fact or rule) to the KB.
        /// </summary>
        public void AssertZ(object term)
        {   
            Assert(term, true, false);
        }

        /// <summary>
        /// Add a term (fact or rule) to the KB.
        /// </summary>
        public void AssertA(Structure structure)
        {
            Assert(structure, false, false);
        }

        /// <summary>
        /// Add a term (fact or rule) to the KB.
        /// </summary>
        public void AssertA(object term)
        {
            
            Assert(term, false, false);
        }

        /// <summary>
        /// Remove all terms matching head
        /// </summary>
        public void RetractAll(Structure head)
        {
            EntryForStoring(head.Functor, head.Arguments.Length).RetractAll(head);
        }

        /// <summary>
        /// Remove a term from the KB.
        /// </summary>
        public void RetractAll(object term)
        {
            if (term == null)
                throw new ArgumentNullException("term", "Term to retract cannot be null.");
            RetractAll(Term.Structurify(term, "Fact is not a valid proposition or predicate."));
        }

        internal IEnumerable<CutState> Retract(Structure head, object body)
        {
            return EntryForStoring(head.Functor, head.Arguments.Length).Retract(head, body);
        }

        internal IEnumerable<CutState> Retract(object term)
        {
            Structure head = Term.Structurify(term, "Argument to retract must be a valid term.");
            object body = Symbol.True;
            if (head.IsFunctor(Symbol.Implication, 2))
            {
                body = head.Argument(1);
                head = Term.Structurify(head.Argument(0), "Invalid clause head.");
            }
            return Retract(head, body);
        }


        /// <summary>
        /// Erases the complete contents of the KB
        /// </summary>
        public void Clear()
        {
            db.Clear();
        }

        /// <summary>
        /// Erases all entries for the specified predicate.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "functor")]
        public void Forget(Symbol functor, int arity)
        {
            EntryListForStoring(functor, arity).Clear();
        }

        /// <summary>
        /// Declares that this predicate is randomizable.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "functor"), System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "Randomizable")]
        public void DeclareRandomizable(Symbol functor, int arity)
        {
            EntryForStoring(functor, arity).Randomizable = true;
        }

        /// <summary>
        /// Declares that rules for this predicate within this KB are allowed and override those in the parent KB.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "functor"), System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "Randomizable")]
        public void DeclareShadow(Symbol functor, int arity)
        {
            EntryForStoring(functor, arity).Shadow = true;
        }

        /// <summary>
        /// Declares that this predicate is either optional or is defined in another KB.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "functor"), System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "Randomizable")]
        public void DeclareExternal(Symbol functor, int arity)
        {
            EntryForStoring(functor, arity).External = true;
        }

        /// <summary>
        /// Declares that this predicate is called from outside, so don't generate unreferenced predicate warnings.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "functor"), System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "Randomizable")]
        public void DeclarePublic(Symbol functor, int arity)
        {
            EntryForStoring(functor, arity).Public = true;
        }

        /// <summary>
        /// Declares that this predicate may call its arguments.  Used by the static checker to help filter out unreferenced predicates.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "functor"), System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "Randomizable")]
        public void DeclareHigherOrderArguments(Symbol functor, int arity, int[] arguments)
        {
            foreach (var i in arguments)
                if (i>=arity)
                    throw new ArgumentException("Argument index larger than arity of predicate: "+i);
                else if (i < 0)
                    throw new ArgumentException("Argument index cannot be less than zero: " + i);
            EntryForStoring(functor, arity).HigherOrderArguments = arguments;
        }

        /// <summary>
        /// Declares that this predicate is randomizable.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "functor")]
        public void DeclareTraced(Symbol functor, int arity)
        {
            if (CheckForPredicateInfoInThisKB(functor, arity) != null)
                EntryForStoring(functor, arity).Trace = true;
            else if (this.Parent != null)
                this.Parent.DeclareTraced(functor, arity);
            else
                throw new UndefinedPredicateException(functor, arity);
        }

        /// <summary>
        /// Declares that this predicate is randomizable.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "functor")]
        public void DeclareUntraced(Symbol functor, int arity)
        {
            if (CheckForPredicateInfoInThisKB(functor, arity) != null)
                EntryForStoring(functor, arity).Trace = false;
            else if (this.Parent != null)
                throw new UndefinedPredicateException(functor, arity);
        }
        #endregion

        #region Predicate compilation and disassembly
        /// <summary>
        /// Compiles the predicate
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "functor"), System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "Randomizable")]
        public void Compile(Symbol functor, int arity)
        {
            EntryForStoring(functor, arity).Compile();
        }

        /// <summary>
        /// Disassembles the copmiled code of the predicate
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "functor"), System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "Randomizable")]
        public void Disassemble(Symbol functor, int arity)
        {
            EntryForStoring(functor, arity).Disassemble();
        }
        #endregion

        #region Consult and reconsult
        /// <summary>
        /// Load assertions into the KB, erasing any previous assertions under their functors.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "Reconsult")]
        public void ReconsultString(string text)
        {
            using (var sr = new StringReader(text))
            {
                string saveFileName = Prolog.CurrentSourceFile;
                int savedLineNumber = Prolog.CurrentSourceLineNumber;
                try
                {
                    Prolog.CurrentSourceFile = null;
                    Prolog.CurrentSourceLineNumber = 0;
                    Reconsult(sr);
                }
                finally
                {
                    Prolog.CurrentSourceFile = saveFileName;
                    Prolog.CurrentSourceLineNumber = savedLineNumber;
                }
            }
        }

        /// <summary>
        /// Load assertions into the KB, erasing any previous assertions under their functors.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "Reconsult")]
        public void Reconsult(string path)
        {
            path = Prolog.LoadFilePath(path);
            using (var stream = File.OpenText(path))
            {
                string savedFileName = Prolog.CurrentSourceFile;
                int savedLineNumber = Prolog.CurrentSourceLineNumber;
                try
                {
                    Prolog.CurrentSourceFile = path;
                    Prolog.CurrentSourceLineNumber = 0;
                    Reconsult(new PositionTrackingTextReader(stream, path));
                }
                finally
                {
                    Prolog.CurrentSourceFile = savedFileName;
                    Prolog.CurrentSourceLineNumber = savedLineNumber;
                }
            }
        }

        /// <summary>
        /// Load assertions into the KB, erasing any previous assertions under their functors.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "Reconsult")]
        public void Reconsult(Stream stream)
        {
            Reconsult(new StreamReader(stream));
        }

        /// <summary>
        /// Load assertions into the KB, erasing any previous assertions under their functors.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "Reconsult")]
        public void Reconsult(TextReader inStream)
        {
            if (sourceFiles.Contains(Prolog.CurrentSourceFile))
            {
                // Remove any clauses asserted previously by this file.
                if (Prolog.CurrentSourceFile != null)
                    foreach (var pair in db)
                        foreach (var info in pair.Value)
                            if (info != null)
                                info.Entries.RemoveAll(kbe => kbe.SourceFile == Prolog.CurrentSourceFile);
            }

            Consult(inStream);
        }

        /// <summary>
        /// Load assertions into the KB
        /// </summary>
        public void ConsultString(string text)
        {
            using (var sr = new StringReader(text))
            {
                string savedFileName = Prolog.CurrentSourceFile;
                int savedLineNumber = Prolog.CurrentSourceLineNumber;
                try
                {
                    Prolog.CurrentSourceFile = null;
                    Prolog.CurrentSourceLineNumber = 0;
                    Consult(sr);
                }
                finally
                {
                    Prolog.CurrentSourceFile = savedFileName;
                    Prolog.CurrentSourceLineNumber = savedLineNumber;
                }
            }
        }

        string DefaultExtension(string path, string extension)
        {
            if (Path.GetExtension(path) == String.Empty)
                return Path.ChangeExtension(path, extension);
            return path;
        }

        /// <summary>
        /// Load assertions into the KB
        /// </summary>
        public void Consult(string path)
        {
            path = DefaultExtension(Prolog.LoadFilePath(path), ".pl");

            using (var stream = File.OpenText(path))
            {
                string savedFileName = Prolog.CurrentSourceFile;
                int savedLineNumber = Prolog.CurrentSourceLineNumber;
                try
                {
                    Prolog.CurrentSourceFile = path;
                    Prolog.CurrentSourceLineNumber = 0;
                    Consult(new PositionTrackingTextReader(stream, path));
                }
                finally
                {
                    Prolog.CurrentSourceFile = savedFileName;
                    Prolog.CurrentSourceLineNumber = savedLineNumber;
                }
            }
        }

        /// <summary>
        /// Load assertions into the KB
        /// </summary>
        public void Consult(Stream stream)
        {
            Consult(new StreamReader(stream));
        }

        /// <summary>
        /// Load assertions into the KB
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA2204:Literals should be spelled correctly", MessageId = "functor")]
        public void Consult(TextReader inStream)
        {
            sourceFiles.NoteFile(Prolog.CurrentSourceFile);
            var reader = new ISOPrologReader(inStream);
            reader.SkipLayout();
            int lastLine = reader.LineNumber;
            PrologContext context = PrologContext.GetFreePrologContext(this, this);

            try
            {
                object unexpanded;
                Prolog.CurrentSourceLineNumber = lastLine;
                while ((unexpanded = reader.ReadTerm()) != Symbol.EndOfFile)
                {
                    // Perform user-level macroexpansion.
                    object assertion = TermExpansion(unexpanded);
                    var t = Term.Structurify(assertion, "Assertions in prolog files must be valid propositions or predicates.");

                    // Perform built-in macroexpansion.
                    t = t.Expand();

                    if (t.IsFunctor(Symbol.Implication, 1))
                    {
                        context.Reset();
                        var goal = Term.Structurify(
                            t.Argument(0),
                            "Argument to a :- directive must be an atom or structure.");
                        // Run t once, but don't backtrack for a second solution (since it's presumably an imperative anyway).
                        Prove(
                            goal.Functor, goal.Arguments,
                            context,
                            0).GetEnumerator().MoveNext();
                    }
                    else
                        Assert(assertion, true, true);
                    reader.SkipLayout();
                    lastLine = reader.LineNumber;
                    Prolog.CurrentSourceLineNumber = lastLine;
                }
            }
            catch (Exception e)
            {
                Repl.RecordExceptionSourceLocation(e, lastLine);
                throw new PrologError(e,
                                      context.StackTrace(Prolog.CurrentSourceFile,
                                                         Prolog.CurrentSourceLineNumber,
                                                         "consult/1"));
            }
            finally
            {
                PrologContext.ReleaseContext(context);
            }
        }

        // ReSharper disable once InconsistentNaming
        private readonly Symbol term_expansion = Symbol.Intern("term_expansion");
        private readonly Symbol expansion = Symbol.Intern("expansion");
        private object TermExpansion(object unexpanded)
        {
            if (CheckForPredicateInfoInThisKB(term_expansion, 2) == null && Global.CheckForPredicateInfoInThisKB(term_expansion, 2) == null)
                // Don't bother if not defined.
                return unexpanded;

            // Attempt to expand it
            var expanded = new LogicVariable(expansion);
            // Try this KB
            if (CheckForPredicateInfoInThisKB(term_expansion, 2) != null)
                // ReSharper disable UnusedVariable
#pragma warning disable 0168
                foreach (var ignore in Prove(new Structure(term_expansion, unexpanded, expanded)))
#pragma warning restore 0168
                {
                    return Term.CopyInstantiation(expanded);
                }

            // Try the global KB
            if (this != Global && Global.CheckForPredicateInfoInThisKB(term_expansion, 2) != null)
#pragma warning disable 0168
                foreach (var ignore in Global.Prove(new Structure(term_expansion, unexpanded, expanded)))
#pragma warning restore 0168
                // ReSharper restore UnusedVariable
                {
                    return Term.CopyInstantiation(expanded);
                }


            // Expansion failed, so use unexpanded version.
            return unexpanded;
        }

        /// <summary>
        /// Reload any files that have been modified.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Globalization", "CA1303:Do not pass literals as localized parameters", MessageId = "System.Console.WriteLine(System.String,System.Object,System.Object)")]
        public void ReloadModifiedSourceFiles()
        {
            foreach (var path in sourceFiles.OutOfDateFiles)
            {
                Console.WriteLine("Reloading {0} into {1} knowledge base", Path.GetFileName(path), Name);
                Reconsult(path);
            }
        }
        #endregion

        #region Source regeneration - listing out of all entries in the DB.
        /// <summary>
        /// All assertions in the database
        /// </summary>
        public IList<Structure> Assertions
        {
            get
            {
                var terms = new List<Structure>();
                foreach (var pair in db)
                {
                    foreach (var info in pair.Value)
                        if (info != null)
                            foreach (var entry in info.Entries)
                            {
                                var rule = entry as KnowledgeBaseRule;
                                if (rule != null)
                                {
                                    var head = new Structure(pair.Key, rule.HeadArgs);
                                    if (rule.BodyGoals == null || rule.BodyGoals.Length == 0)
                                        terms.Add(head);
                                    else
                                        terms.Add(new Structure(Symbol.Implication, head, Commafy(rule.BodyGoals)));
                                }
                            }
                }
                return terms;
            }
        }

        static Structure Commafy(Structure[] structures)
        {
            Structure result = structures[structures.Length - 1];
            for (int i = structures.Length - 2; i >= 0; i--)
                result = new Structure(Symbol.Comma, structures[i], result);
            return result;
        }

        /// <summary>
        /// Reconstructs source code for assertions in database.
        /// </summary>
        public string Source
        {
            get
            {
                var s = new StringWriter();
                var writer = new ISOPrologWriter(s);
// ReSharper disable UnusedVariable
                foreach (var term in Assertions)
// ReSharper restore UnusedVariable
                {
                    writer.Write(term);
                    writer.WriteString(".\n");
                }
                return s.ToString();
            }
        }

        /// <summary>
        /// Returns the source code for the current definition of functor.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "functor")]
        public string SourceFor(Symbol functor, int arity)
        {
            if (functor == null) throw new ArgumentNullException("functor");
            var s = new StringWriter();
            var writer = new ISOPrologWriter(s);
            var predicateInfo = CheckForPredicateInfoInThisKB(functor, arity);
            if (predicateInfo == null)
                throw new ArgumentException(string.Format("Unknown predicate: {0}/{1}.",functor.Name, arity));
            foreach (var knowledgeBaseEntry in predicateInfo.Entries)
            {
                var rule = (KnowledgeBaseRule)knowledgeBaseEntry;
                var head = new Structure(functor, rule.HeadArgs);
                Structure structure;
                if (rule.BodyGoals == null || rule.BodyGoals.Length == 0)
                    structure = head;
                else
                    structure =new Structure(Symbol.Implication, head, Commafy(rule.BodyGoals));
                writer.Write(structure);
                writer.WriteString(".\n");
            }
            return s.ToString();
        }
        #endregion
    }
}
