

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.View\Form;

/**
 * Provides a context provider that does nothing.
 *
 * This context provider simply fulfils the interface requirements
 * that FormHelper has.
 */
class NullContext : ContextInterface
{
    /**
     * Constructor.
     *
     * @param array $context Context info.
     */
    public this(array $context)
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
        deprecationWarning("`NullContext::primaryKey()` is deprecated. Use `NullContext::getPrimaryKey()`.");

        return [];
    }

    /**
     * @inheritDoc
     */
    function getPrimaryKey(): array
    {
        return [];
    }

    /**
     * @inheritDoc
     */
    function isPrimaryKey(string $field): bool
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
    function val(string $field, array $options = [])
    {
        return null;
    }

    /**
     * @inheritDoc
     */
    function isRequired(string $field): ?bool
    {
        return null;
    }

    /**
     * @inheritDoc
     */
    function getRequiredMessage(string $field): ?string
    {
        return null;
    }

    /**
     * @inheritDoc
     */
    function getMaxLength(string $field): ?int
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
    function type(string $field): ?string
    {
        return null;
    }

    /**
     * @inheritDoc
     */
    function attributes(string $field): array
    {
        return [];
    }

    /**
     * @inheritDoc
     */
    function hasError(string $field): bool
    {
        return false;
    }

    /**
     * @inheritDoc
     */
    function error(string $field): array
    {
        return [];
    }
}
