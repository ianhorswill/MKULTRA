using System;

namespace Prolog
{
    internal static class ELProlog
    {
        public const string NonExclusiveOperator = "/";
        public static readonly Symbol SNonExclusiveOperator = Symbol.Intern(NonExclusiveOperator);
        public const string ExclusiveOperator = ":";
        public static readonly Symbol SExclusiveOperator = Symbol.Intern(ExclusiveOperator);

        public static bool IsELTerm(object term)
        {
            var s = term as Structure;
            return s != null && (s.IsFunctor(SNonExclusiveOperator, 2) || s.IsFunctor(SExclusiveOperator, 2));
        }

        #region Queries
        public static bool TryQuery(object term, PrologContext context, out ELNode foundNode, out ELNodeEnumerator enumerator)
        {
            var s = Term.Deref(term) as Structure;
            if (s != null)
                return TryQueryStructure(s, context, out foundNode, out enumerator);

            throw new Exception("Malformed EL query: " + ISOPrologWriter.WriteToString(term));
        }

        public static bool TryQueryStructure(Structure term, PrologContext context, out ELNode foundNode, out ELNodeEnumerator enumerator)
        {
            //
            // Dispatch based on the functor and arity.
            //

            // Handle root queries, i.e. /Key
            if (term.IsFunctor(Symbol.Slash, 1))
                return TryRootQuery(term, context, out foundNode, out enumerator);

            if (term.Arity != 2 || (term.Functor != Symbol.Slash && term.Functor != Symbol.Colon))
                throw new Exception("Malformed EL query: " + ISOPrologWriter.WriteToString(term));

            return TryQuery(
                out foundNode,
                out enumerator,
                term.Argument(0),
                term.Argument(1),
                term.Functor == Symbol.Colon,
                context);
        }

        public static bool TryQuery(
            out ELNode foundNode,
            out ELNodeEnumerator enumerator,
            object parentExpression,
            object keyExpression,
            bool isExclusive,
            PrologContext context)
        {
            // Decode the parent expression
            ELNode parentNode;
            ELNodeEnumerator parentEnumerator;
            if (!TryQuery(parentExpression, context, out parentNode, out parentEnumerator))
            {
                // Parent failed, so we fail
                enumerator = null;
                foundNode = null;
                return false;
            }

            //
            // Decode the key argument
            //
            var key = keyExpression;
            var v = key as LogicVariable;

            return isExclusive?TryExclusiveQuery(out foundNode, out enumerator, parentNode, parentEnumerator, key, v)
                : TryNonExclusiveQuery(out foundNode, out enumerator, parentNode, key, v, parentEnumerator);
        }

        private static bool TryExclusiveQuery(
            out ELNode foundNode,
            out ELNodeEnumerator enumerator,
            ELNode parentNode,
            ELNodeEnumerator parentEnumerator,
            object key,
            LogicVariable v)
        {
            //
            // Expression is Parent:Something
            //
            if (parentNode != null)
            {
                return TryExclusiveQueryDeterministicParent(out foundNode, out enumerator, parentNode, key, v);
            }

            return TryExclusiveQueryEnumeratedParent(out foundNode, out enumerator, parentEnumerator, key, v);
        }

        private static bool TryExclusiveQueryEnumeratedParent(
            out ELNode foundNode,
            out ELNodeEnumerator enumerator,
            ELNodeEnumerator parentEnumerator,
            object key,
            LogicVariable v)
        {
            // Non-deterministic parent path
            // NonUniqueParent:Something
            foundNode = null;
            enumerator = (v == null)
                ? (ELNodeEnumerator)new ELNodeEnumeratorEnumerateParentAndLookupExclusiveKey(parentEnumerator, key)
                : new ELNodeEnumeratorEnumerateParentAndBindVariable(parentEnumerator, v);
            return true;
        }

        private static bool TryExclusiveQueryDeterministicParent(
            out ELNode foundNode,
            out ELNodeEnumerator enumerator,
            ELNode parentNode,
            object key,
            LogicVariable v)
        {
            // Deterministic parent path
            // UniqueParent:Something

            if (parentNode.IsNonExclusive)
            {
                throw new ELNodeExclusionException("Exclusive query of an non-exclusive node", parentNode, key);
            }

            if (v == null)
            {
                // Deterministic child path
                // UniqueParent:Key
                enumerator = null;
                return parentNode.TryLookup(key, out foundNode);
            }

            // Enumerated child path
            // UniqueParent:Variable
            if (parentNode.Children.Count > 0)
            {
                foundNode = null;
                enumerator = new ELNodeEnumeratorBindAndUnbindVariable(parentNode.Children[0], v);
                return true;
            }

            // parentNode is exclusive, but is childless, so we can't match.
            foundNode = null;
            enumerator = null;
            return false;
        }

        private static bool TryNonExclusiveQuery(out ELNode foundNode, out ELNodeEnumerator enumerator, ELNode parentNode, object key, LogicVariable v, ELNodeEnumerator parentEnumerator)
        {
            if (parentNode != null)
            {
                return TryNonExclusiveQueryDeterministicParent(out foundNode, out enumerator, parentNode, key, v);
            }
            return TryNonExclusiveQueryEnumeratedParent(out foundNode, out enumerator, key, v, parentEnumerator);
        }

