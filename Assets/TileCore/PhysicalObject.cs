using UnityEngine;

public abstract class PhysicalObject : BindingBehaviour
{
    [HideInInspector]
    public GameObject Container;

    public void MoveTo(GameObject newContainer)
    {
        Container = newContainer;
        // Reparent our gameObject to newContainer
        // Because Unity is braindamaged, this has to be done by way of the transform.
        transform.parent = newContainer.transform;
        newContainer.GetComponent<PhysicalObject>().ObjectAdded(this.gameObject);
    }

    public bool ContentsVisible;

    public void ObjectAdded(GameObject newObject)
    {
        if (newObject.renderer != null)
            newObject.renderer.enabled = ContentsVisible;
    }
}
