using System.Text;

using UnityEngine;

namespace Prolog
{
    public class DebugOverlay : BindingBehaviour
    {
        private string text;
        private readonly StringBuilder textBuilder = new StringBuilder();

        private static Texture2D greyOutTexture;
        internal void Start()
        {
            if (greyOutTexture == null)
            {
                greyOutTexture = new Texture2D(1, 1);
                greyOutTexture.SetPixel(0, 0, new Color(0, 0, 0, 128));
            }
        }

        internal void OnGUI()
        {
            switch (Event.current.type)
            {
                case EventType.repaint:
                case EventType.Layout:
                    if (!string.IsNullOrEmpty(text))
                    {
                        GUI.depth = -1;

                        var screenRect = new Rect(100, 100, Screen.width-200, Screen.height-200);
                        GUI.Box(screenRect, greyOutTexture);

                        GUILayout.BeginArea(screenRect);
                        GUILayout.Label(text);
                        GUILayout.EndArea();
                    }
                    break;

                case EventType.keyDown:
                    if (Event.current.keyCode == KeyCode.Escape)
                        text = null;
                    break;
            }

        }

        public void UpdateText(object payload)
        {
            textBuilder.Length = 0;
            this.Render(payload);
            text = textBuilder.ToString();
        }

        void Render(object renderingOperation)
        {
            renderingOperation = Term.Deref(renderingOperation);
            var op = renderingOperation as Structure;
            if (op != null)
            {
                switch (op.Functor.Name)
                {
                    case "cons":
                        this.Render(op.Argument(0));
                        var cdr = op.Argument(1);
                        if (cdr != null)
                            this.Render(cdr);
                        break;

                    case "line":
                        foreach (var arg in op.Arguments)
                            this.Render(arg);
                        textBuilder.AppendLine();
                        break;

                    case "color":
                        textBuilder.AppendFormat("<color={0}>", op.Argument(0));
                        for (int i=1; i<op.Arity; i++)
                            this.Render(op.Argument(i));
                        textBuilder.Append("</color>");
                        break;

                    default:
                        textBuilder.Append(ISOPrologWriter.WriteToString(op));
                        break;
                }
            }
            else
            {
                var str = renderingOperation as string;
                textBuilder.Append(str ?? ISOPrologWriter.WriteToString(renderingOperation));
            }
        }
    }
}
