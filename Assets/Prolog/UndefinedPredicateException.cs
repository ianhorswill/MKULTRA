using System;

namespace Prolog
{
    /// <summary>
    /// Thrown to signal that a predicate used as a goal does not appear in the database.
    /// </summary>
    public class UndefinedPredicateException : Exception
    {
        /// <summary>
        /// The offending predicate in question
        /// </summary>
        public Structure Predicate { get; private set; }
        /// <summary>
        /// Thrown to signal that a predicate used as a goal does not appear in the database.
        /// </summary>
        public UndefinedPredicateException(Symbol functor, int arity)
        {
            Predicate = new Structure(Symbol.Intern("/"), functor, arity);
        }

        /// <summary>
        /// Human-readable message describing the exception
        /// </summary>
        public override string Message
        {
            get
            {
                return String.Format("Undefined predicate: {0}/{1}", Predicate.Arguments[0], Predicate.Arguments[1]);
            }
        }
    }
}
