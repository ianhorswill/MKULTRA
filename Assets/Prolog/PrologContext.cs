using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Text;

using UnityEngine;

namespace Prolog
{
    /// <summary>
    /// Controls the execution of a prolog program.
    /// </summary>
    [System.Diagnostics.DebuggerDisplay("Top={GoalStackTopSafe}")]
    public class PrologContext
    {
        /// <summary>
        /// The last PrologContext that threw an exception.
        /// </summary>
        public static PrologContext LastExceptionContext { get; set; }

        /// <summary>
        /// Default maximum number of steps the inference can run for
        /// </summary>
        public static int DefaultStepLimit { get; set; }

        private int stepLimit;

        private bool isFree;

        public TextWriter Output;

        public object This;

        public GameObject GameObject
        {
            get
            {
                return KnowledgeBase.GameObject;
            }
        }

        /// <summary>
        /// Default maximum number of steps the inference can run for
        /// </summary>
        public int StepLimit
        {
            get { return stepLimit;  }
            set { 
                int delta = value - stepLimit;
                stepLimit = value;
                StepsRemaining += delta;
            }
        }

        static PrologContext()
        {
            DefaultStepLimit = 5000;
        }

        /// <summary>
        /// Creates a PrologContext with PrologContext.DefaultStepLimit
        /// </summary>
        private PrologContext(KnowledgeBase kb)
            : this(kb, DefaultStepLimit)
        { }

        static readonly Stack<PrologContext> FreeContexts = new Stack<PrologContext>();

        /// <summary>
        /// Gets a context that is currently free to use.  Should be relased afterward using ReleaseContext().
        /// </summary>
        /// <returns>A free PrologContext</returns>
        public static PrologContext GetFreePrologContext(KnowledgeBase kb, object thisValue)
        {
            if (FreeContexts.Count > 0)
            {
                var c = FreeContexts.Pop();
                if (!c.isFree)
                    throw new InvalidOperationException("Allocated PrologContext is still in use!");
                c.isFree = false;
                c.KnowledgeBase = kb;
                c.Reset(thisValue);
                c.Output = Console.Out;
                return c;
            }
            return new PrologContext(kb) { This = thisValue };
        }

        /// <summary>
        /// Deallocates a PrologContext that was allocated using GetFreePrologContext().
        /// </summary>
        /// <param name="c">Context to deallocate.</param>
        public static void ReleaseContext(PrologContext c)
        {
            c.isFree = true;
            FreeContexts.Push(c);
        }

        /// <summary>
        /// Creates a PrologContext that can for at most the specified number of steps.
        /// </summary>
        public PrologContext(KnowledgeBase kb, int stepLimit) {
            StepsRemaining = stepLimit;
            goalStackFunctor = new List<Symbol>();
            goalStackArguments = new List<object[]>();
            goalStackParent = new List<ushort>();
            GoalStackDepth = 0;
            KnowledgeBase = kb;
            traceVariables = new LogicVariable[256];
            traceValues = new object[256];
            tracePointer = 0;
        }
        
        /// <summary>
        /// Check whether the maximum number of steps has been exceeded.
        /// Called when a new step is initiated.
        /// </summary>
        internal void NewStep() {
            StepsRemaining -= 1;
            if (StepsRemaining < 0)
                throw new InferenceStepsExceededException();
        }

        /// <summary>
        /// Number of further steps this inference is allowed to run for.
        /// </summary>
        public int StepsRemaining { get; set; }

        /// <summary>
        /// Number of inference steps (calls to Prove) performed
        /// </summary>
        public int StepsUsed
        {
            get { return StepLimit - StepsRemaining; }
        }

        /// <summary>
        /// Whether predicates should be randomized.
        /// </summary>
        public bool Randomize { get; set; }

        /// <summary>
        /// Resets the context (clears stack, etc.) and starts a proof of the specified goal.
        /// </summary>
        /// <param name="goal">Goal to attempt to prove</param>
        /// <returns>Enumerator for solutions</returns>
        public IEnumerable<bool> ResetStackAndProve(Structure goal)
        {
            Reset(this.This);
            foreach (var state in KnowledgeBase.Prove(goal.Functor, goal.Arguments, this, 0))
                if (state == CutState.ForceFail)
                    yield break;
                else
                    yield return false;
        }

        /// <summary>
        /// Resets the context (clears stack, etc.) and starts a proof of the specified goal.
        /// </summary>
        /// <param name="goal">Goal to attempt to prove</param>
        /// <returns>Enumerator for solutions</returns>
        public IEnumerable<bool> ResetStackAndProve(object goal)
        {
            Reset(this.This);
            Structure s = Term.Structurify(goal, "Invalid goal.");
            foreach (var state in KnowledgeBase.Prove(s.Functor, s.Arguments, this, 0))
                if (state == CutState.ForceFail)
                    yield break;
                else
                    yield return false;
        }

