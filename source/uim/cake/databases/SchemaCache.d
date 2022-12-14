/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.databases;

@safe:
import uim.cake;

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
class SchemaCache {
    /**
     * Schema
     *
     * @var \Cake\Database\Schema\CachedCollection
     */
    protected $_schema;

    /**
     * Constructor
     *
     * @param \Cake\Database\Connection myConnection Connection name to get the schema for or a connection instance
     */
    this(Connection myConnection) {
        this._schema = this.getSchema(myConnection);
    }

    /**
     * Build metadata.
     *
     * @param string|null myName The name of the table to build cache data for.
     * @return Returns a list build table caches
     */
    string[] build(Nullable!string myName = null) {
        if (myName) {
            myTables = [myName];
        } else {
            myTables = this._schema.listTables();
        }

        foreach (myTables as myTable) {
            /** @psalm-suppress PossiblyNullArgument */
            this._schema.describe(myTable, ["forceRefresh":true]);
        }

        return myTables;
    }

    /**
     * Clear metadata.
     *
     * @param string|null myName The name of the table to clear cache data for.
     * @return Returns a list of cleared table caches
     */
    string[] clear(Nullable!string myName = null) {
        if (myName) {
            myTables = [myName];
        } else {
            myTables = this._schema.listTables();
        }

        $cacher = this._schema.getCacher();

        foreach (myTables as myTable) {
            /** @psalm-suppress PossiblyNullArgument */
            myKey = this._schema.cacheKey(myTable);
            $cacher.delete(myKey);
        }

        return myTables;
    }

    /**
     * Helper method to get the schema collection.
     *
     * @param \Cake\Database\Connection myConnection Connection object
     * @return \Cake\Database\Schema\CachedCollection
     * @throws \RuntimeException If given connection object is not compatible with schema caching
     */
    auto getSchema(Connection myConnection): CachedCollection
    {
        myConfig = myConnection.config();
        if (empty(myConfig["cacheMetadata"])) {
            myConnection.cacheMetadata(true);
        }

        /** @var \Cake\Database\Schema\CachedCollection $schemaCollection */
        $schemaCollection = myConnection.getSchemaCollection();

        return $schemaCollection;
    }
}
