module uim.cake.database.Schema;

/**
 * Schema management/reflection features for SQLServer.
 *
 * @internal
 */
class SqlserverSchemaDialect : SchemaDialect
{
    /**
     * @var string
     */
    public const DEFAULT_SCHEMA_NAME = 'dbo';


    function listTablesSql(array myConfig): array
    {
        mySql = "SELECT TABLE_NAME
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = ?
            AND (TABLE_TYPE = 'BASE TABLE' OR TABLE_TYPE = 'VIEW')
            ORDER BY TABLE_NAME";
        $schema = empty(myConfig['schema']) ? static::DEFAULT_SCHEMA_NAME : myConfig['schema'];

        return [mySql, [$schema]];
    }


    function describeColumnSql(string myTableName, array myConfig): array
    {
        mySql = 'SELECT DISTINCT
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
            ORDER BY column_id';

        $schema = empty(myConfig['schema']) ? static::DEFAULT_SCHEMA_NAME : myConfig['schema'];

        return [mySql, [myTableName, $schema]];
    }

    /**
     * Convert a column definition to the abstract types.
     *
     * The returned type will be a type that
     * Cake\Database\TypeFactory  can handle.
     *
     * @param string $col The column type
     * @param int|null $length the column length
     * @param int|null $precision The column precision
     * @param int|null $scale The column scale
     * @return array<string, mixed> Array of column information.
     * @link https://technet.microsoft.com/en-us/library/ms187752.aspx
     */
    protected auto _convertColumn(
        string $col,
        ?int $length = null,
        ?int $precision = null,
        ?int $scale = null
    ): array {
        $col = strtolower($col);

        myType = this._applyTypeSpecificColumnConversion(
            $col,
            compact('length', 'precision', 'scale')
        );
        if (myType !== null) {
            return myType;
        }

        if (in_array($col, ['date', 'time'])) {
            return ['type' => $col, 'length' => null];
        }

        if ($col === 'datetime') {
            // datetime cannot parse more than 3 digits of precision and isn't accurate
            return ['type' => TableSchema::TYPE_DATETIME, 'length' => null];
        }
        if (strpos($col, 'datetime') !== false) {
            myTypeName = TableSchema::TYPE_DATETIME;
            if ($scale > 0) {
                myTypeName = TableSchema::TYPE_DATETIME_FRACTIONAL;
            }

            return ['type' => myTypeName, 'length' => null, 'precision' => $scale];
        }

        if ($col === 'char') {
            return ['type' => TableSchema::TYPE_CHAR, 'length' => $length];
        }

        if ($col === 'tinyint') {
            return ['type' => TableSchema::TYPE_TINYINTEGER, 'length' => $precision ?: 3];
        }
        if ($col === 'smallint') {
            return ['type' => TableSchema::TYPE_SMALLINTEGER, 'length' => $precision ?: 5];
        }
        if ($col === 'int' || $col === 'integer') {
            return ['type' => TableSchema::TYPE_INTEGER, 'length' => $precision ?: 10];
        }
        if ($col === 'bigint') {
            return ['type' => TableSchema::TYPE_BIGINTEGER, 'length' => $precision ?: 20];
        }
        if ($col === 'bit') {
            return ['type' => TableSchema::TYPE_BOOLEAN, 'length' => null];
        }
        if (
            strpos($col, 'numeric') !== false ||
            strpos($col, 'money') !== false ||
            strpos($col, 'decimal') !== false
        ) {
            return ['type' => TableSchema::TYPE_DECIMAL, 'length' => $precision, 'precision' => $scale];
        }

        if ($col === 'real' || $col === 'float') {
            return ['type' => TableSchema::TYPE_FLOAT, 'length' => null];
        }
        // SqlServer schema reflection returns double length for unicode
        // columns because internally it uses UTF16/UCS2
        if ($col === 'nvarchar' || $col === 'nchar' || $col === 'ntext') {
            $length /= 2;
        }
        if (strpos($col, 'varchar') !== false && $length < 0) {
            return ['type' => TableSchema::TYPE_TEXT, 'length' => null];
        }

        if (strpos($col, 'varchar') !== false) {
            return ['type' => TableSchema::TYPE_STRING, 'length' => $length ?: 255];
        }

        if (strpos($col, 'char') !== false) {
            return ['type' => TableSchema::TYPE_CHAR, 'length' => $length];
        }

        if (strpos($col, 'text') !== false) {
            return ['type' => TableSchema::TYPE_TEXT, 'length' => null];
        }

        if ($col === 'image' || strpos($col, 'binary') !== false) {
            // -1 is the value for MAX which we treat as a 'long' binary
            if ($length == -1) {
                $length = TableSchema::LENGTH_LONG;
            }

            return ['type' => TableSchema::TYPE_BINARY, 'length' => $length];
        }

        if ($col === 'uniqueidentifier') {
            return ['type' => TableSchema::TYPE_UUID];
        }

        return ['type' => TableSchema::TYPE_STRING, 'length' => null];
    }


