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

        public KnowledgeBase KnowledgeBase
        {
            get
            {
                if (kb == null)
                    this.MakeKB();
                return kb; 
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
            kb = new KnowledgeBase(
                gameObject.name, 
                gameObject,
                parentKB == null ? KnowledgeBase.Global : parentKB.KnowledgeBase
                );
            try
            {
                foreach (var file in SourceFiles)
                    kb.Consult(file);
            }
            catch (Exception)
            {
                Debug.Break();   // Pause the game
                throw;
            }
        }
    }
}
