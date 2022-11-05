module uim.baklava.databases.Driver;

import uim.baklava.databases.Driver;
import uim.baklava.databases.expressions\FunctionExpression;
import uim.baklava.databases.expressions\OrderByExpression;
import uim.baklava.databases.expressions\OrderClauseExpression;
import uim.baklava.databases.expressions\TupleComparison;
import uim.baklava.databases.expressions\UnaryExpression;
import uim.baklava.databases.IExpression;
import uim.baklava.databases.Query;
import uim.baklava.databases.QueryCompiler;
import uim.baklava.databases.Schema\SchemaDialect;
import uim.baklava.databases.Schema\SqlserverSchemaDialect;
import uim.baklava.databases.SqlserverCompiler;
import uim.baklava.databases.Statement\SqlserverStatement;
import uim.baklava.databases.IStatement;
use InvalidArgumentException;
use PDO;

/**
 * SQLServer driver.
 */
class Sqlserver : Driver
{
    use SqlDialectTrait;
    use TupleComparisonTranslatorTrait;


    protected const MAX_ALIAS_LENGTH = 128;


    protected const RETRY_ERROR_CODES = [
        40613, // Azure Sql Database paused
    ];

    /**
     * Base configuration settings for Sqlserver driver
     *
     * @var array<string, mixed>
     */
    protected $_baseConfig = [
        'host' => 'localhost\SQLEXPRESS',
        'username' => '',
        'password' => '',
        'database' => 'cake',
        'port' => '',
        // PDO::SQLSRV_ENCODING_UTF8
        'encoding' => 65001,
        'flags' => [],
        'init' => [],
        'settings' => [],
        'attributes' => [],
        'app' => null,
        'connectionPooling' => null,
        'failoverPartner' => null,
        'loginTimeout' => null,
        'multiSubnetFailover' => null,
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
    bool connect() {
        if (this._connection) {
            return true;
        }
        myConfig = this._config;

        if (isset(myConfig['persistent']) && myConfig['persistent']) {
            throw new InvalidArgumentException(
                'Config setting "persistent" cannot be set to true, '
                . 'as the Sqlserver PDO driver does not support PDO::ATTR_PERSISTENT'
            );
        }

        myConfig['flags'] += [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        ];

        if (!empty(myConfig['encoding'])) {
            myConfig['flags'][PDO::SQLSRV_ATTR_ENCODING] = myConfig['encoding'];
        }
        $port = '';
        if (myConfig['port']) {
            $port = ',' . myConfig['port'];
        }

        $dsn = "sqlsrv:Server={myConfig['host']}{$port};Database={myConfig['database']};MultipleActiveResultSets=false";
        if (myConfig['app'] !== null) {
            $dsn .= ";APP={myConfig['app']}";
        }
        if (myConfig['connectionPooling'] !== null) {
            $dsn .= ";ConnectionPooling={myConfig['connectionPooling']}";
        }
        if (myConfig['failoverPartner'] !== null) {
            $dsn .= ";Failover_Partner={myConfig['failoverPartner']}";
        }
        if (myConfig['loginTimeout'] !== null) {
            $dsn .= ";LoginTimeout={myConfig['loginTimeout']}";
        }
        if (myConfig['multiSubnetFailover'] !== null) {
            $dsn .= ";MultiSubnetFailover={myConfig['multiSubnetFailover']}";
        }
        this._connect($dsn, myConfig);

        myConnection = this.getConnection();
        if (!empty(myConfig['init'])) {
            foreach ((array)myConfig['init'] as $command) {
                myConnection.exec($command);
            }
        }
        if (!empty(myConfig['settings']) && is_array(myConfig['settings'])) {
            foreach (myConfig['settings'] as myKey => myValue) {
                myConnection.exec("SET {myKey} {myValue}");
            }
        }
        if (!empty(myConfig['attributes']) && is_array(myConfig['attributes'])) {
            foreach (myConfig['attributes'] as myKey => myValue) {
                myConnection.setAttribute(myKey, myValue);
            }
        }

        return true;
    }

    /**
     * Returns whether PHP is able to use this driver for connecting to database
     *
     * @return bool true if it is valid to use this driver
     */
    bool enabled() {
        return in_array('sqlsrv', PDO::getAvailableDrivers(), true);
    }

    /**
     * Prepares a sql statement to be executed
     *
     * @param \Cake\Database\Query|string myQuery The query to prepare.
     * @return \Cake\Database\IStatement
     */
    function prepare(myQuery): IStatement
    {
        this.connect();

        mySql = myQuery;
        myOptions = [
            PDO::ATTR_CURSOR => PDO::CURSOR_SCROLL,
            PDO::SQLSRV_ATTR_CURSOR_SCROLL_TYPE => PDO::SQLSRV_CURSOR_BUFFERED,
        ];
        if (myQuery instanceof Query) {
            mySql = myQuery.sql();
            if (count(myQuery.getValueBinder().bindings()) > 2100) {
                throw new InvalidArgumentException(
                    'Exceeded maximum number of parameters (2100) for prepared statements in Sql Server. ' .
                    'This is probably due to a very large WHERE IN () clause which generates a parameter ' .
                    'for each value in the array. ' .
                    'If using an Association, try changing the `strategy` from select to subquery.'
                );
            }

            if (!myQuery.isBufferedResultsEnabled()) {
                myOptions = [];
            }
        }

        /** @psalm-suppress PossiblyInvalidArgument */
        $statement = this._connection.prepare(mySql, myOptions);

        return new SqlserverStatement($statement, this);
    }


    function savePointSQL(myName): string
    {
        return 'SAVE TRANSACTION t' . myName;
    }


    function releaseSavePointSQL(myName): string
    {
        // SQLServer has no release save point operation.
        return '';
    }


    function rollbackSavePointSQL(myName): string
    {
        return 'ROLLBACK TRANSACTION t' . myName;
    }


    function disableForeignKeySQL(): string
    {
        return 'EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"';
    }


    function enableForeignKeySQL(): string
    {
        return 'EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"';
    }


    bool supports(string $feature) {
        switch ($feature) {
            case static::FEATURE_CTE:
            case static::FEATURE_TRUNCATE_WITH_CONSTRAINTS:
            case static::FEATURE_WINDOW:
                return true;

            case static::FEATURE_QUOTE:
                this.connect();

                return this._connection.getAttribute(PDO::ATTR_DRIVER_NAME) !== 'odbc';
        }

        return super.supports($feature);
    }


    bool supportsDynamicConstraints() {
        return true;
    }


    function schemaDialect(): SchemaDialect
    {
        if (this._schemaDialect === null) {
            this._schemaDialect = new SqlserverSchemaDialect(this);
        }

        return this._schemaDialect;
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


    protected auto _selectQueryTranslator(Query myQuery): Query
    {
        $limit = myQuery.clause('limit');
        $offset = myQuery.clause('offset');

        if ($limit && $offset === null) {
            myQuery.modifier(['_auto_top_' => sprintf('TOP %d', $limit)]);
        }

        if ($offset !== null && !myQuery.clause('order')) {
            myQuery.order(myQuery.newExpr().add('(SELECT NULL)'));
        }

        if (this.version() < 11 && $offset !== null) {
            return this._pagingSubquery(myQuery, $limit, $offset);
        }

        return this._transformDistinct(myQuery);
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
    protected auto _pagingSubquery(Query $original, Nullable!int $limit, Nullable!int $offset): Query
    {
        myField = '_cake_paging_._cake_page_rownum_';

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
                    myKey = $orderBy;
                    if (
                        isset($select[$orderBy]) &&
                        $select[$orderBy] instanceof IExpression
                    ) {
                        $order.add(new OrderClauseExpression($select[$orderBy], $direction));
                    } else {
                        $order.add([myKey => $direction]);
                    }

                    // Leave original order clause unchanged.
                    return $orderBy;
                });
        } else {
            $order = new OrderByExpression('(SELECT NULL)');
        }

        myQuery = clone $original;
        myQuery.select([
                '_cake_page_rownum_' => new UnaryExpression('ROW_NUMBER() OVER', $order),
            ]).limit(null)
            .offset(null)
            .order([], true);

        $outer = new Query(myQuery.getConnection());
        $outer.select('*')
            .from(['_cake_paging_' => myQuery]);

        if ($offset) {
            $outer.where(["myField > " . $offset]);
        }
        if ($limit) {
            myValue = (int)$offset + $limit;
            $outer.where(["myField <= myValue"]);
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


    protected auto _transformDistinct(Query myQuery): Query
    {
        if (!is_array(myQuery.clause('distinct'))) {
            return myQuery;
        }

        $original = myQuery;
        myQuery = clone $original;

        $distinct = myQuery.clause('distinct');
        myQuery.distinct(false);

        $order = new OrderByExpression($distinct);
        myQuery
            .select(function ($q) use ($distinct, $order) {
                $over = $q.newExpr('ROW_NUMBER() OVER')
                    .add('(PARTITION BY')
                    .add($q.newExpr().add($distinct).setConjunction(','))
                    .add($order)
                    .add(')')
                    .setConjunction(' ');

                return [
                    '_cake_distinct_pivot_' => $over,
                ];
            })
            .limit(null)
            .offset(null)
            .order([], true);

        $outer = new Query(myQuery.getConnection());
        $outer.select('*')
            .from(['_cake_distinct_' => myQuery])
            .where(['_cake_distinct_pivot_' => 1]);

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


    protected auto _expressionTranslators(): array
    {
        return [
            FunctionExpression::class => '_transformFunctionExpression',
            TupleComparison::class => '_transformTupleComparison',
        ];
    }

    /**
     * Receives a FunctionExpression and changes it so that it conforms to this
     * SQL dialect.
     *
     * @param \Cake\Database\Expression\FunctionExpression $expression The function expression to convert to TSQL.
     * @return void
     */
    protected auto _transformFunctionExpression(FunctionExpression $expression): void
    {
        switch ($expression.getName()) {
            case 'CONCAT':
                // CONCAT function is expressed as exp1 + exp2
                $expression.setName('').setConjunction(' +');
                break;
            case 'DATEDIFF':
                /** @var bool $hasDay */
                $hasDay = false;
                $visitor = function (myValue) use (&$hasDay) {
                    if (myValue === 'day') {
                        $hasDay = true;
                    }

                    return myValue;
                };
                $expression.iterateParts($visitor);

                if (!$hasDay) {
                    $expression.add(['day' => 'literal'], [], true);
                }
                break;
            case 'CURRENT_DATE':
                $time = new FunctionExpression('GETUTCDATE');
                $expression.setName('CONVERT').add(['date' => 'literal', $time]);
                break;
            case 'CURRENT_TIME':
                $time = new FunctionExpression('GETUTCDATE');
                $expression.setName('CONVERT').add(['time' => 'literal', $time]);
                break;
            case 'NOW':
                $expression.setName('GETUTCDATE');
                break;
            case 'EXTRACT':
                $expression.setName('DATEPART').setConjunction(' ,');
                break;
            case 'DATE_ADD':
                myParams = [];
                $visitor = function ($p, myKey) use (&myParams) {
                    if (myKey === 0) {
                        myParams[2] = $p;
                    } else {
                        myValueUnit = explode(' ', $p);
                        myParams[0] = rtrim(myValueUnit[1], 's');
                        myParams[1] = myValueUnit[0];
                    }

                    return $p;
                };
                $manipulator = function ($p, myKey) use (&myParams) {
                    return myParams[myKey];
                };

                $expression
                    .setName('DATEADD')
                    .setConjunction(',')
                    .iterateParts($visitor)
                    .iterateParts($manipulator)
                    .add([myParams[2] => 'literal']);
                break;
            case 'DAYOFWEEK':
                $expression
                    .setName('DATEPART')
                    .setConjunction(' ')
                    .add(['weekday, ' => 'literal'], [], true);
                break;
            case 'SUBSTR':
                $expression.setName('SUBSTRING');
                if (count($expression) < 4) {
                    myParams = [];
                    $expression
                        .iterateParts(function ($p) use (&myParams) {
                            return myParams[] = $p;
                        })
                        .add([new FunctionExpression('LEN', [myParams[0]]), ['string']]);
                }

                break;
        }
    }
}
