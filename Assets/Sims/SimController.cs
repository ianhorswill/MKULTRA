using System;
using System.Collections.Generic;
using Prolog;
using UnityEngine;

[AddComponentMenu("Sims/Sim Controller")]
public class SimController : BindingBehaviour
{
    #region Constants
    /// <summary>
    /// The radius of the the circular region around the character that defines
    /// its "conversational space".  Two characters having a conversation should
    /// normally be within one anothers' conversational spaces.
    /// </summary>
    private const float ConversationalSpaceRadius = 2;
    private const float SocialSpaceRadius = 4;

    /// <summary>
    /// Maximum number of characters that can be within a character's conversational space.
    /// </summary>
    private const int MaxConversationalSpaceColliders = 30;
    #endregion

    /// <summary>
    /// Whether to log actions as they're taken.
    /// </summary>
    public bool LogActions;

    /// <summary>
    /// Is this character currently talking?
    /// </summary>
    public bool IsSpeaking
    {
        get
        {
            return currentSpeechBubbleText != null;
        }
    }

    #region Bindings to other components
#pragma warning disable 649
    [Bind]
    private CharacterSteeringController steering;

    [Bind(BindingScope.Global, BindingDefault.Create)]
    private PathPlanner planner;
#pragma warning restore 649
    #endregion

    #region Private fields

    private ELNode elRoot;

    private ELNode perceptionRoot;

    private ELNode conversationalSpace;

    private ELNode socialSpace;

    private ELNode lastDestination;

    private ELNode eventHistory;

    private ELNode motorRoot;

    readonly Queue<Structure> eventQueue = new Queue<Structure>();

    /// <summary>
    /// Holds the current text for the character's speech bubble.
    /// Set to null is no active text.
    /// </summary>
    string currentSpeechBubbleText;

    /// <summary>
    /// Time at which currentSpeechBubbleText should be set to null.
    /// </summary>
    private float clearSpeechTime;

    /// <summary>
    /// Current path being followed if the character is moving.  Null if no current locomotion goal.
    /// </summary>
    private TilePath currentPath;

    private GameObject currentDestination;

    /// <summary>
    /// Object being locomoted to, if any.
    /// </summary>
    /// <summary>
    /// Object being locomoted to, if any.
    /// </summary>
    public GameObject CurrentDestination
    {
        get
        {
            return this.currentDestination;
        }
        set
        {
            this.currentDestination = value;
            if (currentDestination == null)
            {
                motorRoot.DeleteKey(SWalkingTo);
            }
            else
                ELNode.Store(motorRoot/SWalkingTo%CurrentDestination);
        }
    }

    /// <summary>
    /// Time to wake character up and ask for an action.
    /// </summary>
    private float? sleepUntil;
    #endregion

    #region Event queue operations
    /// <summary>
    /// True if there are events waiting to be processed.
    /// </summary>
    bool EventsPending
    {
        get
        {
            return this.eventQueue.Count > 0;
        }
    }

    private static readonly object[] NullArgs = { null };
    /// <summary>
    /// Informs character of the specified event.  Does not copy the arguments.
    /// </summary>
    /// <param name="eventType">Type of event (functor of the Prolog structure describing the event)</param>
    /// <param name="args">Other information (arguments to the functor).
    /// WARNING: does not copy arguments, so they must either be ground or not used elsewhere.</param>
    public void QueueEvent(string eventType, params object[] args)
    {
        if (args == null)
            args = NullArgs;
        this.QueueEvent(new Structure(Symbol.Intern(eventType), args));
    }

    /// <summary>
    /// Informs character of the specified event.  Does not copy the eventDescription.
    /// </summary>
    /// <param name="eventDescription">A Prolog term describing the event.
    /// WARNING: does not copy the term, so it must either be ground or not used elsewhere.</param>
    public void QueueEvent(Structure eventDescription)
    {
        this.eventQueue.Enqueue((Structure)Term.CopyInstantiation(eventDescription));
    }

    Structure GetNextEvent()
    {
        return this.eventQueue.Dequeue();
    }
    #endregion

    #region Event handling
    /// <summary>
    /// Calls Prolog on all pending events and initiates any actions it specifies.
    /// </summary>
    private void HandleEvents()
    {
        if (EventsPending)
            this.sleepUntil = null;
        while (EventsPending)
            this.NotifyEvent(this.GetNextEvent());
    }

    private static readonly Symbol SSleep = Symbol.Intern("sleep");

    private static bool IsSleep(object eventDescription)
    {
        var s = eventDescription as Structure;
        return (s != null && s.IsFunctor(SSleep, 1));
    }

