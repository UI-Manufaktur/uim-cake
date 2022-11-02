module uim.cake.databases.Schema;

import uim.cake.databases.IDriver;
import uim.cake.databases.exceptions\DatabaseException;

/**
 * Schema generation/reflection features for MySQL
 *
 * @internal
 */
class MysqlSchemaDialect : SchemaDialect
{
    /**
     * The driver instance being used.
     *
     * @var \Cake\Database\Driver\Mysql
     */
    protected $_driver;


    function listTablesSql(array myConfig): array
    {
        return ['SHOW TABLES FROM ' . this._driver.quoteIdentifier(myConfig['database']), []];
    }


    function describeColumnSql(string myTableName, array myConfig): array
    {
        return ['SHOW FULL COLUMNS FROM ' . this._driver.quoteIdentifier(myTableName), []];
    }


    function describeIndexSql(string myTableName, array myConfig): array
    {
        return ['SHOW INDEXES FROM ' . this._driver.quoteIdentifier(myTableName), []];
    }


    function describeOptionsSql(string myTableName, array myConfig): array
    {
        return ['SHOW TABLE STATUS WHERE Name = ?', [myTableName]];
    }


    function convertOptionsDescription(TableSchema $schema, array $row): void
    {
        $schema.setOptions([
            'engine' => $row['Engine'],
            'collation' => $row['Collation'],
        ]);
    }

