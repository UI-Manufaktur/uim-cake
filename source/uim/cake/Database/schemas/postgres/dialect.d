module uim.cake.database.Schema;

import uim.cake.database.Exception\DatabaseException;

/**
 * Schema management/reflection features for Postgres.
 *
 * @internal
 */
class PostgresSchemaDialect : SchemaDialect
{

    function listTablesSql(array myConfig): array
    {
        mySql = 'SELECT table_name as name FROM information_schema.tables WHERE table_schema = ? ORDER BY name';
        $schema = empty(myConfig['schema']) ? 'public' : myConfig['schema'];

        return [mySql, [$schema]];
    }


    function describeColumnSql(string myTableName, array myConfig): array
    {
        mySql = 'SELECT DISTINCT table_schema AS schema,
            column_name AS name,
            data_type AS type,
            is_nullable AS null, column_default AS default,
            character_maximum_length AS char_length,
            c.collation_name,
            d.description as comment,
            ordinal_position,
            c.datetime_precision,
            c.numeric_precision as column_precision,
            c.numeric_scale as column_scale,
            pg_get_serial_sequence(attr.attrelid::regclass::text, attr.attname) IS NOT NULL AS has_serial
        FROM information_schema.columns c
        INNER JOIN pg_catalog.pg_module ns ON (ns.nspname = table_schema)
        INNER JOIN pg_catalog.pg_class cl ON (cl.relmodule = ns.oid AND cl.relname = table_name)
        LEFT JOIN pg_catalog.pg_index i ON (i.indrelid = cl.oid AND i.indkey[0] = c.ordinal_position)
        LEFT JOIN pg_catalog.pg_description d on (cl.oid = d.objoid AND d.objsubid = c.ordinal_position)
        LEFT JOIN pg_catalog.pg_attribute attr ON (cl.oid = attr.attrelid AND column_name = attr.attname)
        WHERE table_name = ? AND table_schema = ? AND table_catalog = ?
        ORDER BY ordinal_position';

        $schema = empty(myConfig['schema']) ? 'public' : myConfig['schema'];

        return [mySql, [myTableName, $schema, myConfig['database']]];
    }

    /**
     * Convert a column definition to the abstract types.
     *
     * The returned type will be a type that
     * Cake\Database\TypeFactory can handle.
     *
     * @param string $column The column type + length
     * @throws \Cake\Database\Exception\DatabaseException when column cannot be parsed.
     * @return array<string, mixed> Array of column information.
     */
    protected auto _convertColumn(string $column): array
    {
        preg_match('/([a-z\s]+)(?:\(([0-9,]+)\))?/i', $column, $matches);
        if (empty($matches)) {
            throw new DatabaseException(sprintf('Unable to parse column type from "%s"', $column));
        }

        $col = strtolower($matches[1]);
        $length = $precision = $scale = null;
        if (isset($matches[2])) {
            $length = (int)$matches[2];
        }

        myType = this._applyTypeSpecificColumnConversion(
            $col,
            compact('length', 'precision', 'scale')
        );
        if (myType !== null) {
            return myType;
        }

        if (in_array($col, ['date', 'time', 'boolean'], true)) {
            return ['type' => $col, 'length' => null];
        }
        if (in_array($col, ['timestamptz', 'timestamp with time zone'], true)) {
            return ['type' => TableSchema::TYPE_TIMESTAMP_TIMEZONE, 'length' => null];
        }
        if (strpos($col, 'timestamp') !== false) {
            return ['type' => TableSchema::TYPE_TIMESTAMP_FRACTIONAL, 'length' => null];
        }
        if (strpos($col, 'time') !== false) {
            return ['type' => TableSchema::TYPE_TIME, 'length' => null];
        }
        if ($col === 'serial' || $col === 'integer') {
            return ['type' => TableSchema::TYPE_INTEGER, 'length' => 10];
        }
        if ($col === 'bigserial' || $col === 'bigint') {
            return ['type' => TableSchema::TYPE_BIGINTEGER, 'length' => 20];
        }
        if ($col === 'smallint') {
            return ['type' => TableSchema::TYPE_SMALLINTEGER, 'length' => 5];
        }
        if ($col === 'inet') {
            return ['type' => TableSchema::TYPE_STRING, 'length' => 39];
        }
        if ($col === 'uuid') {
            return ['type' => TableSchema::TYPE_UUID, 'length' => null];
        }
        if ($col === 'char') {
            return ['type' => TableSchema::TYPE_CHAR, 'length' => $length];
        }
        if (strpos($col, 'character') !== false) {
            return ['type' => TableSchema::TYPE_STRING, 'length' => $length];
        }
        // money is 'string' as it includes arbitrary text content
        // before the number value.
        if (strpos($col, 'money') !== false || $col === 'string') {
            return ['type' => TableSchema::TYPE_STRING, 'length' => $length];
        }
        if (strpos($col, 'text') !== false) {
            return ['type' => TableSchema::TYPE_TEXT, 'length' => null];
        }
        if ($col === 'bytea') {
            return ['type' => TableSchema::TYPE_BINARY, 'length' => null];
        }
        if ($col === 'real' || strpos($col, 'double') !== false) {
            return ['type' => TableSchema::TYPE_FLOAT, 'length' => null];
        }
        if (
            strpos($col, 'numeric') !== false ||
            strpos($col, 'decimal') !== false
        ) {
            return ['type' => TableSchema::TYPE_DECIMAL, 'length' => null];
        }

        if (strpos($col, 'json') !== false) {
            return ['type' => TableSchema::TYPE_JSON, 'length' => null];
        }

        $length = is_numeric($length) ? $length : null;

        return ['type' => TableSchema::TYPE_STRING, 'length' => $length];
    }


