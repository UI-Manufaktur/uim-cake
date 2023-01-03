module uim.cake.databases.Schema;

import uim.cake.databases.exceptions.DatabaseException;

/**
 * Schema management/reflection features for Sqlite
 *
 * @internal
 */
class SqliteSchemaDialect : SchemaDialect
{
    /**
     * Array containing the foreign keys constraints names
     * Necessary for composite foreign keys to be handled
     *
     * @var array<string, mixed>
     */
    protected $_constraintsIdMap = [];

    /**
     * Whether there is any table in this connection to SQLite containing sequences.
     */
    protected bool $_hasSequences;

    /**
     * Convert a column definition to the abstract types.
     *
     * The returned type will be a type that
     * Cake\databases.TypeFactory can handle.
     *
     * @param string $column The column type + length
     * @throws uim.cake.databases.exceptions.DatabaseException when unable to parse column type
     * @return array<string, mixed> Array of column information.
     */
    protected function _convertColumn(string $column): array
    {
        if ($column == "") {
            return ["type": TableSchema::TYPE_TEXT, "length": null];
        }

        preg_match("/(unsigned)?\s*([a-z]+)(?:\(([0-9,]+)\))?/i", $column, $matches);
        if (empty($matches)) {
            throw new DatabaseException(sprintf("Unable to parse column type from "%s"", $column));
        }

        $unsigned = false;
        if (strtolower($matches[1]) == "unsigned") {
            $unsigned = true;
        }

        $col = strtolower($matches[2]);
        $length = $precision = $scale = null;
        if (isset($matches[3])) {
            $length = $matches[3];
            if (strpos($length, ",") != false) {
                [$length, $precision] = explode(",", $length);
            }
            $length = (int)$length;
            $precision = (int)$precision;
        }

        $type = _applyTypeSpecificColumnConversion(
            $col,
            compact("length", "precision", "scale")
        );
        if ($type != null) {
            return $type;
        }

        if ($col == "bigint") {
            return ["type": TableSchema::TYPE_BIGINTEGER, "length": $length, "unsigned": $unsigned];
        }
        if ($col == "smallint") {
            return ["type": TableSchema::TYPE_SMALLINTEGER, "length": $length, "unsigned": $unsigned];
        }
        if ($col == "tinyint") {
            return ["type": TableSchema::TYPE_TINYINTEGER, "length": $length, "unsigned": $unsigned];
        }
        if (strpos($col, "int") != false) {
            return ["type": TableSchema::TYPE_INTEGER, "length": $length, "unsigned": $unsigned];
        }
        if (strpos($col, "decimal") != false) {
            return [
                "type": TableSchema::TYPE_DECIMAL,
                "length": $length,
                "precision": $precision,
                "unsigned": $unsigned,
            ];
        }
        if (in_array($col, ["float", "real", "double"])) {
            return [
                "type": TableSchema::TYPE_FLOAT,
                "length": $length,
                "precision": $precision,
                "unsigned": $unsigned,
            ];
        }

        if (strpos($col, "boolean") != false) {
            return ["type": TableSchema::TYPE_BOOLEAN, "length": null];
        }

        if ($col == "char" && $length == 36) {
            return ["type": TableSchema::TYPE_UUID, "length": null];
        }
        if ($col == "char") {
            return ["type": TableSchema::TYPE_CHAR, "length": $length];
        }
        if (strpos($col, "char") != false) {
            return ["type": TableSchema::TYPE_STRING, "length": $length];
        }

        if ($col == "binary" && $length == 16) {
            return ["type": TableSchema::TYPE_BINARY_UUID, "length": null];
        }
        if (in_array($col, ["blob", "clob", "binary", "varbinary"])) {
            return ["type": TableSchema::TYPE_BINARY, "length": $length];
        }

        $datetimeTypes = [
            "date",
            "time",
            "timestamp",
            "timestampfractional",
            "timestamptimezone",
            "datetime",
            "datetimefractional",
        ];
        if (in_array($col, $datetimeTypes)) {
            return ["type": $col, "length": null];
        }

        return ["type": TableSchema::TYPE_TEXT, "length": null];
    }

    /**
     * Generate the SQL to list the tables and views.
     *
     * @param array<string, mixed> $config The connection configuration to use for
     *    getting tables from.
     * @return array An array of (sql, params) to execute.
     */
    function listTablesSql(array $config): array
    {
        return [
            "SELECT name FROM sqlite_master " ~
            "WHERE (type="table" OR type="view") " ~
            "AND name != "sqlite_sequence" ORDER BY name",
            [],
        ];
    }

