module uim.cake.Datasource;

// An interface used by TableSchema objects.
interface ISchema {
    /**
     * Get the name of the table.
     */
    string name();

    /**
     * Add a column to the table.
     *
     * ### Attributes
     *
     * Columns can have several attributes:
     *
     * - `type` The type of the column. This should be
     *   one of CakePHP"s abstract types.
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
     * @param string aName The name of the column
     * @param array<string, mixed>|string $attrs The attributes for the column or the type name.
     * @return this
     */
    function addColumn(string aName, $attrs);

    /**
     * Get column data in the table.
     *
     * @param string aName The column name.
     * @return array<string, mixed>|null Column data or null.
     */
    function getColumn(string aName): ?array;

    /**
     * Returns true if a column exists in the schema.
     *
     * @param string aName Column name.
     * @return bool
     */
    function hasColumn(string aName): bool;

    /**
     * Remove a column from the table schema.
     *
     * If the column is not defined in the table, no error will be raised.
     *
     * @param string aName The name of the column
     * @return this
     */
    function removeColumn(string aName);

    /**
     * Get the column names in the table.
     *
     * @return array<string>
     */
    string[] columns(): array;

    /**
     * Returns column type or null if a column does not exist.
     *
     * @param string aName The column to get the type of.
     * @return string|null
     */
    function getColumnType(string aName): ?string;

    /**
     * Sets the type of a column.
     *
     * @param string aName The column to set the type of.
     * @param string $type The type to set the column to.
     * @return this
     */
    function setColumnType(string aName, string $type);

    /**
     * Returns the base type name for the provided column.
     * This represent the database type a more complex class is
     * based upon.
     *
     * @param string $column The column name to get the base type from
     * @return string|null The base type name
     */
    function baseColumnType(string $column): ?string;

    /**
     * Check whether a field is nullable
     *
     * Missing columns are nullable.
     *
     * @param string aName The column to get the type of.
     * @return bool Whether the field is nullable.
     */
    function isNullable(string aName): bool;

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
     * @param array<string, mixed> $options The options to set, or null to read options.
     * @return this
     */
    function setOptions(array $options);

    /**
     * Gets the options for a table.
     *
     * Table options allow you to set platform specific table level options.
     * For example the engine type in MySQL.
     *
     * @return array<string, mixed> An array of options.
     */
    function getOptions(): array;
}