    function convertColumnDescription(TableSchema $schema, array $row): void
    {
        myField = this._convertColumn($row['type']);

        if (myField['type'] === TableSchema::TYPE_BOOLEAN) {
            if ($row['default'] === 'true') {
                $row['default'] = 1;
            }
            if ($row['default'] === 'false') {
                $row['default'] = 0;
            }
        }
        if (!empty($row['has_serial'])) {
            myField['autoIncrement'] = true;
        }

        myField += [
            'default' => this._defaultValue($row['default']),
            'null' => $row['null'] === 'YES',
            'collate' => $row['collation_name'],
            'comment' => $row['comment'],
        ];
        myField['length'] = $row['char_length'] ?: myField['length'];

        if (myField['type'] === 'numeric' || myField['type'] === 'decimal') {
            myField['length'] = $row['column_precision'];
            myField['precision'] = $row['column_scale'] ?: null;
        }

        if (myField['type'] === TableSchema::TYPE_TIMESTAMP_FRACTIONAL) {
            myField['precision'] = $row['datetime_precision'];
            if (myField['precision'] === 0) {
                myField['type'] = TableSchema::TYPE_TIMESTAMP;
            }
        }

        if (myField['type'] === TableSchema::TYPE_TIMESTAMP_TIMEZONE) {
            myField['precision'] = $row['datetime_precision'];
        }

        $schema.addColumn($row['name'], myField);
    }

    /**
     * Manipulate the default value.
     *
     * Postgres includes sequence data and casting information in default values.
     * We need to remove those.
     *
     * @param string|int|null $default The default value.
     * @return string|int|null
     */
    protected auto _defaultValue($default)
    {
        if (is_numeric($default) || $default === null) {
            return $default;
        }
        // Sequences
        if (strpos($default, 'nextval') === 0) {
            return null;
        }

        if (strpos($default, 'NULL::') === 0) {
            return null;
        }

        // Remove quotes and postgres casts
        return preg_replace(
            "/^'(.*)'(?:::.*)$/",
            '$1',
            $default
        );
    }


    function describeIndexSql(string myTableName, array myConfig): array
    {
        mySql = 'SELECT
        c2.relname,
        a.attname,
        i.indisprimary,
        i.indisunique
        FROM pg_catalog.pg_module n
        INNER JOIN pg_catalog.pg_class c ON (n.oid = c.relmodule)
        INNER JOIN pg_catalog.pg_index i ON (c.oid = i.indrelid)
        INNER JOIN pg_catalog.pg_class c2 ON (c2.oid = i.indexrelid)
        INNER JOIN pg_catalog.pg_attribute a ON (a.attrelid = c.oid AND i.indrelid::regclass = a.attrelid::regclass)
        WHERE n.nspname = ?
        AND a.attnum = ANY(i.indkey)
        AND c.relname = ?
        ORDER BY i.indisprimary DESC, i.indisunique DESC, c.relname, a.attnum';

        $schema = 'public';
        if (!empty(myConfig['schema'])) {
            $schema = myConfig['schema'];
        }

        return [mySql, [$schema, myTableName]];
    }


    function convertIndexDescription(TableSchema $schema, array $row): void
    {
        myType = TableSchema::INDEX_INDEX;
        myName = $row['relname'];
        if ($row['indisprimary']) {
            myName = myType = TableSchema::CONSTRAINT_PRIMARY;
        }
        if ($row['indisunique'] && myType === TableSchema::INDEX_INDEX) {
            myType = TableSchema::CONSTRAINT_UNIQUE;
        }
        if (myType === TableSchema::CONSTRAINT_PRIMARY || myType === TableSchema::CONSTRAINT_UNIQUE) {
            this._convertConstraint($schema, myName, myType, $row);

            return;
        }
        $index = $schema.getIndex(myName);
        if (!$index) {
            $index = [
                'type' => myType,
                'columns' => [],
            ];
        }
        $index['columns'][] = $row['attname'];
        $schema.addIndex(myName, $index);
    }

