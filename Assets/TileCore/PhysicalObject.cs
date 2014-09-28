using UnityEngine;

public abstract class PhysicalObject : BindingBehaviour
{
    /// <summary>
    /// If true, Sims won't notice this object unless they explicitly search for it.
    /// Also, suppresses rendering of the object until it's unhidden.
    /// </summary>
    public bool IsHidden;

    public void SetHidden(bool state)
    {
        this.renderer.enabled = !state;
        this.IsHidden = state;
    }

    public override void Awake()
    {
        base.Awake();
        if (IsHidden)
            this.renderer.enabled = false;
    }

    [HideInInspector]
    public GameObject Container;

    /// <summary>
    /// True if this object has not been destroyed.
    /// </summary>
    public bool Exists = true;

    public void MoveTo(GameObject newContainer)
    {
        Container = newContainer;
        // Reparent our gameObject to newContainer
        // Because Unity is braindamaged, this has to be done by way of the transform.
        transform.parent = newContainer.transform;
        var physicalObject = newContainer.GetComponent<PhysicalObject>();
        if (physicalObject != null)
            physicalObject.ObjectAdded(this.gameObject);
    }

    public bool ContentsVisible;

    public void ObjectAdded(GameObject newObject)
    {
        if (newObject.renderer != null)
        {
            newObject.renderer.enabled = ContentsVisible;
            var sr = newObject.renderer as SpriteRenderer;
            if (sr != null && ContentsVisible)
                sr.sortingLayerName = "PlacedOnSurface";
        }
        newObject.transform.localPosition = Vector3.zero;
    }

    public virtual void Destroy()
    {
        Exists = false;
        this.MoveTo(GameObject.Find("DestroyedObjects"));
        this.enabled = false;
        this.renderer.enabled = false;
    }
}
