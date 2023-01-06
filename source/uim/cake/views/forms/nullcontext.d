module uim.cake.views.forms;

/**
 * Provides a context provider that does nothing.
 *
 * This context provider simply fulfils the interface requirements
 * that FormHelper has.
 */
class NullContext : IContext
{
    /**
     * Constructor.
     *
     * @param array $context Context info.
     */
    this(array $context) {
    }

    /**
     * Get the fields used in the context as a primary key.
     * @deprecated 4.0.0 Renamed to {@link getPrimaryKey()}.
     */
    string[] primaryKey() {
        deprecationWarning("`NullContext::primaryKey()` is deprecated. Use `NullContext::getPrimaryKey()`.");

        return [];
    }


    array getPrimaryKey()
    {
        return [];
    }


    bool isPrimaryKey(string myField) {
        return false;
    }


    bool isCreate() {
        return true;
    }


    function val(string myField, array myOptions = []) {
        return null;
    }


    bool isRequired(string myField): ?bool
    {
        return null;
    }


    Nullable!string getRequiredMessage(string myField) {
        return null;
    }


    Nullable!int getMaxLength(string myField) {
        return null;
    }


    array fieldNames()
    {
        return [];
    }


    Nullable!string type(string myField) {
        return null;
    }


    array attributes(string myField)
    {
        return [];
    }


    bool hasError(string myField) {
        return false;
    }


    array error(string myField)
    {
        return [];
    }
}
