


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.6.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Database;

import uim.cake.databases.Schema\CachedCollection;

/**
 * Schema Cache.
 *
 * This tool is intended to be used by deployment scripts so that you
 * can prevent thundering herd effects on the metadata cache when new
 * versions of your application are deployed, or when migrations
 * requiring updated metadata are required.
 *
 * @link https://en.wikipedia.org/wiki/Thundering_herd_problem About the thundering herd problem
 */
class SchemaCache
{
    /**
     * Schema
     *
     * @var \Cake\Database\Schema\CachedCollection
     */
    protected $_schema;

    /**
     * Constructor
     *
     * @param \Cake\Database\Connection $connection Connection name to get the schema for or a connection instance
     */
    public this(Connection $connection) {
        _schema = this.getSchema($connection);
    }

    /**
     * Build metadata.
     *
     * @param string|null $name The name of the table to build cache data for.
     * @return array<string> Returns a list build table caches
     */
    string[] build(?string $name = null): array
    {
        if ($name) {
            $tables = [$name];
        } else {
            $tables = _schema.listTables();
        }

        foreach ($tables as $table) {
            /** @psalm-suppress PossiblyNullArgument */
            _schema.describe($table, ["forceRefresh": true]);
        }

        return $tables;
    }

    /**
     * Clear metadata.
     *
     * @param string|null $name The name of the table to clear cache data for.
     * @return array<string> Returns a list of cleared table caches
     */
    string[] clear(?string $name = null): array
    {
        if ($name) {
            $tables = [$name];
        } else {
            $tables = _schema.listTables();
        }

        $cacher = _schema.getCacher();

        foreach ($tables as $table) {
            /** @psalm-suppress PossiblyNullArgument */
            $key = _schema.cacheKey($table);
            $cacher.delete($key);
        }

        return $tables;
    }

    /**
     * Helper method to get the schema collection.
     *
     * @param \Cake\Database\Connection $connection Connection object
     * @return \Cake\Database\Schema\CachedCollection
     * @throws \RuntimeException If given connection object is not compatible with schema caching
     */
    function getSchema(Connection $connection): CachedCollection
    {
        $config = $connection.config();
        if (empty($config["cacheMetadata"])) {
            $connection.cacheMetadata(true);
        }

        /** @var \Cake\Database\Schema\CachedCollection $schemaCollection */
        $schemaCollection = $connection.getSchemaCollection();

        return $schemaCollection;
    }
}
