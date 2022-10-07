module uim.cake.database.Schema;

import uim.cake.database.Exception\DatabaseException;

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
     *
     * @var bool
     */
    protected $_hasSequences;

    /**
     * Convert a column definition to the abstract types.
     *
     * The returned type will be a type that
     * Cake\Database\TypeFactory can handle.
     *
     * @param string $column The column type + length
     * @throws \Cake\Database\Exception\DatabaseException when unable to parse column type
     * @return array<string, mixed> Array of column information.
     */
    protected auto _convertColumn(string $column): array
    {
        if ($column === '') {
            return ['type' => TableSchema::TYPE_TEXT, 'length' => null];
        }

        preg_match('/(unsigned)?\s*([a-z]+)(?:\(([0-9,]+)\))?/i', $column, $matches);
        if (empty($matches)) {
            throw new DatabaseException(sprintf('Unable to parse column type from "%s"', $column));
        }

        $unsigned = false;
        if (strtolower($matches[1]) === 'unsigned') {
            $unsigned = true;
        }

        $col = strtolower($matches[2]);
        $length = $precision = $scale = null;
        if (isset($matches[3])) {
            $length = $matches[3];
            if (strpos($length, ',') !== false) {
                [$length, $precision] = explode(',', $length);
            }
            $length = (int)$length;
            $precision = (int)$precision;
        }

        myType = this._applyTypeSpecificColumnConversion(
            $col,
            compact('length', 'precision', 'scale')
        );
        if (myType !== null) {
            return myType;
        }

        if ($col === 'bigint') {
            return ['type' => TableSchema::TYPE_BIGINTEGER, 'length' => $length, 'unsigned' => $unsigned];
        }
        if ($col === 'smallint') {
            return ['type' => TableSchema::TYPE_SMALLINTEGER, 'length' => $length, 'unsigned' => $unsigned];
        }
        if ($col === 'tinyint') {
            return ['type' => TableSchema::TYPE_TINYINTEGER, 'length' => $length, 'unsigned' => $unsigned];
        }
        if (strpos($col, 'int') !== false) {
            return ['type' => TableSchema::TYPE_INTEGER, 'length' => $length, 'unsigned' => $unsigned];
        }
        if (strpos($col, 'decimal') !== false) {
            return [
                'type' => TableSchema::TYPE_DECIMAL,
                'length' => $length,
                'precision' => $precision,
                'unsigned' => $unsigned,
            ];
        }
        if (in_array($col, ['float', 'real', 'double'])) {
            return [
                'type' => TableSchema::TYPE_FLOAT,
                'length' => $length,
                'precision' => $precision,
                'unsigned' => $unsigned,
            ];
        }

        if (strpos($col, 'boolean') !== false) {
            return ['type' => TableSchema::TYPE_BOOLEAN, 'length' => null];
        }

        if ($col === 'char' && $length === 36) {
            return ['type' => TableSchema::TYPE_UUID, 'length' => null];
        }
        if ($col === 'char') {
            return ['type' => TableSchema::TYPE_CHAR, 'length' => $length];
        }
        if (strpos($col, 'char') !== false) {
            return ['type' => TableSchema::TYPE_STRING, 'length' => $length];
        }

        if ($col === 'binary' && $length === 16) {
            return ['type' => TableSchema::TYPE_BINARY_UUID, 'length' => null];
        }
        if (in_array($col, ['blob', 'clob', 'binary', 'varbinary'])) {
            return ['type' => TableSchema::TYPE_BINARY, 'length' => $length];
        }

        $datetimeTypes = [
            'date',
            'time',
            'timestamp',
            'timestampfractional',
            'timestamptimezone',
            'datetime',
            'datetimefractional',
        ];
        if (in_array($col, $datetimeTypes)) {
            return ['type' => $col, 'length' => null];
        }

        return ['type' => TableSchema::TYPE_TEXT, 'length' => null];
    }


    function listTablesSql(array myConfig): array
    {
        return [
            'SELECT name FROM sqlite_master WHERE type="table" ' .
            'AND name != "sqlite_sequence" ORDER BY name',
            [],
        ];
    }


    function describeColumnSql(string myTableName, array myConfig): array
    {
        mySql = sprintf(
            'PRAGMA table_info(%s)',
            this._driver.quoteIdentifier(myTableName)
        );

        return [mySql, []];
    }


    function convertColumnDescription(TableSchema $schema, array $row): void
    {
        myField = this._convertColumn($row['type']);
        myField += [
            'null' => !$row['notnull'],
            'default' => this._defaultValue($row['dflt_value']),
        ];
        $primary = $schema.getConstraint('primary');

        if ($row['pk'] && empty($primary)) {
            myField['null'] = false;
            myField['autoIncrement'] = true;
        }

        // SQLite does not support autoincrement on composite keys.
        if ($row['pk'] && !empty($primary)) {
            $existingColumn = $primary['columns'][0];
            /** @psalm-suppress PossiblyNullOperand */
            $schema.addColumn($existingColumn, ['autoIncrement' => null] + $schema.getColumn($existingColumn));
        }

        $schema.addColumn($row['name'], myField);
        if ($row['pk']) {
            $constraint = (array)$schema.getConstraint('primary') + [
                'type' => TableSchema::CONSTRAINT_PRIMARY,
                'columns' => [],
            ];
            $constraint['columns'] = array_merge($constraint['columns'], [$row['name']]);
            $schema.addConstraint('primary', $constraint);
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
    protected auto _defaultValue($default)
    {
        if ($default === 'NULL' || $default === null) {
            return null;
        }

        // Remove quotes
        if (is_string($default) && preg_match("/^'(.*)'$/", $default, $matches)) {
            return str_replace("''", "'", $matches[1]);
        }

        return $default;
    }


    function describeIndexSql(string myTableName, array myConfig): array
    {
        mySql = sprintf(
            'PRAGMA index_list(%s)',
            this._driver.quoteIdentifier(myTableName)
        );

        return [mySql, []];
    }

    /**
     * {@inheritDoc}
     *
     * Since SQLite does not have a way to get metadata about all indexes at once,
     * additional queries are done here. Sqlite constraint names are not
     * stable, and the names for constraints will not match those used to create
     * the table. This is a limitation in Sqlite's metadata features.
     *
     * @param \Cake\Database\Schema\TableSchema $schema The table object to append
     *    an index or constraint to.
     * @param array $row The row data from `describeIndexSql`.
     * @return void
     */
    function convertIndexDescription(TableSchema $schema, array $row): void
    {
        mySql = sprintf(
            'PRAGMA index_info(%s)',
            this._driver.quoteIdentifier($row['name'])
        );
        $statement = this._driver.prepare(mySql);
        $statement.execute();
        $columns = [];
        /** @psalm-suppress PossiblyFalseIterator */
        foreach ($statement.fetchAll('assoc') as $column) {
            $columns[] = $column['name'];
        }
        $statement.closeCursor();
        if ($row['unique']) {
            $schema.addConstraint($row['name'], [
                'type' => TableSchema::CONSTRAINT_UNIQUE,
                'columns' => $columns,
            ]);
        } else {
            $schema.addIndex($row['name'], [
                'type' => TableSchema::INDEX_INDEX,
                'columns' => $columns,
            ]);
        }
    }


    function describeForeignKeySql(string myTableName, array myConfig): array
    {
        mySql = sprintf('PRAGMA foreign_key_list(%s)', this._driver.quoteIdentifier(myTableName));

        return [mySql, []];
    }


    function convertForeignKeyDescription(TableSchema $schema, array $row): void
    {
        myName = $row['from'] . '_fk';

        $update = $row['on_update'] ?? '';
        $delete = $row['on_delete'] ?? '';
        myData = [
            'type' => TableSchema::CONSTRAINT_FOREIGN,
            'columns' => [$row['from']],
            'references' => [$row['table'], $row['to']],
            'update' => this._convertOnClause($update),
            'delete' => this._convertOnClause($delete),
        ];

        if (isset(this._constraintsIdMap[$schema.name()][$row['id']])) {
            myName = this._constraintsIdMap[$schema.name()][$row['id']];
        } else {
            this._constraintsIdMap[$schema.name()][$row['id']] = myName;
        }

        $schema.addConstraint(myName, myData);
    }

    /**
     * {@inheritDoc}
     *
     * @param \Cake\Database\Schema\TableSchema $schema The table instance the column is in.
     * @param string myName The name of the column.
     * @return string SQL fragment.
     * @throws \Cake\Database\Exception\DatabaseException when the column type is unknown
     */
    function columnSql(TableSchema $schema, string myName): string
    {
        /** @var array myData */
        myData = $schema.getColumn(myName);

        mySql = this._getTypeSpecificColumnSql(myData['type'], $schema, myName);
        if (mySql !== null) {
            return mySql;
        }

        myTypeMap = [
            TableSchema::TYPE_BINARY_UUID => ' BINARY(16)',
            TableSchema::TYPE_UUID => ' CHAR(36)',
            TableSchema::TYPE_CHAR => ' CHAR',
            TableSchema::TYPE_TINYINTEGER => ' TINYINT',
            TableSchema::TYPE_SMALLINTEGER => ' SMALLINT',
            TableSchema::TYPE_INTEGER => ' INTEGER',
            TableSchema::TYPE_BIGINTEGER => ' BIGINT',
            TableSchema::TYPE_BOOLEAN => ' BOOLEAN',
            TableSchema::TYPE_FLOAT => ' FLOAT',
            TableSchema::TYPE_DECIMAL => ' DECIMAL',
            TableSchema::TYPE_DATE => ' DATE',
            TableSchema::TYPE_TIME => ' TIME',
            TableSchema::TYPE_DATETIME => ' DATETIME',
            TableSchema::TYPE_DATETIME_FRACTIONAL => ' DATETIMEFRACTIONAL',
            TableSchema::TYPE_TIMESTAMP => ' TIMESTAMP',
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL => ' TIMESTAMPFRACTIONAL',
            TableSchema::TYPE_TIMESTAMP_TIMEZONE => ' TIMESTAMPTIMEZONE',
            TableSchema::TYPE_JSON => ' TEXT',
        ];

        $out = this._driver.quoteIdentifier(myName);
        $hasUnsigned = [
            TableSchema::TYPE_TINYINTEGER,
            TableSchema::TYPE_SMALLINTEGER,
            TableSchema::TYPE_INTEGER,
            TableSchema::TYPE_BIGINTEGER,
            TableSchema::TYPE_FLOAT,
            TableSchema::TYPE_DECIMAL,
        ];

        if (
            in_array(myData['type'], $hasUnsigned, true) &&
            isset(myData['unsigned']) &&
            myData['unsigned'] === true
        ) {
            if (myData['type'] !== TableSchema::TYPE_INTEGER || $schema.getPrimaryKey() !== [myName]) {
                $out .= ' UNSIGNED';
            }
        }

        if (isset(myTypeMap[myData['type']])) {
            $out .= myTypeMap[myData['type']];
        }

        if (myData['type'] === TableSchema::TYPE_TEXT && myData['length'] !== TableSchema::LENGTH_TINY) {
            $out .= ' TEXT';
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

            if (isset(myData['length'])) {
                $out .= '(' . myData['length'] . ')';
            }
        }

        if (myData['type'] === TableSchema::TYPE_BINARY) {
            if (isset(myData['length'])) {
                $out .= ' BLOB(' . myData['length'] . ')';
            } else {
                $out .= ' BLOB';
            }
        }

        $integerTypes = [
            TableSchema::TYPE_TINYINTEGER,
            TableSchema::TYPE_SMALLINTEGER,
            TableSchema::TYPE_INTEGER,
        ];
        if (
            in_array(myData['type'], $integerTypes, true) &&
            isset(myData['length']) &&
            $schema.getPrimaryKey() !== [myName]
        ) {
            $out .= '(' . (int)myData['length'] . ')';
        }

        $hasPrecision = [TableSchema::TYPE_FLOAT, TableSchema::TYPE_DECIMAL];
        if (
            in_array(myData['type'], $hasPrecision, true) &&
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

        if (myData['type'] === TableSchema::TYPE_INTEGER && $schema.getPrimaryKey() === [myName]) {
            $out .= ' PRIMARY KEY AUTOINCREMENT';
        }

        $timestampTypes = [
            TableSchema::TYPE_DATETIME,
            TableSchema::TYPE_DATETIME_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP,
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP_TIMEZONE,
        ];
        if (isset(myData['null']) && myData['null'] === true && in_array(myData['type'], $timestampTypes, true)) {
            $out .= ' DEFAULT NULL';
        }
        if (isset(myData['default'])) {
            $out .= ' DEFAULT ' . this._driver.schemaValue(myData['default']);
        }

        return $out;
    }

    /**
     * {@inheritDoc}
     *
     * Note integer primary keys will return ''. This is intentional as Sqlite requires
     * that integer primary keys be defined in the column definition.
     *
     * @param \Cake\Database\Schema\TableSchema $schema The table instance the column is in.
     * @param string myName The name of the column.
     * @return string SQL fragment.
     */
    function constraintSql(TableSchema $schema, string myName): string
    {
        /** @var array myData */
        myData = $schema.getConstraint(myName);
        /** @psalm-suppress PossiblyNullArrayAccess */
        if (
            myData['type'] === TableSchema::CONSTRAINT_PRIMARY &&
            count(myData['columns']) === 1 &&
            $schema.getColumn(myData['columns'][0])['type'] === TableSchema::TYPE_INTEGER
        ) {
            return '';
        }
        $clause = '';
        myType = '';
        if (myData['type'] === TableSchema::CONSTRAINT_PRIMARY) {
            myType = 'PRIMARY KEY';
        }
        if (myData['type'] === TableSchema::CONSTRAINT_UNIQUE) {
            myType = 'UNIQUE';
        }
        if (myData['type'] === TableSchema::CONSTRAINT_FOREIGN) {
            myType = 'FOREIGN KEY';

            $clause = sprintf(
                ' REFERENCES %s (%s) ON UPDATE %s ON DELETE %s',
                this._driver.quoteIdentifier(myData['references'][0]),
                this._convertConstraintColumns(myData['references'][1]),
                this._foreignOnClause(myData['update']),
                this._foreignOnClause(myData['delete'])
            );
        }
        $columns = array_map(
            [this._driver, 'quoteIdentifier'],
            myData['columns']
        );

        return sprintf(
            'CONSTRAINT %s %s (%s)%s',
            this._driver.quoteIdentifier(myName),
            myType,
            implode(', ', $columns),
            $clause
        );
    }

    /**
     * {@inheritDoc}
     *
     * SQLite can not properly handle adding a constraint to an existing table.
     * This method is no-op
     *
     * @param \Cake\Database\Schema\TableSchema $schema The table instance the foreign key constraints are.
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
     * @param \Cake\Database\Schema\TableSchema $schema The table instance the foreign key constraints are.
     * @return array SQL fragment.
     */
    function dropConstraintSql(TableSchema $schema): array
    {
        return [];
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


    function createTableSql(TableSchema $schema, array $columns, array $constraints, array $indexes): array
    {
        $lines = array_merge($columns, $constraints);
        myContents = implode(",\n", array_filter($lines));
        $temporary = $schema.isTemporary() ? ' TEMPORARY ' : ' ';
        myTable = sprintf("CREATE%sTABLE \"%s\" (\n%s\n)", $temporary, $schema.name(), myContents);
        $out = [myTable];
        foreach ($indexes as $index) {
            $out[] = $index;
        }

        return $out;
    }


    function truncateTableSql(TableSchema $schema): array
    {
        myName = $schema.name();
        mySql = [];
        if (this.hasSequences()) {
            mySql[] = sprintf('DELETE FROM sqlite_sequence WHERE name="%s"', myName);
        }

        mySql[] = sprintf('DELETE FROM "%s"', myName);

        return mySql;
    }

    /**
     * Returns whether there is any table in this connection to SQLite containing
     * sequences
     */
    bool hasSequences()
    {
        myResult = this._driver.prepare(
            'SELECT 1 FROM sqlite_master WHERE name = "sqlite_sequence"'
        );
        myResult.execute();
        this._hasSequences = (bool)myResult.rowCount();
        myResult.closeCursor();

        return this._hasSequences;
    }
}

// phpcs:disable
// Add backwards compatible alias.
class_alias('Cake\Database\Schema\SqliteSchemaDialect', 'Cake\Database\Schema\SqliteSchema');
// phpcs:enable
