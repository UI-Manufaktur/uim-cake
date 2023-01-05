module uim.cake.databases.Schema;

import uim.cake.databases.Connection;
import uim.cake.databases.exceptions.DatabaseException;
import uim.cake.databases.TypeFactory;

/**
 * Represents a single table in a database schema.
 *
 * Can either be populated using the reflection API"s
 * or by incrementally building an instance using
 * methods.
 *
 * Once created TableSchema instances can be added to
 * Schema\Collection objects. They can also be converted into SQL using the
 * createSql(), dropSql() and truncateSql() methods.
 */
class TableSchema : TableISchema, SqlGeneratorInterface
{
    /**
     * The name of the table
     */
    protected string $_table;

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
     * @var array<string, mixed>
     */
    protected $_options = [];

    /**
     * Whether the table is temporary
     */
    protected bool $_temporary = false;

    /**
     * Column length when using a `tiny` column type
     *
     * @var int
     */
    const LENGTH_TINY = 255;

    /**
     * Column length when using a `medium` column type
     *
     * @var int
     */
    const LENGTH_MEDIUM = 16777215;

    /**
     * Column length when using a `long` column type
     *
     * @var int
     */
    const LENGTH_LONG = 4294967295;

    /**
     * Valid column length that can be used with text type columns
     *
     * @var array<string, int>
     */
    static $columnLengths = [
        "tiny": self::LENGTH_TINY,
        "medium": self::LENGTH_MEDIUM,
        "long": self::LENGTH_LONG,
    ];

    /**
     * The valid keys that can be used in a column
     * definition.
     *
     * @var array<string, mixed>
     */
    protected static $_columnKeys = [
        "type": null,
        "baseType": null,
        "length": null,
        "precision": null,
        "null": null,
        "default": null,
        "comment": null,
    ];

    /**
     * Additional type specific properties.
     *
     * @var array<string, array<string, mixed>>
     */
    protected static $_columnExtras = [
        "string": [
            "collate": null,
        ],
        "char": [
            "collate": null,
        ],
        "text": [
            "collate": null,
        ],
        "tinyinteger": [
            "unsigned": null,
        ],
        "smallinteger": [
            "unsigned": null,
        ],
        "integer": [
            "unsigned": null,
            "autoIncrement": null,
        ],
        "biginteger": [
            "unsigned": null,
            "autoIncrement": null,
        ],
        "decimal": [
            "unsigned": null,
        ],
        "float": [
            "unsigned": null,
        ],
    ];