    /**
     * Generate the SQL to list the tables, excluding all views.
     *
     * @param array<string, mixed> $config The connection configuration to use for
     *    getting tables from.
     * @return array<mixed> An array of (sql, params) to execute.
     */
    function listTablesWithoutViewsSql(array $config): array
    {
        return [
            "SELECT name FROM sqlite_master WHERE type="table" " ~
            "AND name != "sqlite_sequence" ORDER BY name",
            [],
        ];
    }


    function describeColumnSql(string $tableName, array $config): array
    {
        $sql = sprintf(
            "PRAGMA table_info(%s)",
            _driver.quoteIdentifier($tableName)
        );

        return [$sql, []];
    }


    void convertColumnDescription(TableSchema $schema, array $row)
    {
        $field = _convertColumn($row["type"]);
        $field += [
            "null": !$row["notnull"],
            "default": _defaultValue($row["dflt_value"]),
        ];
        $primary = $schema.getConstraint("primary");

        if ($row["pk"] && empty($primary)) {
            $field["null"] = false;
            $field["autoIncrement"] = true;
        }

        // SQLite does not support autoincrement on composite keys.
        if ($row["pk"] && !empty($primary)) {
            $existingColumn = $primary["columns"][0];
            /** @psalm-suppress PossiblyNullOperand */
            $schema.addColumn($existingColumn, ["autoIncrement": null] + $schema.getColumn($existingColumn));
        }

        $schema.addColumn($row["name"], $field);
        if ($row["pk"]) {
            $constraint = (array)$schema.getConstraint("primary") + [
                "type": TableSchema::CONSTRAINT_PRIMARY,
                "columns": [],
            ];
            $constraint["columns"] = array_merge($constraint["columns"], [$row["name"]]);
            $schema.addConstraint("primary", $constraint);
        }
    }

    /**
     * Manipulate the default value.
     *
     * Sqlite includes quotes and bared NULLs in default values.
     * We need to remove those.
     *
     * @param string|int|null $default The default value.
     * @return string|int|null
     */
    protected function _defaultValue($default) {
        if ($default == "NULL" || $default == null) {
            return null;
        }

        // Remove quotes
        if (is_string($default) && preg_match("/^"(.*)"$/", $default, $matches)) {
            return str_replace("""", """, $matches[1]);
        }

        return $default;
    }


    function describeIndexSql(string $tableName, array $config): array
    {
        $sql = sprintf(
            "PRAGMA index_list(%s)",
            _driver.quoteIdentifier($tableName)
        );

        return [$sql, []];
    }

    /**
     * {@inheritDoc}
     *
     * Since SQLite does not have a way to get metadata about all indexes at once,
     * additional queries are done here. Sqlite constraint names are not
     * stable, and the names for constraints will not match those used to create
     * the table. This is a limitation in Sqlite"s metadata features.
     *
     * @param uim.cake.databases.Schema\TableSchema $schema The table object to append
     *    an index or constraint to.
     * @param array $row The row data from `describeIndexSql`.
     */
    void convertIndexDescription(TableSchema $schema, array $row)
    {
        $sql = sprintf(
            "PRAGMA index_info(%s)",
            _driver.quoteIdentifier($row["name"])
        );
        $statement = _driver.prepare($sql);
        $statement.execute();
        $columns = [];
        /** @psalm-suppress PossiblyFalseIterator */
        foreach ($statement.fetchAll("assoc") as $column) {
            $columns[] = $column["name"];
        }
        $statement.closeCursor();
        if ($row["unique"]) {
            $schema.addConstraint($row["name"], [
                "type": TableSchema::CONSTRAINT_UNIQUE,
                "columns": $columns,
            ]);
        } else {
            $schema.addIndex($row["name"], [
                "type": TableSchema::INDEX_INDEX,
                "columns": $columns,
            ]);
        }
    }


    function describeForeignKeySql(string $tableName, array $config): array
    {
        $sql = sprintf("PRAGMA foreign_key_list(%s)", _driver.quoteIdentifier($tableName));

        return [$sql, []];
    }


    void convertForeignKeyDescription(TableSchema $schema, array $row)
    {
        $name = $row["from"] ~ "_fk";

        $update = $row["on_update"] ?? "";
        $delete = $row["on_delete"] ?? "";
        $data = [
            "type": TableSchema::CONSTRAINT_FOREIGN,
            "columns": [$row["from"]],
            "references": [$row["table"], $row["to"]],
            "update": _convertOnClause($update),
            "delete": _convertOnClause($delete),
        ];

        if (isset(_constraintsIdMap[$schema.name()][$row["id"]])) {
            $name = _constraintsIdMap[$schema.name()][$row["id"]];
        } else {
            _constraintsIdMap[$schema.name()][$row["id"]] = $name;
        }

        $schema.addConstraint($name, $data);
    }

