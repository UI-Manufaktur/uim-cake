module uim.cake.databases.Schema;

/**
 * Schema management/reflection features for SQLServer.
 *
 * @internal
 */
class SqlserverSchemaDialect : SchemaDialect
{
    /**
     */
    const string DEFAULT_SCHEMA_NAME = "dbo";

    /**
     * Generate the SQL to list the tables and views.
     *
     * @param array<string, mixed> aConfig The connection configuration to use for
     *    getting tables from.
     * @return array An array of (sql, params) to execute.
     */
    array listTablesSql(Json aConfig) {
        $sql = "SELECT TABLE_NAME
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = ?
            AND (TABLE_TYPE = "BASE TABLE" OR TABLE_TYPE = "VIEW")
            ORDER BY TABLE_NAME";
        $schema = empty(aConfig["schema"]) ? static::DEFAULT_SCHEMA_NAME : aConfig["schema"];

        return [$sql, [$schema]];
    }

    /**
     * Generate the SQL to list the tables, excluding all views.
     *
     * @param array<string, mixed> aConfig The connection configuration to use for
     *    getting tables from.
     * @return array<mixed> An array of (sql, params) to execute.
     */
    array listTablesWithoutViewsSql(Json aConfig) {
        $sql = "SELECT TABLE_NAME
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = ?
            AND (TABLE_TYPE = "BASE TABLE")
            ORDER BY TABLE_NAME";
        $schema = empty(aConfig["schema"]) ? static::DEFAULT_SCHEMA_NAME : aConfig["schema"];

        return [$sql, [$schema]];
    }


    array describeColumnSql(string $tableName, Json aConfig) {
        $sql = "SELECT DISTINCT
            AC.column_id AS [column_id],
            AC.name AS [name],
            TY.name AS [type],
            AC.max_length AS [char_length],
            AC.precision AS [precision],
            AC.scale AS [scale],
            AC.is_identity AS [autoincrement],
            AC.is_nullable AS [null],
            OBJECT_DEFINITION(AC.default_object_id) AS [default],
            AC.collation_name AS [collation_name]
            FROM sys.[objects] T
            INNER JOIN sys.[schemas] S ON S.[schema_id] = T.[schema_id]
            INNER JOIN sys.[all_columns] AC ON T.[object_id] = AC.[object_id]
            INNER JOIN sys.[types] TY ON TY.[user_type_id] = AC.[user_type_id]
            WHERE T.[name] = ? AND S.[name] = ?
            ORDER BY column_id";

        $schema = empty(aConfig["schema"]) ? static::DEFAULT_SCHEMA_NAME : aConfig["schema"];

        return [$sql, [$tableName, $schema]];
    }