    /**
     * Add/update a constraint into the schema object.
     *
     * @param \Cake\Database\Schema\TableSchema $schema The table to update.
     * @param string myName The index name.
     * @param string myType The index type.
     * @param array $row The metadata record to update with.
     * @return void
     */
    protected auto _convertConstraint(TableSchema $schema, string myName, string myType, array $row): void
    {
        $constraint = $schema.getConstraint(myName);
        if (!$constraint) {
            $constraint = [
                'type' => myType,
                'columns' => [],
            ];
        }
        $constraint['columns'][] = $row['attname'];
        $schema.addConstraint(myName, $constraint);
    }


    function describeForeignKeySql(string myTableName, array myConfig): array
    {
        // phpcs:disable Generic.Files.LineLength
        mySql = 'SELECT
        c.conname AS name,
        c.contype AS type,
        a.attname AS column_name,
        c.confmatchtype AS match_type,
        c.confupdtype AS on_update,
        c.confdeltype AS on_delete,
        c.confrelid::regclass AS references_table,
        ab.attname AS references_field
        FROM pg_catalog.pg_module n
        INNER JOIN pg_catalog.pg_class cl ON (n.oid = cl.relmodule)
        INNER JOIN pg_catalog.pg_constraint c ON (n.oid = c.conmodule)
        INNER JOIN pg_catalog.pg_attribute a ON (a.attrelid = cl.oid AND c.conrelid = a.attrelid AND a.attnum = ANY(c.conkey))
        INNER JOIN pg_catalog.pg_attribute ab ON (a.attrelid = cl.oid AND c.confrelid = ab.attrelid AND ab.attnum = ANY(c.confkey))
        WHERE n.nspname = ?
        AND cl.relname = ?
        ORDER BY name, a.attnum, ab.attnum DESC';
        // phpcs:enable Generic.Files.LineLength

        $schema = empty(myConfig['schema']) ? 'public' : myConfig['schema'];

        return [mySql, [$schema, myTableName]];
    }


    function convertForeignKeyDescription(TableSchema $schema, array $row): void
    {
        myData = [
            'type' => TableSchema::CONSTRAINT_FOREIGN,
            'columns' => $row['column_name'],
            'references' => [$row['references_table'], $row['references_field']],
            'update' => this._convertOnClause($row['on_update']),
            'delete' => this._convertOnClause($row['on_delete']),
        ];
        $schema.addConstraint($row['name'], myData);
    }