    function convertColumnDescription(TableSchema $schema, array $row): void
    {
        myField = this._convertColumn(
            $row['type'],
            $row['char_length'] !== null ? (int)$row['char_length'] : null,
            $row['precision'] !== null ? (int)$row['precision'] : null,
            $row['scale'] !== null ? (int)$row['scale'] : null
        );

        if (!empty($row['autoincrement'])) {
            myField['autoIncrement'] = true;
        }

        myField += [
            'null' => $row['null'] === '1',
            'default' => this._defaultValue(myField['type'], $row['default']),
            'collate' => $row['collation_name'],
        ];
        $schema.addColumn($row['name'], myField);
    }

    /**
     * Manipulate the default value.
     *
     * Removes () wrapping default values, extracts strings from
     * N'' wrappers and collation text and converts NULL strings.
     *
     * @param string myType The schema type
     * @param string|null $default The default value.
     * @return string|int|null
     */
    protected auto _defaultValue(myType, $default) {
        if ($default === null) {
            return null;
        }

        // remove () surrounding value (NULL) but leave () at the end of functions
        // integers might have two ((0)) wrapping value
        if (preg_match('/^\(+(.*?(\(\))?)\)+$/', $default, $matches)) {
            $default = $matches[1];
        }

        if ($default === 'NULL') {
            return null;
        }

        if (myType === TableSchema::TYPE_BOOLEAN) {
            return (int)$default;
        }

        // Remove quotes
        if (preg_match("/^\(?N?'(.*)'\)?/", $default, $matches)) {
            return str_replace("''", "'", $matches[1]);
        }

        return $default;
    }


    function describeIndexSql(string myTableName, array myConfig): array
    {
        mySql = "SELECT
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
            WHERE T.[is_ms_shipped] = 0 AND I.[type_desc] <> 'HEAP' AND T.[name] = ? AND S.[name] = ?
            ORDER BY I.[index_id], IC.[index_column_id]";

        $schema = empty(myConfig['schema']) ? static::DEFAULT_SCHEMA_NAME : myConfig['schema'];

        return [mySql, [myTableName, $schema]];
    }


    function convertIndexDescription(TableSchema $schema, array $row): void
    {
        myType = TableSchema::INDEX_INDEX;
        myName = $row['index_name'];
        if ($row['is_primary_key']) {
            myName = myType = TableSchema::CONSTRAINT_PRIMARY;
        }
        if ($row['is_unique_constraint'] && myType === TableSchema::INDEX_INDEX) {
            myType = TableSchema::CONSTRAINT_UNIQUE;
        }

        if (myType === TableSchema::INDEX_INDEX) {
            $existing = $schema.getIndex(myName);
        } else {
            $existing = $schema.getConstraint(myName);
        }

        $columns = [$row['column_name']];
        if (!empty($existing)) {
            $columns = array_merge($existing['columns'], $columns);
        }

        if (myType === TableSchema::CONSTRAINT_PRIMARY || myType === TableSchema::CONSTRAINT_UNIQUE) {
            $schema.addConstraint(myName, [
                'type' => myType,
                'columns' => $columns,
            ]);

            return;
        }
        $schema.addIndex(myName, [
            'type' => myType,
            'columns' => $columns,
        ]);
    }


