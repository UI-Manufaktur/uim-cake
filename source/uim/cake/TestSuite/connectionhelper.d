

 * @since         4.3.0
  */module uim.cake.TestSuite;

import uim.cake.databases.Connection;
import uim.cake.databases.DriverInterface;
import uim.cake.datasources.ConnectionManager;
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
     */
    void addTestAliases(): void
    {
        ConnectionManager::alias("test", "default");
        foreach (ConnectionManager::configured() as $connection) {
            if ($connection == "test" || $connection == "default") {
                continue;
            }

            if (strpos($connection, "test_") == 0) {
                $original = substr($connection, 5);
                ConnectionManager::alias($connection, $original);
            } else {
                $test = "test_" ~ $connection;
                ConnectionManager::alias($test, $connection);
            }
        }
    }

    /**
     * Enables query logging for all database connections.
     *
     * @param array<int, string>|null $connections Connection names or null for all.
     */
    void enableQueryLogging(?array $connections = null): void
    {
        $connections = $connections ?? ConnectionManager::configured();
        foreach ($connections as $connection) {
            $connection = ConnectionManager::get($connection);
            if ($connection instanceof Connection) {
                $connection.enableQueryLogging();
            }
        }
    }

    /**
     * Drops all tables.
     *
     * @param string $connectionName Connection name
     * @param array<string>|null $tables List of tables names or null for all.
     */
    void dropTables(string $connectionName, ?array $tables = null): void
    {
        /** @var uim.cake.databases.Connection $connection */
        $connection = ConnectionManager::get($connectionName);
        $collection = $connection.getSchemaCollection();

        if (method_exists($collection, "listTablesWithoutViews")) {
            $allTables = $collection.listTablesWithoutViews();
        } else {
            $allTables = $collection.listTables();
        }

        $tables = $tables != null ? array_intersect($tables, $allTables) : $allTables;
        $schemas = array_map(function ($table) use ($collection) {
            return $collection.describe($table);
        }, $tables);

        $dialect = $connection.getDriver().schemaDialect();
        /** @var uim.cake.databases.Schema\TableSchema $schema */
        foreach ($schemas as $schema) {
            foreach ($dialect.dropConstraintSql($schema) as $statement) {
                $connection.execute($statement).closeCursor();
            }
        }
        /** @var uim.cake.databases.Schema\TableSchema $schema */
        foreach ($schemas as $schema) {
            foreach ($dialect.dropTableSql($schema) as $statement) {
                $connection.execute($statement).closeCursor();
            }
        }
    }

    /**
     * Truncates all tables.
     *
     * @param string $connectionName Connection name
     * @param array<string>|null $tables List of tables names or null for all.
     */
    void truncateTables(string $connectionName, ?array $tables = null): void
    {
        /** @var uim.cake.databases.Connection $connection */
        $connection = ConnectionManager::get($connectionName);
        $collection = $connection.getSchemaCollection();

        $allTables = $collection.listTablesWithoutViews();
        $tables = $tables != null ? array_intersect($tables, $allTables) : $allTables;
        $schemas = array_map(function ($table) use ($collection) {
            return $collection.describe($table);
        }, $tables);

        this.runWithoutConstraints($connection, function (Connection $connection) use ($schemas): void {
            $dialect = $connection.getDriver().schemaDialect();
            /** @var uim.cake.databases.Schema\TableSchema $schema */
            foreach ($schemas as $schema) {
                foreach ($dialect.truncateTableSql($schema) as $statement) {
                    $connection.execute($statement).closeCursor();
                }
            }
        });
    }

    /**
     * Runs callback with constraints disabled correctly per-database
     *
     * @param uim.cake.databases.Connection $connection Database connection
     * @param \Closure $callback callback
     */
    void runWithoutConstraints(Connection $connection, Closure $callback): void
    {
        if ($connection.getDriver().supports(DriverInterface::FEATURE_DISABLE_CONSTRAINT_WITHOUT_TRANSACTION)) {
            $connection.disableConstraints(function (Connection $connection) use ($callback): void {
                $callback($connection);
            });
        } else {
            $connection.transactional(function (Connection $connection) use ($callback): void {
                $connection.disableConstraints(function (Connection $connection) use ($callback): void {
                    $callback($connection);
                });
            });
        }
    }
}