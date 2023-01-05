module uim.cake.databases.Schema;

import uim.cake.databases.Connection;
import uim.cake.databases.exceptions.DatabaseException;
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
     * @var uim.cake.databases.Connection
     */
    protected $_connection;

    /**
     * Schema dialect instance.
     *
     * @var uim.cake.databases.Schema\SchemaDialect
     */
    protected $_dialect;

    /**
     * Constructor.
     *
     * @param uim.cake.databases.Connection $connection The connection instance.
     */
    this(Connection $connection) {
        _connection = $connection;
        _dialect = $connection.getDriver().schemaDialect();
    }

    /**
     * Get the list of tables, excluding any views, available in the current connection.
     *
     * @return array<string> The list of tables in the connected database/schema.
     */
    array listTablesWithoutViews() {
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
    array listTables() {
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
     * The name can include a database schema name in the form "schema.table".
     *
     * Caching will be applied if `cacheMetadata` key is present in the Connection
     * configuration options. Defaults to _cake_model_ when true.
     *
     * ### Options
     *
     * - `forceRefresh` - Set to true to force rebuilding the cached metadata.
     *   Defaults to false.
     *
     * @param string aName The name of the table to describe.
     * @param array<string, mixed> $options The options to use, see above.
     * @return uim.cake.databases.Schema\TableSchema Object with column metadata.
     * @throws uim.cake.databases.exceptions.DatabaseException when table cannot be described.
     */
    function describe(string aName, array $options = []): TableISchema
    {
        $config = _connection.config();
        if (strpos($name, ".")) {
            [$config["schema"], $name] = explode(".", $name);
        }
        $table = _connection.getDriver().newTableSchema($name);

        _reflect("Column", $name, $config, $table);
        if (count($table.columns()) == 0) {
            throw new DatabaseException(sprintf("Cannot describe %s. It has 0 columns.", $name));
        }

        _reflect("Index", $name, $config, $table);
        _reflect("ForeignKey", $name, $config, $table);
        _reflect("Options", $name, $config, $table);

        return $table;
    }

    /**
     * Helper method for running each step of the reflection process.
     *
     * @param string $stage The stage name.
     * @param string aName The table name.
     * @param array<string, mixed> $config The config data.
     * @param uim.cake.databases.Schema\TableSchema $schema The table schema instance.
     * @return void
     * @throws uim.cake.databases.exceptions.DatabaseException on query failure.
     * @uses uim.cake.databases.Schema\SchemaDialect::describeColumnSql
     * @uses uim.cake.databases.Schema\SchemaDialect::describeIndexSql
     * @uses uim.cake.databases.Schema\SchemaDialect::describeForeignKeySql
     * @uses uim.cake.databases.Schema\SchemaDialect::describeOptionsSql
     * @uses uim.cake.databases.Schema\SchemaDialect::convertColumnDescription
     * @uses uim.cake.databases.Schema\SchemaDialect::convertIndexDescription
     * @uses uim.cake.databases.Schema\SchemaDialect::convertForeignKeyDescription
     * @uses uim.cake.databases.Schema\SchemaDialect::convertOptionsDescription
     */
    protected void _reflect(string $stage, string aName, array $config, TableSchema $schema) {
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
        foreach ($statement.fetchAll("assoc") as $row) {
            _dialect.{$convertMethod}($schema, $row);
        }
        $statement.closeCursor();
    }
}
