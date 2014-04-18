using System;
using System.Collections.Generic;

using Prolog;

using UnityEngine;

[AddComponentMenu("Sims/Sim Controller")]
public class SimController : BindingBehaviour
{
    /// <summary>
    /// Whether to log actions as they're taken.
    /// </summary>
    public bool LogActions;

    #region Bindings to other components
#pragma warning disable 649
    [Bind]
    private CharacterSteeringController steering;

    [Bind(BindingScope.Global, BindingDefault.Create)]
    private PathPlanner planner;
#pragma warning restore 649
    #endregion

    #region Private fields

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

    /// <summary>
    /// Object being locomoted to, if any.
    /// </summary>
    private GameObject currentDestination;
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
        this.eventQueue.Enqueue(eventDescription);
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
        while (EventsPending)
            this.InitiateAction(this.HandleEvent(this.GetNextEvent()));
    }

    /// <summary>
    /// Call into Prolog to respond to EVENTDESCRIPTION
    /// </summary>
    /// <param name="eventDescription">Term representing the event</param>
    /// <returns>Action to take or null.</returns>
    private Structure HandleEvent(object eventDescription)
    {
        // There really ought to be a better way to do this...
        var answer = new LogicVariable("answer");
        var goal = new Structure("handle_event", eventDescription, answer);
        return (Structure)this.SolveFor(answer, goal);
    }
    #endregion

    #region Unity hooks
    internal void Update()
    {
        // Clear speech bubble if it's time.
        if (Time.time > this.clearSpeechTime)
            this.currentSpeechBubbleText = null;

        if (this.currentPath != null)
            // Update the steering
            if (this.currentPath.UpdateSteering(this.steering))
                // Finished the path
                this.currentPath = null;

        // Query Prolog if we have nothing to do.
        if (currentPath == null)
        {
            if (this.currentDestination == null)
                this.QueueEvent("next_action", null);
            else 
                this.QueueEvent("arrived_at", this.currentDestination);
            this.currentDestination = null;
        }

        this.HandleEvents();
    }

    internal void OnCollisionEnter2D(Collision2D collision)
    {
        this.QueueEvent("collision", collision.gameObject);
    }
    #endregion

    #region Primitive actions handled by SimController
    void InitiateAction(object action)
    {
        if (action == null)
            return;

        var structure = action as Structure;
        if (structure != null)
        switch (structure.Functor.Name)
        {
            case "goto":
                currentDestination = structure.Argument<GameObject>(0);
                if (currentDestination == null)
                    steering.Stop();
                else
                    this.currentPath = planner.Plan(gameObject.TilePosition(), currentDestination.DockingTiles());
                break;

            case "face":
                this.Face(structure.Argument<GameObject>(0));
                break;

            case "say":
                this.Say(structure.Argument<string>(0));
                clearSpeechTime = Time.time + 2;
                break;

            case "cons":
                // It's a list of actions to initiate.
                this.InitiateAction(structure.Argument(0));
                this.InitiateAction(structure.Argument(1));
                break;

            default:
                Debug.LogError("Bad structure: "+ISOPrologWriter.WriteToString(structure));
                break;
        }
        else
        {
            var sym = action as Symbol;
            if (sym == null)
                throw new InvalidOperationException("Unknown action: "+ISOPrologWriter.WriteToString(action));
            switch (sym.Name)
            {
                case "stop":
                    steering.Stop();
                    break;

                default:
                    throw new InvalidOperationException("Unknown action: " + ISOPrologWriter.WriteToString(action));
            }
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
    }
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