    /// <summary>
    /// Call into Prolog to respond to EVENTDESCRIPTION
    /// </summary>
    /// <param name="eventDescription">Term representing the event</param>
    private void NotifyEvent(object eventDescription)
    {
        ELNode.Store(eventHistory/Term.CopyInstantiation(eventDescription));
        if (!this.IsTrue(new Structure(SNotifyEvent, eventDescription)))
            Debug.LogError("notify_event/1 failed: "+ISOPrologWriter.WriteToString(eventDescription));
    }

    private static readonly Symbol SNotifyEvent = Symbol.Intern("notify_event");
    #endregion

    #region Unity hooks
    internal void Start()
    {
        elRoot = this.KnowledgeBase().ELRoot;
        this.perceptionRoot = elRoot / Symbol.Intern("perception");
        this.conversationalSpace = perceptionRoot / Symbol.Intern("conversational_space");
        this.socialSpace = perceptionRoot / Symbol.Intern("social_space");
        this.motorRoot = elRoot / Symbol.Intern("motor_state");
        this.eventHistory = elRoot / Symbol.Intern("event_history");
        this.lastDestination = elRoot / Symbol.Intern("last_destination");
        ELNode.Store(lastDestination % null);  // Need a placeholder last destination so that /last_destination/X doesn't fail.
    }

    internal void Update()
    {
        this.UpdateSpeechBubble();

        this.UpdateLocomotion();

        this.UpdateSpace(conversationalSpaceColliders, ConversationalSpaceRadius, conversationalSpace,
                         "enter_conversational_space", "exit_conversational_space", true);
        this.UpdateSpace(socialSpaceColliders, SocialSpaceRadius, socialSpace,
                         "enter_social_space", "exit_social_space", false);

        this.HandleEvents();

        this.MaybeDoNextAction();
    }

    internal void OnCollisionEnter2D(Collision2D collision)
    {
        this.QueueEvent("collision", collision.gameObject);
    }
    #endregion

    #region Perception update
    readonly Collider2D[] conversationalSpaceColliders = new Collider2D[MaxConversationalSpaceColliders];
    readonly Collider2D[] socialSpaceColliders = new Collider2D[MaxConversationalSpaceColliders];

    // ReSharper disable once InconsistentNaming
    private readonly Symbol SNobodySpeaking = Symbol.Intern("nobody_speaking");
    
    /// <summary>
    /// Update the set of character's within this characters' conversational space
    /// and generate any necessary enter/leave events.
    /// </summary>
    private void UpdateSpace(Collider2D[] colliders, float radius, ELNode statusNode, string enterEvent, string exitEvent, bool updateNobodySpeaking)
    {
        var characterCount = Physics2D.OverlapCircleNonAlloc(
            transform.position,
            radius,
            colliders,
            1 << gameObject.layer);
        if (characterCount==MaxConversationalSpaceColliders)
            throw new Exception("Too many colliders in conversational space!");

        // Clean out entries that are no longer in the area
        statusNode.DeleteAll(
            node =>
            {
                // Look to see if node's key (a character) appears in the colliders
                for (var i = 0; i<characterCount;i++)
                    if (ReferenceEquals(node.Key, colliders[i].gameObject))
                        return false;
                // It doesn't, so the character left this character's conversational space.

                // Tell this character about it
                QueueEvent(exitEvent, node.Key);

                // Remove the character
                return true;
            });

        // Add new entries
        for (var i = 0; i<characterCount;i++)
        {
            var character = colliders[i].gameObject;
            if (character != gameObject && !statusNode.ContainsKey(character))
            {
                // The character just arrived in this character's conversational space

                // Tell this character
                QueueEvent(enterEvent, character);

                // Update the KB
                ELNode.Store(statusNode/character);
            }
        }

        if (updateNobodySpeaking)
        {
            bool nobodySpeaking = true;
            for (var i = 0; i<characterCount; i++)
                if (colliders[i].GetComponent<SimController>().IsSpeaking)
                    nobodySpeaking = false;
            if (nobodySpeaking)
                ELNode.Store(perceptionRoot/SNobodySpeaking);
            else
            {
                perceptionRoot.DeleteKey(SNobodySpeaking);
            }
        }
    }
    #endregion

    #region Primitive actions handled by SimController
    private void MaybeDoNextAction()
    {
        if (!this.sleepUntil.HasValue || this.sleepUntil.Value <= Time.time)
        {
            this.DoNextAction();
        }
    }

    void DoNextAction()
    {
        var action = new LogicVariable("Action");
        this.InitiateAction(this.SolveFor(action, new Structure(SNextAction, action)));
    }

    private static readonly Symbol SNextAction = Symbol.Intern("next_action");

    private static readonly Symbol SWalkingTo = Symbol.Intern("walking_to");

