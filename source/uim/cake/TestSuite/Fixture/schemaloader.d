

 * @since         4.3.0
  */module uim.cake.TestSuite\Fixture;

import uim.cake.databases.schemas.TableSchema;
import uim.datasources.ConnectionManager;
import uim.cake.TestSuite\ConnectionHelper;
use InvalidArgumentException;

/**
 * Create test database schema from one or more SQL dump files.
 *
 * This class can be useful to create test database schema when
 * your schema is managed by tools external to your UIM
 * application.
 *
 * It is not well suited for applications/plugins that need to
 * support multiple database platforms. You should use migrations
 * for that instead.
 */
class SchemaLoader
{
    /**
     * @var uim.cake.TestSuite\ConnectionHelper
     */
    protected $helper;

    /**
     * Constructor.
     */
    this() {
        this.helper = new ConnectionHelper();
    }

    /**
     * Load and apply schema sql file, or an array of files.
     *
     * @param array<string>|string $paths Schema files to load
     * @param string $connectionName Connection name
     * @param bool $dropTables Drop all tables prior to loading schema files
     * @param bool $truncateTables Truncate all tables after loading schema files
     */
    void loadSqlFiles(
        $paths,
        string $connectionName = "test",
        bool $dropTables = true,
        bool $truncateTables = false
    ) {
        $files = (array)$paths;

        // Don"t create schema if we are in a phpunit separate process test method.
        if (isset($GLOBALS["__PHPUNIT_BOOTSTRAP"])) {
            return;
        }

        if ($dropTables) {
            this.helper.dropTables($connectionName);
        }

        /** @var DDBConnection $connection */
        $connection = ConnectionManager::get($connectionName);
        foreach ($files as $file) {
            if (!file_exists($file)) {
                throw new InvalidArgumentException("Unable to load SQL file `$file`.");
            }
            $sql = file_get_contents($file);

            // Use the underlying PDO connection so we can avoid prepared statements
            // which don"t support multiple queries in postgres.
            $driver = $connection.getDriver();
            $driver.getConnection().exec($sql);
        }

        if ($truncateTables) {
            this.helper.truncateTables($connectionName);
        }
    }

    /**
     * Load and apply UIM-specific schema file.
     *
     * @param string $file Schema file
     * @param string $connectionName Connection name
     * @return void
     * @internal
     */
    function loadInternalFile(string $file, string $connectionName = "test") {
        // Don"t reload schema when we are in a separate process state.
        if (isset($GLOBALS["__PHPUNIT_BOOTSTRAP"])) {
            return;
        }

        this.helper.dropTables($connectionName);

        $tables = include $file;

        $connection = ConnectionManager::get($connectionName);
        $connection.disableConstraints(function ($connection) use ($tables) {
            foreach ($tables as $table) {
                $schema = new TableSchema($table["table"], $table["columns"]);
                if (isset($table["indexes"])) {
                    foreach ($table["indexes"] as $key: $index) {
                        $schema.addIndex($key, $index);
                    }
                }
                if (isset($table["constraints"])) {
                    foreach ($table["constraints"] as $key: $index) {
                        $schema.addConstraint($key, $index);
                    }
                }

                // Generate SQL for each table.
                foreach ($schema.createSql($connection) as $sql) {
                    $connection.execute($sql);
                }
            }
        });
    }
}