    function describeForeignKeySql(string myTableName, array myConfig): array
    {
        // phpcs:disable Generic.Files.LineLength
        mySql = 'SELECT FK.[name] AS [foreign_key_name], FK.[delete_referential_action_desc] AS [delete_type],
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
            ORDER BY FKC.constraint_column_id';
        // phpcs:enable Generic.Files.LineLength

        $schema = empty(myConfig['schema']) ? static::DEFAULT_SCHEMA_NAME : myConfig['schema'];

        return [mySql, [myTableName, $schema]];
    }


    function convertForeignKeyDescription(TableSchema $schema, array $row): void
    {
        myData = [
            'type' => TableSchema::CONSTRAINT_FOREIGN,
            'columns' => [$row['column']],
            'references' => [$row['reference_table'], $row['reference_column']],
            'update' => this._convertOnClause($row['update_type']),
            'delete' => this._convertOnClause($row['delete_type']),
        ];
        myName = $row['foreign_key_name'];
        $schema.addConstraint(myName, myData);
    }


    protected auto _foreignOnClause(string $on): string
    {
        $parent = super._foreignOnClause($on);

        return $parent === 'RESTRICT' ? super._foreignOnClause(TableSchema::ACTION_NO_ACTION) : $parent;
    }


    protected auto _convertOnClause(string $clause): string
    {
        switch ($clause) {
            case 'NO_ACTION':
                return TableSchema::ACTION_NO_ACTION;
            case 'CASCADE':
                return TableSchema::ACTION_CASCADE;
            case 'SET_NULL':
                return TableSchema::ACTION_SET_NULL;
            case 'SET_DEFAULT':
                return TableSchema::ACTION_SET_DEFAULT;
        }

        return TableSchema::ACTION_SET_NULL;
    }


