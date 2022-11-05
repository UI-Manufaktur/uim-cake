module uim.baklava.databases.Schema;

import uim.baklava.databases.IDriver;
import uim.baklava.databases.Type\ColumnSchemaAwareInterface;
import uim.baklava.databases.TypeFactory;
use InvalidArgumentException;

/**
 * Base class for schema implementations.
 *
 * This class contains methods that are common across
 * the various SQL dialects.
 */
abstract class SchemaDialect
{
    /**
     * The driver instance being used.
     *
     * @var \Cake\Database\IDriver
     */
    protected $_driver;

    /**
     * Constructor
     *
     * This constructor will connect the driver so that methods like columnSql() and others
     * will fail when the driver has not been connected.
     *
     * @param \Cake\Database\IDriver myDriver The driver to use.
     */
    this(IDriver myDriver) {
        myDriver.connect();
        this._driver = myDriver;
    }

    /**
     * Generate an ON clause for a foreign key.
     *
     * @param string $on The on clause
     * @return string
     */
    protected auto _foreignOnClause(string $on): string
    {
        if ($on === TableSchema::ACTION_SET_NULL) {
            return 'SET NULL';
        }
        if ($on === TableSchema::ACTION_SET_DEFAULT) {
            return 'SET DEFAULT';
        }
        if ($on === TableSchema::ACTION_CASCADE) {
            return 'CASCADE';
        }
        if ($on === TableSchema::ACTION_RESTRICT) {
            return 'RESTRICT';
        }
        if ($on === TableSchema::ACTION_NO_ACTION) {
            return 'NO ACTION';
        }

        throw new InvalidArgumentException('Invalid value for "on": ' . $on);
    }

    /**
     * Convert string on clauses to the abstract ones.
     *
     * @param string $clause The on clause to convert.
     * @return string
     */
    protected auto _convertOnClause(string $clause): string
    {
        if ($clause === 'CASCADE' || $clause === 'RESTRICT') {
            return strtolower($clause);
        }
        if ($clause === 'NO ACTION') {
            return TableSchema::ACTION_NO_ACTION;
        }

        return TableSchema::ACTION_SET_NULL;
    }

    /**
     * Convert foreign key constraints references to a valid
     * stringified list
     *
     * @param array<string>|string $references The referenced columns of a foreign key constraint statement
     * @return string
     */
    protected auto _convertConstraintColumns($references): string
    {
        if (is_string($references)) {
            return this._driver.quoteIdentifier($references);
        }

        return implode(', ', array_map(
            [this._driver, 'quoteIdentifier'],
            $references
        ));
    }

    /**
     * Tries to use a matching database type to generate the SQL
     * fragment for a single column in a table.
     *
     * @param string $columnType The column type.
     * @param \Cake\Database\Schema\TableSchemaInterface $schema The table schema instance the column is in.
     * @param string $column The name of the column.
     * @return string|null An SQL fragment, or `null` in case no corresponding type was found or the type didn't provide
     *  custom column SQL.
     */
    protected auto _getTypeSpecificColumnSql(
        string $columnType,
        TableSchemaInterface $schema,
        string $column
    ): Nullable!string {
        if (!TypeFactory::getMap($columnType)) {
            return null;
        }

        myType = TypeFactory::build($columnType);
        if (!(myType instanceof ColumnSchemaAwareInterface)) {
            return null;
        }

        return myType.getColumnSql($schema, $column, this._driver);
    }

    /**
     * Tries to use a matching database type to convert a SQL column
     * definition to an abstract type definition.
     *
     * @param string $columnType The column type.
     * @param array $definition The column definition.
     * @return array|null Array of column information, or `null` in case no corresponding type was found or the type
     *  didn't provide custom column information.
     */
    protected auto _applyTypeSpecificColumnConversion(string $columnType, array $definition): ?array
    {
        if (!TypeFactory::getMap($columnType)) {
            return null;
        }

        myType = TypeFactory::build($columnType);
        if (!(myType instanceof ColumnSchemaAwareInterface)) {
            return null;
        }

        return myType.convertColumnDefinition($definition, this._driver);
    }

    /**
     * Generate the SQL to drop a table.
     *
     * @param \Cake\Database\Schema\TableSchema $schema Schema instance
     * @return array SQL statements to drop a table.
     */
    function dropTableSql(TableSchema $schema): array
    {
        mySql = sprintf(
            'DROP TABLE %s',
            this._driver.quoteIdentifier($schema.name())
        );

        return [mySql];
    }

    /**
     * Generate the SQL to list the tables.
     *
     * @param array<string, mixed> myConfig The connection configuration to use for
     *    getting tables from.
     * @return array An array of (sql, params) to execute.
     */
    abstract function listTablesSql(array myConfig): array;

