module uim.baklava.views.forms;

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
        deprecationWarning('`NullContext::primaryKey()` is deprecated. Use `NullContext::getPrimaryKey()`.');

        return [];
    }


    auto getPrimaryKey(): array
    {
        return [];
    }


    function isPrimaryKey(string myField): bool
    {
        return false;
    }


    function isCreate(): bool
    {
        return true;
    }


    function val(string myField, array myOptions = []) {
        return null;
    }


    function isRequired(string myField): ?bool
    {
        return null;
    }


    auto getRequiredMessage(string myField): ?string
    {
        return null;
    }


    auto getMaxLength(string myField): ?int
    {
        return null;
    }


    function fieldNames(): array
    {
        return [];
    }


    function type(string myField): ?string
    {
        return null;
    }


    function attributes(string myField): array
    {
        return [];
    }


    function hasError(string myField): bool
    {
        return false;
    }


    function error(string myField): array
    {
        return [];
    }
}
