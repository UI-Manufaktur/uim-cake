

/**

 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         1.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite\Fixture;

import uim.cake.core.Exception\CakeException;
import uim.cake.database.ConstraintsInterface;
import uim.cake.database.Schema\TableSchema;
import uim.cake.database.Schema\TableSchemaAwareInterface;
import uim.cake.Datasource\ConnectionInterface;
import uim.cake.Datasource\ConnectionManager;
import uim.cake.Datasource\FixtureInterface;
import uim.cake.Log\Log;
import uim.cake.ORM\Locator\LocatorAwareTrait;
import uim.cake.Utility\Inflector;
use Exception;

/**
 * Cake TestFixture is responsible for building and destroying tables to be used
 * during testing.
 */
class TestFixture : ConstraintsInterface, FixtureInterface, TableSchemaAwareInterface
{
    use LocatorAwareTrait;

    /**
     * Fixture Datasource
     *
     * @var string
     */
    public myConnection = 'test';

    /**
     * Full Table Name
     *
     * @var string
     * @psalm-suppress PropertyNotSetInConstructor
     */
    public myTable;

    /**
     * Fields / Schema for the fixture.
     *
     * This array should be compatible with {@link \Cake\Database\Schema\Schema}.
     * The `_constraints`, `_options` and `_indexes` keys are reserved for defining
     * constraints, options and indexes respectively.
     *
     * @var array
     */
    public myFields = [];

    /**
     * Configuration for importing fixture schema
     *
     * Accepts a `connection` and `model` or `table` key, to define
     * which table and which connection contain the schema to be
     * imported.
     *
     * @var array|null
     */
    public $import;

    /**
     * Fixture records to be inserted.
     *
     * @var array
     */
    public $records = [];

    /**
     * The schema for this fixture.
     *
     * @var \Cake\Database\Schema\TableSchemaInterface&\Cake\Database\Schema\ISqlGenerator
     * @psalm-suppress PropertyNotSetInConstructor
     */
    protected $_schema;

    /**
     * Fixture constraints to be created.
     *
     * @var array<string, mixed>
     */
    protected $_constraints = [];

    /**
     * Instantiate the fixture.
     *
     * @throws \Cake\Core\Exception\CakeException on invalid datasource usage.
     */
    this() {
        if (!empty(this.connection)) {
            myConnection = this.connection;
            if (strpos(myConnection, 'test') !== 0) {
                myMessage = sprintf(
                    'Invalid datasource name "%s" for "%s" fixture. Fixture datasource names must begin with "test".',
                    myConnection,
                    static::class
                );
                throw new CakeException(myMessage);
            }
        }
        this.init();
    }


    function connection(): string
    {
        return this.connection;
    }


    function sourceName(): string
    {
        return this.table;
    }

    /**
     * Initialize the fixture.
     *
     * @return void
     * @throws \Cake\ORM\Exception\MissingTableClassException When importing from a table that does not exist.
     */
    function init(): void
    {
        if (this.table === null) {
            this.table = this._tableFromClass();
        }

        if (empty(this.import) && !empty(this.fields)) {
            this._schemaFromFields();
        }

        if (!empty(this.import)) {
            this._schemaFromImport();
        }

        if (empty(this.import) && empty(this.fields)) {
            this._schemaFromReflection();
        }
    }

    /**
     * Returns the table name using the fixture class
     *
     * @return string
     */
    protected auto _tableFromClass(): string
    {
        [, myClass] = moduleSplit(static::class);
        preg_match('/^(.*)Fixture$/', myClass, $matches);
        myTable = $matches[1] ?? myClass;

        return Inflector::tableize(myTable);
    }

    /**
     * Build the fixtures table schema from the fields property.
     *
     * @return void
     */
    protected auto _schemaFromFields(): void
    {
        myConnection = ConnectionManager::get(this.connection());
        this._schema = myConnection.getDriver().newTableSchema(this.table);
        foreach (this.fields as myField => myData) {
            if (myField === '_constraints' || myField === '_indexes' || myField === '_options') {
                continue;
            }
            this._schema.addColumn(myField, myData);
        }
        if (!empty(this.fields['_constraints'])) {
            foreach (this.fields['_constraints'] as myName => myData) {
                if (!myConnection.supportsDynamicConstraints() || myData['type'] !== TableSchema::CONSTRAINT_FOREIGN) {
                    this._schema.addConstraint(myName, myData);
                } else {
                    this._constraints[myName] = myData;
                }
            }
        }
        if (!empty(this.fields['_indexes'])) {
            foreach (this.fields['_indexes'] as myName => myData) {
                this._schema.addIndex(myName, myData);
            }
        }
        if (!empty(this.fields['_options'])) {
            this._schema.setOptions(this.fields['_options']);
        }
    }

    /**
     * Build fixture schema from a table in another datasource.
     *
     * @return void
     * @throws \Cake\Core\Exception\CakeException when trying to import from an empty table.
     */
    protected auto _schemaFromImport(): void
    {
        if (!is_array(this.import)) {
            return;
        }
        $import = this.import + ['connection' => 'default', 'table' => null, 'model' => null];

        if (!empty($import['model'])) {
            if (!empty($import['table'])) {
                throw new CakeException('You cannot define both table and model.');
            }
            $import['table'] = this.getTableLocator().get($import['model']).getTable();
        }

        if (empty($import['table'])) {
            throw new CakeException('Cannot import from undefined table.');
        }

        this.table = $import['table'];

        $db = ConnectionManager::get($import['connection'], false);
        $schemaCollection = $db.getSchemaCollection();
        myTable = $schemaCollection.describe($import['table']);
        this._schema = myTable;
    }

