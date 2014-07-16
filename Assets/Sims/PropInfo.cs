using System;
using System.Linq;

using Prolog;

using UnityEngine;

public class PropInfo : MonoBehaviour
{
    public string CommonNoun;

    public string Plural;

    char[] vowels = {'a', 'e', 'i', 'o', 'u'};
    public void Awake()
    {
        if (string.IsNullOrEmpty(CommonNoun))
            CommonNoun = name.ToLower();
        if (string.IsNullOrEmpty(Plural) && !string.IsNullOrEmpty(CommonNoun))
            switch (CommonNoun[CommonNoun.Length - 1])
            {
                case 's':
                case 'o':
                    Plural = CommonNoun + "es";
                    break;

                case 'f':
                    Plural = CommonNoun.Substring(0, CommonNoun.Length - 1) + "ves";
                    break;

                case 'y':
                    var secondToLast = CommonNoun[CommonNoun.Length - 2];
                    if (vowels.Contains(secondToLast))
                        Plural = CommonNoun + "s";
                    else
                    {
                        Plural = CommonNoun.Substring(0, CommonNoun.Length - 1) + "ies";
                    }
                    break;
                default:
                    Plural = CommonNoun + "s";
                    break;
            }
    }

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
