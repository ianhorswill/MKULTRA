using UnityEngine;

/// <summary>
/// Prepares variables to be used by PopupDrawer.
/// </summary>

public class PopupAttribute : PropertyAttribute
{
    public string[] List;
    public object VariableType;

    #region PopupAttribute()

    /// <summary>
    /// Makes necessary operations to prepare the variables for later use by PopupDrawer.
    /// </summary>
    /// <param name="list">Parameters array to be analized and assigned.</param>

    public PopupAttribute(params object[] list)
    {
        if (IsVariablesTypeConsistent(list) && AssignVariableType(list[0]))
        {
            this.List = new string[list.Length];
            for (int i = 0; i < list.Length; i++)
            {
                this.List[i] = list[i].ToString();
            }
        }
    }
    #endregion

    #region Helper Methods.
    #region AssignVariableType()

    /// <summary>
    /// Checks if variable type is valid, and assignes the variable type to the proper variable.
    /// </summary>
    /// <param name="variable">Object to get type from.</param>
    /// <returns>Returns true if variable type is valid, and false if it isn't.</returns>
    
    private bool AssignVariableType(object variable)
    {
        if (variable is int)
        {
            this.VariableType = typeof(int[]);
            return true;
        }
        if (variable is float)
        {
            this.VariableType = typeof(float[]);
            return true;
        }
        if (variable is double)
        {
            Debug.LogWarning("Popup Drawer doesn't properly support double type, for float variables please use 'f' at the end of each value.");
            this.VariableType = typeof(float[]);
            return true;
        }
        if (variable is string)
        {
            this.VariableType = typeof(string[]);
            return true;
        }
        Debug.LogError("Popup Property Drawer doesn't support " + variable.GetType() + " this type of variable");
        return false;
    }

    #endregion

    #region IsVariablesTypeConsistent()

    /// <summary>
    /// Checks to see if there is only one variable type in the given value.
    /// </summary>
    /// <param name="values">Array of variables to be checked.</param>
    /// <returns>True if there is only one type, false if there is 2 or more.</returns>
    
    private bool IsVariablesTypeConsistent(object[] values)
    {
        for (int i = 0; i < values.Length; i++)
        {
            if (i == 0)
            {
                this.VariableType = values[i].GetType();
            }
                // ReSharper disable PossibleUnintendedReferenceComparison
            else if (this.VariableType != values[i].GetType())
                // ReSharper restore PossibleUnintendedReferenceComparison
            {
                Debug.LogError("Popup Property Drawer can only contain one type per variable");
                return false;
            }
        }

        return true;
    }
    #endregion
    #endregion
}