    function columnSql(TableSchema $schema, string myName): string
    {
        /** @var array myData */
        myData = $schema.getColumn(myName);

        mySql = this._getTypeSpecificColumnSql(myData['type'], $schema, myName);
        if (mySql !== null) {
            return mySql;
        }

        $out = this._driver.quoteIdentifier(myName);
        myTypeMap = [
            TableSchema::TYPE_TINYINTEGER => ' TINYINT',
            TableSchema::TYPE_SMALLINTEGER => ' SMALLINT',
            TableSchema::TYPE_INTEGER => ' INTEGER',
            TableSchema::TYPE_BIGINTEGER => ' BIGINT',
            TableSchema::TYPE_BINARY_UUID => ' UNIQUEIDENTIFIER',
            TableSchema::TYPE_BOOLEAN => ' BIT',
            TableSchema::TYPE_CHAR => ' NCHAR',
            TableSchema::TYPE_FLOAT => ' FLOAT',
            TableSchema::TYPE_DECIMAL => ' DECIMAL',
            TableSchema::TYPE_DATE => ' DATE',
            TableSchema::TYPE_TIME => ' TIME',
            TableSchema::TYPE_DATETIME => ' DATETIME2',
            TableSchema::TYPE_DATETIME_FRACTIONAL => ' DATETIME2',
            TableSchema::TYPE_TIMESTAMP => ' DATETIME2',
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL => ' DATETIME2',
            TableSchema::TYPE_TIMESTAMP_TIMEZONE => ' DATETIME2',
            TableSchema::TYPE_UUID => ' UNIQUEIDENTIFIER',
            TableSchema::TYPE_JSON => ' NVARCHAR(MAX)',
        ];

        if (isset(myTypeMap[myData['type']])) {
            $out .= myTypeMap[myData['type']];
        }

        if (myData['type'] === TableSchema::TYPE_INTEGER || myData['type'] === TableSchema::TYPE_BIGINTEGER) {
            if ($schema.getPrimaryKey() === [myName] || myData['autoIncrement'] === true) {
                unset(myData['null'], myData['default']);
                $out .= ' IDENTITY(1, 1)';
            }
        }

        if (myData['type'] === TableSchema::TYPE_TEXT && myData['length'] !== TableSchema::LENGTH_TINY) {
            $out .= ' NVARCHAR(MAX)';
        }

        if (myData['type'] === TableSchema::TYPE_CHAR) {
            $out .= '(' . myData['length'] . ')';
        }

        if (myData['type'] === TableSchema::TYPE_BINARY) {
            if (
                !isset(myData['length'])
                || in_array(myData['length'], [TableSchema::LENGTH_MEDIUM, TableSchema::LENGTH_LONG], true)
            ) {
                myData['length'] = 'MAX';
            }

            if (myData['length'] === 1) {
                $out .= ' BINARY(1)';
            } else {
                $out .= ' VARBINARY';

                $out .= sprintf('(%s)', myData['length']);
            }
        }

        if (
            myData['type'] === TableSchema::TYPE_STRING ||
            (
                myData['type'] === TableSchema::TYPE_TEXT &&
                myData['length'] === TableSchema::LENGTH_TINY
            )
        ) {
            myType = ' NVARCHAR';
            $length = myData['length'] ?? TableSchema::LENGTH_TINY;
            $out .= sprintf('%s(%d)', myType, $length);
        }

        $hasCollate = [TableSchema::TYPE_TEXT, TableSchema::TYPE_STRING, TableSchema::TYPE_CHAR];
        if (in_array(myData['type'], $hasCollate, true) && isset(myData['collate']) && myData['collate'] !== '') {
            $out .= ' COLLATE ' . myData['collate'];
        }

        $precisionTypes = [
            TableSchema::TYPE_FLOAT,
            TableSchema::TYPE_DATETIME,
            TableSchema::TYPE_DATETIME_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP,
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL,
        ];
        if (in_array(myData['type'], $precisionTypes, true) && isset(myData['precision'])) {
            $out .= '(' . (int)myData['precision'] . ')';
        }

        if (
            myData['type'] === TableSchema::TYPE_DECIMAL &&
            (
                isset(myData['length']) ||
                isset(myData['precision'])
            )
        ) {
            $out .= '(' . (int)myData['length'] . ',' . (int)myData['precision'] . ')';
        }

        if (isset(myData['null']) && myData['null'] === false) {
            $out .= ' NOT NULL';
        }

        $dateTimeTypes = [
            TableSchema::TYPE_DATETIME,
            TableSchema::TYPE_DATETIME_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP,
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL,
        ];
        $dateTimeDefaults = [
            'current_timestamp',
            'getdate()',
            'getutcdate()',
            'sysdatetime()',
            'sysutcdatetime()',
            'sysdatetimeoffset()',
        ];
        if (
            isset(myData['default']) &&
            in_array(myData['type'], $dateTimeTypes, true) &&
            in_array(strtolower(myData['default']), $dateTimeDefaults, true)
        ) {
            $out .= ' DEFAULT ' . strtoupper(myData['default']);
        } elseif (isset(myData['default'])) {
            $default = is_bool(myData['default'])
                ? (int)myData['default']
                : this._driver.schemaValue(myData['default']);
            $out .= ' DEFAULT ' . $default;
        } elseif (isset(myData['null']) && myData['null'] !== false) {
            $out .= ' DEFAULT NULL';
        }

        return $out;
    }


    function addConstraintSql(TableSchema $schema): array
    {
        mySqlPattern = 'ALTER TABLE %s ADD %s;';
        mySql = [];

        foreach ($schema.constraints() as myName) {
            /** @var array $constraint */
            $constraint = $schema.getConstraint(myName);
            if ($constraint['type'] === TableSchema::CONSTRAINT_FOREIGN) {
                myTableName = this._driver.quoteIdentifier($schema.name());
                mySql[] = sprintf(mySqlPattern, myTableName, this.constraintSql($schema, myName));
            }
        }

        return mySql;
    }