    /**
     * The valid keys that can be used in an index
     * definition.
     *
     * @var array<string, mixed>
     */
    protected static $_indexKeys = [
        "type": null,
        "columns": [],
        "length": [],
        "references": [],
        "update": "restrict",
        "delete": "restrict",
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
     */
    const string CONSTRAINT_PRIMARY = "primary";

    /**
     * Unique constraint type
     */
    const string CONSTRAINT_UNIQUE = "unique";

    /**
     * Foreign constraint type
     */
    const string CONSTRAINT_FOREIGN = "foreign";

    /**
     * Index - index type
     */
    const string INDEX_INDEX = "index";

    /**
     * Fulltext index type
     */
    const string INDEX_FULLTEXT = "fulltext";

    /**
     * Foreign key cascade action
     */
    const string ACTION_CASCADE = "cascade";

    /**
     * Foreign key set null action
     */
    const string ACTION_SET_NULL = "setNull";

    /**
     * Foreign key no action
     */
    const string ACTION_NO_ACTION = "noAction";

    /**
     * Foreign key restrict action
     */
    const string ACTION_RESTRICT = "restrict";

    /**
     * Foreign key restrict default
     */
    const string ACTION_SET_DEFAULT = "setDefault";

    /**
     * Constructor.
     *
     * @param string $table The table name.
     * @param array<string, array|string> $columns The list of columns for the schema.
     */
    this(string $table, array $columns = []) {
        _table = $table;
        foreach ($columns as $field: $definition) {
            this.addColumn($field, $definition);
        }
    }


    string name() {
        return _table;
    }


    function addColumn(string aName, $attrs) {
        if (is_string($attrs)) {
            $attrs = ["type": $attrs];
        }
        $valid = static::$_columnKeys;
        if (isset(static::$_columnExtras[$attrs["type"]])) {
            $valid += static::$_columnExtras[$attrs["type"]];
        }
        $attrs = array_intersect_key($attrs, $valid);
        _columns[$name] = $attrs + $valid;
        _typeMap[$name] = _columns[$name]["type"];

        return this;
    }


    function removeColumn(string aName) {
        unset(_columns[$name], _typeMap[$name]);

        return this;
    }


    array columns()
    {
        return array_keys(_columns);
    }


    function getColumn(string aName): ?array
    {
        if (!isset(_columns[$name])) {
            return null;
        }
        $column = _columns[$name];
        unset($column["baseType"]);

        return $column;
    }


    function getColumnType(string aName): ?string
    {
        if (!isset(_columns[$name])) {
            return null;
        }

        return _columns[$name]["type"];
    }


    function setColumnType(string aName, string $type) {
        if (!isset(_columns[$name])) {
            return this;
        }

        _columns[$name]["type"] = $type;
        _typeMap[$name] = $type;

        return this;
    }


    bool hasColumn(string aName) {
        return isset(_columns[$name]);
    }


    function baseColumnType(string $column): ?string
    {
        if (isset(_columns[$column]["baseType"])) {
            return _columns[$column]["baseType"];
        }

        $type = this.getColumnType($column);

        if ($type == null) {
            return null;
        }

        if (TypeFactory::getMap($type)) {
            $type = TypeFactory::build($type).getBaseType();
        }

        return _columns[$column]["baseType"] = $type;
    }


    array typeMap()
    {
        return _typeMap;
    }


    bool isNullable(string aName) {
        if (!isset(_columns[$name])) {
            return true;
        }

        return _columns[$name]["null"] == true;
    }


    array defaultValues()
    {
        $defaults = [];
        foreach (_columns as $name: $data) {
            if (!array_key_exists("default", $data)) {
                continue;
            }
            if ($data["default"] == null && $data["null"] != true) {
                continue;
            }
            $defaults[$name] = $data["default"];
        }

        return $defaults;
    }


    function addIndex(string aName, $attrs) {
        if (is_string($attrs)) {
            $attrs = ["type": $attrs];
        }
        $attrs = array_intersect_key($attrs, static::$_indexKeys);
        $attrs += static::$_indexKeys;
        unset($attrs["references"], $attrs["update"], $attrs["delete"]);

        if (!in_array($attrs["type"], static::$_validIndexTypes, true)) {
            throw new DatabaseException(sprintf(
                "Invalid index type "%s" in index "%s" in table "%s".",
                $attrs["type"],
                $name,
                _table
            ));
        }
        if (empty($attrs["columns"])) {
            throw new DatabaseException(sprintf(
                "Index "%s" in table "%s" must have at least one column.",
                $name,
                _table
            ));
        }
        $attrs["columns"] = (array)$attrs["columns"];
        foreach ($attrs["columns"] as $field) {
            if (empty(_columns[$field])) {
                $msg = sprintf(
                    "Columns used in index "%s" in table "%s" must be added to the Table schema first~ " ~
                    "The column "%s" was not found.",
                    $name,
                    _table,
                    $field
                );
                throw new DatabaseException($msg);
            }
        }
        _indexes[$name] = $attrs;

        return this;
    }


    array indexes()
    {
        return array_keys(_indexes);
    }


    function getIndex(string aName): ?array
    {
        if (!isset(_indexes[$name])) {
            return null;
        }

        return _indexes[$name];
    }

    /**
     * Get the column(s) used for the primary key.
     *
     * @return array Column name(s) for the primary key. An
     *   empty list will be returned when the table has no primary key.
     * @deprecated 4.0.0 Renamed to {@link getPrimaryKey()}.
     */
    array primaryKey()
    {
        deprecationWarning("`TableSchema::primaryKey()` is deprecated. Use `TableSchema::getPrimaryKey()`.");

        return this.getPrimarykey();
    }


    array getPrimaryKey()
    {
        foreach (_constraints as $data) {
            if ($data["type"] == static::CONSTRAINT_PRIMARY) {
                return $data["columns"];
            }
        }

        return [];
    }


    function addConstraint(string aName, $attrs) {
        if (is_string($attrs)) {
            $attrs = ["type": $attrs];
        }
        $attrs = array_intersect_key($attrs, static::$_indexKeys);
        $attrs += static::$_indexKeys;
        if (!in_array($attrs["type"], static::$_validConstraintTypes, true)) {
            throw new DatabaseException(sprintf(
                "Invalid constraint type "%s" in table "%s".",
                $attrs["type"],
                _table
            ));
        }
        if (empty($attrs["columns"])) {
            throw new DatabaseException(sprintf(
                "Constraints in table "%s" must have at least one column.",
                _table
            ));
        }
        $attrs["columns"] = (array)$attrs["columns"];
        foreach ($attrs["columns"] as $field) {
            if (empty(_columns[$field])) {
                $msg = sprintf(
                    "Columns used in constraints must be added to the Table schema first~ " ~
                    "The column "%s" was not found in table "%s".",
                    $field,
                    _table
                );
                throw new DatabaseException($msg);
            }
        }

        if ($attrs["type"] == static::CONSTRAINT_FOREIGN) {
            $attrs = _checkForeignKey($attrs);

            if (isset(_constraints[$name])) {
                _constraints[$name]["columns"] = array_unique(array_merge(
                    _constraints[$name]["columns"],
                    $attrs["columns"]
                ));

                if (isset(_constraints[$name]["references"])) {
                    _constraints[$name]["references"][1] = array_unique(array_merge(
                        (array)_constraints[$name]["references"][1],
                        [$attrs["references"][1]]
                    ));
                }

                return this;
            }
        } else {
            unset($attrs["references"], $attrs["update"], $attrs["delete"]);
        }

        _constraints[$name] = $attrs;

        return this;
    }


    function dropConstraint(string aName) {
        if (isset(_constraints[$name])) {
            unset(_constraints[$name]);
        }

        return this;
    }

    /**
     * Check whether a table has an autoIncrement column defined.
     */
    bool hasAutoincrement() {
        foreach (_columns as $column) {
            if (isset($column["autoIncrement"]) && $column["autoIncrement"]) {
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
     * @throws uim.cake.databases.exceptions.DatabaseException When foreign key definition is not valid.
     */
    protected function _checkForeignKey(array $attrs): array
    {
        if (count($attrs["references"]) < 2) {
            throw new DatabaseException("References must contain a table and column.");
        }
        if (!in_array($attrs["update"], static::$_validForeignKeyActions)) {
            throw new DatabaseException(sprintf(
                "Update action is invalid. Must be one of %s",
                implode(",", static::$_validForeignKeyActions)
            ));
        }
        if (!in_array($attrs["delete"], static::$_validForeignKeyActions)) {
            throw new DatabaseException(sprintf(
                "Delete action is invalid. Must be one of %s",
                implode(",", static::$_validForeignKeyActions)
            ));
        }

        return $attrs;
    }


    function constraints(): array
    {
        return array_keys(_constraints);
    }


    function getConstraint(string aName): ?array
    {
        return _constraints[$name] ?? null;
    }


    function setOptions(array $options) {
        _options = $options + _options;

        return this;
    }


    function getOptions(): array
    {
        return _options;
    }


    function setTemporary(bool $temporary) {
        _temporary = $temporary;

        return this;
    }


    bool isTemporary() {
        return _temporary;
    }


    function createSql(Connection $connection): array
    {
        $dialect = $connection.getDriver().schemaDialect();
        $columns = $constraints = $indexes = [];
        foreach (array_keys(_columns) as $name) {
            $columns[] = $dialect.columnSql(this, $name);
        }
        foreach (array_keys(_constraints) as $name) {
            $constraints[] = $dialect.constraintSql(this, $name);
        }
        foreach (array_keys(_indexes) as $name) {
            $indexes[] = $dialect.indexSql(this, $name);
        }

        return $dialect.createTableSql(this, $columns, $constraints, $indexes);
    }


    function dropSql(Connection $connection): array
    {
        $dialect = $connection.getDriver().schemaDialect();

        return $dialect.dropTableSql(this);
    }


    function truncateSql(Connection $connection): array
    {
        $dialect = $connection.getDriver().schemaDialect();

        return $dialect.truncateTableSql(this);
    }


    function addConstraintSql(Connection $connection): array
    {
        $dialect = $connection.getDriver().schemaDialect();

        return $dialect.addConstraintSql(this);
    }


    function dropConstraintSql(Connection $connection): array
    {
        $dialect = $connection.getDriver().schemaDialect();

        return $dialect.dropConstraintSql(this);
    }

    /**
     * Returns an array of the table schema.
     *
     * @return array<string, mixed>
     */
    function __debugInfo(): array
    {
        return [
            "table": _table,
            "columns": _columns,
            "indexes": _indexes,
            "constraints": _constraints,
            "options": _options,
            "typeMap": _typeMap,
            "temporary": _temporary,
        ];
    }
}
