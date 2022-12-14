

 * @since         1.2.0
  */module uim.cake.TestSuite\Fixture;

import uim.cake.core.exceptions.UIMException;
import uim.cake.databases.IConstraints;
import uim.cake.databases.schemas.TableSchema;
import uim.cake.databases.schemas.TableSchemaAwareInterface;
import uim.datasources.IConnection;
import uim.datasources.ConnectionManager;
import uim.datasources.IFixture;
import uim.cake.logs.Log;
import uim.cake.orm.locators.LocatorAwareTrait;
import uim.cake.utilities.Inflector;
use Exception;

/**
 * Cake TestFixture is responsible for building and destroying tables to be used
 * during testing.
 */
class TestFixture : IConstraints, IFixture, TableSchemaAwareInterface
{
    use LocatorAwareTrait;

    /**
     * Fixture Datasource
     *
     * @var string
     */
    $connection = "test";

    /**
     * Full Table Name
     *
     * @var string
     * @psalm-suppress PropertyNotSetInConstructor
     */
    $table;

    /**
     * Fields / Schema for the fixture.
     *
     * This array should be compatible with {@link uim.cake.databases.Schema\Schema}.
     * The `_constraints`, `_options` and `_indexes` keys are reserved for defining
     * constraints, options and indexes respectively.
     *
     * @var array
     */
    $fields = null;

    /**
     * Configuration for importing fixture schema
     *
     * Accepts a `connection` and `model` or `table` key, to define
     * which table and which connection contain the schema to be
     * imported.
     *
     * @var array|null
     */
    $import;

    /**
     * Fixture records to be inserted.
     *
     * @var array
     */
    $records = null;

    /**
     * The schema for this fixture.
     *
     * @var DDBSchema\TableISchema&uim.cake.databases.Schema\ISqlGenerator
     * @psalm-suppress PropertyNotSetInConstructor
     */
    protected _schema;

    /**
     * Fixture constraints to be created.
     *
     * @var array<string, mixed>
     */
    protected _constraints = null;

    /**
     * Instantiate the fixture.
     *
     * @throws uim.cake.Core\exceptions.UIMException on invalid datasource usage.
     */
    this() {
        if (!empty(this.connection)) {
            $connection = this.connection;
            if (strpos($connection, "test") != 0) {
                $message = sprintf(
                    "Invalid datasource name '%s' for '%s' fixture. Fixture datasource names must begin with "test".",
                    $connection,
                    static::class
                );
                throw new UIMException($message);
            }
        }
        this.init();
    }


    string connection() {
        return this.connection;
    }


    string sourceName() {
        return this.table;
    }

    /**
     * Initialize the fixture.
     *
     * @return void
     * @throws uim.cake.orm.exceptions.MissingTableClassException When importing from a table that does not exist.
     */
    void init() {
        if (this.table == null) {
            this.table = _tableFromClass();
        }

        if (empty(this.import) && !empty(this.fields)) {
            _schemaFromFields();
        }

        if (!empty(this.import)) {
            _schemaFromImport();
        }

        if (empty(this.import) && empty(this.fields)) {
            _schemaFromReflection();
        }
    }

    /**
     * Returns the table name using the fixture class
     */
    protected string _tableFromClass() {
        [, $class] = namespaceSplit(static::class);
        preg_match("/^(.*)Fixture$/", $class, $matches);
        $table = $matches[1] ?? $class;

        return Inflector::tableize($table);
    }

    /**
     * Build the fixtures table schema from the fields property.
     */
    protected void _schemaFromFields() {
        $connection = ConnectionManager::get(this.connection());
        _schema = $connection.getDriver().newTableSchema(this.table);
        foreach (this.fields as $field: $data) {
            if ($field == "_constraints" || $field == "_indexes" || $field == "_options") {
                continue;
            }
            _schema.addColumn($field, $data);
        }
        if (!empty(this.fields["_constraints"])) {
            foreach (this.fields["_constraints"] as $name: $data) {
                if (!$connection.supportsDynamicConstraints() || $data["type"] != TableSchema::CONSTRAINT_FOREIGN) {
                    _schema.addConstraint($name, $data);
                } else {
                    _constraints[$name] = $data;
                }
            }
        }
        if (!empty(this.fields["_indexes"])) {
            foreach (this.fields["_indexes"] as $name: $data) {
                _schema.addIndex($name, $data);
            }
        }
        if (!empty(this.fields["_options"])) {
            _schema.setOptions(this.fields["_options"]);
        }
    }

    /**
     * Build fixture schema from a table in another datasource.
     *
     * @return void
     * @throws uim.cake.Core\exceptions.UIMException when trying to import from an empty table.
     */
    protected void _schemaFromImport() {
        if (!is_array(this.import)) {
            return;
        }
        $import = this.import + ["connection": "default", "table": null, "model": null];

        if (!empty($import["model"])) {
            if (!empty($import["table"])) {
                throw new UIMException("You cannot define both table and model.");
            }
            $import["table"] = this.getTableLocator().get($import["model"]).getTable();
        }

        if (empty($import["table"])) {
            throw new UIMException("Cannot import from undefined table.");
        }

        this.table = $import["table"];

        $db = ConnectionManager::get($import["connection"], false);
        $schemaCollection = $db.getSchemaCollection();
        $table = $schemaCollection.describe($import["table"]);
        _schema = $table;
    }

