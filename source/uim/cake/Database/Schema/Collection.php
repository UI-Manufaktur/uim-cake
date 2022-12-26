

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Schema;

import uim.cake.databases.Connection;
import uim.cake.databases.Exception\DatabaseException;
use PDOException;

/**
 * Represents a database schema collection
 *
 * Used to access information about the tables,
 * and other data in a database.
 */
class Collection : ICollection
{
    /**
     * Connection object
     *
     * @var \Cake\Database\Connection
     */
    protected $_connection;

    /**
     * Schema dialect instance.
     *
     * @var \Cake\Database\Schema\SchemaDialect
     */
    protected $_dialect;

    /**
     * Constructor.
     *
     * @param \Cake\Database\Connection $connection The connection instance.
     */
    public this(Connection $connection)
    {
        _connection = $connection;
        _dialect = $connection.getDriver().schemaDialect();
    }

    /**
     * Get the list of tables, excluding any views, available in the current connection.
     *
     * @return array<string> The list of tables in the connected database/schema.
     */
    function listTablesWithoutViews(): array
    {
        [$sql, $params] = _dialect.listTablesWithoutViewsSql(_connection.config());
        $result = [];
        $statement = _connection.execute($sql, $params);
        while ($row = $statement.fetch()) {
            $result[] = $row[0];
        }
        $statement.closeCursor();

        return $result;
    }

    /**
     * Get the list of tables and views available in the current connection.
     *
     * @return array<string> The list of tables and views in the connected database/schema.
     */
    function listTables(): array
    {
        [$sql, $params] = _dialect.listTablesSql(_connection.config());
        $result = [];
        $statement = _connection.execute($sql, $params);
        while ($row = $statement.fetch()) {
            $result[] = $row[0];
        }
        $statement.closeCursor();

        return $result;
    }

    /**
     * Get the column metadata for a table.
     *
     * The name can include a database schema name in the form 'schema.table'.
     *
     * Caching will be applied if `cacheMetadata` key is present in the Connection
     * configuration options. Defaults to _cake_model_ when true.
     *
     * ### Options
     *
     * - `forceRefresh` - Set to true to force rebuilding the cached metadata.
     *   Defaults to false.
     *
     * @param string $name The name of the table to describe.
     * @param array<string, mixed> $options The options to use, see above.
     * @return \Cake\Database\Schema\TableSchema Object with column metadata.
     * @throws \Cake\Database\Exception\DatabaseException when table cannot be described.
     */
    function describe(string $name, array $options = []): TableSchemaInterface
    {
        $config = _connection.config();
        if (strpos($name, '.')) {
            [$config['schema'], $name] = explode('.', $name);
        }
        $table = _connection.getDriver().newTableSchema($name);

        _reflect('Column', $name, $config, $table);
        if (count($table.columns()) == 0) {
            throw new DatabaseException(sprintf('Cannot describe %s. It has 0 columns.', $name));
        }

        _reflect('Index', $name, $config, $table);
        _reflect('ForeignKey', $name, $config, $table);
        _reflect('Options', $name, $config, $table);

        return $table;
    }

    /**
     * Helper method for running each step of the reflection process.
     *
     * @param string $stage The stage name.
     * @param string $name The table name.
     * @param array<string, mixed> $config The config data.
     * @param \Cake\Database\Schema\TableSchema $schema The table schema instance.
     * @return void
     * @throws \Cake\Database\Exception\DatabaseException on query failure.
     * @uses \Cake\Database\Schema\SchemaDialect::describeColumnSql
     * @uses \Cake\Database\Schema\SchemaDialect::describeIndexSql
     * @uses \Cake\Database\Schema\SchemaDialect::describeForeignKeySql
     * @uses \Cake\Database\Schema\SchemaDialect::describeOptionsSql
     * @uses \Cake\Database\Schema\SchemaDialect::convertColumnDescription
     * @uses \Cake\Database\Schema\SchemaDialect::convertIndexDescription
     * @uses \Cake\Database\Schema\SchemaDialect::convertForeignKeyDescription
     * @uses \Cake\Database\Schema\SchemaDialect::convertOptionsDescription
     */
    protected function _reflect(string $stage, string $name, array $config, TableSchema $schema): void
    {
        $describeMethod = "describe{$stage}Sql";
        $convertMethod = "convert{$stage}Description";

        [$sql, $params] = _dialect.{$describeMethod}($name, $config);
        if (empty($sql)) {
            return;
        }
        try {
            $statement = _connection.execute($sql, $params);
        } catch (PDOException $e) {
            throw new DatabaseException($e.getMessage(), 500, $e);
        }
        /** @psalm-suppress PossiblyFalseIterator */
        foreach ($statement.fetchAll('assoc') as $row) {
            _dialect.{$convertMethod}($schema, $row);
        }
        $statement.closeCursor();
    }
}
