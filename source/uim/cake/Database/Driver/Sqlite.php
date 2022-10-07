module uim.cake.database.Driver;

import uim.cake.database.Driver;
import uim.cake.database.Expression\FunctionExpression;
import uim.cake.database.Expression\TupleComparison;
import uim.cake.database.Query;
import uim.cake.database.QueryCompiler;
import uim.cake.database.Schema\SchemaDialect;
import uim.cake.database.Schema\SqliteSchemaDialect;
import uim.cake.database.SqliteCompiler;
import uim.cake.database.Statement\PDOStatement;
import uim.cake.database.Statement\SqliteStatement;
import uim.cake.database.IStatement;
use InvalidArgumentException;
use PDO;

/**
 * Class Sqlite
 */
class Sqlite : Driver
{
    use SqlDialectTrait;
    use TupleComparisonTranslatorTrait;

    /**
     * Base configuration settings for Sqlite driver
     *
     * - `mask` The mask used for created database
     *
     * @var array<string, mixed>
     */
    protected $_baseConfig = [
        'persistent' => false,
        'username' => null,
        'password' => null,
        'database' => ':memory:',
        'encoding' => 'utf8',
        'mask' => 0644,
        'flags' => [],
        'init' => [],
    ];

    /**
     * The schema dialect class for this driver
     *
     * @var \Cake\Database\Schema\SqliteSchemaDialect|null
     */
    protected $_schemaDialect;

    /**
     * Whether the connected server supports window functions.
     *
     * @var bool|null
     */
    protected $_supportsWindowFunctions;

    /**
     * String used to start a database identifier quoting to make it safe
     *
     * @var string
     */
    protected $_startQuote = '"';

    /**
     * String used to end a database identifier quoting to make it safe
     *
     * @var string
     */
    protected $_endQuote = '"';

    /**
     * Mapping of date parts.
     *
     * @var array<string, string>
     */
    protected $_dateParts = [
        'day' => 'd',
        'hour' => 'H',
        'month' => 'm',
        'minute' => 'M',
        'second' => 'S',
        'week' => 'W',
        'year' => 'Y',
    ];

    /**
     * Mapping of feature to db server version for feature availability checks.
     *
     * @var array<string, string>
     */
    protected $featureVersions = [
        'cte' => '3.8.3',
        'window' => '3.28.0',
    ];

    /**
     * Establishes a connection to the database server
     *
     * @return bool true on success
     */
    bool connect()
    {
        if (this._connection) {
            return true;
        }
        myConfig = this._config;
        myConfig['flags'] += [
            PDO::ATTR_PERSISTENT => myConfig['persistent'],
            PDO::ATTR_EMULATE_PREPARES => false,
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        ];
        if (!is_string(myConfig['database']) || myConfig['database'] === '') {
            myName = myConfig['name'] ?? 'unknown';
            throw new InvalidArgumentException(
                "The `database` key for the `{myName}` SQLite connection needs to be a non-empty string."
            );
        }

        myDatabaseExists = file_exists(myConfig['database']);

        $dsn = "sqlite:{myConfig['database']}";
        this._connect($dsn, myConfig);

        if (!myDatabaseExists && myConfig['database'] !== ':memory:') {
            // phpcs:disable
            @chmod(myConfig['database'], myConfig['mask']);
            // phpcs:enable
        }

        if (!empty(myConfig['init'])) {
            foreach ((array)myConfig['init'] as $command) {
                this.getConnection().exec($command);
            }
        }

        return true;
    }

    /**
     * Returns whether php is able to use this driver for connecting to database
     *
     * @return bool true if it is valid to use this driver
     */
    bool enabled()
    {
        return in_array('sqlite', PDO::getAvailableDrivers(), true);
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
        $isObject = myQuery instanceof Query;
        /**
         * @psalm-suppress PossiblyInvalidMethodCall
         * @psalm-suppress PossiblyInvalidArgument
         */
        $statement = this._connection.prepare($isObject ? myQuery.sql() : myQuery);
        myResult = new SqliteStatement(new PDOStatement($statement, this), this);
        /** @psalm-suppress PossiblyInvalidMethodCall */
        if ($isObject && myQuery.isBufferedResultsEnabled() === false) {
            myResult.bufferResults(false);
        }

        return myResult;
    }


