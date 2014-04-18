using System.Collections.Generic;

namespace Prolog
{
    public abstract class ELNodeEnumerator
    {
        public ELNode Current;

        public abstract bool MoveNext();
    }
}