    private static readonly Symbol SLastAction = Symbol.Intern("last_action");

    private void InitiateAction(object action)
    {
        if (action == null)
            return;

        var actionCopy = Term.CopyInstantiation(action);
        ELNode.Store(motorRoot / SLastAction % actionCopy);

        var structure = action as Structure;
        if (structure != null)
        {
            switch (structure.Functor.Name)
            {
                case "goto":
                    this.CurrentDestination = structure.Argument<GameObject>(0);
                    if (this.CurrentDestination == null)
                        steering.Stop();
                    else
                        this.currentPath = planner.Plan(
                            gameObject.TilePosition(),
                            this.CurrentDestination.DockingTiles());
                    break;

                case "face":
                    this.Face(structure.Argument<GameObject>(0));
                    break;

                case "say":
                    // Say a fixed string
                    this.Say(structure.Argument<string>(0));
                    break;

                case "dialog":
                    // Perform a general dialog action
                    var recipient = (GameObject)structure.Argument(1);
                    var dialogAct = structure.Argument(2);
                    var textVar = new LogicVariable("DialogText");
                    var text = gameObject.SolveFor(textVar, "generate_text", dialogAct, recipient, textVar);
                    var textString = text as string;
                    if (textString == null)
                        throw new Exception("generate_text returned "+ISOPrologWriter.WriteToString(text)+" for "+ISOPrologWriter.WriteToString(dialogAct));
                    this.Say(textString);

                    // Tell the other characters
                    foreach (var node in socialSpace.Children)
                    {
                        var character = (GameObject)(node.Key);
                        if (character != this.gameObject)
                            character.QueueEvent((Structure)Term.CopyInstantiation(structure));
                    }
                    break;

                case "cons":
                    // It's a list of actions to initiate.
                    this.InitiateAction(structure.Argument(0));
                    this.InitiateAction(structure.Argument(1));
                    break;

                case "sleep":
                    this.sleepUntil = Time.time + Convert.ToSingle(structure.Argument(0));
                    break;

                default:
                    Debug.LogError("Bad structure: " + ISOPrologWriter.WriteToString(structure));
                    break;
            }
        }
        else
        {
            var sym = action as Symbol;
            if (sym == null)
                throw new InvalidOperationException("Unknown action: " + ISOPrologWriter.WriteToString(action));
            switch (sym.Name)
            {
                case "stop":
                    steering.Stop();
                    break;

                default:
                    throw new InvalidOperationException("Unknown action: " + ISOPrologWriter.WriteToString(action));
            }
        }
        if (!IsSleep(action))
            QueueEvent("begin", action);
    }

    private void UpdateLocomotion()
    {
        if (this.currentPath != null)
        {
            // Update the steering
            if (this.currentPath.UpdateSteering(this.steering))
            {
                // Finished the path
                this.currentPath = null;
            }
        }

        // Query Prolog if we have nothing to do.
        if (this.currentPath == null && this.CurrentDestination != null)
        {
            ELNode.Store(lastDestination % this.CurrentDestination);
            this.QueueEvent("arrived_at", this.CurrentDestination);
            this.CurrentDestination = null;
        }
    }

    private void UpdateSpeechBubble()
    {
        // Clear speech bubble if it's time.
        if (this.currentSpeechBubbleText != null && Time.time > this.clearSpeechTime)
        {
            this.currentSpeechBubbleText = null;
            this.motorRoot.DeleteKey(SIAmSpeaking);
        }
    }

    /// <summary>
    /// Turns character to face the specified GameObject
    /// </summary>
    /// <param name="target">Object to face</param>
    public void Face(GameObject target)
    {
        steering.Face(target.Position() - (Vector2)transform.position);
    }

    /// <summary>
    /// Displays the specified string.
    /// </summary>
    /// <param name="speech">String to display</param>
    public void Say(string speech)
    {
        this.currentSpeechBubbleText = speech;
        ELNode.Store(motorRoot / SIAmSpeaking);
        clearSpeechTime = Time.time + 2;
    }

    // ReSharper disable once InconsistentNaming
    private static readonly Symbol SIAmSpeaking = Symbol.Intern("i_am_speaking");
    #endregion

    #region Speech bubbles
    public GUIStyle SpeechBubbleStyle;

    internal void OnGUI()
    {
        if (Camera.current != null && !string.IsNullOrEmpty(this.currentSpeechBubbleText))
        {
            var bubblelocation = (Vector2)Camera.current.WorldToScreenPoint(transform.position);
            GUI.Label(new Rect(bubblelocation.x, Camera.current.pixelHeight-bubblelocation.y, 300, 300), this.currentSpeechBubbleText, SpeechBubbleStyle);
        }
    }
    #endregion
}
