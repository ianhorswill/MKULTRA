using Prolog;
using UnityEngine;

// ReSharper disable once InconsistentNaming
public class NLPrompt : MonoBehaviour
{
    private string input = "";

    private string completion = "";

    private string commentary = "";

    private string formatted = "";

    public Rect InputRect = new Rect(0, 0, 1000, 100);

    public Rect CommentaryRect = new Rect(0, 100, 1000, 100);

    public GUIStyle InputGUIStyle = new GUIStyle();

    public GUIStyle CommentaryGUIStyle = new GUIStyle();

    internal void OnGUI()
    {
        var e = Event.current;
        switch (e.type)
        {
            case EventType.KeyDown:
                this.HandleKeyDown(e);
                break;

            case EventType.Repaint:
                GUI.Label(InputRect, formatted, InputGUIStyle);
                GUI.Label(CommentaryRect, commentary, CommentaryGUIStyle);
                break;
        }
    }

    private void HandleKeyDown(Event e)
    {
        switch (e.keyCode)
        {
            case KeyCode.Delete:
            case KeyCode.Backspace:
                if (this.input != "")
                {
                    this.formatted = this.input = this.input.Substring(0, this.input.Length - 1);
                }
                break;

            case KeyCode.Return:
            case KeyCode.KeypadEnter:
                this.formatted = this.input = "";
                break;

            default:
                if (e.character > 0)
                {
                    this.AddToInput(e.character);
                }
                break;
        }
    }

    private void AddToInput(char c)
    {
        this.input = this.input + c;
        if (c == ' ')
        {
            this.TryCompletion();
        }
        else
        {
            this.formatted = null;
            var lastSpace = this.input.LastIndexOf(' ');
            if (lastSpace >= 0 && lastSpace < this.input.Length)
            {
                var lastWord = this.input.Substring(lastSpace + 1);
                if (Symbol.IsInterned(lastWord))
                {
                    this.TryCompletion();
                }
            }
            if (this.formatted == null)
            {
                this.formatted = this.input;
            }
        }
    }

    private void TryCompletion()
    {
        var completionVar = new LogicVariable("Output");
        var commentaryVar = new LogicVariable("Commentary");
        if (this.IsTrue("input_completion", this.input, completionVar, commentaryVar))
        {
            this.completion = (string)completionVar.Value;
            this.commentary = ISOPrologWriter.WriteToString(commentaryVar.Value);
            this.formatted = string.Format("{0}<i>{1}</i>", this.input, this.completion);
        }
        else
        {
            this.formatted = string.Format("<color=red>{0}</color>", this.input);
        }
    }
}
