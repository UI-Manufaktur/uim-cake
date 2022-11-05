module uim.baklava.databases.Schema;

import uim.baklava.databases.Connection;
import uim.baklava.databases.exceptions\DatabaseException;
import uim.baklava.databases.TypeFactory;

/**
 * Represents a single table in a database schema.
 *
 * Can either be populated using the reflection API's
 * or by incrementally building an instance using
 * methods.
 *
 * Once created TableSchema instances can be added to
 * Schema\Collection objects. They can also be converted into SQL using the
 * createSql(), dropSql() and truncateSql() methods.
 */
class TableSchema : TableSchemaInterface, ISqlGenerator
{
    /**
     * The name of the table
     *
     * @var string
     */
    protected $_table;

    /**
     * Columns in the table.
     *
     * @var array<string, array>
     */
    protected $_columns = [];

    /**
     * A map with columns to types
     *
     * @var array<string, string>
     */
    protected $_typeMap = [];

    /**
     * Indexes in the table.
     *
     * @var array<string, array>
     */
    protected $_indexes = [];

    /**
     * Constraints in the table.
     *
     * @var array<string, array<string, mixed>>
     */
    protected $_constraints = [];

    /**
     * Options for the table.
     *
     * @var array
     */
    protected $_options = [];

    /**
     * Whether the table is temporary
     *
     * @var bool
     */
    protected $_temporary = false;

    /**
     * Column length when using a `tiny` column type
     *
     * @var int
     */
    public const LENGTH_TINY = 255;

    /**
     * Column length when using a `medium` column type
     *
     * @var int
     */
    public const LENGTH_MEDIUM = 16777215;

    /**
     * Column length when using a `long` column type
     *
     * @var int
     */
    public const LENGTH_LONG = 4294967295;

    /**
     * Valid column length that can be used with text type columns
     *
     * @var array<string, int>
     */
    static $columnLengths = [
        'tiny' => self::LENGTH_TINY,
        'medium' => self::LENGTH_MEDIUM,
        'long' => self::LENGTH_LONG,
    ];

    /**
     * The valid keys that can be used in a column
     * definition.
     *
     * @var array<string, mixed>
     */
    protected static $_columnKeys = [
        'type' => null,
        'baseType' => null,
        'length' => null,
        'precision' => null,
        'null' => null,
        'default' => null,
        'comment' => null,
    ];

    /**
     * Additional type specific properties.
     *
     * @var array<string, array<string, mixed>>
     */
    protected static $_columnExtras = [
        'string' => [
            'collate' => null,
        ],
        'char' => [
            'collate' => null,
        ],
        'text' => [
            'collate' => null,
        ],
        'tinyinteger' => [
            'unsigned' => null,
        ],
        'smallinteger' => [
            'unsigned' => null,
        ],
        'integer' => [
            'unsigned' => null,
            'autoIncrement' => null,
        ],
        'biginteger' => [
            'unsigned' => null,
            'autoIncrement' => null,
        ],
        'decimal' => [
            'unsigned' => null,
        ],
        'float' => [
            'unsigned' => null,
        ],
    ];

    /**
     * The valid keys that can be used in an index
     * definition.
     *
     * @var array<string, mixed>
     */
    protected static $_indexKeys = [
        'type' => null,
        'columns' => [],
        'length' => [],
        'references' => [],
        'update' => 'restrict',
        'delete' => 'restrict',
    ];

    /**
     * Names of the valid index types.
     *
     * @var array<string>
     */
    protected static $_validIndexTypes = [
        self::INDEX_INDEX,
        self::INDEX_FULLTEXT,
    ];

    /**
     * Names of the valid constraint types.
     *
     * @var array<string>
     */
    protected static $_validConstraintTypes = [
        self::CONSTRAINT_PRIMARY,
        self::CONSTRAINT_UNIQUE,
        self::CONSTRAINT_FOREIGN,
    ];

