
module uim.cake.Database;

import uim.cake.core.App;
import uim.cake.core.Retry\CommandRetry;
import uim.cake.databases.exceptions.MissingConnectionException;
import uim.cake.databases.Retry\ErrorCodeWaitStrategy;
import uim.cake.databases.schemas.SchemaDialect;
import uim.cake.databases.schemas.TableSchema;
import uim.cake.databases.statements.PDOStatement;
use Closure;
use InvalidArgumentException;
use PDO;
use PDOException;

/**
 * Represents a database driver containing all specificities for
 * a database engine including its SQL dialect.
 */
abstract class Driver : DriverInterface
{
    /**
     * @var int|null Maximum alias length or null if no limit
     */
    protected const MAX_ALIAS_LENGTH = null;

    /**
     * @var array<int>  DB-specific error codes that allow connect retry
     */
    protected const RETRY_ERROR_CODES = [];

    /**
     * Instance of PDO.
     *
     * @var \PDO
     */
    protected $_connection;

    /**
     * Configuration data.
     *
     * @var array<string, mixed>
     */
    protected $_config;

    /**
     * Base configuration that is merged into the user
     * supplied configuration data.
     *
     * @var array<string, mixed>
     */
    protected $_baseConfig = [];

    /**
     * Indicates whether the driver is doing automatic identifier quoting
     * for all queries
     *
     */
    protected bool $_autoQuoting = false;

    /**
     * The server version
     *
     * @var string|null
     */
    protected $_version;

    /**
     * The last number of connection retry attempts.
     *
     */
    protected int $connectRetries = 0;

    /**
     * Constructor
     *
     * @param array<string, mixed> $config The configuration for the driver.
     * @throws \InvalidArgumentException
     */
    this(array $config = []) {
        if (empty($config["username"]) && !empty($config["login"])) {
            throw new InvalidArgumentException(
                "Please pass "username" instead of "login" for connecting to the database"
            );
        }
        $config += _baseConfig;
        _config = $config;
        if (!empty($config["quoteIdentifiers"])) {
            this.enableAutoQuoting();
        }
    }

    /**
     * Establishes a connection to the database server
     *
     * @param string $dsn A Driver-specific PDO-DSN
     * @param array<string, mixed> $config configuration to be used for creating connection
     * @return bool true on success
     */
    protected function _connect(string $dsn, array $config): bool
    {
        $action = function () use ($dsn, $config) {
            this.setConnection(new PDO(
                $dsn,
                $config["username"] ?: null,
                $config["password"] ?: null,
                $config["flags"]
            ));
        };

        $retry = new CommandRetry(new ErrorCodeWaitStrategy(static::RETRY_ERROR_CODES, 5), 4);
        try {
            $retry.run($action);
        } catch (PDOException $e) {
            throw new MissingConnectionException(
                [
                    "driver": App::shortName(static::class, "Database/Driver"),
                    "reason": $e.getMessage(),
                ],
                null,
                $e
            );
        } finally {
            this.connectRetries = $retry.getRetries();
        }

        return true;
    }


    abstract function connect(): bool;


    void disconnect() {
        /** @psalm-suppress PossiblyNullPropertyAssignmentValue */
        _connection = null;
        _version = null;
    }

    /**
     * Returns connected server version.
     */
    string version(): string
    {
        if (_version == null) {
            this.connect();
            _version = (string)_connection.getAttribute(PDO::ATTR_SERVER_VERSION);
        }

        return _version;
    }

    /**
     * Get the internal PDO connection instance.
     *
     * @return \PDO
     */
    function getConnection() {
        if (_connection == null) {
            throw new MissingConnectionException([
                "driver": App::shortName(static::class, "Database/Driver"),
                "reason": "Unknown",
            ]);
        }

        return _connection;
    }

    /**
     * Set the internal PDO connection instance.
     *
     * @param \PDO $connection PDO instance.
     * @return this
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    function setConnection($connection) {
        _connection = $connection;

        return this;
    }


    abstract function enabled(): bool;


    function prepare($query): StatementInterface
    {
        this.connect();
        $statement = _connection.prepare($query instanceof Query ? $query.sql() : $query);

        return new PDOStatement($statement, this);
    }


    function beginTransaction(): bool
    {
        this.connect();
        if (_connection.inTransaction()) {
            return true;
        }

        return _connection.beginTransaction();
    }


    function commitTransaction(): bool
    {
        this.connect();
        if (!_connection.inTransaction()) {
            return false;
        }

        return _connection.commit();
    }


    function rollbackTransaction(): bool
    {
        this.connect();
        if (!_connection.inTransaction()) {
            return false;
        }

        return _connection.rollBack();
    }

    /**
     * Returns whether a transaction is active for connection.
     *
     * @return bool
     */
    function inTransaction(): bool
    {
        this.connect();

        return _connection.inTransaction();
    }