        private static bool TryNonExclusiveQueryEnumeratedParent(
            out ELNode foundNode,
            out ELNodeEnumerator enumerator,
            object key,
            LogicVariable v,
            ELNodeEnumerator parentEnumerator)
        {
            // Enumerated parent path
            // NonUniqueParent/Something
            foundNode = null;
            if (v == null)
            {
                // NonUniqueParent/Key
                // Enumerate parent, then do deterministic lookup for child.
                enumerator = new ELNodeEnumeratorFixedChildFromParentEnumerator(parentEnumerator, key);
                return true;
            }
            // NonUniqueParent/Variable
            // Enumerate both parent and child.
            enumerator = new ELNodeEnumeratorLogicVariableFromParentEnumerator(parentEnumerator, v);
            return true;
        }

        private static bool TryNonExclusiveQueryDeterministicParent(
            out ELNode foundNode,
            out ELNodeEnumerator enumerator,
            ELNode parentNode,
            object key,
            LogicVariable v)
        {
            // Deterministic parent path
            // The expression is UniqueParent/Something
            if (parentNode.IsExclusive)
            {
                throw new ELNodeExclusionException("Non-exclusive query of an exclusive node", parentNode, key);
            }

            if (v == null)
            {
                // fully deterministic path
                // UniqueParent/Key corresponds to at most one ELNode.
                enumerator = null;
                return parentNode.TryLookup(key, out foundNode);
            }
            // UniqueParent/Variable, so do a singly-nested iteration.
            foundNode = null;
            enumerator = new ELNodeEnumeratorLogicVariableFromNode(parentNode, v);
            return true;
        }

        private static bool TryRootQuery(Structure term, PrologContext context, out ELNode foundNode, out ELNodeEnumerator enumerator)
        {
            // Expression is /Key.
            var arg0 = term.Argument(0);

            // This is a "/constant" expression, i.e. a top-level lookup.
            if (arg0 is LogicVariable)
            {
                throw new NotImplementedException("Lookups of the form /Variable are not supported.");
            }
            enumerator = null;
            return context.KnowledgeBase.ELRoot.TryLookup(arg0, out foundNode);
        }

        class ELNodeEnumeratorLogicVariableFromNode : ELNodeEnumerator
        {
            public ELNodeEnumeratorLogicVariableFromNode(ELNode parentNode, LogicVariable v)
            {
                this.parentNode = parentNode;
                this.variable = v;
                childIndex = parentNode.Children.Count - 1;
            }

            private int childIndex;

            private readonly ELNode parentNode;

            private readonly LogicVariable variable;

            public override bool MoveNext()
            {
                if (this.childIndex >= 0)
                {
                    Current = parentNode.Children[this.childIndex--];
                    this.variable.Value = Current.Key;
                    return true;
                }
                this.variable.ForciblyUnbind();
                return false;
            }
        }

        class ELNodeEnumeratorFixedChildFromParentEnumerator : ELNodeEnumerator
        {
            public ELNodeEnumeratorFixedChildFromParentEnumerator(ELNodeEnumerator parentEnumerator, object childKey)
            {
                this.parentEnumerator = parentEnumerator;
                this.childKey = childKey;
            }

            private readonly ELNodeEnumerator parentEnumerator;

            private readonly object childKey;

            public override bool MoveNext()
            {
                while (parentEnumerator.MoveNext())
                {
                    // ReSharper disable once PossibleNullReferenceException
                    if (parentEnumerator.Current.IsExclusive)
                        throw new ELNodeExclusionException("Non-exclusive query of an exclusive node", parentEnumerator.Current, childKey);
                    // ReSharper disable once PossibleNullReferenceException
                    if (parentEnumerator.Current.TryLookup(childKey, out Current))
                        return true;
                }
                return false;
            }
        }

        class ELNodeEnumeratorLogicVariableFromParentEnumerator : ELNodeEnumerator
        {
            public ELNodeEnumeratorLogicVariableFromParentEnumerator(ELNodeEnumerator parentEnumerator, LogicVariable v)
            {
                this.parentEnumerator = parentEnumerator;
                this.v = v;
                childIndex = -1;
            }

            private readonly ELNodeEnumerator parentEnumerator;

            private readonly LogicVariable v;

            private int childIndex;

            public override bool MoveNext()
            {
                retry:

                // First, try the next child of the current parent.
                if (childIndex >= 0)
                {
                    Current = parentEnumerator.Current.Children[childIndex--];
                    v.Value = Current.Key;
                    return true;
                }

                // Ran out of children on the current parent.
                if (parentEnumerator.MoveNext())
                {
                    // ReSharper disable once PossibleNullReferenceException
                    if (parentEnumerator.Current.IsExclusive)
                        throw new ELNodeExclusionException(
                            "Non-exclusive query of an exclusive node",
                            parentEnumerator.Current,
                            v);

                    childIndex = parentEnumerator.Current.Children.Count - 1;

                    goto retry;
                }
                v.ForciblyUnbind();
                return false;
            }
        }

