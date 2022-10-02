module uim.cake.database.Driver;

import uim.cake.database.Driver;
import uim.cake.database.Query;
import uim.cake.database.Schema\MysqlSchemaDialect;
import uim.cake.database.Schema\SchemaDialect;
import uim.cake.database.Statement\MysqlStatement;
import uim.cake.database.IStatement;
use PDO;

/**
 * MySQL Driver
 */
class Mysql : Driver
{
    use SqlDialectTrait;

    /**
     * @inheritDoc
     */
    protected const MAX_ALIAS_LENGTH = 256;

    /**
     * Server type MySQL
     *
     * @var string
     */
    protected const SERVER_TYPE_MYSQL = 'mysql';

    /**
     * Server type MariaDB
     *
     * @var string
     */
    protected const SERVER_TYPE_MARIADB = 'mariadb';

    /**
     * Base configuration settings for MySQL driver
     *
     * @var array<string, mixed>
     */
    protected $_baseConfig = [
        'persistent' => true,
        'host' => 'localhost',
        'username' => 'root',
        'password' => '',
        'database' => 'cake',
        'port' => '3306',
        'flags' => [],
        'encoding' => 'utf8mb4',
        'timezone' => null,
        'init' => [],
    ];

    /**
     * The schema dialect for this driver
     *
     * @var \Cake\Database\Schema\MysqlSchemaDialect|null
     */
    protected $_schemaDialect;

    /**
     * String used to start a database identifier quoting to make it safe
     *
     * @var string
     */
    protected $_startQuote = '`';

    /**
     * String used to end a database identifier quoting to make it safe
     *
     * @var string
     */
    protected $_endQuote = '`';

    /**
     * Server type.
     *
     * If the underlying server is MariaDB, its value will get set to `'mariadb'`
     * after `version()` method is called.
     *
     * @var string
     */
    protected $serverType = self::SERVER_TYPE_MYSQL;

    /**
     * Mapping of feature to db server version for feature availability checks.
     *
     * @var array<string, array<string, string>>
     */
    protected $featureVersions = [
        'mysql' => [
            'json' => '5.7.0',
            'cte' => '8.0.0',
            'window' => '8.0.0',
        ],
        'mariadb' => [
            'json' => '10.2.7',
            'cte' => '10.2.1',
            'window' => '10.2.0',
        ],
    ];

    /**
     * Establishes a connection to the database server
     *
     * @return bool true on success
     */
    function connect(): bool
    {
        if (this._connection) {
            return true;
        }
        myConfig = this._config;

        if (myConfig['timezone'] === 'UTC') {
            myConfig['timezone'] = '+0:00';
        }

        if (!empty(myConfig['timezone'])) {
            myConfig['init'][] = sprintf("SET time_zone = '%s'", myConfig['timezone']);
        }

        myConfig['flags'] += [
            PDO::ATTR_PERSISTENT => myConfig['persistent'],
            PDO::MYSQL_ATTR_USE_BUFFERED_QUERY => true,
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        ];

        if (!empty(myConfig['ssl_key']) && !empty(myConfig['ssl_cert'])) {
            myConfig['flags'][PDO::MYSQL_ATTR_SSL_KEY] = myConfig['ssl_key'];
            myConfig['flags'][PDO::MYSQL_ATTR_SSL_CERT] = myConfig['ssl_cert'];
        }
        if (!empty(myConfig['ssl_ca'])) {
            myConfig['flags'][PDO::MYSQL_ATTR_SSL_CA] = myConfig['ssl_ca'];
        }

        if (empty(myConfig['unix_socket'])) {
            $dsn = "mysql:host={myConfig['host']};port={myConfig['port']};dbname={myConfig['database']}";
        } else {
            $dsn = "mysql:unix_socket={myConfig['unix_socket']};dbname={myConfig['database']}";
        }

        if (!empty(myConfig['encoding'])) {
            $dsn .= ";charset={myConfig['encoding']}";
        }

        this._connect($dsn, myConfig);

        if (!empty(myConfig['init'])) {
            myConnection = this.getConnection();
            foreach ((array)myConfig['init'] as $command) {
                myConnection.exec($command);
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
        return in_array('mysql', PDO::getAvailableDrivers(), true);
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
        myResult = new MysqlStatement($statement, this);
        /** @psalm-suppress PossiblyInvalidMethodCall */
        if ($isObject && myQuery.isBufferedResultsEnabled() === false) {
            myResult.bufferResults(false);
        }

        return myResult;
    }

    /**
     * @inheritDoc
     */
    function schemaDialect(): SchemaDialect
    {
        if (this._schemaDialect === null) {
            this._schemaDialect = new MysqlSchemaDialect(this);
        }

        return this._schemaDialect;
    }

    /**
     * @inheritDoc
     */
    function schema(): string
    {
        return this._config['database'];
    }

    /**
     * @inheritDoc
     */
    function disableForeignKeySQL(): string
    {
        return 'SET foreign_key_checks = 0';
    }

    /**
     * @inheritDoc
     */
    function enableForeignKeySQL(): string
    {
        return 'SET foreign_key_checks = 1';
    }

    /**
     * @inheritDoc
     */
    function supports(string $feature): bool
    {
        switch ($feature) {
            case static::FEATURE_CTE:
            case static::FEATURE_JSON:
            case static::FEATURE_WINDOW:
                return version_compare(
                    this.version(),
                    this.featureVersions[this.serverType][$feature],
                    '>='
                );
        }

        return super.supports($feature);
    }

    /**
     * @inheritDoc
     */
    function supportsDynamicConstraints(): bool
    {
        return true;
    }

    /**
     * Returns true if the connected server is MariaDB.
     *
     * @return bool
     */
    function isMariadb(): bool
    {
        this.version();

        return this.serverType === static::SERVER_TYPE_MARIADB;
    }

    /**
     * Returns connected server version.
     *
     * @return string
     */
    function version(): string
    {
        if (this._version === null) {
            this.connect();
            this._version = (string)this._connection.getAttribute(PDO::ATTR_SERVER_VERSION);

            if (strpos(this._version, 'MariaDB') !== false) {
                this.serverType = static::SERVER_TYPE_MARIADB;
                preg_match('/^(?:5\.5\.5-)?(\d+\.\d+\.\d+.*-MariaDB[^:]*)/', this._version, $matches);
                this._version = $matches[1];
            }
        }

        return this._version;
    }

    /**
     * Returns true if the server supports common table expressions.
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(IDriver::FEATURE_CTE)` instead
     */
    function supportsCTEs(): bool
    {
        deprecationWarning('Feature support checks are now implemented by `supports()` with FEATURE_* constants.');

        return this.supports(static::FEATURE_CTE);
    }

    /**
     * Returns true if the server supports native JSON columns
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(IDriver::FEATURE_JSON)` instead
     */
    function supportsNativeJson(): bool
    {
        deprecationWarning('Feature support checks are now implemented by `supports()` with FEATURE_* constants.');

        return this.supports(static::FEATURE_JSON);
    }

    /**
     * Returns true if the connected server supports window functions.
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(IDriver::FEATURE_WINDOW)` instead
     */
    function supportsWindowFunctions(): bool
    {
        deprecationWarning('Feature support checks are now implemented by `supports()` with FEATURE_* constants.');

        return this.supports(static::FEATURE_WINDOW);
    }
}
