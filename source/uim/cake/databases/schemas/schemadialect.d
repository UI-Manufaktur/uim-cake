module uim.cake.databases.Schema;

import uim.cake.databases.IDriver;
import uim.cake.databases.types.ColumnSchemaAwareInterface;
import uim.cake.databases.TypeFactory;
use InvalidArgumentException;

/**
 * Base class for schema implementations.
 *
 * This class contains methods that are common across
 * the various SQL dialects.
 *
 * @method array<mixed> listTablesWithoutViewsSql(array $config) Generate the SQL to list the tables, excluding all views.
 */
abstract class SchemaDialect
{
    /**
     * The driver instance being used.
     *
     * @var uim.cake.databases.IDriver
     */
    protected $_driver;

    /**
     * Constructor
     *
     * This constructor will connect the driver so that methods like columnSql() and others
     * will fail when the driver has not been connected.
     *
     * @param uim.cake.databases.IDriver $driver The driver to use.
     */
    this(IDriver $driver) {
        $driver.connect();
        _driver = $driver;
    }

    /**
     * Generate an ON clause for a foreign key.
     *
     * @param string $on The on clause
     */
    protected string _foreignOnClause(string $on) {
        if ($on == TableSchema::ACTION_SET_NULL) {
            return "SET NULL";
        }
        if ($on == TableSchema::ACTION_SET_DEFAULT) {
            return "SET DEFAULT";
        }
        if ($on == TableSchema::ACTION_CASCADE) {
            return "CASCADE";
        }
        if ($on == TableSchema::ACTION_RESTRICT) {
            return "RESTRICT";
        }
        if ($on == TableSchema::ACTION_NO_ACTION) {
            return "NO ACTION";
        }

        throw new InvalidArgumentException("Invalid value for "on": " ~ $on);
    }

    /**
     * Convert string on clauses to the abstract ones.
     *
     * @param string $clause The on clause to convert.
     */
    protected string _convertOnClause(string $clause) {
        if ($clause == "CASCADE" || $clause == "RESTRICT") {
            return strtolower($clause);
        }
        if ($clause == "NO ACTION") {
            return TableSchema::ACTION_NO_ACTION;
        }

        return TableSchema::ACTION_SET_NULL;
    }

    /**
     * Convert foreign key constraints references to a valid
     * stringified list
     *
     * @param array<string>|string $references The referenced columns of a foreign key constraint statement
     */
    protected string _convertConstraintColumns($references) {
        if (is_string($references)) {
            return _driver.quoteIdentifier($references);
        }

        return implode(", ", array_map(
            [_driver, "quoteIdentifier"],
            $references
        ));
    }

    /**
     * Tries to use a matching database type to generate the SQL
     * fragment for a single column in a table.
     *
     * @param string $columnType The column type.
     * @param uim.cake.databases.Schema\TableISchema $schema The table schema instance the column is in.
     * @param string $column The name of the column.
     * @return string|null An SQL fragment, or `null` in case no corresponding type was found or the type didn"t provide
     *  custom column SQL.
     */
    protected function _getTypeSpecificColumnSql(
        string $columnType,
        TableISchema $schema,
        string $column
    ): ?string {
        if (!TypeFactory::getMap($columnType)) {
            return null;
        }

        $type = TypeFactory::build($columnType);
        if (!($type instanceof ColumnSchemaAwareInterface)) {
            return null;
        }

        return $type.getColumnSql($schema, $column, _driver);
    }

    /**
     * Tries to use a matching database type to convert a SQL column
     * definition to an abstract type definition.
     *
     * @param string $columnType The column type.
     * @param array $definition The column definition.
     * @return array|null Array of column information, or `null` in case no corresponding type was found or the type
     *  didn"t provide custom column information.
     */
    protected function _applyTypeSpecificColumnConversion(string $columnType, array $definition): ?array
    {
        if (!TypeFactory::getMap($columnType)) {
            return null;
        }

        $type = TypeFactory::build($columnType);
        if (!($type instanceof ColumnSchemaAwareInterface)) {
            return null;
        }

        return $type.convertColumnDefinition($definition, _driver);
    }

    /**
     * Generate the SQL to drop a table.
     *
     * @param uim.cake.databases.Schema\TableSchema $schema Schema instance
     * @return array SQL statements to drop a table.
     */
    function dropTableSql(TableSchema $schema): array
    {
        $sql = sprintf(
            "DROP TABLE %s",
            _driver.quoteIdentifier($schema.name())
        );

        return [$sql];
    }

