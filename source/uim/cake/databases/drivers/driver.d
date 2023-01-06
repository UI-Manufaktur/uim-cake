module uim.cake.databases;

@safe:
import uim.cake;

/**
 * Represents a database driver containing all specificities for
 * a database engine including its SQL dialect.
 */
abstract class Driver : IDriver
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
     */
    protected int $connectRetries = 0;

    /**
     * Constructor
     *
     * @param array<string, mixed> aConfig The configuration for the driver.
     * @throws \InvalidArgumentException
     */
    this(Json aConfig = []) {
        if (empty(aConfig["username"]) && !empty(aConfig["login"])) {
            throw new InvalidArgumentException(
                "Please pass "username" instead of "login" for connecting to the database"
            );
        }
        aConfig += _baseConfig;
        _config = aConfig;
        if (!empty(aConfig["quoteIdentifiers"])) {
            this.enableAutoQuoting();
        }
    }

    /**
     * Establishes a connection to the database server
     *
     * @param string $dsn A Driver-specific PDO-DSN
     * @param array<string, mixed> aConfig configuration to be used for creating connection
     * @return bool true on success
     */
    protected bool _connect(string $dsn, Json aConfig) {
        $action = function () use ($dsn, aConfig) {
            this.setConnection(new PDO(
                $dsn,
                aConfig["username"] ?: null,
                aConfig["password"] ?: null,
                aConfig["flags"]
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


    abstract bool connect();


    void disconnect() {
        /** @psalm-suppress PossiblyNullPropertyAssignmentValue */
        _connection = null;
        _version = null;
    }

    /**
     * Returns connected server version.
     */
    string version() {
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


    abstract bool enabled();


    function prepare($query): IStatement
    {
        this.connect();
        $statement = _connection.prepare($query instanceof Query ? $query.sql() : $query);

        return new PDOStatement($statement, this);
    }


    bool beginTransaction() {
        this.connect();
        if (_connection.inTransaction()) {
            return true;
        }

        return _connection.beginTransaction();
    }


    bool commitTransaction() {
        this.connect();
        if (!_connection.inTransaction()) {
            return false;
        }

        return _connection.commit();
    }


    bool rollbackTransaction() {
        this.connect();
        if (!_connection.inTransaction()) {
            return false;
        }

        return _connection.rollBack();
    }

    /**
     * Returns whether a transaction is active for connection.
     */
    bool inTransaction() {
        this.connect();

        return _connection.inTransaction();
    }


    bool supportsSavePoints() {
        deprecationWarning("Feature support checks are now implemented by `supports()` with FEATURE_* constants.");

        return this.supports(static::FEATURE_SAVEPOINT);
    }

    /**
     * Returns true if the server supports common table expressions.
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(IDriver::FEATURE_QUOTE)` instead
     */
    bool supportsCTEs() {
        deprecationWarning("Feature support checks are now implemented by `supports()` with FEATURE_* constants.");

        return this.supports(static::FEATURE_CTE);
    }


    string quote($value, $type = PDO::PARAM_STR) {
        this.connect();

        return _connection.quote((string)$value, $type);
    }

    /**
     * Checks if the driver supports quoting, as PDO_ODBC does not support it.
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(IDriver::FEATURE_QUOTE)` instead
     */
    bool supportsQuoting() {
        deprecationWarning("Feature support checks are now implemented by `supports()` with FEATURE_* constants.");

        return this.supports(static::FEATURE_QUOTE);
    }


    abstract function queryTranslator(string $type): Closure;


    abstract function schemaDialect(): SchemaDialect;


    abstract string quoteIdentifier(string $identifier);


    string schemaValue($value) {
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


    string schema() {
        return _config["schema"];
    }


    function lastInsertId(?string $table = null, ?string $column = null) {
        this.connect();

        if (_connection instanceof PDO) {
            return _connection.lastInsertId($table);
        }

        return _connection.lastInsertId($table);
    }


    bool isConnected() {
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


    bool isAutoQuotingEnabled() {
        return _autoQuoting;
    }

    /**
     * Returns whether the driver supports the feature.
     *
     * Defaults to true for FEATURE_QUOTE and FEATURE_SAVEPOINT.
     *
     * @param string $feature Driver feature name
     */
    bool supports(string $feature) {
        switch ($feature) {
            case static::FEATURE_DISABLE_CONSTRAINT_WITHOUT_TRANSACTION:
            case static::FEATURE_QUOTE:
            case static::FEATURE_SAVEPOINT:
                return true;
        }

        return false;
    }


    array compileQuery(Query $query, ValueBinder aBinder) {
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
    Nullable!int getMaxAliasLength()
    {
        return static::MAX_ALIAS_LENGTH;
    }

    /**
     * Returns the number of connection retry attempts made.
     */
    int getConnectRetries()
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
    array __debugInfo() {
        return [
            "connected": _connection != null,
        ];
    }
}
