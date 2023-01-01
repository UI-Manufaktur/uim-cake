module uim.cake.Database;

/**
 * : default and single-use mappings for columns to their associated types
 */
class TypeMap
{
    /**
     * Array with the default fields and the related types this query might contain.
     *
     * Used to avoid repetition when calling multiple functions inside this class that
     * may require a custom type for a specific field.
     *
     * @var array<int|string, string>
     */
    protected $_defaults = [];

    /**
     * Array with the fields and the related types that override defaults this query might contain
     *
     * Used to avoid repetition when calling multiple functions inside this class that
     * may require a custom type for a specific field.
     *
     * @var array<int|string, string>
     */
    protected $_types = [];

    /**
     * Creates an instance with the given defaults
     *
     * @param array<int|string, string> $defaults The defaults to use.
     */
    this(array $defaults = []) {
        this.setDefaults($defaults);
    }

    /**
     * Configures a map of fields and associated type.
     *
     * These values will be used as the default mapping of types for every function
     * in this instance that supports a `$types` param.
     *
     * This method is useful when you want to avoid repeating type definitions
     * as setting types overwrites the last set of types.
     *
     * ### Example
     *
     * ```
     * $query.setDefaults(["created": "datetime", "is_visible": "boolean"]);
     * ```
     *
     * This method will replace all the existing default mappings with the ones provided.
     * To add into the mappings use `addDefaults()`.
     *
     * @param array<int|string, string> $defaults Array where keys are field names / positions and values
     * are the correspondent type.
     * @return this
     */
    function setDefaults(array $defaults) {
        _defaults = $defaults;

        return this;
    }

    /**
     * Returns the currently configured types.
     *
     * @return array<int|string, string>
     */
    function getDefaults(): array
    {
        return _defaults;
    }

    /**
     * Add additional default types into the type map.
     *
     * If a key already exists it will not be overwritten.
     *
     * @param array<int|string, string> $types The additional types to add.
     */
    void addDefaults(array $types) {
        _defaults += $types;
    }

    /**
     * Sets a map of fields and their associated types for single-use.
     *
     * ### Example
     *
     * ```
     * $query.setTypes(["created": "time"]);
     * ```
     *
     * This method will replace all the existing type maps with the ones provided.
     *
     * @param array<int|string, string> $types Array where keys are field names / positions and values
     * are the correspondent type.
     * @return this
     */
    function setTypes(array $types) {
        _types = $types;

        return this;
    }

    /**
     * Gets a map of fields and their associated types for single-use.
     *
     * @return array<int|string, string>
     */
    function getTypes(): array
    {
        return _types;
    }

    /**
     * Returns the type of the given column. If there is no single use type is configured,
     * the column type will be looked for inside the default mapping. If neither exist,
     * null will be returned.
     *
     * @param string|int $column The type for a given column
     * @return string|null
     */
    function type($column): ?string
    {
        return _types[$column] ?? _defaults[$column] ?? null;
    }

    /**
     * Returns an array of all types mapped types
     *
     * @return array<int|string, string>
     */
    function toArray(): array
    {
        return _types + _defaults;
    }
}