        /// <summary>
        /// This doesn't really enumerate children, since there's only a single, fixed child.
        /// But we structure it as an enumerator so that we get a callback after the one child
        /// is processed, and that lets us unbind the variable we bound.
        /// </summary>
        class ELNodeEnumeratorBindAndUnbindVariable : ELNodeEnumerator
        {
            public ELNodeEnumeratorBindAndUnbindVariable(ELNode child, LogicVariable v)
            {
                this.child = child;
                this.v = v;
            }

            private readonly ELNode child;
            private readonly LogicVariable v;

            public override bool MoveNext()
            {
                if (v.IsBound)
                {
                    // We've already been through it once, so unbind the variable and fail.
                    v.ForciblyUnbind();
                    return false;
                }
                
                // This is our first time through, so bind the variable and succeed.
                Current = child;
                v.Value = child.Key;
                return true;
            }
        }

        class ELNodeEnumeratorEnumerateParentAndLookupExclusiveKey : ELNodeEnumerator
        {
            public ELNodeEnumeratorEnumerateParentAndLookupExclusiveKey(ELNodeEnumerator parentEnumerator, object key)
            {
                this.parentEnumerator = parentEnumerator;
                this.key = key;
            }

            private readonly ELNodeEnumerator parentEnumerator;

            private readonly object key;

            public override bool MoveNext()
            {
                while (parentEnumerator.MoveNext())
                {
                    if (parentEnumerator.Current.IsNonExclusive)
                    {
                        throw new ELNodeExclusionException("Exclusive query of an non-exclusive node", parentEnumerator.Current, key);
                    }
                    if (parentEnumerator.Current.TryLookup(key, out Current))
                        return true;
                }
                return false;
            }
        }

        class ELNodeEnumeratorEnumerateParentAndBindVariable : ELNodeEnumerator
        {
            public ELNodeEnumeratorEnumerateParentAndBindVariable(ELNodeEnumerator parentEnumerator, LogicVariable v)
            {
                this.parentEnumerator = parentEnumerator;
                this.v = v;
            }

            private readonly ELNodeEnumerator parentEnumerator;

            private readonly LogicVariable v;

            public override bool MoveNext()
            {
                while (parentEnumerator.MoveNext())
                {
                    if (parentEnumerator.Current.IsNonExclusive)
                    {
                        throw new ELNodeExclusionException("Exclusive query of an non-exclusive node", parentEnumerator.Current, v);
                    }
                    if (parentEnumerator.Current.Children.Count > 0)
                    {
                        Current = parentEnumerator.Current.Children[0];
                        v.Value = Current.Key;
                        return true;
                    }
                }
                v.ForciblyUnbind();
                return false;
            }
        }
        #endregion

        #region Assertion
        //
        // these write a single nodes, so they don't need to loop like queries do.
        //

        /// <summary>
        /// Write TERM to EL KB, creating any nodes that need to be cerated.
        /// </summary>
        /// <param name="term">Prolog-format term to store into KB</param>
        /// <param name="context">PrologContext (used for context.KnolwedgeBase.ELRoot.</param>
        /// <returns></returns>
        public static ELNode Update(object term, PrologContext context)
        {
            var s = term as Structure;
            if (s != null)
                return UpdateStructure(s, context);

            throw new Exception("Malformed EL assertion: " + ISOPrologWriter.WriteToString(term));
        }

        public static ELNode UpdateStructure(Structure term, PrologContext context)
        {
            if (term.Functor == Symbol.Slash)
            {
                if (term.Arity == 1)
                    return context.KnowledgeBase.ELRoot.StoreNonExclusive(term.Argument(0));
                return Update(term.Argument(0), context).StoreNonExclusive(term.Argument(1));
            }
            if (term.Functor == Symbol.Colon)
            {
                return Update(term.Argument(0), context).StoreExclusive(term.Argument(1), true); 
            }
            throw new Exception("Malformed EL assertion: "+ISOPrologWriter.WriteToString(term));
        }
        #endregion

        #region Retraction
        internal static System.Collections.Generic.IEnumerable<CutState> Retract(object term, PrologContext context)
        {
            ELNode foundNode;
            ELNodeEnumerator enumerator;
            if (!TryQuery(term, context, out foundNode, out enumerator))
                return PrologPrimitives.FailDriver();
            if (foundNode != null)
            {
                foundNode.DeleteSelf();
                return PrologPrimitives.SucceedDriver();
            }
            return DeleteSuccessive(enumerator);
        }

        private static System.Collections.Generic.IEnumerable<CutState> DeleteSuccessive(ELNodeEnumerator enumerator)
        {
            while (enumerator.MoveNext())
            {
                enumerator.Current.DeleteSelf();
                yield return CutState.Continue;
            }
        }

        internal static void RetractAll(object term, PrologContext context)
        {
            ELNode foundNode;
            ELNodeEnumerator enumerator;
            if (!TryQuery(term, context, out foundNode, out enumerator))
                return;
            if (foundNode != null)
                foundNode.DeleteSelf();
            else
                while (enumerator.MoveNext()) enumerator.Current.DeleteSelf();
        }
        #endregion
    }
}