        /// <summary>
        /// Proves the goal in the specified structure.
        /// </summary>
        internal IEnumerable<CutState> Prove(Structure goal)
        {
            return KnowledgeBase.Prove(goal.Functor, goal.Arguments, this, CurrentFrame);
        }

        /// <summary>
        /// Proves the specified goal, throwing an exception with badGoalErrorMessage if the goal is ill-formed.
        /// </summary>
        internal IEnumerable<CutState> Prove(object goal, string badGoalErrorMessage)
        {
            Structure s = Term.Structurify(goal, badGoalErrorMessage);
            return KnowledgeBase.Prove(s.Functor, s.Arguments, this, CurrentFrame);
        }

        /// <summary>
        /// The KB to use for inference.
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1702:CompoundWordsShouldBeCasedCorrectly", MessageId = "KnowledgeBase")]
        public KnowledgeBase KnowledgeBase { get; internal set; }

        #region Goal stack operations
        /// <summary>
        /// Number of goals on the stack, meaning it's also the index at which to store the NEXT new subgoal.
        /// </summary>
        public ushort GoalStackDepth { get; private set; }

        /// <summary>
        /// The stackaddress of the current stack frame.
        /// </summary>
        public ushort CurrentFrame
        {
            get
            {
                return (ushort)(GoalStackDepth - 1);
            }
        }

        /// <summary>
        /// Functors of goals on stack. 
        /// </summary>
        readonly List<Symbol> goalStackFunctor;
        /// <summary>
        /// Arguments of goals on stack.
        /// </summary>
        readonly List<object[]> goalStackArguments;
        /// <summary>
        /// Stack pointers for parent goals of parents frames of goals.
        /// </summary>
        readonly List<ushort> goalStackParent;

        ///// <summary>
        ///// All the frames currently on the stack, starting at the bottom.
        ///// </summary>
        //public IEnumerable<Term> GoalStack
        //{
        //    get
        //    {
        //        for (int i = 0; i < GoalStackDepth; i++)
        //            yield return (goalStackFunctor[i]==null)?null:new Term(goalStackFunctor[i], goalStackArguments[i]);
        //    }
        //}

        /// <summary>
        /// Returns the goal at the specified position on the stack
        /// </summary>
        public Structure GoalStackGoal(ushort frame)
        {
            if (goalStackFunctor[frame] != null)
                return new Structure(goalStackFunctor[frame], goalStackArguments[frame]);
            return null;
        }

        /// <summary>
        /// Returns the stack position of the parent goal of the goal at the specified position on the stack
        /// </summary>
        public ushort GoalStackParent(ushort frame)
        {
            return goalStackParent[frame];
        }