    /**
     * Convert a column definition to the abstract types.
     *
     * The returned type will be a type that
     * Cake\databases.TypeFactory  can handle.
     *
     * @param string $col The column type
     * @param int|null $length the column length
     * @param int|null $precision The column precision
     * @param int|null $scale The column scale
     * @return array<string, mixed> Array of column information.
     * @link https://technet.microsoft.com/en-us/library/ms187752.aspx
     */
    protected array _convertColumn(
        string $col,
        Nullable!int $length = null,
        Nullable!int $precision = null,
        Nullable!int $scale = null
    ) {
        $col = strtolower($col);

        $type = _applyTypeSpecificColumnConversion(
            $col,
            compact("length", "precision", "scale")
        );
        if ($type != null) {
            return $type;
        }

        if (in_array($col, ["date", "time"])) {
            return ["type": $col, "length": null];
        }

        if ($col == "datetime") {
            // datetime cannot parse more than 3 digits of precision and isn"t accurate
            return ["type": TableSchema::TYPE_DATETIME, "length": null];
        }
        if (strpos($col, "datetime") != false) {
            $typeName = TableSchema::TYPE_DATETIME;
            if ($scale > 0) {
                $typeName = TableSchema::TYPE_DATETIME_FRACTIONAL;
            }

            return ["type": $typeName, "length": null, "precision": $scale];
        }

        if ($col == "char") {
            return ["type": TableSchema::TYPE_CHAR, "length": $length];
        }

        if ($col == "tinyint") {
            return ["type": TableSchema::TYPE_TINYINTEGER, "length": $precision ?: 3];
        }
        if ($col == "smallint") {
            return ["type": TableSchema::TYPE_SMALLINTEGER, "length": $precision ?: 5];
        }
        if ($col == "int" || $col == "integer") {
            return ["type": TableSchema::TYPE_INTEGER, "length": $precision ?: 10];
        }
        if ($col == "bigint") {
            return ["type": TableSchema::TYPE_BIGINTEGER, "length": $precision ?: 20];
        }
        if ($col == "bit") {
            return ["type": TableSchema::TYPE_BOOLEAN, "length": null];
        }
        if (
            strpos($col, "numeric") != false ||
            strpos($col, "money") != false ||
            strpos($col, "decimal") != false
        ) {
            return ["type": TableSchema::TYPE_DECIMAL, "length": $precision, "precision": $scale];
        }

        if ($col == "real" || $col == "float") {
            return ["type": TableSchema::TYPE_FLOAT, "length": null];
        }
        // SqlServer schema reflection returns double length for unicode
        // columns because internally it uses UTF16/UCS2
        if ($col == "nvarchar" || $col == "nchar" || $col == "ntext") {
            $length /= 2;
        }
        if (strpos($col, "varchar") != false && $length < 0) {
            return ["type": TableSchema::TYPE_TEXT, "length": null];
        }

        if (strpos($col, "varchar") != false) {
            return ["type": TableSchema::TYPE_STRING, "length": $length ?: 255];
        }

        if (strpos($col, "char") != false) {
            return ["type": TableSchema::TYPE_CHAR, "length": $length];
        }

        if (strpos($col, "text") != false) {
            return ["type": TableSchema::TYPE_TEXT, "length": null];
        }

        if ($col == "image" || strpos($col, "binary") != false) {
            // -1 is the value for MAX which we treat as a "long" binary
            if ($length == -1) {
                $length = TableSchema::LENGTH_LONG;
            }

            return ["type": TableSchema::TYPE_BINARY, "length": $length];
        }

        if ($col == "uniqueidentifier") {
            return ["type": TableSchema::TYPE_UUID];
        }

        return ["type": TableSchema::TYPE_STRING, "length": null];
    }


    void convertColumnDescription(TableSchema $schema, array $row) {
        $field = _convertColumn(
            $row["type"],
            $row["char_length"] != null ? (int)$row["char_length"] : null,
            $row["precision"] != null ? (int)$row["precision"] : null,
            $row["scale"] != null ? (int)$row["scale"] : null
        );

        if (!empty($row["autoincrement"])) {
            $field["autoIncrement"] = true;
        }

        $field += [
            "null": $row["null"] == "1",
            "default": _defaultValue($field["type"], $row["default"]),
            "collate": $row["collation_name"],
        ];
        $schema.addColumn($row["name"], $field);
    }

    /**
     * Manipulate the default value.
     *
     * Removes () wrapping default values, extracts strings from
     * N"" wrappers and collation text and converts NULL strings.
     *
     * @param string $type The schema type
     * @param string|null $default The default value.
     * @return string|int|null
     */
    protected function _defaultValue($type, $default) {
        if ($default == null) {
            return null;
        }

        // remove () surrounding value (NULL) but leave () at the end of functions
        // integers might have two ((0)) wrapping value
        if (preg_match("/^\(+(.*?(\(\))?)\)+$/", $default, $matches)) {
            $default = $matches[1];
        }

        if ($default == "NULL") {
            return null;
        }

        if ($type == TableSchema::TYPE_BOOLEAN) {
            return (int)$default;
        }

        // Remove quotes
        if (preg_match("/^\(?N?"(.*)"\)?/", $default, $matches)) {
            return str_replace("""", """, $matches[1]);
        }

        return $default;
    }


    array describeIndexSql(string $tableName, Json aConfig) {
        $sql = "SELECT
                I.[name] AS [index_name],
                IC.[index_column_id] AS [index_order],
                AC.[name] AS [column_name],
                I.[is_unique], I.[is_primary_key],
                I.[is_unique_constraint]
            FROM sys.[tables] AS T
            INNER JOIN sys.[schemas] S ON S.[schema_id] = T.[schema_id]
            INNER JOIN sys.[indexes] I ON T.[object_id] = I.[object_id]
            INNER JOIN sys.[index_columns] IC ON I.[object_id] = IC.[object_id] AND I.[index_id] = IC.[index_id]
            INNER JOIN sys.[all_columns] AC ON T.[object_id] = AC.[object_id] AND IC.[column_id] = AC.[column_id]
            WHERE T.[is_ms_shipped] = 0 AND I.[type_desc] <> "HEAP" AND T.[name] = ? AND S.[name] = ?
            ORDER BY I.[index_id], IC.[index_column_id]";

        $schema = empty(aConfig["schema"]) ? static::DEFAULT_SCHEMA_NAME : aConfig["schema"];

        return [$sql, [$tableName, $schema]];
    }


