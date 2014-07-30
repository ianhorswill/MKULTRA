using System;
using System.Collections.Generic;
using System.Linq;
using Prolog;

using UnityEngine;

public class PropInfo : PhysicalObject
{
    /// <summary>
    /// True if this is a container that can hold other things.
    /// </summary>
    public bool IsContainer;

    /// <summary>
    /// The word for this type of object
    /// </summary>
    public string CommonNoun;
    /// <summary>
    /// The plural form of the word for this type of object
    /// </summary>
    public string Plural;

    /// <summary>
    /// Any adjectives to attach to this object
    /// </summary>
    public string[] Adjectives=new string[0];

    static readonly char[] Vowels = {'a', 'e', 'i', 'o', 'u'};

    public override void Awake()
    {
        base.Awake();
        foreach (var o in Contents)
            o.Container = gameObject;

        if (string.IsNullOrEmpty(CommonNoun))
            CommonNoun = name.ToLower();
        CommonNoun = LastWordOf(CommonNoun);
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
                    if (Vowels.Contains(secondToLast))
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

    private string LastWordOf(string phrase)
    {
        var space = phrase.LastIndexOf(' ');
        if (space < 0)
            return phrase;
        return phrase.Substring(space + 1);
    }

    public void Start()
    {
        if (string.IsNullOrEmpty(CommonNoun))
            CommonNoun = name;
        if (string.IsNullOrEmpty(Plural))
            Plural = CommonNoun + (CommonNoun.EndsWith("s") ? "es" : "s");
        if (!KB.Global.IsTrue("register_prop",
                                gameObject, Symbol.Intern(CommonNoun),
                                Symbol.Intern(Plural),
                                // Mono can't infer the type on this, for some reason
                                // ReSharper disable once RedundantTypeArgumentsOfMethod
                                Prolog.Prolog.IListToPrologList(new List<Symbol>(Adjectives.Select<string,Symbol>(Symbol.Intern))))
            )
            throw new Exception("Can't register prop "+name);
    }

    #region Container operations
    public IEnumerable<PhysicalObject> Contents
    {
        get
        {
            foreach (Transform child in transform)
                yield return child.GetComponent<PhysicalObject>();
        }
    } 
    #endregion
}