    /**
     * Generate the SQL to describe a table.
     *
     * @param string myTableName The table name to get information on.
     * @param array<string, mixed> myConfig The connection configuration.
     * @return array An array of (sql, params) to execute.
     */
    abstract function describeColumnSql(string myTableName, array myConfig): array;

    /**
     * Generate the SQL to describe the indexes in a table.
     *
     * @param string myTableName The table name to get information on.
     * @param array<string, mixed> myConfig The connection configuration.
     * @return array An array of (sql, params) to execute.
     */
    abstract function describeIndexSql(string myTableName, array myConfig): array;

    /**
     * Generate the SQL to describe the foreign keys in a table.
     *
     * @param string myTableName The table name to get information on.
     * @param array<string, mixed> myConfig The connection configuration.
     * @return array An array of (sql, params) to execute.
     */
    abstract function describeForeignKeySql(string myTableName, array myConfig): array;

    /**
     * Generate the SQL to describe table options
     *
     * @param string myTableName Table name.
     * @param array<string, mixed> myConfig The connection configuration.
     * @return array SQL statements to get options for a table.
     */
    function describeOptionsSql(string myTableName, array myConfig): array
    {
        return ['', ''];
    }

    /**
     * Convert field description results into abstract schema fields.
     *
     * @param \Cake\Database\Schema\TableSchema $schema The table object to append fields to.
     * @param array $row The row data from `describeColumnSql`.
     * @return void
     */
    abstract function convertColumnDescription(TableSchema $schema, array $row): void;

    /**
     * Convert an index description results into abstract schema indexes or constraints.
     *
     * @param \Cake\Database\Schema\TableSchema $schema The table object to append
     *    an index or constraint to.
     * @param array $row The row data from `describeIndexSql`.
     * @return void
     */
    abstract function convertIndexDescription(TableSchema $schema, array $row): void;

    /**
     * Convert a foreign key description into constraints on the Table object.
     *
     * @param \Cake\Database\Schema\TableSchema $schema The table object to append
     *    a constraint to.
     * @param array $row The row data from `describeForeignKeySql`.
     * @return void
     */
    abstract function convertForeignKeyDescription(TableSchema $schema, array $row): void;

    /**
     * Convert options data into table options.
     *
     * @param \Cake\Database\Schema\TableSchema $schema Table instance.
     * @param array $row The row of data.
     * @return void
     */
    function convertOptionsDescription(TableSchema $schema, array $row): void
    {
    }

    /**
     * Generate the SQL to create a table.
     *
     * @param \Cake\Database\Schema\TableSchema $schema Table instance.
     * @param array<string> $columns The columns to go inside the table.
     * @param array<string> $constraints The constraints for the table.
     * @param array<string> $indexes The indexes for the table.
     * @return array<string> SQL statements to create a table.
     */
    abstract function createTableSql(
        TableSchema $schema,
        array $columns,
        array $constraints,
        array $indexes
    ): array;

    /**
     * Generate the SQL fragment for a single column in a table.
     *
     * @param \Cake\Database\Schema\TableSchema $schema The table instance the column is in.
     * @param string myName The name of the column.
     * @return string SQL fragment.
     */
    abstract function columnSql(TableSchema $schema, string myName): string;

    /**
     * Generate the SQL queries needed to add foreign key constraints to the table
     *
     * @param \Cake\Database\Schema\TableSchema $schema The table instance the foreign key constraints are.
     * @return array SQL fragment.
     */
    abstract function addConstraintSql(TableSchema $schema): array;

    /**
     * Generate the SQL queries needed to drop foreign key constraints from the table
     *
     * @param \Cake\Database\Schema\TableSchema $schema The table instance the foreign key constraints are.
     * @return array SQL fragment.
     */
    abstract function dropConstraintSql(TableSchema $schema): array;

    /**
     * Generate the SQL fragments for defining table constraints.
     *
     * @param \Cake\Database\Schema\TableSchema $schema The table instance the column is in.
     * @param string myName The name of the column.
     * @return string SQL fragment.
     */
    abstract function constraintSql(TableSchema $schema, string myName): string;

    /**
     * Generate the SQL fragment for a single index in a table.
     *
     * @param \Cake\Database\Schema\TableSchema $schema The table object the column is in.
     * @param string myName The name of the column.
     * @return string SQL fragment.
     */
    abstract function indexSql(TableSchema $schema, string myName): string;

    /**
     * Generate the SQL to truncate a table.
     *
     * @param \Cake\Database\Schema\TableSchema $schema Table instance.
     * @return array SQL statements to truncate a table.
     */
    abstract function truncateTableSql(TableSchema $schema): array;
}

// phpcs:disable
// Add backwards compatible alias.
class_alias('Cake\Database\Schema\SchemaDialect', 'Cake\Database\Schema\BaseSchema');
// phpcs:enable
