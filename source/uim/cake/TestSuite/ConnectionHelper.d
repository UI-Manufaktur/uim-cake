

/**

 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite;

import uim.cake.database.Connection;
import uim.cake.database.IDriver;
import uim.cake.Datasource\ConnectionManager;
use Closure;

/**
 * Helper for managing test connections
 *
 * @internal
 */
class ConnectionHelper
{
    /**
     * Adds `test_<connection name>` aliases for all non-test connections.
     *
     * This forces all models to use the test connection instead. For example,
     * if a model is confused to use connection `files` then it will be aliased
     * to `test_files`.
     *
     * The `default` connection is aliased to `test`.
     *
     * @return void
     */
    function addTestAliases(): void
    {
        ConnectionManager::alias('test', 'default');
        foreach (ConnectionManager::configured() as myConnection) {
            if (myConnection === 'test' || myConnection === 'default') {
                continue;
            }

            if (strpos(myConnection, 'test_') === 0) {
                $original = substr(myConnection, 5);
                ConnectionManager::alias(myConnection, $original);
            } else {
                $test = 'test_' . myConnection;
                ConnectionManager::alias($test, myConnection);
            }
        }
    }

    /**
     * Enables query logging for all database connections.
     *
     * @param array<int, string>|null myConnections Connection names or null for all.
     * @return void
     */
    function enableQueryLogging(?array myConnections = null): void
    {
        myConnections = myConnections ?? ConnectionManager::configured();
        foreach (myConnections as myConnection) {
            myConnection = ConnectionManager::get(myConnection);
            if (myConnection instanceof Connection) {
                myConnection.enableQueryLogging();
            }
        }
    }

    /**
     * Drops all tables.
     *
     * @param string myConnectionName Connection name
     * @param array<string>|null myTables List of tables names or null for all.
     * @return void
     */
    function dropTables(string myConnectionName, ?array myTables = null): void
    {
        /** @var \Cake\Database\Connection myConnection */
        myConnection = ConnectionManager::get(myConnectionName);
        myCollection = myConnection.getSchemaCollection();

        $allTables = myCollection.listTables();
        myTables = myTables !== null ? array_intersect(myTables, $allTables) : $allTables;
        $schemas = array_map(function (myTable) use (myCollection) {
            return myCollection.describe(myTable);
        }, myTables);

        $dialect = myConnection.getDriver().schemaDialect();
        /** @var \Cake\Database\Schema\TableSchema $schema */
        foreach ($schemas as $schema) {
            foreach ($dialect.dropConstraintSql($schema) as $statement) {
                myConnection.execute($statement).closeCursor();
            }
        }
        /** @var \Cake\Database\Schema\TableSchema $schema */
        foreach ($schemas as $schema) {
            foreach ($dialect.dropTableSql($schema) as $statement) {
                myConnection.execute($statement).closeCursor();
            }
        }
    }

    /**
     * Truncates all tables.
     *
     * @param string myConnectionName Connection name
     * @param array<string>|null myTables List of tables names or null for all.
     * @return void
     */
    function truncateTables(string myConnectionName, ?array myTables = null): void
    {
        /** @var \Cake\Database\Connection myConnection */
        myConnection = ConnectionManager::get(myConnectionName);
        myCollection = myConnection.getSchemaCollection();

        $allTables = myCollection.listTables();
        myTables = myTables !== null ? array_intersect(myTables, $allTables) : $allTables;
        $schemas = array_map(function (myTable) use (myCollection) {
            return myCollection.describe(myTable);
        }, myTables);

        this.runWithoutConstraints(myConnection, function (Connection myConnection) use ($schemas) {
            $dialect = myConnection.getDriver().schemaDialect();
            /** @var \Cake\Database\Schema\TableSchema $schema */
            foreach ($schemas as $schema) {
                foreach ($dialect.truncateTableSql($schema) as $statement) {
                    myConnection.execute($statement).closeCursor();
                }
            }
        });
    }

    /**
     * Runs callback with constraints disabled correctly per-database
     *
     * @param \Cake\Database\Connection myConnection Database connection
     * @param \Closure $callback callback
     * @return void
     */
    function runWithoutConstraints(Connection myConnection, Closure $callback): void
    {
        if (myConnection.getDriver().supports(IDriver::FEATURE_DISABLE_CONSTRAINT_WITHOUT_TRANSACTION)) {
            myConnection.disableConstraints(function (Connection myConnection) use ($callback) {
                $callback(myConnection);
            });
        } else {
            myConnection.transactional(function (Connection myConnection) use ($callback) {
                myConnection.disableConstraints(function (Connection myConnection) use ($callback) {
                    $callback(myConnection);
                });
            });
        }
    }
}
