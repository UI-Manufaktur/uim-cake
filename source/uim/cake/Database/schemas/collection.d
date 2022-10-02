module uim.cake.database.Schema;

import uim.cake.database.Connection;
import uim.cake.database.Exception\DatabaseException;
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
     * @param \Cake\Database\Connection myConnection The connection instance.
     */
    this(Connection myConnection)
    {
        this._connection = myConnection;
        this._dialect = myConnection.getDriver().schemaDialect();
    }

    /**
     * Get the list of tables available in the current connection.
     *
     * @return array<string> The list of tables in the connected database/schema.
     */
    function listTables(): array
    {
        [mySql, myParams] = this._dialect.listTablesSql(this._connection.config());
        myResult = [];
        $statement = this._connection.execute(mySql, myParams);
        while ($row = $statement.fetch()) {
            myResult[] = $row[0];
        }
        $statement.closeCursor();

        return myResult;
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
     * @param string myName The name of the table to describe.
     * @param array<string, mixed> myOptions The options to use, see above.
     * @return \Cake\Database\Schema\TableSchema Object with column metadata.
     * @throws \Cake\Database\Exception\DatabaseException when table cannot be described.
     */
    function describe(string myName, array myOptions = []): TableSchemaInterface
    {
        myConfig = this._connection.config();
        if (strpos(myName, '.')) {
            [myConfig['schema'], myName] = explode('.', myName);
        }
        myTable = this._connection.getDriver().newTableSchema(myName);

        this._reflect('Column', myName, myConfig, myTable);
        if (count(myTable.columns()) === 0) {
            throw new DatabaseException(sprintf('Cannot describe %s. It has 0 columns.', myName));
        }

        this._reflect('Index', myName, myConfig, myTable);
        this._reflect('ForeignKey', myName, myConfig, myTable);
        this._reflect('Options', myName, myConfig, myTable);

        return myTable;
    }

    /**
     * Helper method for running each step of the reflection process.
     *
     * @param string $stage The stage name.
     * @param string myName The table name.
     * @param array<string, mixed> myConfig The config data.
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
    protected auto _reflect(string $stage, string myName, array myConfig, TableSchema $schema): void
    {
        $describeMethod = "describe{$stage}Sql";
        $convertMethod = "convert{$stage}Description";

        [mySql, myParams] = this._dialect.{$describeMethod}(myName, myConfig);
        if (empty(mySql)) {
            return;
        }
        try {
            $statement = this._connection.execute(mySql, myParams);
        } catch (PDOException $e) {
            throw new DatabaseException($e.getMessage(), 500, $e);
        }
        /** @psalm-suppress PossiblyFalseIterator */
        foreach ($statement.fetchAll('assoc') as $row) {
            this._dialect.{$convertMethod}($schema, $row);
        }
        $statement.closeCursor();
    }
}
