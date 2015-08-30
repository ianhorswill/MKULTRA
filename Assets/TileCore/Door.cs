using UnityEngine;

[AddComponentMenu("Tile/Door")]
[RequireComponent(typeof(SpriteRenderer), typeof(BoxCollider2D))]
class Door : MonoBehaviour
{
#pragma warning disable 0649
    public Sprite ClosedSprite;
    public Sprite OpenSprite;
    public bool InitiallyOpen;
    public bool Locked;
#pragma warning restore 0649

    public bool Open
    {
        get
        {
            return this.GetComponent<Collider2D>().enabled;
        }

        set
        {
            if (Locked && value)
                // Can't open a locked door
                return;

            this.ForceDoorState(value);
        }
    }

    public void ForceDoorState(bool value)
    {
        this.GetComponent<Collider2D>().enabled = !value;
        this.GetComponent<SpriteRenderer>().sprite = value ? this.OpenSprite : this.ClosedSprite;
    }

    internal void Awake()
    {
        this.ForceDoorState(InitiallyOpen);
    }
}