    /**
     * Names of the valid foreign key actions.
     *
     * @var array<string>
     */
    protected static $_validForeignKeyActions = [
        self::ACTION_CASCADE,
        self::ACTION_SET_NULL,
        self::ACTION_SET_DEFAULT,
        self::ACTION_NO_ACTION,
        self::ACTION_RESTRICT,
    ];

    /**
     * Primary constraint type
     *
     * @var string
     */
    public const CONSTRAINT_PRIMARY = 'primary';

    /**
     * Unique constraint type
     *
     * @var string
     */
    public const CONSTRAINT_UNIQUE = 'unique';

    /**
     * Foreign constraint type
     *
     * @var string
     */
    public const CONSTRAINT_FOREIGN = 'foreign';

    /**
     * Index - index type
     *
     * @var string
     */
    public const INDEX_INDEX = 'index';

    /**
     * Fulltext index type
     *
     * @var string
     */
    public const INDEX_FULLTEXT = 'fulltext';

    /**
     * Foreign key cascade action
     *
     * @var string
     */
    public const ACTION_CASCADE = 'cascade';

    /**
     * Foreign key set null action
     *
     * @var string
     */
    public const ACTION_SET_NULL = 'setNull';

    /**
     * Foreign key no action
     *
     * @var string
     */
    public const ACTION_NO_ACTION = 'noAction';

    /**
     * Foreign key restrict action
     *
     * @var string
     */
    public const ACTION_RESTRICT = 'restrict';

    /**
     * Foreign key restrict default
     *
     * @var string
     */
    public const ACTION_SET_DEFAULT = 'setDefault';

    /**
     * Constructor.
     *
     * @param string myTable The table name.
     * @param array<string, array|string> $columns The list of columns for the schema.
     */
    this(string myTable, array $columns = []) {
        this._table = myTable;
        foreach ($columns as myField => $definition) {
            this.addColumn(myField, $definition);
        }
    }


    function name(): string
    {
        return this._table;
    }


    function addColumn(string myName, $attrs) {
        if (is_string($attrs)) {
            $attrs = ['type' => $attrs];
        }
        $valid = static::$_columnKeys;
        if (isset(static::$_columnExtras[$attrs['type']])) {
            $valid += static::$_columnExtras[$attrs['type']];
        }
        $attrs = array_intersect_key($attrs, $valid);
        this._columns[myName] = $attrs + $valid;
        this._typeMap[myName] = this._columns[myName]['type'];

        return this;
    }


    function removeColumn(string myName) {
        unset(this._columns[myName], this._typeMap[myName]);

        return this;
    }


    function columns(): array
    {
        return array_keys(this._columns);
    }


    auto getColumn(string myName): ?array
    {
        if (!isset(this._columns[myName])) {
            return null;
        }
        $column = this._columns[myName];
        unset($column['baseType']);

        return $column;
    }


    string getColumnType(string myName) {
        if (!isset(this._columns[myName])) {
            return null;
        }

        return this._columns[myName]['type'];
    }


    auto setColumnType(string myName, string myType) {
        if (!isset(this._columns[myName])) {
            return this;
        }

        this._columns[myName]['type'] = myType;
        this._typeMap[myName] = myType;

        return this;
    }


    bool hasColumn(string myName) {
        return isset(this._columns[myName]);
    }


    string baseColumnType(string $column) {
        if (isset(this._columns[$column]['baseType'])) {
            return this._columns[$column]['baseType'];
        }

        myType = this.getColumnType($column);

        if (myType === null) {
            return null;
        }

        if (TypeFactory::getMap(myType)) {
            myType = TypeFactory::build(myType).getBaseType();
        }

        return this._columns[$column]['baseType'] = myType;
    }


    function typeMap(): array
    {
        return this._typeMap;
    }


    bool isNullable(string myName) {
        if (!isset(this._columns[myName])) {
            return true;
        }

        return this._columns[myName]['null'] === true;
    }