    /**
     * Build fixture schema directly from the datasource
     *
     * @return void
     * @throws \Cake\Core\Exception\CakeException when trying to reflect a table that does not exist
     */
    protected auto _schemaFromReflection(): void
    {
        $db = ConnectionManager::get(this.connection());
        try {
            myName = Inflector::camelize(this.table);
            $ormTable = this.fetchTable(myName, ['connection' => $db]);

            /** @var \Cake\Database\Schema\TableSchema $schema */
            $schema = $ormTable.getSchema();
            this._schema = $schema;
        } catch (CakeException $e) {
            myMessage = sprintf(
                'Cannot describe schema for table `%s` for fixture `%s`. The table does not exist.',
                this.table,
                static::class
            );
            throw new CakeException(myMessage, null, $e);
        }
    }


    function create(ConnectionInterface myConnection): bool
    {
        /** @psalm-suppress RedundantPropertyInitializationCheck */
        if (!isset(this._schema)) {
            return false;
        }

        if (empty(this.import) && empty(this.fields)) {
            return true;
        }

        try {
            /** @psalm-suppress ArgumentTypeCoercion */
            $queries = this._schema.createSql(myConnection);
            foreach ($queries as myQuery) {
                $stmt = myConnection.prepare(myQuery);
                $stmt.execute();
                $stmt.closeCursor();
            }
        } catch (Exception $e) {
            $msg = sprintf(
                'Fixture creation for "%s" failed "%s"',
                this.table,
                $e.getMessage()
            );
            Log::error($msg);
            trigger_error($msg, E_USER_WARNING);

            return false;
        }

        return true;
    }


    function drop(ConnectionInterface myConnection): bool
    {
        /** @psalm-suppress RedundantPropertyInitializationCheck */
        if (!isset(this._schema)) {
            return false;
        }

        if (empty(this.import) && empty(this.fields)) {
            return this.truncate(myConnection);
        }

        try {
            /** @psalm-suppress ArgumentTypeCoercion */
            mySql = this._schema.dropSql(myConnection);
            foreach (mySql as $stmt) {
                myConnection.execute($stmt).closeCursor();
            }
        } catch (Exception $e) {
            return false;
        }

        return true;
    }


    function insert(ConnectionInterface myConnection) {
        if (!empty(this.records)) {
            [myFields, myValues, myTypes] = this._getRecords();
            myQuery = myConnection.newQuery()
                .insert(myFields, myTypes)
                .into(this.sourceName());

            foreach (myValues as $row) {
                myQuery.values($row);
            }
            $statement = myQuery.execute();
            $statement.closeCursor();

            return $statement;
        }

        return true;
    }


    function createConstraints(ConnectionInterface myConnection): bool
    {
        if (empty(this._constraints)) {
            return true;
        }

        foreach (this._constraints as myName => myData) {
            this._schema.addConstraint(myName, myData);
        }

        /** @psalm-suppress ArgumentTypeCoercion */
        mySql = this._schema.addConstraintSql(myConnection);

        if (empty(mySql)) {
            return true;
        }

        foreach (mySql as $stmt) {
            myConnection.execute($stmt).closeCursor();
        }

        return true;
    }


    function dropConstraints(ConnectionInterface myConnection): bool
    {
        if (empty(this._constraints)) {
            return true;
        }

        /** @psalm-suppress ArgumentTypeCoercion */
        mySql = this._schema.dropConstraintSql(myConnection);

        if (empty(mySql)) {
            return true;
        }

        foreach (mySql as $stmt) {
            myConnection.execute($stmt).closeCursor();
        }

        foreach (this._constraints as myName => myData) {
            this._schema.dropConstraint(myName);
        }

        return true;
    }

    /**
     * Converts the internal records into data used to generate a query.
     *
     * @return array
     */
    protected auto _getRecords(): array
    {
        myFields = myValues = myTypes = [];
        $columns = this._schema.columns();
        foreach (this.records as $record) {
            myFields = array_merge(myFields, array_intersect(array_keys($record), $columns));
        }
        myFields = array_values(array_unique(myFields));
        foreach (myFields as myField) {
            /** @var array $column */
            $column = this._schema.getColumn(myField);
            myTypes[myField] = $column['type'];
        }
        $default = array_fill_keys(myFields, null);
        foreach (this.records as $record) {
            myValues[] = array_merge($default, $record);
        }

        return [myFields, myValues, myTypes];
    }


    function truncate(ConnectionInterface myConnection): bool
    {
        /** @psalm-suppress ArgumentTypeCoercion */
        mySql = this._schema.truncateSql(myConnection);
        foreach (mySql as $stmt) {
            myConnection.execute($stmt).closeCursor();
        }

        return true;
    }


    auto getTableSchema() {
        return this._schema;
    }


    auto setTableSchema($schema) {
        this._schema = $schema;

        return this;
    }
}