    function disableForeignKeySQL(): string
    {
        return 'PRAGMA foreign_keys = OFF';
    }


    function enableForeignKeySQL(): string
    {
        return 'PRAGMA foreign_keys = ON';
    }


    bool supports(string $feature)
    {
        switch ($feature) {
            case static::FEATURE_CTE:
            case static::FEATURE_WINDOW:
                return version_compare(
                    this.version(),
                    this.featureVersions[$feature],
                    '>='
                );

            case static::FEATURE_TRUNCATE_WITH_CONSTRAINTS:
                return true;
        }

        return super.supports($feature);
    }


    bool supportsDynamicConstraints()
    {
        return false;
    }


    function schemaDialect(): SchemaDialect
    {
        if (this._schemaDialect === null) {
            this._schemaDialect = new SqliteSchemaDialect(this);
        }

        return this._schemaDialect;
    }


    function newCompiler(): QueryCompiler
    {
        return new SqliteCompiler();
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
                // CONCAT function is expressed as exp1 || exp2
                $expression.setName('').setConjunction(' ||');
                break;
            case 'DATEDIFF':
                $expression
                    .setName('ROUND')
                    .setConjunction('-')
                    .iterateParts(function ($p) {
                        return new FunctionExpression('JULIANDAY', [$p['value']], [$p['type']]);
                    });
                break;
            case 'NOW':
                $expression.setName('DATETIME').add(["'now'" => 'literal']);
                break;
            case 'RAND':
                $expression
                    .setName('ABS')
                    .add(['RANDOM() % 1' => 'literal'], [], true);
                break;
            case 'CURRENT_DATE':
                $expression.setName('DATE').add(["'now'" => 'literal']);
                break;
            case 'CURRENT_TIME':
                $expression.setName('TIME').add(["'now'" => 'literal']);
                break;
            case 'EXTRACT':
                $expression
                    .setName('STRFTIME')
                    .setConjunction(' ,')
                    .iterateParts(function ($p, myKey) {
                        if (myKey === 0) {
                            myValue = rtrim(strtolower($p), 's');
                            if (isset(this._dateParts[myValue])) {
                                $p = ['value' => '%' . this._dateParts[myValue], 'type' => null];
                            }
                        }

                        return $p;
                    });
                break;
            case 'DATE_ADD':
                $expression
                    .setName('DATE')
                    .setConjunction(',')
                    .iterateParts(function ($p, myKey) {
                        if (myKey === 1) {
                            $p = ['value' => $p, 'type' => null];
                        }

                        return $p;
                    });
                break;
            case 'DAYOFWEEK':
                $expression
                    .setName('STRFTIME')
                    .setConjunction(' ')
                    .add(["'%w', " => 'literal'], [], true)
                    .add([') + (1' => 'literal']); // Sqlite starts on index 0 but Sunday should be 1
                break;
        }
    }

    /**
     * Returns true if the server supports common table expressions.
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(IDriver::FEATURE_CTE)` instead
     */
    bool supportsCTEs()
    {
        deprecationWarning('Feature support checks are now implemented by `supports()` with FEATURE_* constants.');

        return this.supports(static::FEATURE_CTE);
    }

    /**
     * Returns true if the connected server supports window functions.
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(IDriver::FEATURE_WINDOW)` instead
     */
    bool supportsWindowFunctions()
    {
        deprecationWarning('Feature support checks are now implemented by `supports()` with FEATURE_* constants.');

        return this.supports(static::FEATURE_WINDOW);
    }
}