    void convertIndexDescription(TableSchema $schema, array $row) {
        $type = TableSchema::INDEX_INDEX;
        $name = $row["index_name"];
        if ($row["is_primary_key"]) {
            $name = $type = TableSchema::CONSTRAINT_PRIMARY;
        }
        if ($row["is_unique_constraint"] && $type == TableSchema::INDEX_INDEX) {
            $type = TableSchema::CONSTRAINT_UNIQUE;
        }

        if ($type == TableSchema::INDEX_INDEX) {
            $existing = $schema.getIndex($name);
        } else {
            $existing = $schema.getConstraint($name);
        }

        $columns = [$row["column_name"]];
        if (!empty($existing)) {
            $columns = array_merge($existing["columns"], $columns);
        }

        if ($type == TableSchema::CONSTRAINT_PRIMARY || $type == TableSchema::CONSTRAINT_UNIQUE) {
            $schema.addConstraint($name, [
                "type": $type,
                "columns": $columns,
            ]);

            return;
        }
        $schema.addIndex($name, [
            "type": $type,
            "columns": $columns,
        ]);
    }


    array describeForeignKeySql(string $tableName, Json aConfig) {
        // phpcs:disable Generic.Files.LineLength
        $sql = "SELECT FK.[name] AS [foreign_key_name], FK.[delete_referential_action_desc] AS [delete_type],
                FK.[update_referential_action_desc] AS [update_type], C.name AS [column], RT.name AS [reference_table],
                RC.name AS [reference_column]
            FROM sys.foreign_keys FK
            INNER JOIN sys.foreign_key_columns FKC ON FKC.constraint_object_id = FK.object_id
            INNER JOIN sys.tables T ON T.object_id = FKC.parent_object_id
            INNER JOIN sys.tables RT ON RT.object_id = FKC.referenced_object_id
            INNER JOIN sys.schemas S ON S.schema_id = T.schema_id AND S.schema_id = RT.schema_id
            INNER JOIN sys.columns C ON C.column_id = FKC.parent_column_id AND C.object_id = FKC.parent_object_id
            INNER JOIN sys.columns RC ON RC.column_id = FKC.referenced_column_id AND RC.object_id = FKC.referenced_object_id
            WHERE FK.is_ms_shipped = 0 AND T.name = ? AND S.name = ?
            ORDER BY FKC.constraint_column_id";
        // phpcs:enable Generic.Files.LineLength

        $schema = empty(aConfig["schema"]) ? static::DEFAULT_SCHEMA_NAME : aConfig["schema"];

        return [$sql, [$tableName, $schema]];
    }


    void convertForeignKeyDescription(TableSchema $schema, array $row) {
        $data = [
            "type": TableSchema::CONSTRAINT_FOREIGN,
            "columns": [$row["column"]],
            "references": [$row["reference_table"], $row["reference_column"]],
            "update": _convertOnClause($row["update_type"]),
            "delete": _convertOnClause($row["delete_type"]),
        ];
        $name = $row["foreign_key_name"];
        $schema.addConstraint($name, $data);
    }


    protected string _foreignOnClause(string $on) {
        $parent = super._foreignOnClause($on);

        return $parent == "RESTRICT" ? super._foreignOnClause(TableSchema::ACTION_NO_ACTION) : $parent;
    }


    protected string _convertOnClause(string $clause) {
        switch ($clause) {
            case "NO_ACTION":
                return TableSchema::ACTION_NO_ACTION;
            case "CASCADE":
                return TableSchema::ACTION_CASCADE;
            case "SET_NULL":
                return TableSchema::ACTION_SET_NULL;
            case "SET_DEFAULT":
                return TableSchema::ACTION_SET_DEFAULT;
        }

        return TableSchema::ACTION_SET_NULL;
    }


