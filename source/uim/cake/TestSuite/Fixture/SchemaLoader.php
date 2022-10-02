

/**

 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite\Fixture;

import uim.cake.database.Schema\TableSchema;
import uim.cake.Datasource\ConnectionManager;
import uim.cake.TestSuite\ConnectionHelper;
use InvalidArgumentException;

/**
 * Create test database schema from one or more SQL dump files.
 *
 * This class can be useful to create test database schema when
 * your schema is managed by tools external to your CakePHP
 * application.
 *
 * It is not well suited for applications/plugins that need to
 * support multiple database platforms. You should use migrations
 * for that instead.
 */
class SchemaLoader
{
    /**
     * @var \Cake\TestSuite\ConnectionHelper
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
     * @param array<string>|string myPaths Schema files to load
     * @param string myConnectionName Connection name
     * @param bool $dropTables Drop all tables prior to loading schema files
     * @param bool $truncateTables Truncate all tables after loading schema files
     * @return void
     */
    function loadSqlFiles(
        myPaths,
        string myConnectionName = 'test',
        bool $dropTables = true,
        bool $truncateTables = false
    ): void {
        $files = (array)myPaths;

        // Don't create schema if we are in a phpunit separate process test method.
        if (isset($GLOBALS['__PHPUNIT_BOOTSTRAP'])) {
            return;
        }

        if ($dropTables) {
            this.helper.dropTables(myConnectionName);
        }

        /** @var \Cake\Database\Connection myConnection */
        myConnection = ConnectionManager::get(myConnectionName);
        foreach ($files as $file) {
            if (!file_exists($file)) {
                throw new InvalidArgumentException("Unable to load SQL file `$file`.");
            }
            mySql = file_get_contents($file);

            // Use the underlying PDO connection so we can avoid prepared statements
            // which don't support multiple queries in postgres.
            myDriver = myConnection.getDriver();
            myDriver.getConnection().exec(mySql);
        }

        if ($truncateTables) {
            this.helper.truncateTables(myConnectionName);
        }
    }

    /**
     * Load and apply CakePHP-specific schema file.
     *
     * @param string $file Schema file
     * @param string myConnectionName Connection name
     * @return void
     * @internal
     */
    function loadInternalFile(string $file, string myConnectionName = 'test'): void
    {
        // Don't reload schema when we are in a separate process state.
        if (isset($GLOBALS['__PHPUNIT_BOOTSTRAP'])) {
            return;
        }

        this.helper.dropTables(myConnectionName);

        myTables = include $file;

        myConnection = ConnectionManager::get(myConnectionName);
        myConnection.disableConstraints(function (myConnection) use (myTables) {
            foreach (myTables as myTable) {
                $schema = new TableSchema(myTable['table'], myTable['columns']);
                if (isset(myTable['indexes'])) {
                    foreach (myTable['indexes'] as myKey => $index) {
                        $schema.addIndex(myKey, $index);
                    }
                }
                if (isset(myTable['constraints'])) {
                    foreach (myTable['constraints'] as myKey => $index) {
                        $schema.addConstraint(myKey, $index);
                    }
                }

                // Generate SQL for each table.
                foreach ($schema.createSql(myConnection) as mySql) {
                    myConnection.execute(mySql);
                }
            }
        });
    }
}
