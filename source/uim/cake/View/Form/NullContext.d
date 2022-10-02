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
    this(array $context)
    {
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

    /**
     * @inheritDoc
     */
    auto getPrimaryKey(): array
    {
        return [];
    }

    /**
     * @inheritDoc
     */
    function isPrimaryKey(string myField): bool
    {
        return false;
    }

    /**
     * @inheritDoc
     */
    function isCreate(): bool
    {
        return true;
    }

    /**
     * @inheritDoc
     */
    function val(string myField, array myOptions = [])
    {
        return null;
    }

    /**
     * @inheritDoc
     */
    function isRequired(string myField): ?bool
    {
        return null;
    }

    /**
     * @inheritDoc
     */
    auto getRequiredMessage(string myField): ?string
    {
        return null;
    }

    /**
     * @inheritDoc
     */
    auto getMaxLength(string myField): ?int
    {
        return null;
    }

    /**
     * @inheritDoc
     */
    function fieldNames(): array
    {
        return [];
    }

    /**
     * @inheritDoc
     */
    function type(string myField): ?string
    {
        return null;
    }

    /**
     * @inheritDoc
     */
    function attributes(string myField): array
    {
        return [];
    }

    /**
     * @inheritDoc
     */
    function hasError(string myField): bool
    {
        return false;
    }

    /**
     * @inheritDoc
     */
    function error(string myField): array
    {
        return [];
    }
}
