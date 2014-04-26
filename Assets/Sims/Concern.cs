using System;
using Prolog;
using UnityEngine;

public class Concern : MonoBehaviour
{
    public string[] Concerns = new string[0];

    internal void Start()
    {
        foreach (var c in Concerns)
        {
            if (!this.IsTrue("begin_concern", Symbol.Intern(c)))
                throw new Exception(string.Format("Could not initiate concern {0} in character {1}", c, name));
        }
    }
}
