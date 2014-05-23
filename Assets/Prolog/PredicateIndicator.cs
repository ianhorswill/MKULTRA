namespace Prolog
{
    public struct PredicateIndicator
    {
        public readonly Symbol Functor;
        public readonly int Arity;

        public PredicateIndicator(Symbol functor, int arity)
        {
            this.Functor = functor;
            this.Arity = arity;
        }

        public PredicateIndicator(Structure s) : this(s.Functor, s.Arity) { }

        public static bool operator==(PredicateIndicator a, PredicateIndicator b)
        {
            return a.Functor == b.Functor && a.Arity == b.Arity;
        }

        public static bool operator !=(PredicateIndicator a, PredicateIndicator b)
        {
            return a.Functor != b.Functor || a.Arity != b.Arity;
        }

        public override int GetHashCode()
        {
            return Functor.GetHashCode() ^ Arity;
        }

        public override bool Equals(object obj)
        {
            if (obj is PredicateIndicator)
            {
                var o = (PredicateIndicator)obj;
                return this.Functor == o.Functor && this.Arity == o.Arity;
            }
            return false;
        }

        public override string ToString()
        {
            return string.Format("{0}/{1}", Functor.Name, Arity);
        }
    }
}