    function supportsSavePoints(): bool
    {
        deprecationWarning("Feature support checks are now implemented by `supports()` with FEATURE_* constants.");

        return this.supports(static::FEATURE_SAVEPOINT);
    }

    /**
     * Returns true if the server supports common table expressions.
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(DriverInterface::FEATURE_QUOTE)` instead
     */
    function supportsCTEs(): bool
    {
        deprecationWarning("Feature support checks are now implemented by `supports()` with FEATURE_* constants.");

        return this.supports(static::FEATURE_CTE);
    }


    function quote($value, $type = PDO::PARAM_STR): string
    {
        this.connect();

        return _connection.quote((string)$value, $type);
    }

    /**
     * Checks if the driver supports quoting, as PDO_ODBC does not support it.
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(DriverInterface::FEATURE_QUOTE)` instead
     */
    function supportsQuoting(): bool
    {
        deprecationWarning("Feature support checks are now implemented by `supports()` with FEATURE_* constants.");

        return this.supports(static::FEATURE_QUOTE);
    }


    abstract function queryTranslator(string $type): Closure;


    abstract function schemaDialect(): SchemaDialect;


    abstract function quoteIdentifier(string $identifier): string;


    function schemaValue($value): string
    {
        if ($value == null) {
            return "NULL";
        }
        if ($value == false) {
            return "FALSE";
        }
        if ($value == true) {
            return "TRUE";
        }
        if (is_float($value)) {
            return str_replace(",", ".", (string)$value);
        }
        /** @psalm-suppress InvalidArgument */
        if (
            (
                is_int($value) ||
                $value == "0"
            ) ||
            (
                is_numeric($value) &&
                strpos($value, ",") == false &&
                substr($value, 0, 1) != "0" &&
                strpos($value, "e") == false
            )
        ) {
            return (string)$value;
        }

        return _connection.quote((string)$value, PDO::PARAM_STR);
    }


    function schema(): string
    {
        return _config["schema"];
    }


    function lastInsertId(?string $table = null, ?string $column = null) {
        this.connect();

        if (_connection instanceof PDO) {
            return _connection.lastInsertId($table);
        }

        return _connection.lastInsertId($table);
    }


    function isConnected(): bool
    {
        if (_connection == null) {
            $connected = false;
        } else {
            try {
                $connected = (bool)_connection.query("SELECT 1");
            } catch (PDOException $e) {
                $connected = false;
            }
        }

        return $connected;
    }


    function enableAutoQuoting(bool $enable = true) {
        _autoQuoting = $enable;

        return this;
    }


    function disableAutoQuoting() {
        _autoQuoting = false;

        return this;
    }


    function isAutoQuotingEnabled(): bool
    {
        return _autoQuoting;
    }

    /**
     * Returns whether the driver supports the feature.
     *
     * Defaults to true for FEATURE_QUOTE and FEATURE_SAVEPOINT.
     *
     * @param string $feature Driver feature name
     * @return bool
     */
    function supports(string $feature): bool
    {
        switch ($feature) {
            case static::FEATURE_DISABLE_CONSTRAINT_WITHOUT_TRANSACTION:
            case static::FEATURE_QUOTE:
            case static::FEATURE_SAVEPOINT:
                return true;
        }

        return false;
    }


    function compileQuery(Query $query, ValueBinder $binder): array
    {
        $processor = this.newCompiler();
        $translator = this.queryTranslator($query.type());
        $query = $translator($query);

        return [$query, $processor.compile($query, $binder)];
    }


    function newCompiler(): QueryCompiler
    {
        return new QueryCompiler();
    }


    function newTableSchema(string $table, array $columns = []): TableSchema
    {
        $className = TableSchema::class;
        if (isset(_config["tableSchema"])) {
            /** @var class-string<uim.cake.databases.Schema\TableSchema> $className */
            $className = _config["tableSchema"];
        }

        return new $className($table, $columns);
    }

    /**
     * Returns the maximum alias length allowed.
     * This can be different from the maximum identifier length for columns.
     *
     * @return int|null Maximum alias length or null if no limit
     */
    function getMaxAliasLength(): ?int
    {
        return static::MAX_ALIAS_LENGTH;
    }

    /**
     * Returns the number of connection retry attempts made.
     *
     * @return int
     */
    function getConnectRetries(): int
    {
        return this.connectRetries;
    }

    /**
     * Destructor
     */
    function __destruct() {
        /** @psalm-suppress PossiblyNullPropertyAssignmentValue */
        _connection = null;
    }

    /**
     * Returns an array that can be used to describe the internal state of this
     * object.
     *
     * @return array<string, mixed>
     */
    function __debugInfo(): array
    {
        return [
            "connected": _connection != null,
        ];
    }
}
