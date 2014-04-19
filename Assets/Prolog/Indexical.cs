using System;
using System.Collections.Generic;

using UnityEngine;

namespace Prolog
{
    /// <summary>
    /// Represents a time-varying value such as this or now.
    /// </summary>
    public class Indexical
    {
        static Indexical()
        {
            DeclareIndexical("this",
                context =>
                {
                    if (context.This == null)
                        throw new Exception("Indexical $this has not been given a value");
                    return context.This;
                });
            DeclareIndexical("game_object",
                context =>
                {
                    if (context.KnowledgeBase.GameObject == null)
                        throw new Exception("Current KnowledgeBase has no associated game object");
                    return context.GameObject;
                });
            DeclareIndexical("parent",
                context =>
                {
                    if (context.KnowledgeBase.Parent == null)
                        throw new Exception("Current KnowledgeBase has no parent.");
                    return context.KnowledgeBase.Parent;
                });
            DeclareIndexical("global", context => KnowledgeBase.Global);
            DeclareIndexical("now", context => Time.time);
        }

        static readonly Dictionary<Symbol,Indexical> IndexicalTable = new Dictionary<Symbol, Indexical>();

        public static Indexical Find(Symbol name)
        {
            Indexical result;
            return IndexicalTable.TryGetValue(name, out result) ? result : null;
        }

        public static void DeclareIndexical(string name, Func<PrologContext, object> valueFunc)
        {
            DeclareIndexical(Symbol.Intern(name), valueFunc);
        }

        public static void DeclareIndexical(Symbol name, Func<PrologContext, object> valueFunc)
        {
            IndexicalTable[name] = new Indexical(name, valueFunc);
        }

        public readonly Symbol Name;
        readonly Func<PrologContext, object> valueFunc;

        private Indexical(Symbol name, Func<PrologContext, object> valueFunc)
        {
            this.Name = name;
            this.valueFunc = valueFunc;
        }

        public object GetValue(PrologContext context)
        {
            return this.valueFunc(context);
        }
    }
}
