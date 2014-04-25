using System;

using UnityEngine;

namespace Prolog
{
    class ELInspector : MonoBehaviour
    {
        public Rect WindowRect = new Rect(0, 0, 640, 480);
        public bool ShowInspector = true;
        public GUIStyle Style = new GUIStyle();
        public string WindowTitle { get; set; }

        private ELNode root;
        // ReSharper disable once InconsistentNaming
        private int ID;
        private Vector2 scrollPosition;
        // ReSharper disable once InconsistentNaming
        protected static int IDCount = typeof(ELInspector).GetHashCode();

        // Total height of the dumped EL database
        private float viewHeight = 10;

        internal void Start()
        {
            root = this.KnowledgeBase().ELRoot;
            ID = IDCount++;
            WindowTitle = "EL";
        }

        internal void OnGUI()
        {
            if (this.ShowInspector)
            {
                this.WindowRect = GUI.Window(ID, this.WindowRect, this.DrawWindow, WindowTitle);
            }
        }

        // ReSharper disable once InconsistentNaming
        private void DrawWindow(int windowID)
        {
            //Console Window
            GUI.DragWindow(new Rect(0, 0, this.WindowRect.width, 20));
            //Scroll Area
            scrollPosition = 
                GUI.BeginScrollView(
                    new Rect(0, 0, WindowRect.width, WindowRect.height),
                    scrollPosition,
                    new Rect(0, 0, WindowRect.width, viewHeight), false, true);
            viewHeight = Math.Max(
                viewHeight,
                this.RenderAt(root, 0, 0));
            GUI.EndScrollView();
        }

        private float RenderAt(ELNode node, float x, float y)
        {
            var go = node.Key as GameObject;
            var description = go != null ? go.name : node.Key.ToString();
            var key = new GUIContent(description+node.ModeString);
            var size = Style.CalcSize(key);
            GUI.Label(new Rect(x, y, size.x, size.y), key, Style);
            x += size.x;
            if (node.Children.Count == 0)
                y += size.y;
            else
                foreach (var child in node.Children)
                {
                    y = this.RenderAt(child, x, y);
                }
            return y;
        }
    }
}