    function dropConstraintSql(TableSchema $schema): array
    {
        mySqlPattern = 'ALTER TABLE %s DROP CONSTRAINT %s;';
        mySql = [];

        foreach ($schema.constraints() as myName) {
            /** @var array $constraint */
            $constraint = $schema.getConstraint(myName);
            if ($constraint['type'] === TableSchema::CONSTRAINT_FOREIGN) {
                myTableName = this._driver.quoteIdentifier($schema.name());
                $constraintName = this._driver.quoteIdentifier(myName);
                mySql[] = sprintf(mySqlPattern, myTableName, $constraintName);
            }
        }

        return mySql;
    }


    function indexSql(TableSchema $schema, string myName): string
    {
        /** @var array myData */
        myData = $schema.getIndex(myName);
        $columns = array_map(
            [this._driver, 'quoteIdentifier'],
            myData['columns']
        );

        return sprintf(
            'CREATE INDEX %s ON %s (%s)',
            this._driver.quoteIdentifier(myName),
            this._driver.quoteIdentifier($schema.name()),
            implode(', ', $columns)
        );
    }


    function constraintSql(TableSchema $schema, string myName): string
    {
        /** @var array myData */
        myData = $schema.getConstraint(myName);
        $out = 'CONSTRAINT ' . this._driver.quoteIdentifier(myName);
        if (myData['type'] === TableSchema::CONSTRAINT_PRIMARY) {
            $out = 'PRIMARY KEY';
        }
        if (myData['type'] === TableSchema::CONSTRAINT_UNIQUE) {
            $out .= ' UNIQUE';
        }

        return this._keySql($out, myData);
    }

    /**
     * Helper method for generating key SQL snippets.
     *
     * @param string $prefix The key prefix
     * @param array myData Key data.
     * @return string
     */
    protected auto _keySql(string $prefix, array myData): string
    {
        $columns = array_map(
            [this._driver, 'quoteIdentifier'],
            myData['columns']
        );
        if (myData['type'] === TableSchema::CONSTRAINT_FOREIGN) {
            return $prefix . sprintf(
                ' FOREIGN KEY (%s) REFERENCES %s (%s) ON UPDATE %s ON DELETE %s',
                implode(', ', $columns),
                this._driver.quoteIdentifier(myData['references'][0]),
                this._convertConstraintColumns(myData['references'][1]),
                this._foreignOnClause(myData['update']),
                this._foreignOnClause(myData['delete'])
            );
        }

        return $prefix . ' (' . implode(', ', $columns) . ')';
    }


    function createTableSql(TableSchema $schema, array $columns, array $constraints, array $indexes): array
    {
        myContents = array_merge($columns, $constraints);
        myContents = implode(",\n", array_filter(myContents));
        myTableName = this._driver.quoteIdentifier($schema.name());
        $out = [];
        $out[] = sprintf("CREATE TABLE %s (\n%s\n)", myTableName, myContents);
        foreach ($indexes as $index) {
            $out[] = $index;
        }

        return $out;
    }


    function truncateTableSql(TableSchema $schema): array
    {
        myName = this._driver.quoteIdentifier($schema.name());
        $queries = [
            sprintf('DELETE FROM %s', myName),
        ];

        // Restart identity sequences
        $pk = $schema.getPrimaryKey();
        if (count($pk) === 1) {
            /** @var array $column */
            $column = $schema.getColumn($pk[0]);
            if (in_array($column['type'], ['integer', 'biginteger'])) {
                $queries[] = sprintf(
                    "IF EXISTS (SELECT * FROM sys.identity_columns WHERE OBJECT_NAME(OBJECT_ID) = '%s' AND " .
                    "last_value IS NOT NULL) DBCC CHECKIDENT('%s', RESEED, 0)",
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
class_alias('Cake\Database\Schema\SqlserverSchemaDialect', 'Cake\Database\Schema\SqlserverSchema');
// phpcs:enable