    protected auto _convertOnClause(string $clause): string
    {
        if ($clause === 'r') {
            return TableSchema::ACTION_RESTRICT;
        }
        if ($clause === 'a') {
            return TableSchema::ACTION_NO_ACTION;
        }
        if ($clause === 'c') {
            return TableSchema::ACTION_CASCADE;
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
            TableSchema::TYPE_TINYINTEGER => ' SMALLINT',
            TableSchema::TYPE_SMALLINTEGER => ' SMALLINT',
            TableSchema::TYPE_BINARY_UUID => ' UUID',
            TableSchema::TYPE_BOOLEAN => ' BOOLEAN',
            TableSchema::TYPE_FLOAT => ' FLOAT',
            TableSchema::TYPE_DECIMAL => ' DECIMAL',
            TableSchema::TYPE_DATE => ' DATE',
            TableSchema::TYPE_TIME => ' TIME',
            TableSchema::TYPE_DATETIME => ' TIMESTAMP',
            TableSchema::TYPE_DATETIME_FRACTIONAL => ' TIMESTAMP',
            TableSchema::TYPE_TIMESTAMP => ' TIMESTAMP',
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL => ' TIMESTAMP',
            TableSchema::TYPE_TIMESTAMP_TIMEZONE => ' TIMESTAMPTZ',
            TableSchema::TYPE_UUID => ' UUID',
            TableSchema::TYPE_CHAR => ' CHAR',
            TableSchema::TYPE_JSON => ' JSONB',
        ];

        if (isset(myTypeMap[myData['type']])) {
            $out .= myTypeMap[myData['type']];
        }

        if (myData['type'] === TableSchema::TYPE_INTEGER || myData['type'] === TableSchema::TYPE_BIGINTEGER) {
            myType = myData['type'] === TableSchema::TYPE_INTEGER ? ' INTEGER' : ' BIGINT';
            if ($schema.getPrimaryKey() === [myName] || myData['autoIncrement'] === true) {
                myType = myData['type'] === TableSchema::TYPE_INTEGER ? ' SERIAL' : ' BIGSERIAL';
                unset(myData['null'], myData['default']);
            }
            $out .= myType;
        }

        if (myData['type'] === TableSchema::TYPE_TEXT && myData['length'] !== TableSchema::LENGTH_TINY) {
            $out .= ' TEXT';
        }
        if (myData['type'] === TableSchema::TYPE_BINARY) {
            $out .= ' BYTEA';
        }

        if (myData['type'] === TableSchema::TYPE_CHAR) {
            $out .= '(' . myData['length'] . ')';
        }

        if (
            myData['type'] === TableSchema::TYPE_STRING ||
            (
                myData['type'] === TableSchema::TYPE_TEXT &&
                myData['length'] === TableSchema::LENGTH_TINY
            )
        ) {
            $out .= ' VARCHAR';
            if (isset(myData['length']) && myData['length'] !== '') {
                $out .= '(' . myData['length'] . ')';
            }
        }

        $hasCollate = [TableSchema::TYPE_TEXT, TableSchema::TYPE_STRING, TableSchema::TYPE_CHAR];
        if (in_array(myData['type'], $hasCollate, true) && isset(myData['collate']) && myData['collate'] !== '') {
            $out .= ' COLLATE "' . myData['collate'] . '"';
        }

        $hasPrecision = [
            TableSchema::TYPE_FLOAT,
            TableSchema::TYPE_DATETIME,
            TableSchema::TYPE_DATETIME_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP,
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP_TIMEZONE,
        ];
        if (in_array(myData['type'], $hasPrecision) && isset(myData['precision'])) {
            $out .= '(' . myData['precision'] . ')';
        }

        if (
            myData['type'] === TableSchema::TYPE_DECIMAL &&
            (
                isset(myData['length']) ||
                isset(myData['precision'])
            )
        ) {
            $out .= '(' . myData['length'] . ',' . (int)myData['precision'] . ')';
        }

        if (isset(myData['null']) && myData['null'] === false) {
            $out .= ' NOT NULL';
        }

        $datetimeTypes = [
            TableSchema::TYPE_DATETIME,
            TableSchema::TYPE_DATETIME_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP,
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP_TIMEZONE,
        ];
        if (
            isset(myData['default']) &&
            in_array(myData['type'], $datetimeTypes) &&
            strtolower(myData['default']) === 'current_timestamp'
        ) {
            $out .= ' DEFAULT CURRENT_TIMESTAMP';
        } elseif (isset(myData['default'])) {
            $defaultValue = myData['default'];
            if (myData['type'] === 'boolean') {
                $defaultValue = (bool)$defaultValue;
            }
            $out .= ' DEFAULT ' . this._driver.schemaValue($defaultValue);
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
        /** @var array<string, mixed> myData */
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
     * @param array<string, mixed> myData Key data.
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
                ' FOREIGN KEY (%s) REFERENCES %s (%s) ON UPDATE %s ON DELETE %s DEFERRABLE INITIALLY IMMEDIATE',
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
        $temporary = $schema.isTemporary() ? ' TEMPORARY ' : ' ';
        $out = [];
        $out[] = sprintf("CREATE%sTABLE %s (\n%s\n)", $temporary, myTableName, myContents);
        foreach ($indexes as $index) {
            $out[] = $index;
        }
        foreach ($schema.columns() as $column) {
            $columnData = $schema.getColumn($column);
            if (isset($columnData['comment'])) {
                $out[] = sprintf(
                    'COMMENT ON COLUMN %s.%s IS %s',
                    myTableName,
                    this._driver.quoteIdentifier($column),
                    this._driver.schemaValue($columnData['comment'])
                );
            }
        }

        return $out;
    }


    function truncateTableSql(TableSchema $schema): array
    {
        myName = this._driver.quoteIdentifier($schema.name());

        return [
            sprintf('TRUNCATE %s RESTART IDENTITY CASCADE', myName),
        ];
    }

    /**
     * Generate the SQL to drop a table.
     *
     * @param \Cake\Database\Schema\TableSchema $schema Table instance
     * @return array SQL statements to drop a table.
     */
    function dropTableSql(TableSchema $schema): array
    {
        mySql = sprintf(
            'DROP TABLE %s CASCADE',
            this._driver.quoteIdentifier($schema.name())
        );

        return [mySql];
    }
}

// phpcs:disable
// Add backwards compatible alias.
class_alias('Cake\Database\Schema\PostgresSchemaDialect', 'Cake\Database\Schema\PostgresSchema');
// phpcs:enable
