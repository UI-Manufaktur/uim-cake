module uim.cake.database;

/**
 * : default and single-use mappings for columns to their associated types
 */
class TypeMap
{
    /**
     * Associative array with the default fields and the related types this query might contain.
     *
     * Used to avoid repetition when calling multiple functions inside this class that
     * may require a custom type for a specific field.
     *
     * @var array<string, string>
     */
    protected $_defaults = [];

    /**
     * Associative array with the fields and the related types that override defaults this query might contain
     *
     * Used to avoid repetition when calling multiple functions inside this class that
     * may require a custom type for a specific field.
     *
     * @var array<string, string>
     */
    protected $_types = [];

    /**
     * Creates an instance with the given defaults
     *
     * @param array<string, string> $defaults The defaults to use.
     */
    this(array $defaults = []) {
        this.setDefaults($defaults);
    }

    /**
     * Configures a map of fields and associated type.
     *
     * These values will be used as the default mapping of types for every function
     * in this instance that supports a `myTypes` param.
     *
     * This method is useful when you want to avoid repeating type definitions
     * as setting types overwrites the last set of types.
     *
     * ### Example
     *
     * ```
     * myQuery.setDefaults(['created' => 'datetime', 'is_visible' => 'boolean']);
     * ```
     *
     * This method will replace all the existing default mappings with the ones provided.
     * To add into the mappings use `addDefaults()`.
     *
     * @param array<string, string> $defaults Associative array where keys are field names and values
     * are the correspondent type.
     * @return this
     */
    auto setDefaults(array $defaults) {
        this._defaults = $defaults;

        return this;
    }

    /**
     * Returns the currently configured types.
     *
     * @return array<string, string>
     */
    auto getDefaults(): array
    {
        return this._defaults;
    }

    /**
     * Add additional default types into the type map.
     *
     * If a key already exists it will not be overwritten.
     *
     * @param array<string, string> myTypes The additional types to add.
     * @return void
     */
    function addDefaults(array myTypes): void
    {
        this._defaults += myTypes;
    }

    /**
     * Sets a map of fields and their associated types for single-use.
     *
     * ### Example
     *
     * ```
     * myQuery.setTypes(['created' => 'time']);
     * ```
     *
     * This method will replace all the existing type maps with the ones provided.
     *
     * @param array<string, string> myTypes Associative array where keys are field names and values
     * are the correspondent type.
     * @return this
     */
    auto setTypes(array myTypes) {
        this._types = myTypes;

        return this;
    }

    /**
     * Gets a map of fields and their associated types for single-use.
     *
     * @return array<string, string>
     */
    auto getTypes(): array
    {
        return this._types;
    }

    /**
     * Returns the type of the given column. If there is no single use type is configured,
     * the column type will be looked for inside the default mapping. If neither exist,
     * null will be returned.
     *
     * @param string|int $column The type for a given column
     * @return string|null
     */
    string type($column) {
        return this._types[$column] ?? this._defaults[$column] ?? null;
    }

    /**
     * Returns an array of all types mapped types
     *
     * @return array<string, string>
     */
    function toArray(): array
    {
        return this._types + this._defaults;
    }
}
