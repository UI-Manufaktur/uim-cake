


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Driver;

import uim.cake.databases.Driver;
import uim.cake.databases.Expression\FunctionExpression;
import uim.cake.databases.Expression\TupleComparison;
import uim.cake.databases.Query;
import uim.cake.databases.QueryCompiler;
import uim.cake.databases.schemas.SchemaDialect;
import uim.cake.databases.schemas.SqliteSchemaDialect;
import uim.cake.databases.SqliteCompiler;
import uim.cake.databases.statements.PDOStatement;
import uim.cake.databases.statements.SqliteStatement;
import uim.cake.databases.StatementInterface;
use InvalidArgumentException;
use PDO;
use RuntimeException;

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
        'persistent': false,
        'username': null,
        'password': null,
        'database': ':memory:',
        'encoding': 'utf8',
        'mask': 0644,
        'cache': null,
        'mode': null,
        'flags': [],
        'init': [],
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
        'day': 'd',
        'hour': 'H',
        'month': 'm',
        'minute': 'M',
        'second': 'S',
        'week': 'W',
        'year': 'Y',
    ];

    /**
     * Mapping of feature to db server version for feature availability checks.
     *
     * @var array<string, string>
     */
    protected $featureVersions = [
        'cte': '3.8.3',
        'window': '3.28.0',
    ];

    /**
     * Establishes a connection to the database server
     *
     * @return bool true on success
     */
    function connect(): bool
    {
        if (_connection) {
            return true;
        }
        $config = _config;
        $config['flags'] += [
            PDO::ATTR_PERSISTENT: $config['persistent'],
            PDO::ATTR_EMULATE_PREPARES: false,
            PDO::ATTR_ERRMODE: PDO::ERRMODE_EXCEPTION,
        ];
        if (!is_string($config['database']) || $config['database'] == '') {
            $name = $config['name'] ?? 'unknown';
            throw new InvalidArgumentException(
                "The `database` key for the `{$name}` SQLite connection needs to be a non-empty string."
            );
        }

        $chmodFile = false;
        if ($config['database'] != ':memory:' && $config['mode'] != 'memory') {
            $chmodFile = !file_exists($config['database']);
        }

        $params = [];
        if ($config['cache']) {
            $params[] = 'cache=' . $config['cache'];
        }
        if ($config['mode']) {
            $params[] = 'mode=' . $config['mode'];
        }

        if ($params) {
            if (PHP_VERSION_ID < 80100) {
                throw new RuntimeException('SQLite URI support requires PHP 8.1.');
            }
            $dsn = 'sqlite:file:' . $config['database'] . '?' . implode('&', $params);
        } else {
            $dsn = 'sqlite:' . $config['database'];
        }

        _connect($dsn, $config);
        if ($chmodFile) {
            // phpcs:disable
            @chmod($config['database'], $config['mask']);
            // phpcs:enable
        }

        if (!empty($config['init'])) {
            foreach ((array)$config['init'] as $command) {
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
    function enabled(): bool
    {
        return in_array('sqlite', PDO::getAvailableDrivers(), true);
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
        $isObject = $query instanceof Query;
        /**
         * @psalm-suppress PossiblyInvalidMethodCall
         * @psalm-suppress PossiblyInvalidArgument
         */
        $statement = _connection.prepare($isObject ? $query.sql() : $query);
        $result = new SqliteStatement(new PDOStatement($statement, this), this);
        /** @psalm-suppress PossiblyInvalidMethodCall */
        if ($isObject && $query.isBufferedResultsEnabled() == false) {
            $result.bufferResults(false);
        }

        return $result;
    }

    /**
     * @inheritDoc
     */
    function disableForeignKeySQL(): string
    {
        return 'PRAGMA foreign_keys = OFF';
    }

    /**
     * @inheritDoc
     */
    function enableForeignKeySQL(): string
    {
        return 'PRAGMA foreign_keys = ON';
    }

    /**
     * @inheritDoc
     */
    function supports(string $feature): bool
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

        return parent::supports($feature);
    }

    /**
     * @inheritDoc
     */
    function supportsDynamicConstraints(): bool
    {
        return false;
    }

    /**
     * @inheritDoc
     */
    function schemaDialect(): SchemaDialect
    {
        if (_schemaDialect == null) {
            _schemaDialect = new SqliteSchemaDialect(this);
        }

        return _schemaDialect;
    }

    /**
     * @inheritDoc
     */
    function newCompiler(): QueryCompiler
    {
        return new SqliteCompiler();
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
                $expression.setName('DATETIME').add(["'now'": 'literal']);
                break;
            case 'RAND':
                $expression
                    .setName('ABS')
                    .add(['RANDOM() % 1': 'literal'], [], true);
                break;
            case 'CURRENT_DATE':
                $expression.setName('DATE').add(["'now'": 'literal']);
                break;
            case 'CURRENT_TIME':
                $expression.setName('TIME').add(["'now'": 'literal']);
                break;
            case 'EXTRACT':
                $expression
                    .setName('STRFTIME')
                    .setConjunction(' ,')
                    .iterateParts(function ($p, $key) {
                        if ($key == 0) {
                            $value = rtrim(strtolower($p), 's');
                            if (isset(_dateParts[$value])) {
                                $p = ['value': '%' . _dateParts[$value], 'type': null];
                            }
                        }

                        return $p;
                    });
                break;
            case 'DATE_ADD':
                $expression
                    .setName('DATE')
                    .setConjunction(',')
                    .iterateParts(function ($p, $key) {
                        if ($key == 1) {
                            $p = ['value': $p, 'type': null];
                        }

                        return $p;
                    });
                break;
            case 'DAYOFWEEK':
                $expression
                    .setName('STRFTIME')
                    .setConjunction(' ')
                    .add(["'%w', ": 'literal'], [], true)
                    .add([') + (1': 'literal']); // Sqlite starts on index 0 but Sunday should be 1
                break;
        }
    }

    /**
     * Returns true if the server supports common table expressions.
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(DriverInterface::FEATURE_CTE)` instead
     */
    function supportsCTEs(): bool
    {
        deprecationWarning('Feature support checks are now implemented by `supports()` with FEATURE_* constants.');

        return this.supports(static::FEATURE_CTE);
    }

    /**
     * Returns true if the connected server supports window functions.
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(DriverInterface::FEATURE_WINDOW)` instead
     */
    function supportsWindowFunctions(): bool
    {
        deprecationWarning('Feature support checks are now implemented by `supports()` with FEATURE_* constants.');

        return this.supports(static::FEATURE_WINDOW);
    }
}
