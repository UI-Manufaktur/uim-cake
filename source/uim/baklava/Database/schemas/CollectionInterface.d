module uim.baklava.databases.Schema;

/**
 * Represents a database schema collection
 *
 * Used to access information about the tables,
 * and other data in a database.
 */
interface ICollection
{
    /**
     * Get the list of tables available in the current connection.
     *
     * @return array<string> The list of tables in the connected database/schema.
     */
    function listTables(): array;

    /**
     * Get the column metadata for a table.
     *
     * Caching will be applied if `cacheMetadata` key is present in the Connection
     * configuration options. Defaults to _cake_model_ when true.
     *
     * ### Options
     *
     * - `forceRefresh` - Set to true to force rebuilding the cached metadata.
     *   Defaults to false.
     *
     * @param string myName The name of the table to describe.
     * @param array<string, mixed> myOptions The options to use, see above.
     * @return \Cake\Database\Schema\TableSchemaInterface Object with column metadata.
     * @throws \Cake\Database\Exception\DatabaseException when table cannot be described.
     */
    function describe(string myName, array myOptions = []): TableSchemaInterface;
}
