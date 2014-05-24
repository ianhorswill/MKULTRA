namespace Prolog
{
    public struct PredicateArgumentIndexer
    {
        public PredicateArgumentIndexer(IndexerType type, object functor, byte arity)
        {
            this.Type = type;
            this.Functor = functor;
            this.Arity = arity;
        }

        public PredicateArgumentIndexer(object argument)
        {
            argument = Term.Deref(argument);
            if (argument is LogicVariable)
            {
                this.Type = IndexerType.Variable;
                this.Functor = null;
                this.Arity = 0;
            }
            else
            {
                var s = argument as Structure;
                if (s != null)
                {
                    this.Type = IndexerType.Structure;
                    this.Functor = s.Functor;
                    this.Arity = (byte)s.Arity;
                }
                else
                {
                    this.Type = IndexerType.Atom;
                    this.Functor = argument;
                    this.Arity = 0;
                }
            }
        }

        public static PredicateArgumentIndexer[] ArglistIndexers(object[] args)
        {
            var result = new PredicateArgumentIndexer[args.Length];
            for (int i = 0; i < result.Length; i++)
                result[i] = new PredicateArgumentIndexer(args[i]);
            return result;
        }

        public static bool PotentiallyMatchable(PredicateArgumentIndexer a, PredicateArgumentIndexer b)
        {
            return a.Type == IndexerType.Variable || b.Type == IndexerType.Variable || a == b;
        }

        public static bool PotentiallyMatchable(object a, PredicateArgumentIndexer b)
        {
            return PotentiallyMatchable(new PredicateArgumentIndexer(a), b);
        }

        public static bool PotentiallyMatchable(PredicateArgumentIndexer[] a, PredicateArgumentIndexer[] b)
        {
            for (var i=0; i<a.Length; i++)
                if (!PotentiallyMatchable(a[i], b[i]))
                    return false;
            return true;
        }

        public enum IndexerType : byte
        {
            Variable, Atom, Structure
        }

        public readonly IndexerType Type;
        public readonly byte Arity;
        public readonly object Functor;

        public static bool operator ==(PredicateArgumentIndexer a, PredicateArgumentIndexer b)
        {
            return a.Type == b.Type && a.Functor.Equals(b.Functor) && a.Arity == b.Arity;
        }

        public static bool operator !=(PredicateArgumentIndexer a, PredicateArgumentIndexer b)
        {
            return a.Type != b.Type || !a.Functor.Equals(b.Functor) || a.Arity != b.Arity;
        }

        public override int GetHashCode()
        {
            return (int)Type ^ Functor.GetHashCode() ^ Arity;
        }

        public override bool Equals(object obj)
        {
            if (obj is PredicateArgumentIndexer)
            {
                var o = (PredicateArgumentIndexer)obj;
                return this.Type == o.Type && this.Functor.Equals(o.Functor) && this.Arity == o.Arity;
            }
            return false;
        }

        public override string ToString()
        {
            switch (Type)
            {
                case IndexerType.Structure:
                    return string.Format("{0}/{1}", ((Symbol)Functor).Name, Arity);

                case IndexerType.Atom:
                    return ISOPrologWriter.WriteToString(Functor);

                case IndexerType.Variable:
                    return "Var";
            }
            return "<PredicateArgumentIndexer with invalid type>";
        }
    }
}
