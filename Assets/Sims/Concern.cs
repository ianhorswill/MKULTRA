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
            this.Assert("special_concern", Symbol.Intern(c));
        }
    }
}
