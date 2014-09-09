using System;
using System.Collections;
using System.Collections.Generic;

namespace Prolog
{
    internal sealed class CutStateSequencer : IEnumerable<CutState>, IEnumerator<CutState>
    {
        /// <summary>
        /// Returns a sequencer that succeeds once.
        /// </summary>
        public static CutStateSequencer Succeed()
        {
            return FromBoolean(true);
        }

        /// <summary>
        /// Returns a sequencer that fails.
        /// </summary>
        public static CutStateSequencer Fail()
        {
            return FromBoolean(false);
        }

        public static CutStateSequencer FromBoolean(bool succeed)
        {
            var s = Pool.Allocate();
            s.succeedNextCall = succeed;
            return s;
        }

        public void Dispose()
        {
            Pool.Deallocate(this);
        }

        private CutStateSequencer() 
        { }

        private static readonly StoragePool<CutStateSequencer> Pool = new StoragePool<CutStateSequencer>(() => new CutStateSequencer()); 

        private bool succeedNextCall;

        public CutState Current
        {
            get
            {
                return CutState.Continue;
            }
        }

        public void Reset()
        {
            throw new NotImplementedException();
        }

        object IEnumerator.Current
        {
            get
            {
                return Current;
            }
        }

        public bool MoveNext()
        {
            var r = succeedNextCall;
            succeedNextCall = false;
            return r;
        }

        public IEnumerator<CutState> GetEnumerator()
        {
            return this;
        }

        IEnumerator IEnumerable.GetEnumerator()
        {
            return this;
        }
    }
}
