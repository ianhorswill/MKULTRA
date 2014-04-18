using UnityEngine;

/// <summary>
/// Stores data about a single tile in the map
/// </summary>
public class Tile
{
    #region Scene <-> tile mapping
    /// <summary>
    /// The size of a tile in scene units
    /// </summary>
    public static float SizeInSceneUnits = 1;

    /// <summary>
    /// The X coordinate of the left edge of the map, in scene units.
    /// </summary>
    public static float MapXMin = 0;

    /// <summary>
    /// The Y coordinate of the bottom edge of the map, in scene units.
    /// </summary>
    public static float MapYMin = 0;

    /// <summary>
    /// Quantizes a scene position to tile units.
    /// </summary>
    /// <param name="sceneUnits">Floating point scene position</param>
    /// <returns>Integer tile number</returns>
    public static int SceneToTileUnits(float sceneUnits)
    {
        return Mathf.FloorToInt(sceneUnits/SizeInSceneUnits);
    }

    /// <summary>
    /// Returns the minimum of the scene coordinates corresponding to this tile coordinate.
    /// </summary>
    /// <param name="tileUnits">Integer tile number</param>
    /// <returns>Floating point scene position</returns>
    public static float TileToSceneUnitsMin(int tileUnits)
    {
        return tileUnits * SizeInSceneUnits;
    }

    /// <summary>
    /// Returns the minimum of the scene coordinates corresponding to this tile coordinate.
    /// </summary>
    /// <param name="tileUnits">Integer tile number</param>
    /// <returns>Floating point scene position</returns>
    public static float TileToSceneUnitsMax(int tileUnits)
    {
        return (tileUnits+1) * SizeInSceneUnits;
    }

    /// <summary>
    /// Returns the midpoint of the scene coordinates corresponding to this tile coordinate.
    /// </summary>
    /// <param name="tileUnits">Integer tile number</param>
    /// <returns>Floating point scene position</returns>
    public static float TileToSceneUnitsMidpoint(int tileUnits)
    {
        return (tileUnits+0.5f) * SizeInSceneUnits;
    }
    #endregion

    public string SpriteName;

    /// <summary>
    /// The type of tile this is (freespace, wall, etc.)
    /// </summary>
    public TileType Type = TileType.Freespace;
}