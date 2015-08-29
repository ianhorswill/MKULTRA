using System;
using UnityEditor;
using UnityEngine;

[Serializable]
public class WallMaterial : ScriptableObject
{
    public Sprite LeftSprite;
    public Sprite CenterSprite;
    public Sprite RightSprite;

    [MenuItem("Assets/Create/Wall Material")]
    internal static void Create()
    {
        AssetDatabase.CreateAsset(CreateInstance<WallMaterial>(), "Assets/Wall Materials/New Wall Material.asset");
    }
}
