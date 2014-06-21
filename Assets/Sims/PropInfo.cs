using System;

using Prolog;

using UnityEngine;

public class PropInfo : MonoBehaviour
{
    public string CommonNoun;

    public string Plural;

    public void Start()
    {
        if (string.IsNullOrEmpty(CommonNoun))
            CommonNoun = name;
        if (string.IsNullOrEmpty(Plural))
            Plural = CommonNoun + (CommonNoun.EndsWith("s") ? "es" : "s");
        if (!KB.Global.IsTrue("register_prop", gameObject, Symbol.Intern(CommonNoun), Symbol.Intern(Plural)))
            throw new Exception("Can't register prop "+name);
    }
}
