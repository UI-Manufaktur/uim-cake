module uim.cake.databases.Schema;

import uim.cake.datasources.ISchema;

/**
 * An interface used by database TableSchema objects.
 */
interface TableISchema : ISchema
{
    /**
     * Binary column type
     */
    const string TYPE_BINARY = "binary";

    /**
     * Binary UUID column type
     */
    const string TYPE_BINARY_UUID = "binaryuuid";

    /**
     * Date column type
     */
    const string TYPE_DATE = "date";

    /**
     * Datetime column type
     */
    const string TYPE_DATETIME = "datetime";

    /**
     * Datetime with fractional seconds column type
     */
    const string TYPE_DATETIME_FRACTIONAL = "datetimefractional";

    /**
     * Time column type
     */
    const string TYPE_TIME = "time";

    /**
     * Timestamp column type
     */
    const string TYPE_TIMESTAMP = "timestamp";

    /**
     * Timestamp with fractional seconds column type
     */
    const string TYPE_TIMESTAMP_FRACTIONAL = "timestampfractional";

    /**
     * Timestamp with time zone column type
     */
    const string TYPE_TIMESTAMP_TIMEZONE = "timestamptimezone";

    /**
     * JSON column type
     */
    const string TYPE_JSON = "json";

    /**
     * String column type
     */
    const string TYPE_STRING = "string";

    /**
     * Char column type
     */
    const string TYPE_CHAR = "char";

    /**
     * Text column type
     */
    const string TYPE_TEXT = "text";

    /**
     * Tiny Integer column type
     */
    const string TYPE_TINYINTEGER = "tinyinteger";

    /**
     * Small Integer column type
     */
    const string TYPE_SMALLINTEGER = "smallinteger";

    /**
     * Integer column type
     */
    const string TYPE_INTEGER = "integer";

    /**
     * Big Integer column type
     */
    const string TYPE_BIGINTEGER = "biginteger";

    /**
     * Float column type
     */
    const string TYPE_FLOAT = "float";

    /**
     * Decimal column type
     */
    const string TYPE_DECIMAL = "decimal";

    /**
     * Boolean column type
     */
    const string TYPE_BOOLEAN = "boolean";

    /**
     * UUID column type
     */
    const string TYPE_UUID = "uuid";

    /**
     * Check whether a table has an autoIncrement column defined.
     */
    bool hasAutoincrement();

    /**
     * Sets whether the table is temporary in the database.
     *
     * @param bool $temporary Whether the table is to be temporary.
     * @return this
     */
    function setTemporary(bool $temporary);

    /**
     * Gets whether the table is temporary in the database.
     *
     * @return bool The current temporary setting.
     */
    bool isTemporary();

    /**
     * Get the column(s) used for the primary key.
     *
     * @return array<string> Column name(s) for the primary key. An
     *   empty list will be returned when the table has no primary key.
     */
    string[] getPrimaryKey();

    /**
     * Add an index.
     *
     * Used to add indexes, and full text indexes in platforms that support
     * them.
     *
     * ### Attributes
     *
     * - `type` The type of index being added.
     * - `columns` The columns in the index.
     *
     * @param string aName The name of the index.
     * @param array<string, mixed>|string $attrs The attributes for the index.
     *   If string it will be used as `type`.
     * @return this
     * @throws uim.cake.databases.exceptions.DatabaseException
     */
    function addIndex(string aName, $attrs);

    /**
     * Read information about an index based on name.
     *
     * @param string aName The name of the index.
     * @return array<string, mixed>|null Array of index data, or null
     */
    function getIndex(string aName): ?array;

    /**
     * Get the names of all the indexes in the table.
     *
     * @return array<string>
     */
    string[] indexes();

    /**
     * Add a constraint.
     *
     * Used to add constraints to a table. For example primary keys, unique
     * keys and foreign keys.
     *
     * ### Attributes
     *
     * - `type` The type of constraint being added.
     * - `columns` The columns in the index.
     * - `references` The table, column a foreign key references.
     * - `update` The behavior on update. Options are "restrict", "setNull", "cascade", "noAction".
     * - `delete` The behavior on delete. Options are "restrict", "setNull", "cascade", "noAction".
     *
     * The default for "update" & "delete" is "cascade".
     *
     * @param string aName The name of the constraint.
     * @param array<string, mixed>|string $attrs The attributes for the constraint.
     *   If string it will be used as `type`.
     * @return this
     * @throws uim.cake.databases.exceptions.DatabaseException
     */
    function addConstraint(string aName, $attrs);

    /**
     * Read information about a constraint based on name.
     *
     * @param string aName The name of the constraint.
     * @return array<string, mixed>|null Array of constraint data, or null
     */
    function getConstraint(string aName): ?array;

    /**
     * Remove a constraint.
     *
     * @param string aName Name of the constraint to remove
     * @return this
     */
    function dropConstraint(string aName);

    /**
     * Get the names of all the constraints in the table.
     *
     * @return array<string>
     */
    string[] constraints();
}
