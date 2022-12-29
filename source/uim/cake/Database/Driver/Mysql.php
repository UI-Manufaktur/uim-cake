


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Driver;

import uim.cake.databases.Driver;
import uim.cake.databases.Query;
import uim.cake.databases.schemas.MysqlSchemaDialect;
import uim.cake.databases.schemas.SchemaDialect;
import uim.cake.databases.statements.MysqlStatement;
import uim.cake.databases.StatementInterface;
use PDO;

/**
 * MySQL Driver
 */
class Mysql : Driver
{
    use SqlDialectTrait;


    protected const MAX_ALIAS_LENGTH = 256;

    /**
     * Server type MySQL
     *
     * @var string
     */
    protected const SERVER_TYPE_MYSQL = "mysql";

    /**
     * Server type MariaDB
     *
     * @var string
     */
    protected const SERVER_TYPE_MARIADB = "mariadb";

    /**
     * Base configuration settings for MySQL driver
     *
     * @var array<string, mixed>
     */
    protected $_baseConfig = [
        "persistent": true,
        "host": "localhost",
        "username": "root",
        "password": "",
        "database": "cake",
        "port": "3306",
        "flags": [],
        "encoding": "utf8mb4",
        "timezone": null,
        "init": [],
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
    protected $_startQuote = "`";

    /**
     * String used to end a database identifier quoting to make it safe
     *
     * @var string
     */
    protected $_endQuote = "`";

    /**
     * Server type.
     *
     * If the underlying server is MariaDB, its value will get set to `"mariadb"`
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
        "mysql": [
            "json": "5.7.0",
            "cte": "8.0.0",
            "window": "8.0.0",
        ],
        "mariadb": [
            "json": "10.2.7",
            "cte": "10.2.1",
            "window": "10.2.0",
        ],
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

        if ($config["timezone"] == "UTC") {
            $config["timezone"] = "+0:00";
        }

        if (!empty($config["timezone"])) {
            $config["init"][] = sprintf("SET time_zone = "%s"", $config["timezone"]);
        }

        $config["flags"] += [
            PDO::ATTR_PERSISTENT: $config["persistent"],
            PDO::MYSQL_ATTR_USE_BUFFERED_QUERY: true,
            PDO::ATTR_ERRMODE: PDO::ERRMODE_EXCEPTION,
        ];

        if (!empty($config["ssl_key"]) && !empty($config["ssl_cert"])) {
            $config["flags"][PDO::MYSQL_ATTR_SSL_KEY] = $config["ssl_key"];
            $config["flags"][PDO::MYSQL_ATTR_SSL_CERT] = $config["ssl_cert"];
        }
        if (!empty($config["ssl_ca"])) {
            $config["flags"][PDO::MYSQL_ATTR_SSL_CA] = $config["ssl_ca"];
        }

        if (empty($config["unix_socket"])) {
            $dsn = "mysql:host={$config["host"]};port={$config["port"]};dbname={$config["database"]}";
        } else {
            $dsn = "mysql:unix_socket={$config["unix_socket"]};dbname={$config["database"]}";
        }

        if (!empty($config["encoding"])) {
            $dsn .= ";charset={$config["encoding"]}";
        }

        _connect($dsn, $config);

        if (!empty($config["init"])) {
            $connection = this.getConnection();
            foreach ((array)$config["init"] as $command) {
                $connection.exec($command);
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
        return in_array("mysql", PDO::getAvailableDrivers(), true);
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
        $result = new MysqlStatement($statement, this);
        /** @psalm-suppress PossiblyInvalidMethodCall */
        if ($isObject && $query.isBufferedResultsEnabled() == false) {
            $result.bufferResults(false);
        }

        return $result;
    }


    function schemaDialect(): SchemaDialect
    {
        if (_schemaDialect == null) {
            _schemaDialect = new MysqlSchemaDialect(this);
        }

        return _schemaDialect;
    }


    function schema(): string
    {
        return _config["database"];
    }


    function disableForeignKeySQL(): string
    {
        return "SET foreign_key_checks = 0";
    }


    function enableForeignKeySQL(): string
    {
        return "SET foreign_key_checks = 1";
    }


    function supports(string $feature): bool
    {
        switch ($feature) {
            case static::FEATURE_CTE:
            case static::FEATURE_JSON:
            case static::FEATURE_WINDOW:
                return version_compare(
                    this.version(),
                    this.featureVersions[this.serverType][$feature],
                    ">="
                );
        }

        return parent::supports($feature);
    }


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

        return this.serverType == static::SERVER_TYPE_MARIADB;
    }

    /**
     * Returns connected server version.
     *
     * @return string
     */
    function version(): string
    {
        if (_version == null) {
            this.connect();
            _version = (string)_connection.getAttribute(PDO::ATTR_SERVER_VERSION);

            if (strpos(_version, "MariaDB") != false) {
                this.serverType = static::SERVER_TYPE_MARIADB;
                preg_match("/^(?:5\.5\.5-)?(\d+\.\d+\.\d+.*-MariaDB[^:]*)/", _version, $matches);
                _version = $matches[1];
            }
        }

        return _version;
    }

    /**
     * Returns true if the server supports common table expressions.
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(DriverInterface::FEATURE_CTE)` instead
     */
    function supportsCTEs(): bool
    {
        deprecationWarning("Feature support checks are now implemented by `supports()` with FEATURE_* constants.");

        return this.supports(static::FEATURE_CTE);
    }

    /**
     * Returns true if the server supports native JSON columns
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(DriverInterface::FEATURE_JSON)` instead
     */
    function supportsNativeJson(): bool
    {
        deprecationWarning("Feature support checks are now implemented by `supports()` with FEATURE_* constants.");

        return this.supports(static::FEATURE_JSON);
    }

    /**
     * Returns true if the connected server supports window functions.
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(DriverInterface::FEATURE_WINDOW)` instead
     */
    function supportsWindowFunctions(): bool
    {
        deprecationWarning("Feature support checks are now implemented by `supports()` with FEATURE_* constants.");

        return this.supports(static::FEATURE_WINDOW);
    }
}
