


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Driver;

import uim.cake.databases.Driver;
import uim.cake.databases.Expression\FunctionExpression;
import uim.cake.databases.Expression\OrderByExpression;
import uim.cake.databases.Expression\OrderClauseExpression;
import uim.cake.databases.Expression\TupleComparison;
import uim.cake.databases.Expression\UnaryExpression;
import uim.cake.databases.IExpression;
import uim.cake.databases.Query;
import uim.cake.databases.QueryCompiler;
import uim.cake.databases.schemas.SchemaDialect;
import uim.cake.databases.schemas.SqlserverSchemaDialect;
import uim.cake.databases.SqlserverCompiler;
import uim.cake.databases.Statement\SqlserverStatement;
import uim.cake.databases.StatementInterface;
use InvalidArgumentException;
use PDO;

/**
 * SQLServer driver.
 */
class Sqlserver : Driver
{
    use SqlDialectTrait;
    use TupleComparisonTranslatorTrait;

    /**
     * @inheritDoc
     */
    protected const MAX_ALIAS_LENGTH = 128;

    /**
     * @inheritDoc
     */
    protected const RETRY_ERROR_CODES = [
        40613, // Azure Sql Database paused
    ];

    /**
     * Base configuration settings for Sqlserver driver
     *
     * @var array<string, mixed>
     */
    protected $_baseConfig = [
        'host': 'localhost\SQLEXPRESS',
        'username': '',
        'password': '',
        'database': 'cake',
        'port': '',
        // PDO::SQLSRV_ENCODING_UTF8
        'encoding': 65001,
        'flags': [],
        'init': [],
        'settings': [],
        'attributes': [],
        'app': null,
        'connectionPooling': null,
        'failoverPartner': null,
        'loginTimeout': null,
        'multiSubnetFailover': null,
        'encrypt': null,
        'trustServerCertificate': null,
    ];

    /**
     * The schema dialect class for this driver
     *
     * @var \Cake\Database\Schema\SqlserverSchemaDialect|null
     */
    protected $_schemaDialect;

    /**
     * String used to start a database identifier quoting to make it safe
     *
     * @var string
     */
    protected $_startQuote = '[';

    /**
     * String used to end a database identifier quoting to make it safe
     *
     * @var string
     */
    protected $_endQuote = ']';

    /**
     * Establishes a connection to the database server.
     *
     * Please note that the PDO::ATTR_PERSISTENT attribute is not supported by
     * the SQL Server PHP PDO drivers.  As a result you cannot use the
     * persistent config option when connecting to a SQL Server  (for more
     * information see: https://github.com/Microsoft/msphpsql/issues/65).
     *
     * @throws \InvalidArgumentException if an unsupported setting is in the driver config
     * @return bool true on success
     */
    function connect(): bool
    {
        if (_connection) {
            return true;
        }
        $config = _config;

        if (isset($config['persistent']) && $config['persistent']) {
            throw new InvalidArgumentException(
                'Config setting "persistent" cannot be set to true, '
                . 'as the Sqlserver PDO driver does not support PDO::ATTR_PERSISTENT'
            );
        }

        $config['flags'] += [
            PDO::ATTR_ERRMODE: PDO::ERRMODE_EXCEPTION,
        ];

        if (!empty($config['encoding'])) {
            $config['flags'][PDO::SQLSRV_ATTR_ENCODING] = $config['encoding'];
        }
        $port = '';
        if ($config['port']) {
            $port = ',' . $config['port'];
        }

        $dsn = "sqlsrv:Server={$config['host']}{$port};Database={$config['database']};MultipleActiveResultSets=false";
        if ($config['app'] != null) {
            $dsn .= ";APP={$config['app']}";
        }
        if ($config['connectionPooling'] != null) {
            $dsn .= ";ConnectionPooling={$config['connectionPooling']}";
        }
        if ($config['failoverPartner'] != null) {
            $dsn .= ";Failover_Partner={$config['failoverPartner']}";
        }
        if ($config['loginTimeout'] != null) {
            $dsn .= ";LoginTimeout={$config['loginTimeout']}";
        }
        if ($config['multiSubnetFailover'] != null) {
            $dsn .= ";MultiSubnetFailover={$config['multiSubnetFailover']}";
        }
        if ($config['encrypt'] != null) {
            $dsn .= ";Encrypt={$config['encrypt']}";
        }
        if ($config['trustServerCertificate'] != null) {
            $dsn .= ";TrustServerCertificate={$config['trustServerCertificate']}";
        }
        _connect($dsn, $config);

        $connection = this.getConnection();
        if (!empty($config['init'])) {
            foreach ((array)$config['init'] as $command) {
                $connection.exec($command);
            }
        }
        if (!empty($config['settings']) && is_array($config['settings'])) {
            foreach ($config['settings'] as $key: $value) {
                $connection.exec("SET {$key} {$value}");
            }
        }
        if (!empty($config['attributes']) && is_array($config['attributes'])) {
            foreach ($config['attributes'] as $key: $value) {
                $connection.setAttribute($key, $value);
            }
        }

        return true;
    }

