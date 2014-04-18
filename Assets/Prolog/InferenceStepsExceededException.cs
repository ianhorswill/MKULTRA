using System;

namespace Prolog
{
    /// <summary>
    /// Thrown when a top-level Prolog goal runs for longer than is allowable
    /// </summary>
    [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2237:MarkISerializableTypesWithSerializable"), System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1032:ImplementStandardExceptionConstructors")]
    public class InferenceStepsExceededException : Exception
    {
        /// <summary>
        /// Indicates that a Prolog computation ran for more than its maximum number of allowable steps.
        /// </summary>
        public InferenceStepsExceededException()
            : base("Prolog ran for longer than was allowed; this may indicate an infinite recursion.")
        { }
    }
}