    /**
     * Generate the SQL to list the tables.
     *
     * @param array<string, mixed> $config The connection configuration to use for
     *    getting tables from.
     * @return array An array of (sql, params) to execute.
     */
    abstract function listTablesSql(array $config): array;

    /**
     * Generate the SQL to describe a table.
     *
     * @param string $tableName The table name to get information on.
     * @param array<string, mixed> $config The connection configuration.
     * @return array An array of (sql, params) to execute.
     */
    abstract array describeColumnSql(string $tableName, array $config): array;

    /**
     * Generate the SQL to describe the indexes in a table.
     *
     * @param string $tableName The table name to get information on.
     * @param array<string, mixed> $config The connection configuration.
     * @return array An array of (sql, params) to execute.
     */
    abstract array describeIndexSql(string $tableName, array $config): array;

    /**
     * Generate the SQL to describe the foreign keys in a table.
     *
     * @param string $tableName The table name to get information on.
     * @param array<string, mixed> $config The connection configuration.
     * @return array An array of (sql, params) to execute.
     */
    abstract array describeForeignKeySql(string $tableName, array $config): array;

    /**
     * Generate the SQL to describe table options
     *
     * @param string $tableName Table name.
     * @param array<string, mixed> $config The connection configuration.
     * @return array SQL statements to get options for a table.
     */
    function describeOptionsSql(string $tableName, array $config): array
    {
        return ["", ""];
    }

    /**
     * Convert field description results into abstract schema fields.
     *
     * @param uim.cake.databases.Schema\TableSchema $schema The table object to append fields to.
     * @param array $row The row data from `describeColumnSql`.
     * @return void
     */
    abstract void convertColumnDescription(TableSchema $schema, array $row);

    /**
     * Convert an index description results into abstract schema indexes or constraints.
     *
     * @param uim.cake.databases.Schema\TableSchema $schema The table object to append
     *    an index or constraint to.
     * @param array $row The row data from `describeIndexSql`.
     * @return void
     */
    abstract void convertIndexDescription(TableSchema $schema, array $row);

    /**
     * Convert a foreign key description into constraints on the Table object.
     *
     * @param uim.cake.databases.Schema\TableSchema $schema The table object to append
     *    a constraint to.
     * @param array $row The row data from `describeForeignKeySql`.
     * @return void
     */
    abstract void convertForeignKeyDescription(TableSchema $schema, array $row);

    /**
     * Convert options data into table options.
     *
     * @param uim.cake.databases.Schema\TableSchema $schema Table instance.
     * @param array $row The row of data.
     */
    void convertOptionsDescription(TableSchema $schema, array $row) {
    }

    /**
     * Generate the SQL to create a table.
     *
     * @param uim.cake.databases.Schema\TableSchema $schema Table instance.
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
     * @param uim.cake.databases.Schema\TableSchema $schema The table instance the column is in.
     * @param string aName The name of the column.
     * @return string SQL fragment.
     */
    abstract string columnSql(TableSchema $schema, string aName);

    /**
     * Generate the SQL queries needed to add foreign key constraints to the table
     *
     * @param uim.cake.databases.Schema\TableSchema $schema The table instance the foreign key constraints are.
     * @return array SQL fragment.
     */
    abstract array addConstraintSql(TableSchema $schema): array;

    /**
     * Generate the SQL queries needed to drop foreign key constraints from the table
     *
     * @param uim.cake.databases.Schema\TableSchema $schema The table instance the foreign key constraints are.
     * @return array SQL fragment.
     */
    abstract array dropConstraintSql(TableSchema $schema): array;

    /**
     * Generate the SQL fragments for defining table constraints.
     *
     * @param uim.cake.databases.Schema\TableSchema $schema The table instance the column is in.
     * @param string aName The name of the column.
     * @return string SQL fragment.
     */
    abstract string constraintSql(TableSchema $schema, string aName);

    /**
     * Generate the SQL fragment for a single index in a table.
     *
     * @param uim.cake.databases.Schema\TableSchema $schema The table object the column is in.
     * @param string aName The name of the column.
     * @return string SQL fragment.
     */
    abstract string indexSql(TableSchema $schema, string aName);

    /**
     * Generate the SQL to truncate a table.
     *
     * @param uim.cake.databases.Schema\TableSchema $schema Table instance.
     * @return array SQL statements to truncate a table.
     */
    abstract function truncateTableSql(TableSchema $schema): array;
}

// phpcs:disable
// Add backwards compatible alias.
class_alias("Cake\databases.Schema\SchemaDialect", "Cake\databases.Schema\BaseSchema");
// phpcs:enable