    /**
     * Returns whether PHP is able to use this driver for connecting to database
     *
     * @return bool true if it is valid to use this driver
     */
    function enabled(): bool
    {
        return in_array('sqlsrv', PDO::getAvailableDrivers(), true);
    }

    /**
     * Prepares a sql statement to be executed
     *
     * @param \Cake\Database\Query|string $query The query to prepare.
     * @return \Cake\Database\StatementInterface
     */
    function prepare($query): StatementInterface
    {
        this.connect();

        $sql = $query;
        $options = [
            PDO::ATTR_CURSOR: PDO::CURSOR_SCROLL,
            PDO::SQLSRV_ATTR_CURSOR_SCROLL_TYPE: PDO::SQLSRV_CURSOR_BUFFERED,
        ];
        if ($query instanceof Query) {
            $sql = $query.sql();
            if (count($query.getValueBinder().bindings()) > 2100) {
                throw new InvalidArgumentException(
                    'Exceeded maximum number of parameters (2100) for prepared statements in Sql Server. ' .
                    'This is probably due to a very large WHERE IN () clause which generates a parameter ' .
                    'for each value in the array. ' .
                    'If using an Association, try changing the `strategy` from select to subquery.'
                );
            }

            if (!$query.isBufferedResultsEnabled()) {
                $options = [];
            }
        }

        /** @psalm-suppress PossiblyInvalidArgument */
        $statement = _connection.prepare($sql, $options);

        return new SqlserverStatement($statement, this);
    }

    /**
     * @inheritDoc
     */
    function savePointSQL($name): string
    {
        return 'SAVE TRANSACTION t' . $name;
    }

    /**
     * @inheritDoc
     */
    function releaseSavePointSQL($name): string
    {
        // SQLServer has no release save point operation.
        return '';
    }

    /**
     * @inheritDoc
     */
    function rollbackSavePointSQL($name): string
    {
        return 'ROLLBACK TRANSACTION t' . $name;
    }

    /**
     * @inheritDoc
     */
    function disableForeignKeySQL(): string
    {
        return 'EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"';
    }

    /**
     * @inheritDoc
     */
    function enableForeignKeySQL(): string
    {
        return 'EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"';
    }

    /**
     * @inheritDoc
     */
    function supports(string $feature): bool
    {
        switch ($feature) {
            case static::FEATURE_CTE:
            case static::FEATURE_TRUNCATE_WITH_CONSTRAINTS:
            case static::FEATURE_WINDOW:
                return true;

            case static::FEATURE_QUOTE:
                this.connect();

                return _connection.getAttribute(PDO::ATTR_DRIVER_NAME) != 'odbc';
        }

        return parent::supports($feature);
    }

    /**
     * @inheritDoc
     */
    function supportsDynamicConstraints(): bool
    {
        return true;
    }

    /**
     * @inheritDoc
     */
    function schemaDialect(): SchemaDialect
    {
        if (_schemaDialect == null) {
            _schemaDialect = new SqlserverSchemaDialect(this);
        }

        return _schemaDialect;
    }

    /**
     * {@inheritDoc}
     *
     * @return \Cake\Database\SqlserverCompiler
     */
    function newCompiler(): QueryCompiler
    {
        return new SqlserverCompiler();
    }

    /**
     * @inheritDoc
     */
    protected function _selectQueryTranslator(Query $query): Query
    {
        $limit = $query.clause('limit');
        $offset = $query.clause('offset');

        if ($limit && $offset == null) {
            $query.modifier(['_auto_top_': sprintf('TOP %d', $limit)]);
        }

        if ($offset != null && !$query.clause('order')) {
            $query.order($query.newExpr().add('(SELECT NULL)'));
        }

        if (this.version() < 11 && $offset != null) {
            return _pagingSubquery($query, $limit, $offset);
        }

        return _transformDistinct($query);
    }

    /**
     * Generate a paging subquery for older versions of SQLserver.
     *
     * Prior to SQLServer 2012 there was no equivalent to LIMIT OFFSET, so a subquery must
     * be used.
     *
     * @param \Cake\Database\Query $original The query to wrap in a subquery.
     * @param int|null $limit The number of rows to fetch.
     * @param int|null $offset The number of rows to offset.
     * @return \Cake\Database\Query Modified query object.
     */
    protected function _pagingSubquery(Query $original, ?int $limit, ?int $offset): Query
    {
        $field = '_cake_paging_._cake_page_rownum_';

        if ($original.clause('order')) {
            // SQL server does not support column aliases in OVER clauses.  But
            // the only practical way to specify the use of calculated columns
            // is with their alias.  So substitute the select SQL in place of
            // any column aliases for those entries in the order clause.
            $select = $original.clause('select');
            $order = new OrderByExpression();
            $original
                .clause('order')
                .iterateParts(function ($direction, $orderBy) use ($select, $order) {
                    $key = $orderBy;
                    if (
                        isset($select[$orderBy]) &&
                        $select[$orderBy] instanceof IExpression
                    ) {
                        $order.add(new OrderClauseExpression($select[$orderBy], $direction));
                    } else {
                        $order.add([$key: $direction]);
                    }

                    // Leave original order clause unchanged.
                    return $orderBy;
                });
        } else {
            $order = new OrderByExpression('(SELECT NULL)');
        }

        $query = clone $original;
        $query.select([
                '_cake_page_rownum_': new UnaryExpression('ROW_NUMBER() OVER', $order),
            ]).limit(null)
            .offset(null)
            .order([], true);

        $outer = new Query($query.getConnection());
        $outer.select('*')
            .from(['_cake_paging_': $query]);

        if ($offset) {
            $outer.where(["$field > " . $offset]);
        }
        if ($limit) {
            $value = (int)$offset + $limit;
            $outer.where(["$field <= $value"]);
        }

        // Decorate the original query as that is what the
        // end developer will be calling execute() on originally.
        $original.decorateResults(function ($row) {
            if (isset($row['_cake_page_rownum_'])) {
                unset($row['_cake_page_rownum_']);
            }

            return $row;
        });

        return $outer;
    }