    /**
     * {@inheritDoc}
     *
     * @param uim.cake.databases.Schema\TableSchema $schema The table instance the column is in.
     * @param string aName The name of the column.
     * @return string SQL fragment.
     * @throws uim.cake.databases.exceptions.DatabaseException when the column type is unknown
     */
    string columnSql(TableSchema $schema, string aName) {
        /** @var array $data */
        $data = $schema.getColumn($name);

        $sql = _getTypeSpecificColumnSql($data["type"], $schema, $name);
        if ($sql != null) {
            return $sql;
        }

        $typeMap = [
            TableSchema::TYPE_BINARY_UUID: " BINARY(16)",
            TableSchema::TYPE_UUID: " CHAR(36)",
            TableSchema::TYPE_CHAR: " CHAR",
            TableSchema::TYPE_TINYINTEGER: " TINYINT",
            TableSchema::TYPE_SMALLINTEGER: " SMALLINT",
            TableSchema::TYPE_INTEGER: " INTEGER",
            TableSchema::TYPE_BIGINTEGER: " BIGINT",
            TableSchema::TYPE_BOOLEAN: " BOOLEAN",
            TableSchema::TYPE_FLOAT: " FLOAT",
            TableSchema::TYPE_DECIMAL: " DECIMAL",
            TableSchema::TYPE_DATE: " DATE",
            TableSchema::TYPE_TIME: " TIME",
            TableSchema::TYPE_DATETIME: " DATETIME",
            TableSchema::TYPE_DATETIME_FRACTIONAL: " DATETIMEFRACTIONAL",
            TableSchema::TYPE_TIMESTAMP: " TIMESTAMP",
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL: " TIMESTAMPFRACTIONAL",
            TableSchema::TYPE_TIMESTAMP_TIMEZONE: " TIMESTAMPTIMEZONE",
            TableSchema::TYPE_JSON: " TEXT",
        ];

        $out = _driver.quoteIdentifier($name);
        $hasUnsigned = [
            TableSchema::TYPE_TINYINTEGER,
            TableSchema::TYPE_SMALLINTEGER,
            TableSchema::TYPE_INTEGER,
            TableSchema::TYPE_BIGINTEGER,
            TableSchema::TYPE_FLOAT,
            TableSchema::TYPE_DECIMAL,
        ];

        if (
            in_array($data["type"], $hasUnsigned, true) &&
            isset($data["unsigned"]) &&
            $data["unsigned"] == true
        ) {
            if ($data["type"] != TableSchema::TYPE_INTEGER || $schema.getPrimaryKey() != [$name]) {
                $out .= " UNSIGNED";
            }
        }

        if (isset($typeMap[$data["type"]])) {
            $out .= $typeMap[$data["type"]];
        }

        if ($data["type"] == TableSchema::TYPE_TEXT && $data["length"] != TableSchema::LENGTH_TINY) {
            $out .= " TEXT";
        }

        if ($data["type"] == TableSchema::TYPE_CHAR) {
            $out .= "(" ~ $data["length"] ~ ")";
        }

        if (
            $data["type"] == TableSchema::TYPE_STRING ||
            (
                $data["type"] == TableSchema::TYPE_TEXT &&
                $data["length"] == TableSchema::LENGTH_TINY
            )
        ) {
            $out .= " VARCHAR";

            if (isset($data["length"])) {
                $out .= "(" ~ $data["length"] ~ ")";
            }
        }

        if ($data["type"] == TableSchema::TYPE_BINARY) {
            if (isset($data["length"])) {
                $out .= " BLOB(" ~ $data["length"] ~ ")";
            } else {
                $out .= " BLOB";
            }
        }

        $integerTypes = [
            TableSchema::TYPE_TINYINTEGER,
            TableSchema::TYPE_SMALLINTEGER,
            TableSchema::TYPE_INTEGER,
        ];
        if (
            in_array($data["type"], $integerTypes, true) &&
            isset($data["length"]) &&
            $schema.getPrimaryKey() != [$name]
        ) {
            $out .= "(" ~ (int)$data["length"] ~ ")";
        }

        $hasPrecision = [TableSchema::TYPE_FLOAT, TableSchema::TYPE_DECIMAL];
        if (
            in_array($data["type"], $hasPrecision, true) &&
            (
                isset($data["length"]) ||
                isset($data["precision"])
            )
        ) {
            $out .= "(" ~ (int)$data["length"] ~ "," ~ (int)$data["precision"] ~ ")";
        }

        if (isset($data["null"]) && $data["null"] == false) {
            $out .= " NOT NULL";
        }

        if ($data["type"] == TableSchema::TYPE_INTEGER && $schema.getPrimaryKey() == [$name]) {
            $out .= " PRIMARY KEY AUTOINCREMENT";
        }

        $timestampTypes = [
            TableSchema::TYPE_DATETIME,
            TableSchema::TYPE_DATETIME_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP,
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP_TIMEZONE,
        ];
        if (isset($data["null"]) && $data["null"] == true && in_array($data["type"], $timestampTypes, true)) {
            $out .= " DEFAULT NULL";
        }
        if (isset($data["default"])) {
            $out .= " DEFAULT " ~ _driver.schemaValue($data["default"]);
        }

        return $out;
    }