    function defaultValues(): array
    {
        $defaults = [];
        foreach (this._columns as myName => myData) {
            if (!array_key_exists('default', myData)) {
                continue;
            }
            if (myData['default'] === null && myData['null'] !== true) {
                continue;
            }
            $defaults[myName] = myData['default'];
        }

        return $defaults;
    }


    function addIndex(string myName, $attrs) {
        if (is_string($attrs)) {
            $attrs = ['type' => $attrs];
        }
        $attrs = array_intersect_key($attrs, static::$_indexKeys);
        $attrs += static::$_indexKeys;
        unset($attrs['references'], $attrs['update'], $attrs['delete']);

        if (!in_array($attrs['type'], static::$_validIndexTypes, true)) {
            throw new DatabaseException(sprintf(
                'Invalid index type "%s" in index "%s" in table "%s".',
                $attrs['type'],
                myName,
                this._table
            ));
        }
        if (empty($attrs['columns'])) {
            throw new DatabaseException(sprintf(
                'Index "%s" in table "%s" must have at least one column.',
                myName,
                this._table
            ));
        }
        $attrs['columns'] = (array)$attrs['columns'];
        foreach ($attrs['columns'] as myField) {
            if (empty(this._columns[myField])) {
                $msg = sprintf(
                    'Columns used in index "%s" in table "%s" must be added to the Table schema first. ' .
                    'The column "%s" was not found.',
                    myName,
                    this._table,
                    myField
                );
                throw new DatabaseException($msg);
            }
        }
        this._indexes[myName] = $attrs;

        return this;
    }


    function indexes(): array
    {
        return array_keys(this._indexes);
    }


    auto getIndex(string myName): ?array
    {
        if (!isset(this._indexes[myName])) {
            return null;
        }

        return this._indexes[myName];
    }

    /**
     * Get the column(s) used for the primary key.
     *
     * @return array Column name(s) for the primary key. An
     *   empty list will be returned when the table has no primary key.
     * @deprecated 4.0.0 Renamed to {@link getPrimaryKey()}.
     */
    function primaryKey(): array
    {
        deprecationWarning('`TableSchema::primaryKey()` is deprecated. Use `TableSchema::getPrimaryKey()`.');

        return this.getPrimarykey();
    }


    auto getPrimaryKey(): array
    {
        foreach (this._constraints as myData) {
            if (myData['type'] === static::CONSTRAINT_PRIMARY) {
                return myData['columns'];
            }
        }

        return [];
    }


    function addConstraint(string myName, $attrs) {
        if (is_string($attrs)) {
            $attrs = ['type' => $attrs];
        }
        $attrs = array_intersect_key($attrs, static::$_indexKeys);
        $attrs += static::$_indexKeys;
        if (!in_array($attrs['type'], static::$_validConstraintTypes, true)) {
            throw new DatabaseException(sprintf(
                'Invalid constraint type "%s" in table "%s".',
                $attrs['type'],
                this._table
            ));
        }
        if (empty($attrs['columns'])) {
            throw new DatabaseException(sprintf(
                'Constraints in table "%s" must have at least one column.',
                this._table
            ));
        }
        $attrs['columns'] = (array)$attrs['columns'];
        foreach ($attrs['columns'] as myField) {
            if (empty(this._columns[myField])) {
                $msg = sprintf(
                    'Columns used in constraints must be added to the Table schema first. ' .
                    'The column "%s" was not found in table "%s".',
                    myField,
                    this._table
                );
                throw new DatabaseException($msg);
            }
        }

        if ($attrs['type'] === static::CONSTRAINT_FOREIGN) {
            $attrs = this._checkForeignKey($attrs);

            if (isset(this._constraints[myName])) {
                this._constraints[myName]['columns'] = array_unique(array_merge(
                    this._constraints[myName]['columns'],
                    $attrs['columns']
                ));

                if (isset(this._constraints[myName]['references'])) {
                    this._constraints[myName]['references'][1] = array_unique(array_merge(
                        (array)this._constraints[myName]['references'][1],
                        [$attrs['references'][1]]
                    ));
                }

                return this;
            }
        } else {
            unset($attrs['references'], $attrs['update'], $attrs['delete']);
        }

        this._constraints[myName] = $attrs;

        return this;
    }


