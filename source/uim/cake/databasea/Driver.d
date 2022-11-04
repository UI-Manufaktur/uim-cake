module uim.cake.database;

import uim.cake.core.App;
import uim.cake.core.Retry\CommandRetry;
import uim.cake.database.Exception\MissingConnectionException;
import uim.cake.database.Retry\ErrorCodeWaitStrategy;
import uim.cake.database.Schema\SchemaDialect;
import uim.cake.database.Schema\TableSchema;
import uim.cake.database.Statement\PDOStatement;
use Closure;
use InvalidArgumentException;
use PDO;
use PDOException;

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
     *
     * @var bool
     */
    protected $_autoQuoting = false;

    /**
     * The server version
     *
     * @var string|null
     */
    protected $_version;

    /**
     * The last number of connection retry attempts.
     *
     * @var int
     */
    protected $connectRetries = 0;

    /**
     * Constructor
     *
     * @param array<string, mixed> myConfig The configuration for the driver.
     * @throws \InvalidArgumentException
     */
    this(array myConfig = []) {
        if (empty(myConfig['username']) && !empty(myConfig['login'])) {
            throw new InvalidArgumentException(
                'Please pass "username" instead of "login" for connecting to the database'
            );
        }
        myConfig += this._baseConfig;
        this._config = myConfig;
        if (!empty(myConfig['quoteIdentifiers'])) {
            this.enableAutoQuoting();
        }
    }

    /**
     * Establishes a connection to the database server
     *
     * @param string $dsn A Driver-specific PDO-DSN
     * @param array<string, mixed> myConfig configuration to be used for creating connection
     * @return bool true on success
     */
    protected bool _connect(string $dsn, array myConfig)
    {
        $action = function () use ($dsn, myConfig) {
            this.setConnection(new PDO(
                $dsn,
                myConfig['username'] ?: null,
                myConfig['password'] ?: null,
                myConfig['flags']
            ));
        };

        $retry = new CommandRetry(new ErrorCodeWaitStrategy(static::RETRY_ERROR_CODES, 5), 4);
        try {
            $retry.run($action);
        } catch (PDOException $e) {
            throw new MissingConnectionException(
                [
                    'driver' => App::shortName(static::class, 'Database/Driver'),
                    'reason' => $e.getMessage(),
                ],
                null,
                $e
            );
        } finally {
            this.connectRetries = $retry.getRetries();
        }

        return true;
    }

    /**
     * @inheritDoc
     */
    abstract bool connect();

    /**
     * @inheritDoc
     */
    function disconnect(): void
    {
        /** @psalm-suppress PossiblyNullPropertyAssignmentValue */
        this._connection = null;
        this._version = null;
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
        }

        return this._version;
    }

    /**
     * Get the internal PDO connection instance.
     *
     * @return \PDO
     */
    auto getConnection() {
        if (this._connection === null) {
            throw new MissingConnectionException([
                'driver' => App::shortName(static::class, 'Database/Driver'),
                'reason' => 'Unknown',
            ]);
        }

        return this._connection;
    }

    /**
     * Set the internal PDO connection instance.
     *
     * @param \PDO myConnection PDO instance.
     * @return this
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    auto setConnection(myConnection) {
        this._connection = myConnection;

        return this;
    }

    /**
     * @inheritDoc
     */
    abstract bool enabled();

    /**
     * @inheritDoc
     */
    function prepare(myQuery): IStatement
    {
        this.connect();
        $statement = this._connection.prepare(myQuery instanceof Query ? myQuery.sql() : myQuery);

        return new PDOStatement($statement, this);
    }

    /**
     * @inheritDoc
     */
    bool beginTransaction()
    {
        this.connect();
        if (this._connection.inTransaction()) {
            return true;
        }

        return this._connection.beginTransaction();
    }

    /**
     * @inheritDoc
     */
    bool commitTransaction()
    {
        this.connect();
        if (!this._connection.inTransaction()) {
            return false;
        }

        return this._connection.commit();
    }

    /**
     * @inheritDoc
     */
    bool rollbackTransaction()
    {
        this.connect();
        if (!this._connection.inTransaction()) {
            return false;
        }

        return this._connection.rollBack();
    }

    /**
     * Returns whether a transaction is active for connection.
     *
     * @return bool
     */
    bool inTransaction()
    {
        this.connect();

        return this._connection.inTransaction();
    }

    /**
     * @inheritDoc
     */
    bool supportsSavePoints()
    {
        deprecationWarning('Feature support checks are now implemented by `supports()` with FEATURE_* constants.');

        return this.supports(static::FEATURE_SAVEPOINT);
    }

    /**
     * Returns true if the server supports common table expressions.
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(IDriver::FEATURE_QUOTE)` instead
     */
    bool supportsCTEs()
    {
        deprecationWarning('Feature support checks are now implemented by `supports()` with FEATURE_* constants.');

        return this.supports(static::FEATURE_CTE);
    }

    /**
     * @inheritDoc
     */
    function quote(myValue, myType = PDO::PARAM_STR): string
    {
        this.connect();

        return this._connection.quote((string)myValue, myType);
    }

    /**
     * Checks if the driver supports quoting, as PDO_ODBC does not support it.
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(IDriver::FEATURE_QUOTE)` instead
     */
    bool supportsQuoting()
    {
        deprecationWarning('Feature support checks are now implemented by `supports()` with FEATURE_* constants.');

        return this.supports(static::FEATURE_QUOTE);
    }

    /**
     * @inheritDoc
     */
    abstract function queryTranslator(string myType): Closure;

    /**
     * @inheritDoc
     */
    abstract function schemaDialect(): SchemaDialect;

    /**
     * @inheritDoc
     */
    abstract function quoteIdentifier(string myIdentifier): string;

    /**
     * @inheritDoc
     */
    function schemaValue(myValue): string
    {
        if (myValue === null) {
            return 'NULL';
        }
        if (myValue === false) {
            return 'FALSE';
        }
        if (myValue === true) {
            return 'TRUE';
        }
        if (is_float(myValue)) {
            return str_replace(',', '.', (string)myValue);
        }
        /** @psalm-suppress InvalidArgument */
        if (
            (
                is_int(myValue) ||
                myValue === '0'
            ) ||
            (
                is_numeric(myValue) &&
                strpos(myValue, ',') === false &&
                substr(myValue, 0, 1) !== '0' &&
                strpos(myValue, 'e') === false
            )
        ) {
            return (string)myValue;
        }

        return this._connection.quote((string)myValue, PDO::PARAM_STR);
    }

    /**
     * @inheritDoc
     */
    function schema(): string
    {
        return this._config['schema'];
    }

    /**
     * @inheritDoc
     */
    function lastInsertId(?string myTable = null, ?string $column = null) {
        this.connect();

        if (this._connection instanceof PDO) {
            return this._connection.lastInsertId(myTable);
        }

        return this._connection.lastInsertId(myTable);
    }

    /**
     * @inheritDoc
     */
    bool isConnected()
    {
        if (this._connection === null) {
            $connected = false;
        } else {
            try {
                $connected = (bool)this._connection.query('SELECT 1');
            } catch (PDOException $e) {
                $connected = false;
            }
        }

        return $connected;
    }

    /**
     * @inheritDoc
     */
    function enableAutoQuoting(bool myEnable = true) {
        this._autoQuoting = myEnable;

        return this;
    }

    /**
     * @inheritDoc
     */
    function disableAutoQuoting() {
        this._autoQuoting = false;

        return this;
    }

    /**
     * @inheritDoc
     */
    bool isAutoQuotingEnabled()
    {
        return this._autoQuoting;
    }

    /**
     * Returns whether the driver supports the feature.
     *
     * Defaults to true for FEATURE_QUOTE and FEATURE_SAVEPOINT.
     *
     * @param string $feature Driver feature name
     * @return bool
     */
    bool supports(string $feature)
    {
        switch ($feature) {
            case static::FEATURE_DISABLE_CONSTRAINT_WITHOUT_TRANSACTION:
            case static::FEATURE_QUOTE:
            case static::FEATURE_SAVEPOINT:
                return true;
        }

        return false;
    }

    /**
     * @inheritDoc
     */
    function compileQuery(Query myQuery, ValueBinder $binder): array
    {
        $processor = this.newCompiler();
        $translator = this.queryTranslator(myQuery.type());
        myQuery = $translator(myQuery);

        return [myQuery, $processor.compile(myQuery, $binder)];
    }

    /**
     * @inheritDoc
     */
    function newCompiler(): QueryCompiler
    {
        return new QueryCompiler();
    }

    /**
     * @inheritDoc
     */
    function newTableSchema(string myTable, array $columns = []): TableSchema
    {
        myClassName = TableSchema::class;
        if (isset(this._config['tableSchema'])) {
            /** @var class-string<\Cake\Database\Schema\TableSchema> myClassName */
            myClassName = this._config['tableSchema'];
        }

        return new myClassName(myTable, $columns);
    }

    /**
     * Returns the maximum alias length allowed.
     * This can be different from the maximum identifier length for columns.
     *
     * @return int|null Maximum alias length or null if no limit
     */
    auto getMaxAliasLength(): ?int
    {
        return static::MAX_ALIAS_LENGTH;
    }

    /**
     * Returns the number of connection retry attempts made.
     *
     * @return int
     */
    auto getConnectRetries(): int
    {
        return this.connectRetries;
    }

    /**
     * Destructor
     */
    auto __destruct() {
        /** @psalm-suppress PossiblyNullPropertyAssignmentValue */
        this._connection = null;
    }

    /**
     * Returns an array that can be used to describe the internal state of this
     * object.
     *
     * @return array<string, mixed>
     */
    auto __debugInfo(): array
    {
        return [
            'connected' => this._connection !== null,
        ];
    }
}
