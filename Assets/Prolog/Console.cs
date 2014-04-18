using UnityEngine;
using System.IO;
using System.Text;

namespace Northwestern.UnityUtils
{
    public class Console : MonoBehaviour
    {
        public Rect WindowRect = new Rect(0, 0, 640, 480); //Defines console size and dimensions
        public string WindowTitle = "Console";
        public string Header = ""; //First thing shown when console starts

        public KeyCode ActivationKey = KeyCode.F2;	//Key used to show/hide console
        public bool ShowConsole = false;				//Whether or not console is visible


        //Public variables for writing to console stdout and stdin
        public string In;

        public ConsoleWriter Out;

        protected static int IDCount = 0;

        // ReSharper disable once InconsistentNaming
        private int ID; //unique generated ID

        private string consoleID; //generated from ID

        private string consoleBuffer; //Tied to GUI.Label

        private Vector2 scrollPosition;

        private bool firstFocus; //Controls console input focus

        /// <summary>
        /// Initializes console properties and sets up environment.
        /// </summary>
        internal virtual void Start()
        {
            Initialize();
            In = string.Empty;
            Out = new ConsoleWriter();
            consoleBuffer = Header;
            if (consoleBuffer != "")
                Out.WriteLine(consoleBuffer);
            scrollPosition = Vector2.zero;
            ID = IDCount++;
            this.consoleID = "window" + ID;
            firstFocus = true;
        }

        // Update is called once per frame
        internal void Update()
        {

        }

        /// <summary>
        /// Creates the Console Window.
        /// </summary>
        /// <param name='windowID'>
        /// unused parameter.
        /// </param>
        private void DoConsoleWindow(int windowID)
        {
            //Console Window
            GUI.DragWindow(new Rect(0, 0, this.WindowRect.width, 20));
            //Scroll Area
            scrollPosition = GUILayout.BeginScrollView(
                scrollPosition,
                GUILayout.MaxHeight(this.WindowRect.height - 48),
                GUILayout.ExpandHeight(false),
                GUILayout.Width(this.WindowRect.width - 15));
            //Console Buffer
            GUILayout.Label(consoleBuffer, GUILayout.ExpandHeight(true));
            GUILayout.EndScrollView();
            //Input Box
            GUI.SetNextControlName(this.consoleID);
            In = GUI.TextField(new Rect(4, this.WindowRect.height - 24, this.WindowRect.width - 8, 20), In);
            if (firstFocus)
            {
                GUI.FocusControl(this.consoleID);
                firstFocus = false;
            }
        }

        internal void OnGUI()
        {
            if (this.ShowConsole)
            {
                this.WindowRect = GUI.Window(ID, this.WindowRect, this.DoConsoleWindow, WindowTitle);
            }
            if (Event.current.isKey && Event.current.keyCode == ActivationKey && Event.current.type == EventType.KeyUp)
            {
                this.ShowConsole = !this.ShowConsole;
                firstFocus = true;
            }
            if (Event.current.isKey && Event.current.keyCode == KeyCode.Return
                && GUI.GetNameOfFocusedControl() == this.consoleID && In != string.Empty)
            {
                scrollPosition = GUI.skin.label.CalcSize(new GUIContent(consoleBuffer));
                string command = In;
                In = string.Empty;
                Run(command);
            }
            if (Out != null && Out.IsUpdated())
            {
                consoleBuffer = Out.GetTextUpdate();
            }
        }

        /// <summary>
        /// A TextWriter for output buffer
        /// </summary>
        public class ConsoleWriter : TextWriter
        {
            private bool bufferUpdated;

            //tracks when changes are made to StringBuilder to prevent generating new strings every click

            private readonly StringBuilder oBuffer;

            public ConsoleWriter()
            {
                oBuffer = new StringBuilder();
            }

            public override Encoding Encoding
            {
                get
                {
                    return Encoding.Default;
                }
            }

            public override void Write(string value)
            {
                oBuffer.Append(value);
                bufferUpdated = true;
            }

            public override void WriteLine(string value)
            {
                oBuffer.AppendLine(value);
                bufferUpdated = true;
            }

            public override void WriteLine()
            {
                this.WriteLine("");
            }

            public string GetTextUpdate()
            {
                bufferUpdated = false;
                return oBuffer.ToString();
            }

            public bool IsUpdated()
            {
                return bufferUpdated;
            }
        }

        /// <summary>
        /// Run when a newline is entered in the input box.
        /// </summary>
        /// <param name='command'>
        /// The entered text prior to the newline.
        /// </param>
        protected virtual void Run(string command)
        {
            Out.WriteLine(">> " + command);
            //override for functionality
        }

        /// <summary>
        /// Allows for initialization of <code>Width</code>, <code>Height</code>, <code>Header</code>, <code>ActivationKey</code>, and <code>showConsole</code>
        /// </summary>
        protected virtual void Initialize()
        {
            //override to set console properties
        }
    }
}
