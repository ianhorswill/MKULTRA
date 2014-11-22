using Prolog;
using UnityEngine;

// ReSharper disable once InconsistentNaming
public class NLPrompt : BindingBehaviour
{
    #region Public fields editable within the editor
    /// <summary>
    /// Location where user input is displayed
    /// </summary>
    public Rect InputRect = new Rect(0, 0, 1000, 100);
    /// <summary>
    /// Location where the decoded dialog act is displayed
    /// </summary>
    public Rect CommentaryRect = new Rect(0, 100, 1000, 100);
    /// <summary>
    /// Location where output from the character to the player is displayed
    /// </summary>
    public Rect ResponseRect = new Rect(0, 100, 1000, 100);

    /// <summary>
    /// Font, color, etc. for displaying the player's input.
    /// </summary>
    public GUIStyle InputGUIStyle = new GUIStyle();
    /// <summary>
    /// Font, color, etc. for displaying the decoded dialog act
    /// </summary>
    public GUIStyle CommentaryGUIStyle = new GUIStyle();
    #endregion

    #region Private fields
    /// <summary>
    /// What the user has typed so far.
    /// </summary>
    private string input = "";
    /// <summary>
    /// Text that completes the input to be a valid utterance of the grammar (if any)
    /// </summary>
    private string completion = "";
    /// <summary>
    /// Text describing the decoded dialog act
    /// </summary>
    private string commentary = "";
    /// <summary>
    /// Combined input+completion with colorization
    /// </summary>
    private string formatted = "";
    /// <summary>
    /// The dialog act as a Prolog term.
    /// </summary>
    private object dialogAct;
    /// <summary>
    /// Output form player character to player, if any.
    /// </summary>
    private string characterResponse = "";

    [Bind]
#pragma warning disable 649
    private SimController simController;
#pragma warning restore 649
    #endregion

    /// <summary>
    /// Display output from the player character to the player.
    /// </summary>
    /// <param name="formattedText">Text to display</param>
    public void OutputToPlayer(string formattedText)
    {
        characterResponse = formattedText;
    }

    internal void OnGUI()
    {
        GUI.depth = 0;
        var e = Event.current;
        switch (e.type)
        {
            case EventType.KeyDown:
                if (GUI.GetNameOfFocusedControl()=="")
                {
                    this.HandleKeyDown(e);
                    this.TryCompletionIfCompleteWord();
                }
                break;

            case EventType.Repaint:
                GUI.Label(InputRect, formatted, InputGUIStyle);
                GUI.Label(CommentaryRect, commentary, CommentaryGUIStyle);
                GUI.Label(ResponseRect, characterResponse, InputGUIStyle);
                break;
        }
    }

    private void HandleKeyDown(Event e)
    {
        switch (e.keyCode)
        {
            case KeyCode.Escape:
                this.input = this.formatted = this.commentary = "";
                this.dialogAct = null;
                PauseManager.Paused = false;
                break;

            case KeyCode.Delete:
            case KeyCode.Backspace:
                if (this.input != "")
                {
                    this.formatted = this.input = this.input.Substring(0, this.input.Length - 1);
                    this.TryCompletionIfCompleteWord();
                }
                break;

            case KeyCode.Tab:
                this.input = string.Format("{0}{1}{2}",
                                           this.input,
                                           ( this.input.EndsWith(" ")
                                             || ( !string.IsNullOrEmpty(completion)
                                                  && !char.IsLetterOrDigit(completion[0])))
                                           ? "" : " ",
                                           this.completion);
                break;

            case KeyCode.Return:
            case KeyCode.KeypadEnter:
                if (this.dialogAct != null)
                {
                    simController.QueueEvent("player_input", dialogAct);
                    this.formatted = this.input = this.completion = this.commentary = "";
                    this.dialogAct = null;
                    PauseManager.Paused = false;
                }
                Event.current.Use();
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
        if (c == '\n')
            return;

        PauseManager.Paused = true;
        characterResponse = "";
        if (c != ' ' || (this.input != "" && !this.input.EndsWith(" "))) // don't let them type redundant spaces
            this.input = this.input + c;

        this.TryCompletionIfCompleteWord();
    }

    private void TryCompletionIfCompleteWord()
    {
        this.formatted = null;
        if (this.input.EndsWith(" "))
            this.TryCompletion();
        else
        {
            var lastSpace = this.input.LastIndexOf(' ');
            var lastWord = lastSpace < 0 ? this.input : this.input.Substring(lastSpace + 1);
            lastWord = lastWord.Trim('(', ')', '.', ',', '?', '!', ';', ':', '\'', '"');
            if (Symbol.IsInterned(lastWord))
            {
                this.TryCompletion();
            }
        }

        if (this.formatted == null)
        {
            this.formatted = this.input;
            this.dialogAct = null;
        }
    }

    private void TryCompletion()
    {
        var completionVar = new LogicVariable("Output");
        var commentaryVar = new LogicVariable("Commentary");
        bool completionSuccess = false;
        try
        {
            completionSuccess = this.IsTrue("input_completion", this.input, completionVar, commentaryVar);
        }
        catch (InferenceStepsExceededException e)
        {
            Debug.LogError("Completion took too many steps for input: "+this.input);
            Debug.LogException(e);
        }
        if (completionSuccess)
        {
            this.completion = (string)completionVar.Value;
            this.dialogAct = Term.CopyInstantiation(commentaryVar.Value);
            this.commentary = ISOPrologWriter.WriteToString(commentaryVar.Value);
            this.formatted = this.completion=="" ?
                                string.Format("<b><color=lime>{0}</color></b>", this.input)
                                : string.Format("<color=lime>{0}{1}</color><color=grey><i>{2}</i></color>",
                                                this.input,
                                                (this.input.EndsWith(" ") || !char.IsLetterOrDigit(completion[0]))?"":" ",
                                                this.completion);
        }
        else
        {
            this.formatted = string.Format("<color=red>{0}</color>", this.input);
        }
    }
}