    function dropConstraint(string myName) {
        if (isset(this._constraints[myName])) {
            unset(this._constraints[myName]);
        }

        return this;
    }

    /**
     * Check whether a table has an autoIncrement column defined.
     */
    bool hasAutoincrement() {
        foreach (this._columns as $column) {
            if (isset($column['autoIncrement']) && $column['autoIncrement']) {
                return true;
            }
        }

        return false;
    }

    /**
     * Helper method to check/validate foreign keys.
     *
     * @param array<string, mixed> $attrs Attributes to set.
     * @return array<string, mixed>
     * @throws \Cake\Database\Exception\DatabaseException When foreign key definition is not valid.
     */
    protected auto _checkForeignKey(array $attrs): array
    {
        if (count($attrs['references']) < 2) {
            throw new DatabaseException('References must contain a table and column.');
        }
        if (!in_array($attrs['update'], static::$_validForeignKeyActions)) {
            throw new DatabaseException(sprintf(
                'Update action is invalid. Must be one of %s',
                implode(',', static::$_validForeignKeyActions)
            ));
        }
        if (!in_array($attrs['delete'], static::$_validForeignKeyActions)) {
            throw new DatabaseException(sprintf(
                'Delete action is invalid. Must be one of %s',
                implode(',', static::$_validForeignKeyActions)
            ));
        }

        return $attrs;
    }


    function constraints(): array
    {
        return array_keys(this._constraints);
    }


    auto getConstraint(string myName): ?array
    {
        return this._constraints[myName] ?? null;
    }


    auto setOptions(array myOptions) {
        this._options = myOptions + this._options;

        return this;
    }


    auto getOptions(): array
    {
        return this._options;
    }


    auto setTemporary(bool $temporary) {
        this._temporary = $temporary;

        return this;
    }


    bool isTemporary() {
        return this._temporary;
    }


    function createSql(Connection myConnection): array
    {
        $dialect = myConnection.getDriver().schemaDialect();
        $columns = $constraints = $indexes = [];
        foreach (array_keys(this._columns) as myName) {
            $columns[] = $dialect.columnSql(this, myName);
        }
        foreach (array_keys(this._constraints) as myName) {
            $constraints[] = $dialect.constraintSql(this, myName);
        }
        foreach (array_keys(this._indexes) as myName) {
            $indexes[] = $dialect.indexSql(this, myName);
        }

        return $dialect.createTableSql(this, $columns, $constraints, $indexes);
    }


    function dropSql(Connection myConnection): array
    {
        $dialect = myConnection.getDriver().schemaDialect();

        return $dialect.dropTableSql(this);
    }


    function truncateSql(Connection myConnection): array
    {
        $dialect = myConnection.getDriver().schemaDialect();

        return $dialect.truncateTableSql(this);
    }


    function addConstraintSql(Connection myConnection): array
    {
        $dialect = myConnection.getDriver().schemaDialect();

        return $dialect.addConstraintSql(this);
    }


    function dropConstraintSql(Connection myConnection): array
    {
        $dialect = myConnection.getDriver().schemaDialect();

        return $dialect.dropConstraintSql(this);
    }

    /**
     * Returns an array of the table schema.
     *
     * @return array<string, mixed>
     */
    auto __debugInfo(): array
    {
        return [
            'table' => this._table,
            'columns' => this._columns,
            'indexes' => this._indexes,
            'constraints' => this._constraints,
            'options' => this._options,
            'typeMap' => this._typeMap,
            'temporary' => this._temporary,
        ];
    }
}