    string columnSql(TableSchema $schema, string aName) {
        /** @var array $data */
        $data = $schema.getColumn($name);

        $sql = _getTypeSpecificColumnSql($data["type"], $schema, $name);
        if ($sql != null) {
            return $sql;
        }

        $out = _driver.quoteIdentifier($name);
        $typeMap = [
            TableSchema::TYPE_TINYINTEGER: " TINYINT",
            TableSchema::TYPE_SMALLINTEGER: " SMALLINT",
            TableSchema::TYPE_INTEGER: " INTEGER",
            TableSchema::TYPE_BIGINTEGER: " BIGINT",
            TableSchema::TYPE_BINARY_UUID: " UNIQUEIDENTIFIER",
            TableSchema::TYPE_BOOLEAN: " BIT",
            TableSchema::TYPE_CHAR: " NCHAR",
            TableSchema::TYPE_FLOAT: " FLOAT",
            TableSchema::TYPE_DECIMAL: " DECIMAL",
            TableSchema::TYPE_DATE: " DATE",
            TableSchema::TYPE_TIME: " TIME",
            TableSchema::TYPE_DATETIME: " DATETIME2",
            TableSchema::TYPE_DATETIME_FRACTIONAL: " DATETIME2",
            TableSchema::TYPE_TIMESTAMP: " DATETIME2",
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL: " DATETIME2",
            TableSchema::TYPE_TIMESTAMP_TIMEZONE: " DATETIME2",
            TableSchema::TYPE_UUID: " UNIQUEIDENTIFIER",
            TableSchema::TYPE_JSON: " NVARCHAR(MAX)",
        ];

        if (isset($typeMap[$data["type"]])) {
            $out .= $typeMap[$data["type"]];
        }

        if ($data["type"] == TableSchema::TYPE_INTEGER || $data["type"] == TableSchema::TYPE_BIGINTEGER) {
            if ($schema.getPrimaryKey() == [$name] || $data["autoIncrement"] == true) {
                unset($data["null"], $data["default"]);
                $out .= " IDENTITY(1, 1)";
            }
        }

        if ($data["type"] == TableSchema::TYPE_TEXT && $data["length"] != TableSchema::LENGTH_TINY) {
            $out .= " NVARCHAR(MAX)";
        }

        if ($data["type"] == TableSchema::TYPE_CHAR) {
            $out .= "(" ~ $data["length"] ~ ")";
        }

        if ($data["type"] == TableSchema::TYPE_BINARY) {
            if (
                !isset($data["length"])
                || in_array($data["length"], [TableSchema::LENGTH_MEDIUM, TableSchema::LENGTH_LONG], true)
            ) {
                $data["length"] = "MAX";
            }

            if ($data["length"] == 1) {
                $out .= " BINARY(1)";
            } else {
                $out .= " VARBINARY";

                $out .= sprintf("(%s)", $data["length"]);
            }
        }

        if (
            $data["type"] == TableSchema::TYPE_STRING ||
            (
                $data["type"] == TableSchema::TYPE_TEXT &&
                $data["length"] == TableSchema::LENGTH_TINY
            )
        ) {
            $type = " NVARCHAR";
            $length = $data["length"] ?? TableSchema::LENGTH_TINY;
            $out .= sprintf("%s(%d)", $type, $length);
        }

        $hasCollate = [TableSchema::TYPE_TEXT, TableSchema::TYPE_STRING, TableSchema::TYPE_CHAR];
        if (in_array($data["type"], $hasCollate, true) && isset($data["collate"]) && $data["collate"] != "") {
            $out .= " COLLATE " ~ $data["collate"];
        }

        $precisionTypes = [
            TableSchema::TYPE_FLOAT,
            TableSchema::TYPE_DATETIME,
            TableSchema::TYPE_DATETIME_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP,
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL,
        ];
        if (in_array($data["type"], $precisionTypes, true) && isset($data["precision"])) {
            $out .= "(" ~ (int)$data["precision"] ~ ")";
        }

        if (
            $data["type"] == TableSchema::TYPE_DECIMAL &&
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

        $dateTimeTypes = [
            TableSchema::TYPE_DATETIME,
            TableSchema::TYPE_DATETIME_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP,
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL,
        ];
        $dateTimeDefaults = [
            "current_timestamp",
            "getdate()",
            "getutcdate()",
            "sysdatetime()",
            "sysutcdatetime()",
            "sysdatetimeoffset()",
        ];
        if (
            isset($data["default"]) &&
            in_array($data["type"], $dateTimeTypes, true) &&
            in_array(strtolower($data["default"]), $dateTimeDefaults, true)
        ) {
            $out .= " DEFAULT " ~ strtoupper($data["default"]);
        } elseif (isset($data["default"])) {
            $default = is_bool($data["default"])
                ? (int)$data["default"]
                : _driver.schemaValue($data["default"]);
            $out .= " DEFAULT " ~ $default;
        } elseif (isset($data["null"]) && $data["null"] != false) {
            $out .= " DEFAULT NULL";
        }

        return $out;
    }


    array addConstraintSql(TableSchema $schema) {
        $sqlPattern = "ALTER TABLE %s ADD %s;";
        $sql = [];

        foreach ($schema.constraints() as $name) {
            /** @var array $constraint */
            $constraint = $schema.getConstraint($name);
            if ($constraint["type"] == TableSchema::CONSTRAINT_FOREIGN) {
                $tableName = _driver.quoteIdentifier($schema.name());
                $sql[] = sprintf($sqlPattern, $tableName, this.constraintSql($schema, $name));
            }
        }

        return $sql;
    }


    array dropConstraintSql(TableSchema $schema) {
        $sqlPattern = "ALTER TABLE %s DROP CONSTRAINT %s;";
        $sql = [];

        foreach ($schema.constraints() as $name) {
            /** @var array $constraint */
            $constraint = $schema.getConstraint($name);
            if ($constraint["type"] == TableSchema::CONSTRAINT_FOREIGN) {
                $tableName = _driver.quoteIdentifier($schema.name());
                $constraintName = _driver.quoteIdentifier($name);
                $sql[] = sprintf($sqlPattern, $tableName, $constraintName);
            }
        }

        return $sql;
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


    string constraintSql(TableSchema $schema, string aName) {
        /** @var array $data */
        $data = $schema.getConstraint($name);
        $out = "CONSTRAINT " ~ _driver.quoteIdentifier($name);
        if ($data["type"] == TableSchema::CONSTRAINT_PRIMARY) {
            $out = "PRIMARY KEY";
        }
        if ($data["type"] == TableSchema::CONSTRAINT_UNIQUE) {
            $out .= " UNIQUE";
        }

        return _keySql($out, $data);
    }

    /**
     * Helper method for generating key SQL snippets.
     *
     * @param string $prefix The key prefix
     * @param array $data Key data.
     */
    protected string _keySql(string $prefix, array $data) {
        $columns = array_map(
            [_driver, "quoteIdentifier"],
            $data["columns"]
        );
        if ($data["type"] == TableSchema::CONSTRAINT_FOREIGN) {
            return $prefix . sprintf(
                " FOREIGN KEY (%s) REFERENCES %s (%s) ON UPDATE %s ON DELETE %s",
                implode(", ", $columns),
                _driver.quoteIdentifier($data["references"][0]),
                _convertConstraintColumns($data["references"][1]),
                _foreignOnClause($data["update"]),
                _foreignOnClause($data["delete"])
            );
        }

        return $prefix ~ " (" ~ implode(", ", $columns) ~ ")";
    }


    array createTableSql(TableSchema $schema, array $columns, array $constraints, array $indexes) {
        $content = array_merge($columns, $constraints);
        $content = implode(",\n", array_filter($content));
        $tableName = _driver.quoteIdentifier($schema.name());
        $out = [];
        $out[] = sprintf("CREATE TABLE %s (\n%s\n)", $tableName, $content);
        foreach ($indexes as $index) {
            $out[] = $index;
        }

        return $out;
    }


    array truncateTableSql(TableSchema $schema) {
        $name = _driver.quoteIdentifier($schema.name());
        $queries = [
            sprintf("DELETE FROM %s", $name),
        ];

        // Restart identity sequences
        $pk = $schema.getPrimaryKey();
        if (count($pk) == 1) {
            /** @var array $column */
            $column = $schema.getColumn($pk[0]);
            if (in_array($column["type"], ["integer", "biginteger"])) {
                $queries[] = sprintf(
                    "IF EXISTS (SELECT * FROM sys.identity_columns WHERE OBJECT_NAME(OBJECT_ID) = "%s" AND " ~
                    "last_value IS NOT NULL) DBCC CHECKIDENT("%s", RESEED, 0)",
                    $schema.name(),
                    $schema.name()
                );
            }
        }

        return $queries;
    }
}

// phpcs:disable
// Add backwards compatible alias.
class_alias("Cake\databases.Schema\SqlserverSchemaDialect", "Cake\databases.Schema\SqlserverSchema");
// phpcs:enable