    /**
     * {@inheritDoc}
     *
     * Note integer primary keys will return "". This is intentional as Sqlite requires
     * that integer primary keys be defined in the column definition.
     *
     * @param uim.cake.databases.Schema\TableSchema $schema The table instance the column is in.
     * @param string aName The name of the column.
     * @return string SQL fragment.
     */
    string constraintSql(TableSchema $schema, string aName) {
        /** @var array $data */
        $data = $schema.getConstraint($name);
        /** @psalm-suppress PossiblyNullArrayAccess */
        if (
            $data["type"] == TableSchema::CONSTRAINT_PRIMARY &&
            count($data["columns"]) == 1 &&
            $schema.getColumn($data["columns"][0])["type"] == TableSchema::TYPE_INTEGER
        ) {
            return "";
        }
        $clause = "";
        $type = "";
        if ($data["type"] == TableSchema::CONSTRAINT_PRIMARY) {
            $type = "PRIMARY KEY";
        }
        if ($data["type"] == TableSchema::CONSTRAINT_UNIQUE) {
            $type = "UNIQUE";
        }
        if ($data["type"] == TableSchema::CONSTRAINT_FOREIGN) {
            $type = "FOREIGN KEY";

            $clause = sprintf(
                " REFERENCES %s (%s) ON UPDATE %s ON DELETE %s",
                _driver.quoteIdentifier($data["references"][0]),
                _convertConstraintColumns($data["references"][1]),
                _foreignOnClause($data["update"]),
                _foreignOnClause($data["delete"])
            );
        }
        $columns = array_map(
            [_driver, "quoteIdentifier"],
            $data["columns"]
        );

        return sprintf(
            "CONSTRAINT %s %s (%s)%s",
            _driver.quoteIdentifier($name),
            $type,
            implode(", ", $columns),
            $clause
        );
    }

    /**
     * {@inheritDoc}
     *
     * SQLite can not properly handle adding a constraint to an existing table.
     * This method is no-op
     *
     * @param uim.cake.databases.Schema\TableSchema $schema The table instance the foreign key constraints are.
     * @return array SQL fragment.
     */
    function addConstraintSql(TableSchema $schema): array
    {
        return [];
    }

    /**
     * {@inheritDoc}
     *
     * SQLite can not properly handle dropping a constraint to an existing table.
     * This method is no-op
     *
     * @param uim.cake.databases.Schema\TableSchema $schema The table instance the foreign key constraints are.
     * @return array SQL fragment.
     */
    function dropConstraintSql(TableSchema $schema): array
    {
        return [];
    }


    string indexSql(TableSchema $schema, string aName) {
        /** @var array $data */
        $data = $schema.getIndex($name);
        $columns = array_map(
            [_driver, "quoteIdentifier"],
            $data["columns"]
        );

        return sprintf(
            "CREATE INDEX %s ON %s (%s)",
            _driver.quoteIdentifier($name),
            _driver.quoteIdentifier($schema.name()),
            implode(", ", $columns)
        );
    }


    function createTableSql(TableSchema $schema, array $columns, array $constraints, array $indexes): array
    {
        $lines = array_merge($columns, $constraints);
        $content = implode(",\n", array_filter($lines));
        $temporary = $schema.isTemporary() ? " TEMPORARY " : " ";
        $table = sprintf("CREATE%sTABLE \"%s\" (\n%s\n)", $temporary, $schema.name(), $content);
        $out = [$table];
        foreach ($indexes as $index) {
            $out[] = $index;
        }

        return $out;
    }


    function truncateTableSql(TableSchema $schema): array
    {
        $name = $schema.name();
        $sql = [];
        if (this.hasSequences()) {
            $sql[] = sprintf("DELETE FROM sqlite_sequence WHERE name="%s"", $name);
        }

        $sql[] = sprintf("DELETE FROM "%s"", $name);

        return $sql;
    }

    /**
     * Returns whether there is any table in this connection to SQLite containing sequences
     */
    bool hasSequences() {
        $result = _driver.prepare(
            "SELECT 1 FROM sqlite_master WHERE name = "sqlite_sequence""
        );
        $result.execute();
        _hasSequences = (bool)$result.rowCount();
        $result.closeCursor();

        return _hasSequences;
    }
}

// phpcs:disable
// Add backwards compatible alias.
class_alias("Cake\databases.Schema\SqliteSchemaDialect", "Cake\databases.Schema\SqliteSchema");
// phpcs:enable