    /**
     * @inheritDoc
     */
    protected function _transformDistinct(Query $query): Query
    {
        if (!is_array($query.clause('distinct'))) {
            return $query;
        }

        $original = $query;
        $query = clone $original;

        $distinct = $query.clause('distinct');
        $query.distinct(false);

        $order = new OrderByExpression($distinct);
        $query
            .select(function ($q) use ($distinct, $order) {
                $over = $q.newExpr('ROW_NUMBER() OVER')
                    .add('(PARTITION BY')
                    .add($q.newExpr().add($distinct).setConjunction(','))
                    .add($order)
                    .add(')')
                    .setConjunction(' ');

                return [
                    '_cake_distinct_pivot_': $over,
                ];
            })
            .limit(null)
            .offset(null)
            .order([], true);

        $outer = new Query($query.getConnection());
        $outer.select('*')
            .from(['_cake_distinct_': $query])
            .where(['_cake_distinct_pivot_': 1]);

        // Decorate the original query as that is what the
        // end developer will be calling execute() on originally.
        $original.decorateResults(function ($row) {
            if (isset($row['_cake_distinct_pivot_'])) {
                unset($row['_cake_distinct_pivot_']);
            }

            return $row;
        });

        return $outer;
    }

    /**
     * @inheritDoc
     */
    protected function _expressionTranslators(): array
    {
        return [
            FunctionExpression::class: '_transformFunctionExpression',
            TupleComparison::class: '_transformTupleComparison',
        ];
    }

    /**
     * Receives a FunctionExpression and changes it so that it conforms to this
     * SQL dialect.
     *
     * @param \Cake\Database\Expression\FunctionExpression $expression The function expression to convert to TSQL.
     * @return void
     */
    protected function _transformFunctionExpression(FunctionExpression $expression): void
    {
        switch ($expression.getName()) {
            case 'CONCAT':
                // CONCAT function is expressed as exp1 + exp2
                $expression.setName('').setConjunction(' +');
                break;
            case 'DATEDIFF':
                /** @var bool $hasDay */
                $hasDay = false;
                $visitor = function ($value) use (&$hasDay) {
                    if ($value == 'day') {
                        $hasDay = true;
                    }

                    return $value;
                };
                $expression.iterateParts($visitor);

                if (!$hasDay) {
                    $expression.add(['day': 'literal'], [], true);
                }
                break;
            case 'CURRENT_DATE':
                $time = new FunctionExpression('GETUTCDATE');
                $expression.setName('CONVERT').add(['date': 'literal', $time]);
                break;
            case 'CURRENT_TIME':
                $time = new FunctionExpression('GETUTCDATE');
                $expression.setName('CONVERT').add(['time': 'literal', $time]);
                break;
            case 'NOW':
                $expression.setName('GETUTCDATE');
                break;
            case 'EXTRACT':
                $expression.setName('DATEPART').setConjunction(' ,');
                break;
            case 'DATE_ADD':
                $params = [];
                $visitor = function ($p, $key) use (&$params) {
                    if ($key == 0) {
                        $params[2] = $p;
                    } else {
                        $valueUnit = explode(' ', $p);
                        $params[0] = rtrim($valueUnit[1], 's');
                        $params[1] = $valueUnit[0];
                    }

                    return $p;
                };
                $manipulator = function ($p, $key) use (&$params) {
                    return $params[$key];
                };

                $expression
                    .setName('DATEADD')
                    .setConjunction(',')
                    .iterateParts($visitor)
                    .iterateParts($manipulator)
                    .add([$params[2]: 'literal']);
                break;
            case 'DAYOFWEEK':
                $expression
                    .setName('DATEPART')
                    .setConjunction(' ')
                    .add(['weekday, ': 'literal'], [], true);
                break;
            case 'SUBSTR':
                $expression.setName('SUBSTRING');
                if (count($expression) < 4) {
                    $params = [];
                    $expression
                        .iterateParts(function ($p) use (&$params) {
                            return $params[] = $p;
                        })
                        .add([new FunctionExpression('LEN', [$params[0]]), ['string']]);
                }

                break;
        }
    }
}
