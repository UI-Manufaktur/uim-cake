module uim.caketasources;

/**
 * An interface used by TableSchema objects.
 */
interface SchemaInterface
{
    /**
     * Get the name of the table.
     *
     * @return string
     */
    function name(): string;

    /**
     * Add a column to the table.
     *
     * ### Attributes
     *
     * Columns can have several attributes:
     *
     * - `type` The type of the column. This should be
     *   one of CakePHP's abstract types.
     * - `length` The length of the column.
     * - `precision` The number of decimal places to store
     *   for float and decimal types.
     * - `default` The default value of the column.
     * - `null` Whether the column can hold nulls.
     * - `fixed` Whether the column is a fixed length column.
     *   This is only present/valid with string columns.
     * - `unsigned` Whether the column is an unsigned column.
     *   This is only present/valid for integer, decimal, float columns.
     *
     * In addition to the above keys, the following keys are
     * implemented in some database dialects, but not all:
     *
     * - `comment` The comment for the column.
     *
     * @param string myName The name of the column
     * @param array<string, mixed>|string $attrs The attributes for the column or the type name.
     * @return this
     */
    function addColumn(string myName, $attrs);

    /**
     * Get column data in the table.
     *
     * @param string myName The column name.
     * @return array<string, mixed>|null Column data or null.
     */
    auto getColumn(string myName): ?array;

    /**
     * Returns true if a column exists in the schema.
     *
     * @param string myName Column name.
     */
    bool hasColumn(string myName);

    /**
     * Remove a column from the table schema.
     *
     * If the column is not defined in the table, no error will be raised.
     *
     * @param string myName The name of the column
     * @return this
     */
    function removeColumn(string myName);

    /**
     * Get the column names in the table.
     *
     * @return array<string>
     */
    function columns(): array;

    /**
     * Returns column type or null if a column does not exist.
     *
     * @param string myName The column to get the type of.
     * @return string|null
     */
    auto getColumnType(string myName): Nullable!string;

    /**
     * Sets the type of a column.
     *
     * @param string myName The column to set the type of.
     * @param string myType The type to set the column to.
     * @return this
     */
    auto setColumnType(string myName, string myType);

    /**
     * Returns the base type name for the provided column.
     * This represent the database type a more complex class is
     * based upon.
     *
     * @param string $column The column name to get the base type from
     * @return string|null The base type name
     */
    function baseColumnType(string $column): Nullable!string;

    /**
     * Check whether a field is nullable
     *
     * Missing columns are nullable.
     *
     * @param string myName The column to get the type of.
     * @return bool Whether the field is nullable.
     */
    bool isNullable(string myName);

    /**
     * Returns an array where the keys are the column names in the schema
     * and the values the database type they have.
     *
     * @return array<string, string>
     */
    function typeMap(): array;

    /**
     * Get a hash of columns and their default values.
     *
     * @return array<string, mixed>
     */
    function defaultValues(): array;

    /**
     * Sets the options for a table.
     *
     * Table options allow you to set platform specific table level options.
     * For example the engine type in MySQL.
     *
     * @param array<string, mixed> myOptions The options to set, or null to read options.
     * @return this
     */
    auto setOptions(array myOptions);

    /**
     * Gets the options for a table.
     *
     * Table options allow you to set platform specific table level options.
     * For example the engine type in MySQL.
     *
     * @return array<string, mixed> An array of options.
     */
    auto getOptions(): array;
}