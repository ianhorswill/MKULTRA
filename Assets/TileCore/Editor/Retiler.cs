using UnityEngine;
using System.Linq;

using Object = UnityEngine.Object;

public static class Retiler
{
    private static Room[] rooms;

    private static TileMap tileMap;

    public static void RetileMap()
    {
        rooms = Object.FindObjectsOfType(typeof(Room)).Cast<Room>().ToArray();
        tileMap = Object.FindObjectOfType<TileMap>();
        tileMap.EnsureMapBuilt();
        for (int row = 0; row < tileMap.MapRows; row++)
            for (int column = 0; column < tileMap.MapColumns; column++)
            {
                var tilePosition = new TilePosition(column, row);
                var newSprite = TileSpriteAt(tilePosition);
                if (newSprite != null)
                    tileMap.SetTileSprite(tilePosition, newSprite);
            }
    }

    private static Sprite TileSpriteAt(TilePosition tilePosition)
    {
        foreach (var r in rooms)
        {
            if (r.Contains(tilePosition))
                return r.Floor.Sprite;
        }
        return null;
    }
}
