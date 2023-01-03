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
     * @deprecated 4.0.0 Renamed to {@link getPrimaryKey()}.
     */
    function primaryKey(): array
    {
        deprecationWarning("`NullContext::primaryKey()` is deprecated. Use `NullContext::getPrimaryKey()`.");

        return [];
    }


    function getPrimaryKey(): array
    {
        return [];
    }


    bool isPrimaryKey(string $field) {
        return false;
    }


    bool isCreate() {
        return true;
    }


    function val(string $field, array $options = []) {
        return null;
    }


    bool isRequired(string $field): ?bool
    {
        return null;
    }


    function getRequiredMessage(string $field): ?string
    {
        return null;
    }


    function getMaxLength(string $field): ?int
    {
        return null;
    }


    function fieldNames(): array
    {
        return [];
    }


    function type(string $field): ?string
    {
        return null;
    }


    function attributes(string $field): array
    {
        return [];
    }


    bool hasError(string $field) {
        return false;
    }


    function error(string $field): array
    {
        return [];
    }
}
