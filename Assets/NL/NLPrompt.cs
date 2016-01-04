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
    /// Database node for storing when the user last typed.
    /// </summary>
    private ELNode lastPlayerActivity;

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

    private ELNode mouseSelectionELNode;

    [Bind]
#pragma warning disable 649
    private SimController simController;

    private float typingPromptStartTime;
#pragma warning restore 649
    #endregion

    internal void Start()
    {
        lastPlayerActivity = KnowledgeBase.Global.ELRoot.StoreNonExclusive(Symbol.Intern("last_player_activity"));
        lastPlayerActivity.StoreExclusive(-1, true);
        mouseSelectionELNode = this.KnowledgeBase().ELRoot/ Symbol.Intern("perception") / Symbol.Intern("mouse_selection");
    }

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
            case EventType.MouseDown:
                typingPromptStartTime = Time.time;
                break;

            case EventType.KeyDown:
                if (GUI.GetNameOfFocusedControl() == "")
                {
                    HandleKeyDown(e);
                    if (!e.alt && !e.control)
                        TryCompletionIfCompleteWord();
                }
                break;

            case EventType.Repaint:
                var arrowActive = typingPromptStartTime > Time.time-3;

                // You'd want this to be called by a MouseMove event, but it's not supported in game,
                // and in any case, we probably need to keep updating because of potential object movement.
                UpdateMouseSelection();
                ShowMouseSelectionCaption();

                if (!string.IsNullOrEmpty(input) || arrowActive)
                {
                    GameObject addressee;
                    var da = dialogAct as Structure;
                    if (da == null)
                        addressee = GameObject.Find("pc");
                    else addressee = (GameObject) da.Argument(1);

                    addressee.DrawThumbNail(new Vector2(InputRect.x - 40, InputRect.y));
                }
                var text = (string.IsNullOrEmpty(input) && arrowActive) ? "<color=grey><i>Talk to me</i></color>" : formatted;
                GUI.Label(InputRect, text, InputGUIStyle);
                GUI.Label(CommentaryRect, commentary, CommentaryGUIStyle);
                GUI.Label(ResponseRect, characterResponse, InputGUIStyle);
                break;
        }
    }

    private void HandleKeyDown(Event e)
    {
        if (e.keyCode != KeyCode.None)
        {
            if (e.alt || e.control || (e.keyCode >= KeyCode.F1 && e.keyCode <= KeyCode.F15))
            {
                object key = Symbol.Intern(e.keyCode.ToString().ToLower());
                if (e.alt)
                {
                    if (e.control)
                        key = new Structure(
                            "-",
                            new Structure("-", Symbol.Intern("control"), Symbol.Intern("alt")),
                            key);
                    else
                        key = new Structure("-", Symbol.Intern("alt"), key);
                }
                else if (e.control)
                    key = new Structure("-", Symbol.Intern("control"), key);

                KnowledgeBase.Global.IsTrue(new Structure("fkey_command", key));
                return;
            }

            // Update last user activity time
            lastPlayerActivity.StoreExclusive(Time.time, true);

            switch (e.keyCode)
            {
                case KeyCode.Escape:
                    input = formatted = commentary = "";
                    dialogAct = null;
                    PauseManager.Paused = false;
                    break;

                case KeyCode.Delete:
                case KeyCode.Backspace:
                    if (input != "")
                    {
                        formatted = input = input.Substring(0, input.Length - 1);
                        TryCompletionIfCompleteWord();
                    }
                    break;

                case KeyCode.Tab:
                    input = string.Format(
                        "{0}{1}{2}",
                        input,
                        (input.EndsWith(" ")
                         || (!string.IsNullOrEmpty(completion) && !char.IsLetterOrDigit(completion[0])))
                            ? ""
                            : " ",
                        completion);
                    break;

                case KeyCode.Return:
                case KeyCode.KeypadEnter:
                    if (dialogAct != null)
                    {
                        simController.QueueEvent("player_input", dialogAct);
                        this.IsTrue("log_dialog_act", dialogAct);
                        formatted = input = completion = commentary = "";
                        dialogAct = null;
                        PauseManager.Paused = false;
                    }
                    Event.current.Use();
                    break;

                case KeyCode.UpArrow:
                case KeyCode.DownArrow:
                case KeyCode.LeftArrow:
                case KeyCode.RightArrow:
                    typingPromptStartTime = Time.time;
                    break;
            }
        }

        if (e.character > 0 && !e.alt && !e.control && e.character >= ' ')
        {
            AddToInput(e.character);
        }
    }

    private void AddToInput(char c)
    {
        if (c == '\n')
            return;

        PauseManager.Paused = true;
        characterResponse = "";
        if (c != ' ' || (input != "" && !input.EndsWith(" "))) // don't let them type redundant spaces
            input = input + c;

        TryCompletionIfCompleteWord();
    }

    /// <summary>
    /// True if the input ends with a character that can't be part of a word.
    /// </summary>
    bool InputEndsWithCompleteWord
    {
        get
        {
            if (input == "")
                return false;
            if (!input.EndsWith("'")
                && !char.IsLetterOrDigit(input[input.Length-1]))
                return true;
            // Check for cases like "who're"
            foreach (var e in Prolog.Prolog.EnglishEnclitics)
            {
                if (input.EndsWith(e) && input.Length > e.Length && input[input.Length - 1 - e.Length] == '\'')
                    return true;
            }
            return false;
        }
    }

    private void TryCompletionIfCompleteWord()
    {
        formatted = null;
        if (InputEndsWithCompleteWord)
            TryCompletion();
        else
        {
            var lastSpace = input.LastIndexOf(' ');
            var lastWord = lastSpace < 0 ? input : input.Substring(lastSpace + 1);
            lastWord = lastWord.Trim('(', ')', '.', ',', '?', '!', ';', ':', '\'', '"');

            if (Prolog.Prolog.IsLexicalItem(lastWord))
            {
                TryCompletion();
            }
        }

        if (formatted == null)
        {
            formatted = input;
            dialogAct = null;
        }
    }

    private void TryCompletion()
    {
        // Update the mouse selection, so Prolog can get at it.
        mouseSelectionELNode.StoreExclusive(MouseSelection, true);

        var completionVar = new LogicVariable("Output");
        var dialogActVar = new LogicVariable("DialogAct");
        bool completionSuccess = false;
        try
        {
            completionSuccess = this.IsTrue("input_completion", input, completionVar, dialogActVar);
        }
        catch (InferenceStepsExceededException e)
        {
            Debug.LogError("Completion took too many steps for input: "+ input);
            Debug.LogException(e);
        }
        if (completionSuccess)
        {
            completion = (string)completionVar.Value;
            dialogAct = Term.CopyInstantiation(dialogActVar.Value);
            if (this.IsTrue("well_formed_dialog_act", dialogAct))
            {
                formatted = completion == "" ?
                    string.Format("<b><color=lime>{0}</color></b>", input)
                    : string.Format("<color=lime>{0}{1}<i>{2}</i></color>",
                                    input,
                                    (input.EndsWith(" ") || input.EndsWith("'") 
                                      || !char.IsLetterOrDigit(completion[0])) 
                                    ? "" : " ",
                                    completion);
                var da = dialogAct as Structure;
                if (da != null && da.Arity > 1)
                {
                    var a = da.Argument<GameObject>(1);
                    commentary = string.Format("{0} to {1}\n{2}", da.Functor, (a == this) ? "myself" : a.name,
                                                    ISOPrologWriter.WriteToString(dialogActVar.Value));
                }
                else
                {
                    commentary = ISOPrologWriter.WriteToString(dialogActVar.Value);
                }
            }
            else
            {
                // Input is grammatical but not well formed.
                formatted = completion == "" ?
                    string.Format("<b><color=yellow>{0}</color></b>", input)
                    : string.Format("<color=yellow>{0}{1}</color><color=grey><i>{2}</i></color>",
                                    input,
                                    (input.EndsWith(" ") || !char.IsLetterOrDigit(completion[0])) ? "" : " ",
                                    completion);
                if (completion == "")
                    commentary = string.Format(
                        "This input is grammatical, but doesn't make sense to me\n{0}",
                        ISOPrologWriter.WriteToString(dialogActVar.Value));
                else
                {
                    commentary = "This is grammatical but nonsensical\n" + ISOPrologWriter.WriteToString(dialogActVar.Value);
                }
            }

        }
        else
        {
            formatted = string.Format("<color=red>{0}</color>", input);
            commentary = "Sorry; I don't understand any sentences beginning with those words.";
        }
    }

    #region Mouse handling
    /// <summary>
    /// The GameObject of the PhysicalObject over which the mouse is currently hovering.
    /// </summary>
    public GameObject MouseSelection;
    private void UpdateMouseSelection()
    {
        GameObject newSelection = null;

        foreach (var physob in FindObjectsOfType<PhysicalObject>())
        {
            var go = physob.gameObject;
            var rect = go.GUIScreenRect();
            if (rect.HasValue && rect.Value.Contains(Event.current.mousePosition))
                newSelection = go;
        }

        if (newSelection != MouseSelection)
            MouseSelectionChanged(newSelection);
    }

    GUIContent caption;
    GUIStyle captionStyle = new GUIStyle(GUIStyle.none);
    Vector2 captionSize;

    private void MouseSelectionChanged(GameObject newSelection)
    {
        MouseSelection = newSelection;
        if (MouseSelection != null)
        {
            captionStyle.normal.textColor = Color.white;
            var cap = new LogicVariable("Caption");
            caption =
                new GUIContent(
                    (string) KnowledgeBase.Global.SolveFor(cap, new Structure("caption", MouseSelection, cap), this));
            captionSize = captionStyle.CalcSize(caption);
        }
        TryCompletionIfCompleteWord();
    }

    protected void ShowMouseSelectionCaption()
    {
        if (MouseSelection != null)
        {
            var screenPosition = MouseSelection.GUIScreenPosition();
            var bubbleRect = new Rect(screenPosition.x, screenPosition.y, captionSize.x, captionSize.y);
            GUI.Box(bubbleRect, SimController.GreyOutTexture);
            GUI.Label(
                bubbleRect,
                caption,
                captionStyle);
        }
    }
    #endregion
}