    /**
     * Build fixture schema directly from the datasource
     *
     * @return void
     * @throws uim.cake.Core\exceptions.UIMException when trying to reflect a table that does not exist
     */
    protected void _schemaFromReflection() {
        $db = ConnectionManager::get(this.connection());
        try {
            $name = Inflector::camelize(this.table);
            $ormTable = this.fetchTable($name, ["connection": $db]);

            /** @var DDBSchema\TableSchema $schema */
            $schema = $ormTable.getSchema();
            _schema = $schema;

            this.getTableLocator().clear();
        } catch (UIMException $e) {
            $message = sprintf(
                "Cannot describe schema for table `%s` for fixture `%s`. The table does not exist.",
                this.table,
                static::class
            );
            throw new UIMException($message, null, $e);
        }
    }


    bool create(IConnection aConnection) {
        /** @psalm-suppress RedundantPropertyInitializationCheck */
        if (!isset(_schema)) {
            return false;
        }

        if (empty(this.import) && empty(this.fields)) {
            return true;
        }

        try {
            /** @psalm-suppress ArgumentTypeCoercion */
            $queries = _schema.createSql($connection);
            foreach ($queries as $query) {
                $stmt = $connection.prepare($query);
                $stmt.execute();
                $stmt.closeCursor();
            }
        } catch (Exception $e) {
            $msg = sprintf(
                "Fixture creation for '%s' failed '%s'",
                this.table,
                $e.getMessage()
            );
            Log::error($msg);
            trigger_error($msg, E_USER_WARNING);

            return false;
        }

        return true;
    }


    bool drop(IConnection aConnection) {
        /** @psalm-suppress RedundantPropertyInitializationCheck */
        if (!isset(_schema)) {
            return false;
        }

        if (empty(this.import) && empty(this.fields)) {
            return this.truncate($connection);
        }

        try {
            /** @psalm-suppress ArgumentTypeCoercion */
            $sql = _schema.dropSql($connection);
            foreach ($sql as $stmt) {
                $connection.execute($stmt).closeCursor();
            }
        } catch (Exception $e) {
            return false;
        }

        return true;
    }


    function insert(IConnection aConnection) {
        if (!empty(this.records)) {
            [$fields, $values, $types] = _getRecords();
            $query = $connection.newQuery()
                .insert($fields, $types)
                .into(this.sourceName());

            foreach ($values as $row) {
                $query.values($row);
            }
            $statement = $query.execute();
            $statement.closeCursor();

            return $statement;
        }

        return true;
    }


    bool createConstraints(IConnection aConnection) {
        if (empty(_constraints)) {
            return true;
        }

        foreach (_constraints as $name: $data) {
            _schema.addConstraint($name, $data);
        }

        /** @psalm-suppress ArgumentTypeCoercion */
        $sql = _schema.addConstraintSql($connection);

        if (empty($sql)) {
            return true;
        }

        foreach ($sql as $stmt) {
            $connection.execute($stmt).closeCursor();
        }

        return true;
    }


    bool dropConstraints(IConnection aConnection) {
        if (empty(_constraints)) {
            return true;
        }

        /** @psalm-suppress ArgumentTypeCoercion */
        $sql = _schema.dropConstraintSql($connection);

        if (empty($sql)) {
            return true;
        }

        foreach ($sql as $stmt) {
            $connection.execute($stmt).closeCursor();
        }

        foreach (_constraints as $name: $data) {
            _schema.dropConstraint($name);
        }

        return true;
    }

    /**
     * Converts the internal records into data used to generate a query.
     *
     * @return array
     */
    protected array _getRecords() {
        $fields = $values = $types = null;
        $columns = _schema.columns();
        foreach (this.records as $record) {
            $fields = array_merge($fields, array_intersect(array_keys($record), $columns));
        }
        $fields = array_values(array_unique($fields));
        foreach ($fields as $field) {
            /** @var array $column */
            $column = _schema.getColumn($field);
            $types[$field] = $column["type"];
        }
        $default = array_fill_keys($fields, null);
        foreach (this.records as $record) {
            $values[] = array_merge($default, $record);
        }

        return [$fields, $values, $types];
    }


    bool truncate(IConnection aConnection) {
        /** @psalm-suppress ArgumentTypeCoercion */
        $sql = _schema.truncateSql($connection);
        foreach ($sql as $stmt) {
            $connection.execute($stmt).closeCursor();
        }

        return true;
    }


    function getTableSchema() {
        return _schema;
    }


    function setTableSchema($schema) {
        _schema = $schema;

        return this;
    }
}