    /**
     * Convert a MySQL column type into an abstract type.
     *
     * The returned type will be a type that Cake\Database\TypeFactory can handle.
     *
     * @param string $column The column type + length
     * @return array<string, mixed> Array of column information.
     * @throws \Cake\Database\Exception\DatabaseException When column type cannot be parsed.
     */
    protected auto _convertColumn(string $column): array
    {
        preg_match('/([a-z]+)(?:\(([0-9,]+)\))?\s*([a-z]+)?/i', $column, $matches);
        if (empty($matches)) {
            throw new DatabaseException(sprintf('Unable to parse column type from "%s"', $column));
        }

        $col = strtolower($matches[1]);
        $length = $precision = $scale = null;
        if (isset($matches[2]) && strlen($matches[2])) {
            $length = $matches[2];
            if (strpos($matches[2], ',') !== false) {
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

        if (in_array($col, ['date', 'time'])) {
            return ['type' => $col, 'length' => null];
        }
        if (in_array($col, ['datetime', 'timestamp'])) {
            myTypeName = $col;
            if ($length > 0) {
                myTypeName = $col . 'fractional';
            }

            return ['type' => myTypeName, 'length' => null, 'precision' => $length];
        }

        if (($col === 'tinyint' && $length === 1) || $col === 'boolean') {
            return ['type' => TableSchema::TYPE_BOOLEAN, 'length' => null];
        }

        $unsigned = (isset($matches[3]) && strtolower($matches[3]) === 'unsigned');
        if (strpos($col, 'bigint') !== false || $col === 'bigint') {
            return ['type' => TableSchema::TYPE_BIGINTEGER, 'length' => null, 'unsigned' => $unsigned];
        }
        if ($col === 'tinyint') {
            return ['type' => TableSchema::TYPE_TINYINTEGER, 'length' => null, 'unsigned' => $unsigned];
        }
        if ($col === 'smallint') {
            return ['type' => TableSchema::TYPE_SMALLINTEGER, 'length' => null, 'unsigned' => $unsigned];
        }
        if (in_array($col, ['int', 'integer', 'mediumint'])) {
            return ['type' => TableSchema::TYPE_INTEGER, 'length' => null, 'unsigned' => $unsigned];
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
        if (strpos($col, 'text') !== false) {
            $lengthName = substr($col, 0, -4);
            $length = TableSchema::$columnLengths[$lengthName] ?? null;

            return ['type' => TableSchema::TYPE_TEXT, 'length' => $length];
        }
        if ($col === 'binary' && $length === 16) {
            return ['type' => TableSchema::TYPE_BINARY_UUID, 'length' => null];
        }
        if (strpos($col, 'blob') !== false || in_array($col, ['binary', 'varbinary'])) {
            $lengthName = substr($col, 0, -4);
            $length = TableSchema::$columnLengths[$lengthName] ?? $length;

            return ['type' => TableSchema::TYPE_BINARY, 'length' => $length];
        }
        if (strpos($col, 'float') !== false || strpos($col, 'double') !== false) {
            return [
                'type' => TableSchema::TYPE_FLOAT,
                'length' => $length,
                'precision' => $precision,
                'unsigned' => $unsigned,
            ];
        }
        if (strpos($col, 'decimal') !== false) {
            return [
                'type' => TableSchema::TYPE_DECIMAL,
                'length' => $length,
                'precision' => $precision,
                'unsigned' => $unsigned,
            ];
        }

        if (strpos($col, 'json') !== false) {
            return ['type' => TableSchema::TYPE_JSON, 'length' => null];
        }

        return ['type' => TableSchema::TYPE_STRING, 'length' => null];
    }


    function convertColumnDescription(TableSchema $schema, array $row): void
    {
        myField = this._convertColumn($row['Type']);
        myField += [
            'null' => $row['Null'] === 'YES',
            'default' => $row['Default'],
            'collate' => $row['Collation'],
            'comment' => $row['Comment'],
        ];
        if (isset($row['Extra']) && $row['Extra'] === 'auto_increment') {
            myField['autoIncrement'] = true;
        }
        $schema.addColumn($row['Field'], myField);
    }


    function convertIndexDescription(TableSchema $schema, array $row): void
    {
        myType = null;
        $columns = $length = [];

        myName = $row['Key_name'];
        if (myName === 'PRIMARY') {
            myName = myType = TableSchema::CONSTRAINT_PRIMARY;
        }

        $columns[] = $row['Column_name'];

        if ($row['Index_type'] === 'FULLTEXT') {
            myType = TableSchema::INDEX_FULLTEXT;
        } elseif ((int)$row['Non_unique'] === 0 && myType !== 'primary') {
            myType = TableSchema::CONSTRAINT_UNIQUE;
        } elseif (myType !== 'primary') {
            myType = TableSchema::INDEX_INDEX;
        }

        if (!empty($row['Sub_part'])) {
            $length[$row['Column_name']] = $row['Sub_part'];
        }
        $isIndex = (
            myType === TableSchema::INDEX_INDEX ||
            myType === TableSchema::INDEX_FULLTEXT
        );
        if ($isIndex) {
            $existing = $schema.getIndex(myName);
        } else {
            $existing = $schema.getConstraint(myName);
        }

        // MySQL multi column indexes come back as multiple rows.
        if (!empty($existing)) {
            $columns = array_merge($existing['columns'], $columns);
            $length = array_merge($existing['length'], $length);
        }
        if ($isIndex) {
            $schema.addIndex(myName, [
                'type' => myType,
                'columns' => $columns,
                'length' => $length,
            ]);
        } else {
            $schema.addConstraint(myName, [
                'type' => myType,
                'columns' => $columns,
                'length' => $length,
            ]);
        }
    }


    function describeForeignKeySql(string myTableName, array myConfig): array
    {
        mySql = 'SELECT * FROM information_schema.key_column_usage AS kcu
            INNER JOIN information_schema.referential_constraints AS rc
            ON (
                kcu.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
                AND kcu.CONSTRAINT_SCHEMA = rc.CONSTRAINT_SCHEMA
            )
            WHERE kcu.TABLE_SCHEMA = ? AND kcu.TABLE_NAME = ? AND rc.TABLE_NAME = ?
            ORDER BY kcu.ORDINAL_POSITION ASC';

        return [mySql, [myConfig['database'], myTableName, myTableName]];
    }


    function convertForeignKeyDescription(TableSchema $schema, array $row): void
    {
        myData = [
            'type' => TableSchema::CONSTRAINT_FOREIGN,
            'columns' => [$row['COLUMN_NAME']],
            'references' => [$row['REFERENCED_TABLE_NAME'], $row['REFERENCED_COLUMN_NAME']],
            'update' => this._convertOnClause($row['UPDATE_RULE']),
            'delete' => this._convertOnClause($row['DELETE_RULE']),
        ];
        myName = $row['CONSTRAINT_NAME'];
        $schema.addConstraint(myName, myData);
    }


    function truncateTableSql(TableSchema $schema): array
    {
        return [sprintf('TRUNCATE TABLE `%s`', $schema.name())];
    }


    function createTableSql(TableSchema $schema, array $columns, array $constraints, array $indexes): array
    {
        myContents = implode(",\n", array_merge($columns, $constraints, $indexes));
        $temporary = $schema.isTemporary() ? ' TEMPORARY ' : ' ';
        myContents = sprintf("CREATE%sTABLE `%s` (\n%s\n)", $temporary, $schema.name(), myContents);
        myOptions = $schema.getOptions();
        if (isset(myOptions['engine'])) {
            myContents .= sprintf(' ENGINE=%s', myOptions['engine']);
        }
        if (isset(myOptions['charset'])) {
            myContents .= sprintf(' DEFAULT CHARSET=%s', myOptions['charset']);
        }
        if (isset(myOptions['collate'])) {
            myContents .= sprintf(' COLLATE=%s', myOptions['collate']);
        }

        return [myContents];
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
        $nativeJson = this._driver.supports(IDriver::FEATURE_JSON);

        myTypeMap = [
            TableSchema::TYPE_TINYINTEGER => ' TINYINT',
            TableSchema::TYPE_SMALLINTEGER => ' SMALLINT',
            TableSchema::TYPE_INTEGER => ' INTEGER',
            TableSchema::TYPE_BIGINTEGER => ' BIGINT',
            TableSchema::TYPE_BINARY_UUID => ' BINARY(16)',
            TableSchema::TYPE_BOOLEAN => ' BOOLEAN',
            TableSchema::TYPE_FLOAT => ' FLOAT',
            TableSchema::TYPE_DECIMAL => ' DECIMAL',
            TableSchema::TYPE_DATE => ' DATE',
            TableSchema::TYPE_TIME => ' TIME',
            TableSchema::TYPE_DATETIME => ' DATETIME',
            TableSchema::TYPE_DATETIME_FRACTIONAL => ' DATETIME',
            TableSchema::TYPE_TIMESTAMP => ' TIMESTAMP',
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL => ' TIMESTAMP',
            TableSchema::TYPE_TIMESTAMP_TIMEZONE => ' TIMESTAMP',
            TableSchema::TYPE_CHAR => ' CHAR',
            TableSchema::TYPE_UUID => ' CHAR(36)',
            TableSchema::TYPE_JSON => $nativeJson ? ' JSON' : ' LONGTEXT',
        ];
        $specialMap = [
            'string' => true,
            'text' => true,
            'char' => true,
            'binary' => true,
        ];
        if (isset(myTypeMap[myData['type']])) {
            $out .= myTypeMap[myData['type']];
        }
        if (isset($specialMap[myData['type']])) {
            switch (myData['type']) {
                case TableSchema::TYPE_STRING:
                    $out .= ' VARCHAR';
                    if (!isset(myData['length'])) {
                        myData['length'] = 255;
                    }
                    break;
                case TableSchema::TYPE_TEXT:
                    $isKnownLength = in_array(myData['length'], TableSchema::$columnLengths);
                    if (empty(myData['length']) || !$isKnownLength) {
                        $out .= ' TEXT';
                        break;
                    }

                    /** @var string $length */
                    $length = array_search(myData['length'], TableSchema::$columnLengths);
                    $out .= ' ' . strtoupper($length) . 'TEXT';

                    break;
                case TableSchema::TYPE_BINARY:
                    $isKnownLength = in_array(myData['length'], TableSchema::$columnLengths);
                    if ($isKnownLength) {
                        /** @var string $length */
                        $length = array_search(myData['length'], TableSchema::$columnLengths);
                        $out .= ' ' . strtoupper($length) . 'BLOB';
                        break;
                    }

                    if (empty(myData['length'])) {
                        $out .= ' BLOB';
                        break;
                    }

                    if (myData['length'] > 2) {
                        $out .= ' VARBINARY(' . myData['length'] . ')';
                    } else {
                        $out .= ' BINARY(' . myData['length'] . ')';
                    }
                    break;
            }
        }
        $hasLength = [
            TableSchema::TYPE_INTEGER,
            TableSchema::TYPE_CHAR,
            TableSchema::TYPE_SMALLINTEGER,
            TableSchema::TYPE_TINYINTEGER,
            TableSchema::TYPE_STRING,
        ];
        if (in_array(myData['type'], $hasLength, true) && isset(myData['length'])) {
            $out .= '(' . myData['length'] . ')';
        }

        $lengthAndPrecisionTypes = [TableSchema::TYPE_FLOAT, TableSchema::TYPE_DECIMAL];
        if (in_array(myData['type'], $lengthAndPrecisionTypes, true) && isset(myData['length'])) {
            if (isset(myData['precision'])) {
                $out .= '(' . (int)myData['length'] . ',' . (int)myData['precision'] . ')';
            } else {
                $out .= '(' . (int)myData['length'] . ')';
            }
        }

        $precisionTypes = [TableSchema::TYPE_DATETIME_FRACTIONAL, TableSchema::TYPE_TIMESTAMP_FRACTIONAL];
        if (in_array(myData['type'], $precisionTypes, true) && isset(myData['precision'])) {
            $out .= '(' . (int)myData['precision'] . ')';
        }

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
            $out .= ' UNSIGNED';
        }

        $hasCollate = [
            TableSchema::TYPE_TEXT,
            TableSchema::TYPE_CHAR,
            TableSchema::TYPE_STRING,
        ];
        if (in_array(myData['type'], $hasCollate, true) && isset(myData['collate']) && myData['collate'] !== '') {
            $out .= ' COLLATE ' . myData['collate'];
        }

        if (isset(myData['null']) && myData['null'] === false) {
            $out .= ' NOT NULL';
        }
        $addAutoIncrement = (
            $schema.getPrimaryKey() === [myName] &&
            !$schema.hasAutoincrement() &&
            !isset(myData['autoIncrement'])
        );
        if (
            in_array(myData['type'], [TableSchema::TYPE_INTEGER, TableSchema::TYPE_BIGINTEGER]) &&
            (
                myData['autoIncrement'] === true ||
                $addAutoIncrement
            )
        ) {
            $out .= ' AUTO_INCREMENT';
        }

        $timestampTypes = [
            TableSchema::TYPE_TIMESTAMP,
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP_TIMEZONE,
        ];
        if (isset(myData['null']) && myData['null'] === true && in_array(myData['type'], $timestampTypes, true)) {
            $out .= ' NULL';
            unset(myData['default']);
        }

        $dateTimeTypes = [
            TableSchema::TYPE_DATETIME,
            TableSchema::TYPE_DATETIME_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP,
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP_TIMEZONE,
        ];
        if (
            isset(myData['default']) &&
            in_array(myData['type'], $dateTimeTypes) &&
            strpos(strtolower(myData['default']), 'current_timestamp') !== false
        ) {
            $out .= ' DEFAULT CURRENT_TIMESTAMP';
            if (isset(myData['precision'])) {
                $out .= '(' . myData['precision'] . ')';
            }
            unset(myData['default']);
        }
        if (isset(myData['default'])) {
            $out .= ' DEFAULT ' . this._driver.schemaValue(myData['default']);
            unset(myData['default']);
        }
        if (isset(myData['comment']) && myData['comment'] !== '') {
            $out .= ' COMMENT ' . this._driver.schemaValue(myData['comment']);
        }

        return $out;
    }


    function constraintSql(TableSchema $schema, string myName): string
    {
        /** @var array myData */
        myData = $schema.getConstraint(myName);
        if (myData['type'] === TableSchema::CONSTRAINT_PRIMARY) {
            $columns = array_map(
                [this._driver, 'quoteIdentifier'],
                myData['columns']
            );

            return sprintf('PRIMARY KEY (%s)', implode(', ', $columns));
        }

        $out = '';
        if (myData['type'] === TableSchema::CONSTRAINT_UNIQUE) {
            $out = 'UNIQUE KEY ';
        }
        if (myData['type'] === TableSchema::CONSTRAINT_FOREIGN) {
            $out = 'CONSTRAINT ';
        }
        $out .= this._driver.quoteIdentifier(myName);

        return this._keySql($out, myData);
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
        mySqlPattern = 'ALTER TABLE %s DROP FOREIGN KEY %s;';
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
        $out = '';
        if (myData['type'] === TableSchema::INDEX_INDEX) {
            $out = 'KEY ';
        }
        if (myData['type'] === TableSchema::INDEX_FULLTEXT) {
            $out = 'FULLTEXT KEY ';
        }
        $out .= this._driver.quoteIdentifier(myName);

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
        foreach (myData['columns'] as $i => $column) {
            if (isset(myData['length'][$column])) {
                $columns[$i] .= sprintf('(%d)', myData['length'][$column]);
            }
        }
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
}

// phpcs:disable
// Add backwards compatible alias.
class_alias('Cake\Database\Schema\MysqlSchemaDialect', 'Cake\Database\Schema\MysqlSchema');
// phpcs:enable
