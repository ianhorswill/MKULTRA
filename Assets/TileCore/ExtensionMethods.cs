using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;


public static class TileCoreExtensionMethods
{
    public static Vector2 ScreenPosition(this GameObject gameObject)
    {
        return Camera.main.WorldToScreenPoint(gameObject.transform.position);
    }

    public static Vector2 GUIScreenPosition(this GameObject gameObject)
    {
        var screenPosition = ScreenPosition(gameObject);
        return new Vector2(screenPosition.x, Screen.height - screenPosition.y);
    }

    public static void DrawThumbNail(this GameObject gameObject, Vector2 screenLocation)
    {
        var ss = gameObject.GetComponent<SpriteSheetAnimationController>();
        if (ss == null)
            throw new ArgumentNullException("ThumbNailImage() called on game object with not SpriteSheetAnimationController");
        ss.DrawThumbNail(screenLocation);
    }
}
