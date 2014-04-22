using System;

using UnityEngine;

namespace Prolog
{
    /// <summary>
    /// A wrapper for a Prolog KnowledgeBase as a Unity Component.
    /// </summary>
    class KB : MonoBehaviour
    {
        public string[] SourceFiles=new string[0];
        private KnowledgeBase kb;

        private static bool globalKBInitialized;

        public KnowledgeBase KnowledgeBase
        {
            get
            {
                if (kb == null)
                    this.MakeKB();

                return kb; 
            }
        }

        /// <summary>
        /// True if this is the KB object for the global Prolog knowledgebase.
        /// </summary>
        public bool IsGlobal
        {
            get
            {
                return name == "Global";
            }
        }

        internal void Awake()
        {
            if (IsGlobal)
            {
                if (globalKBInitialized)
                    Debug.LogError("There appear to be multiple KB components for the Global Prolog knowledgebase.");
                else
                    globalKBInitialized = true;
                this.MakeKB();
            }
        }

        internal void Start()
        {
            if (kb == null)
                MakeKB();
        }

        private void MakeKB()
        {

            var parentGameObject = transform.parent.gameObject;
            var parentKB = parentGameObject.GetComponent<KB>();
            kb = IsGlobal?
                KnowledgeBase.Global
                : new KnowledgeBase(
                    gameObject.name,
                    gameObject,
                    parentKB == null ? KnowledgeBase.Global : parentKB.KnowledgeBase);
            try
            {
                foreach (var file in SourceFiles)
                    kb.Consult(file);
            }
            catch (Exception)
            {
                Debug.Break(); // Pause the game
                throw;
            }
        }
    }
}
