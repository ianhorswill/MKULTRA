using Prolog;
using UnityEngine;

// ReSharper disable once InconsistentNaming
public class NLPrompt : MonoBehaviour
{
    private string input = "";

    private string completion = "";

    private string commentary = "";

    private string formatted = "";

    internal void OnGUI()
    {
        var e = Event.current;
        if (e.type == EventType.KeyDown)
        {
            switch (e.keyCode)
            {
                case KeyCode.Delete:
                case KeyCode.Backspace:
                    if (input != "")
                        formatted = input = input.Substring(0, input.Length - 1);
                    break;

                case KeyCode.Return:
                case KeyCode.KeypadEnter:
                    formatted = input = "";
                    break;

                default:
                    if (e.character > 0)
                    {
                        input = input + e.character;
                        if (e.character == ' ')
                        {
                            var completionVar = new LogicVariable("Output");
                            var commentaryVar = new LogicVariable("Commentary");
                            if (this.IsTrue("completion", input, completionVar, commentaryVar))
                            {
                                completion = (string)completionVar.Value;
                                commentary = ISOPrologWriter.WriteToString(commentaryVar.Value);
                                formatted = string.Format("{0}<i>{1}</i>", input, completion);
                            }
                            else
                            {
                                formatted = string.Format("<color=red>{0}</color>", input);
                            }
                        }
                        else
                        {
                            formatted = null;
                            var lastSpace = input.LastIndexOf(' ');
                            if (lastSpace >= 0 && lastSpace < input.Length)
                            {
                                var lastWord = input.Substring(lastSpace + 1);
                                if (Symbol.IsInterned(lastWord))
                                {
                                    // Input ends with a complete word
                                    if (this.IsTrue("parse_input", input, new LogicVariable("Semantics")))
                                        formatted = string.Format("<b><color=green>{0}</color></b>", input);
                                }
                            }
                            if (formatted == null)
                                formatted = input;
                        }
                    }
                    break;
            }
        }
        
        GUILayout.Label(formatted);
        GUILayout.Label(commentary);
    }
}
