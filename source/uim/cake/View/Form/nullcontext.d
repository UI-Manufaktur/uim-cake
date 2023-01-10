module uim.cake.View\Form;

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
     *
     * @return array<string>
     * @deprecated 4.0.0 Renamed to {@link getPrimaryKeys()}.
     */
    array primaryKey() {
        deprecationWarning("`NullContext::primaryKey()` is deprecated. Use `NullContext::getPrimaryKeys()`.");

        return [];
    }


    array getPrimaryKeys() {
        return [];
    }


    bool isPrimaryKey(string $field) {
        return false;
    }


    bool isCreate() {
        return true;
    }


    function val(string $field, STRINGAA someOptions = []) {
        return null;
    }


    bool isRequired(string $field): ?bool
    {
        return null;
    }


    Nullable!string getRequiredMessage(string $field) {
        return null;
    }


    Nullable!int getMaxLength(string $field) {
        return null;
    }


    array fieldNames() {
        return [];
    }


    Nullable!string type(string $field) {
        return null;
    }


    array attributes(string $field) {
        return [];
    }


    bool hasError(string $field) {
        return false;
    }


    array error(string $field) {
        return [];
    }
}
