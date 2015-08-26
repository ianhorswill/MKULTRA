using System;
using Prolog;
using UnityEngine;

public class Room : BindingBehaviour
{
    public int Left;

    public int Bottom;

    public int Width;

    public int Height;

    public FloorMaterial Floor;

    public Portal[] Portals;

    [Serializable]
    public class Portal
    {
        public int Left;

        public int Bottom;

        public int Width;

        public int Height;

        private TileRect tileRect;

        public bool Contains(GameObject o)
        {
            return this.tileRect.Contains(o.Position());
        }

        public void Initialize()
        {
            this.tileRect = new TileRect(Left, Bottom, Width, Height);
        }
    }

    public override void Awake()
    {
        this.tileRect = new TileRect(Left, Bottom, Width, Height);
        foreach (var portal in Portals)
            portal.Initialize();
    }

    public void Start()
    {
        if (!KB.Global.IsTrue("register_room", gameObject, Symbol.Intern(name)))
            throw new Exception("Can't register prop " + name);
    }

    /// <summary>
    /// Boundardies of the room
    /// </summary>
    private TileRect tileRect;

    public TileRect TileRect
    {
        get
        {
            return tileRect;
        }
    }

    /// <summary>
    /// True iff the room contains this object.
    /// </summary>
    public bool Contains(GameObject o)
    {
        if (this.tileRect.Contains(o.Position()))
            return true;
        foreach (var portal in Portals)
            if (portal.Contains(o))
                return true;
        return false;
    }

    internal void OnDrawGizmosSelected()
    {
        TileMap.UpdateMapVariables();
        Gizmos.color = Color.yellow;
        GizmoUtils.Draw(new Rect(Tile.MapXMin+Left*Tile.SizeInSceneUnits,
            Tile.MapYMin+Bottom*Tile.SizeInSceneUnits,
            Width*Tile.SizeInSceneUnits,
            Height*Tile.SizeInSceneUnits));

        foreach (var portal in Portals)
        {
            GizmoUtils.Draw(new Rect(Tile.MapXMin + portal.Left * Tile.SizeInSceneUnits,
               Tile.MapYMin + portal.Bottom * Tile.SizeInSceneUnits,
               portal.Width * Tile.SizeInSceneUnits,
               portal.Height * Tile.SizeInSceneUnits));   
        }
    }

    //internal void OnValidate()
    //{
    //    Debug.Log("Room changed: "+name);
    //}
}
