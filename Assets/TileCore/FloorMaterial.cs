using System;
using UnityEditor;
using UnityEngine;

[Serializable]
public class FloorMaterial : ScriptableObject
{
    public Sprite Sprite;

    [MenuItem("Assets/Create/Floor Material")]
    internal static void Create()
    {
        AssetDatabase.CreateAsset(CreateInstance<FloorMaterial>(), "Assets/Floor Materials/New Floor Material.asset");
    }
}