        /// <summary>
        /// The goal at the top of the stack (i.e. the most recent/most-recursed subgoal).
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA2204:Literals should be spelled correctly", MessageId = "GoalStackTop")]
        public Structure GoalStackTop
        {
            get
            {
                return GetStackTop(true);
            }
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Performance", "CA1811:AvoidUncalledPrivateCode")]
// ReSharper disable UnusedMember.Local
        Structure GoalStackTopSafe
// ReSharper restore UnusedMember.Local
        {
            get
            {
                return GetStackTop(false);
            }
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA2204:Literals should be spelled correctly", MessageId = "GoalStackTop")]
        private Structure GetStackTop(bool throwOnEmptyStack)
        {
            if (GoalStackDepth == 0)
            {
                if (throwOnEmptyStack)
                    throw new InvalidOperationException("GoalStackTop: Goal stack is empty");
                return null;
            }
            if (goalStackFunctor[GoalStackDepth - 1] == null)
                return new Structure(goalStackFunctor[GoalStackDepth - 2], goalStackArguments[GoalStackDepth - 2]);
            return new Structure(goalStackFunctor[GoalStackDepth - 1], goalStackArguments[GoalStackDepth - 1]);
        }

        public void Reset()
        {
            this.Reset(this.This);
        }

        /// <summary>
        /// Forcibly clears the execution context.
        /// </summary>
        public void Reset(object thisValue)
        {
            GoalStackDepth = 0;
            dataStackPointer = 0;
            if (wokenStack != null)
                wokenStack.Clear();
            StepsRemaining = StepLimit = DefaultStepLimit;
            this.This = thisValue;
        }

        /// <summary>
        /// Renews the step limit (e.g. for when the repl is asking for a new solution.
        /// </summary>
        public void ResetStepLimit()
        {
            StepsRemaining = DefaultStepLimit;
        }

        /// <summary>
        /// Adds a new goal to the goal stack
        /// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "functor")]
        public void PushGoalStack(Symbol functor, object[] args, ushort parentFrame)
        {
            if (GoalStackDepth >= goalStackArguments.Count)
            {
                goalStackFunctor.Add(functor);
                goalStackArguments.Add(args);
                goalStackParent.Add(parentFrame);
            }
            else
            {
                goalStackFunctor[GoalStackDepth] = functor;
                goalStackArguments[GoalStackDepth] = args;
                goalStackParent[GoalStackDepth] = parentFrame;
            }
            GoalStackDepth++;
        }

        /// <summary>
        /// Mark that this is the start of a new clause
        /// </summary>
        public ushort PushClause()
        {
            PushGoalStack(null, null, 0);
            return (ushort)(GoalStackDepth - 2);
        }

        /// <summary>
        /// Removes the top goal from the goal stack
        /// </summary>
        public void PopGoalStack()
        {
            GoalStackDepth = (ushort)(GoalStackDepth - 1);
        }

        /// <summary>
        /// Resets the stack to the specified depth.
        /// </summary>
        public void UnwindStack(ushort depth)
        {
            GoalStackDepth = depth;
        }

        /// <summary>
        /// Generate a stack trace that's close enough to a normal mono stack dump that the Unity logger will understand it.
        /// </summary>
        /// <param name="sourcePath">Path for the source file being loaded.</param>
        /// <param name="lineNumber">Current line number in the source file.</param>
        /// <param name="toplevelCommand">Original prolog command to output, if stack is empty.</param>
        /// <returns></returns>
        public string StackTrace(string sourcePath, int lineNumber, string toplevelCommand)
        {
            var result = new StringBuilder();
            if (this.GoalStackDepth > 0)
                for (ushort i = 0; i <= this.CurrentFrame; i++)
                {
                    Structure g = this.GoalStackGoal(i);
                    if (g != null)
                    {
                        ushort frame = i;
                        while (frame != 0)
                        {
                            //Output.Write("{0}/", frame);
                            result.Append("  ");
                            frame = this.GoalStackParent(frame);
                        }
                        //Output.Write(' ');
                        //Output.Write("{0}<{1}: ", i, PrologContext.GoalStackParent(i));
                        result.Append(Term.ToStringInPrologFormat(g));
                        result.AppendFormat(" (at {0}:{1})", sourcePath, lineNumber);
                        result.AppendLine();
                    }
                }
            else
                result.AppendFormat("{0} (at {1}:{2})\n", toplevelCommand, sourcePath, lineNumber);
            return result.ToString();
        }

        #endregion

        #region Trace (undo stack) operations
        /// <summary>
        /// The position in the trace where the next spilled variable will be stored.
        /// </summary>
        private int tracePointer;

        private LogicVariable[] traceVariables;
        private object[] traceValues;

        /// <summary>
        /// Saves the current value of a variable on the trace (i.e. the undo stack).
        /// </summary>
        public void SaveVariable(LogicVariable lvar)
        {
            if (tracePointer==traceVariables.Length)
            {
                var newTraceVariables = new LogicVariable[traceVariables.Length*2];
                var newTraceValues = new object[traceVariables.Length*2];
                traceVariables.CopyTo(newTraceVariables, 0);
                traceValues.CopyTo(newTraceValues, 0);
                traceVariables = newTraceVariables;
                traceValues = newTraceValues;
            }
            traceVariables[tracePointer] = lvar;
            traceValues[tracePointer] = lvar.mValue;
            tracePointer++;
        }

        /// <summary>
        /// Restores the values of all variables back to the specified position on the trace (i.e. the undo stack).
        /// </summary>
        public void RestoreVariables(int savedTracePointer)
        {
            AbortWokenGoals(savedTracePointer);
            while (tracePointer != savedTracePointer)
            {
                tracePointer--;
                traceVariables[tracePointer].mValue = traceValues[tracePointer];
            }
        }

        /// <summary>
        /// Marks a place on the trace so subsequent bindings can be undone.
        /// Present implementation does not actually modify the stack in any way.
        /// </summary>
        /// <returns></returns>
        public int MarkTrace()
        {
            return tracePointer;
        }
        #endregion

        #region Data stack operations
        private object[] dataStack = new object[256];
        private int dataStackPointer;
        /// <summary>
        /// Reserve space for a new frame.
        /// </summary>
        /// <param name="size">Number of words needed for frame</param>
        public int MakeFrame(int size)
        {
            int framePointer = dataStackPointer;
            dataStackPointer += size;
            if (dataStackPointer>dataStack.Length)
            {
                var newStack = new object[dataStack.Length*2+ByteCompiledRule.MaxArity];
                dataStack.CopyTo(newStack,0);
                dataStack = newStack;
            }
            return framePointer;
        }

        /// <summary>
        /// Resets stack pointer to point at base of old frame.
        /// </summary>
        /// <param name="framePointer">Base of the frame we're popping off</param>
        public void PopFrame(int framePointer)
        {
            dataStackPointer = framePointer;
        }

        /// <summary>
        /// Reads a value from the stack.
        /// </summary>
        /// <param name="frame">Base address of stack frame</param>
        /// <param name="offset">Offset into stack frame</param>
        /// <returns>Value of stack entry</returns>
        public object GetStack(int frame, int offset)
        {
            return dataStack[frame + offset];
        }

        /// <summary>
        /// Modifies a value from the stack.
        /// </summary>
        /// <param name="frame">Base address of stack frame</param>
        /// <param name="offset">Offset into stack frame</param>
        /// <param name="value">New value for stack variable</param>
        public void SetStack(int frame, int offset, object value)
        {
            dataStack[frame + offset] = value;
        }

        /// <summary>
        /// Sets argument for an upcoming call.
        /// </summary>
        /// <param name="argumentNumber">Index of the argument (0=first, 1=second, etc.)</param>
        /// <param name="value">Value of the argument</param>
        public void SetCallArg(int argumentNumber, object value)
        {
            dataStack[dataStackPointer + argumentNumber] = value;
        }

        /// <summary>
        /// Copies args to a arguments position for the next stack frame.
        /// </summary>
        internal void PushArguments(object[] args)
        {
            args.CopyTo(dataStack, dataStackPointer);
        }

        /// <summary>
        /// Copies args to a arguments position for the next stack frame.
        /// </summary>
        internal void PushArguments(IList args)
        {
            args.CopyTo(dataStack, dataStackPointer);
        }

        internal object[] GetCallArgumentsAsArray(int arity)
        {
            var args = new object[arity];
            Array.Copy(dataStack, dataStackPointer, args, 0, arity);
            return args;
        }

        #endregion

        #region Suspended goal stack
        /// <summary>
        /// Represents a recently woken goal.
        /// We keep a saved trace pointer so that if we have to abort the current unification before the goals are run, we can recognize which ones to remove.
        /// </summary>
        private class WokenGoal
        {
            public int TracePointer;
            public Structure Goal;
        }
        private Stack<WokenGoal> wokenStack;
        internal void WakeUpGoal(Structure goal)
        {
            if (wokenStack == null)
                wokenStack = new Stack<WokenGoal>();
            wokenStack.Push(new WokenGoal { TracePointer = tracePointer, Goal = goal});
        }

        void AbortWokenGoals(int newTracePointer)
        {
            if (wokenStack == null)
                return;
            while (wokenStack.Count > 0 && wokenStack.Peek().TracePointer > newTracePointer)
                wokenStack.Pop();
        }

        /// <summary>
        /// True if there are woken goals to process.
        /// </summary>
        public bool GoalsHaveWoken
        {
            get { return wokenStack != null && wokenStack.Count > 0;  }
        }

        /// <summary>
        /// Attempts to prove all woken goals, in the order they were woken.
        /// 
        /// </summary>
        internal IEnumerable<CutState> ProveAllWokenGoals()
        {
            if (wokenStack == null || wokenStack.Count==0)
                return PrologPrimitives.SucceedDriver();
            WokenGoal[] goals = wokenStack.ToArray();
            wokenStack.Clear();
            return ProveWokenGoalsInternal(goals, 0);
        }

        private IEnumerable<CutState> ProveWokenGoalsInternal(WokenGoal[] goals, int goalIndex)
        {
#pragma warning disable 168
            // ReSharper disable UnusedVariable
            foreach (var ignore in Prove(goals[goalIndex].Goal))
                if (goalIndex < goals.Length - 1)
                    foreach (var ignore2 in ProveWokenGoalsInternal(goals, goalIndex + 1))
                        // ReSharper restore UnusedVariable
#pragma warning restore 168
                        yield return CutState.Continue;
                else
                    yield return CutState.Continue;
        }
        #endregion

        /// <summary>
        /// Prints trace information.
        /// </summary>
        public void TraceOutput(string format, object arg)
        {
            ushort frame = CurrentFrame;
            while (frame != 0)
            {
                Prolog.TraceOutput.Write(' ');
                frame = goalStackParent[frame];
            }
            Prolog.TraceOutput.WriteLine(format, arg);
        }
    }
}
