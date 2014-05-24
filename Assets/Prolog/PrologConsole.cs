using UnityEngine;

namespace Prolog
{
    class PrologConsole : Northwestern.UnityUtils.Console
    {
#pragma warning disable 649
        public GameObject DefaultGameObject;
#pragma warning restore 649

        private Repl repl;

        internal override void Start()
        {
            //Header = "Prolog REPL";
            WindowTitle = "Prolog console";
            base.Start();
            repl = new Repl {
                       Output = Out,
                       CurrentGameObject = DefaultGameObject??gameObject
                   };
            Prolog.TraceOutput = Out;
            PrologChecker.Check();
        }

        protected override void Run(string command)
        {

            if (command != ";")
                Out.Write("?- ");
            Out.WriteLine(command);
            repl.ProcessCommandLine(command);
        }
    }
}
