module uim.cake.databases;

import uim.cake.caches\Cache;
import uim.cake.core.App;
import uim.cake.core.Retry\CommandRetry;
import uim.cake.databases.Exception\MissingConnectionException;
import uim.cake.databases.Exception\MissingDriverException;
import uim.cake.databases.Exception\MissingExtensionException;
import uim.cake.databases.Exception\NestedTransactionRollbackException;
import uim.cake.databases.Log\LoggedQuery;
import uim.cake.databases.Log\LoggingStatement;
import uim.cake.databases.Log\QueryLogger;
import uim.cake.databases.Retry\ReconnectStrategy;
import uim.cake.databases.Schema\CachedCollection;
import uim.cake.databases.Schema\Collection as SchemaCollection;
import uim.cake.databases.Schema\ICollection as SchemaICollection;
import uim.cake.datasources\ConnectionInterface;
import uim.cakegs\Log;
use Psr\Log\LoggerInterface;
use Psr\SimpleCache\ICache;
use RuntimeException;
use Throwable;

/**
 * Represents a connection with a database server.
 */
class Connection : ConnectionInterface
{
    use TypeConverterTrait;

    /**
     * Contains the configuration params for this connection.
     *
     * @var array<string, mixed>
     */
    protected $_config;

    /**
     * Driver object, responsible for creating the real connection
     * and provide specific SQL dialect.
     *
     * @var \Cake\Database\IDriver
     */
    protected $_driver;

    /**
     * Contains how many nested transactions have been started.
     *
     * @var int
     */
    protected $_transactionLevel = 0;

    /**
     * Whether a transaction is active in this connection.
     *
     * @var bool
     */
    protected $_transactionStarted = false;

    /**
     * Whether this connection can and should use savepoints for nested
     * transactions.
     *
     * @var bool
     */
    protected $_useSavePoints = false;

    /**
     * Whether to log queries generated during this connection.
     *
     * @var bool
     */
    protected $_logQueries = false;

    /**
     * Logger object instance.
     *
     * @var \Psr\Log\LoggerInterface|null
     */
    protected $_logger;

    /**
     * Cacher object instance.
     *
     * @var \Psr\SimpleCache\ICache|null
     */
    protected $cacher;

    /**
     * The schema collection object
     *
     * @var \Cake\Database\Schema\ICollection|null
     */
    protected $_schemaCollection;

    /**
     * NestedTransactionRollbackException object instance, will be stored if
     * the rollback method is called in some nested transaction.
     *
     * @var \Cake\Database\Exception\NestedTransactionRollbackException|null
     */
    protected $nestedTransactionRollbackException;

    /**
     * Constructor.
     *
     * ### Available options:
     *
     * - `driver` Sort name or FCQN for driver.
     * - `log` Boolean indicating whether to use query logging.
     * - `name` Connection name.
     * - `cacheMetaData` Boolean indicating whether metadata (datasource schemas) should be cached.
     *    If set to a string it will be used as the name of cache config to use.
     * - `cacheKeyPrefix` Custom prefix to use when generation cache keys. Defaults to connection name.
     *
     * @param array<string, mixed> myConfig Configuration array.
     */
    this(array myConfig) {
        this._config = myConfig;

        myDriver = "";
        if (!empty(myConfig["driver"])) {
            myDriver = myConfig["driver"];
        }
        this.setDriver(myDriver, myConfig);

        if (!empty(myConfig["log"])) {
            this.enableQueryLogging((bool)myConfig["log"]);
        }
    }

    /**
     * Destructor
     *
     * Disconnects the driver to release the connection.
     */
    auto __destruct() {
        if (this._transactionStarted && class_exists(Log::class)) {
            Log::warning("The connection is going to be closed but there is an active transaction.");
        }
    }

    /**
     * @inheritDoc
     */
    function config(): array
    {
        return this._config;
    }

    /**
     * @inheritDoc
     */
    string configName() {
        return this._config["name"] ?? "";
    }

    /**
     * Sets the driver instance. If a string is passed it will be treated
     * as a class name and will be instantiated.
     *
     * @param \Cake\Database\IDriver|string myDriver The driver instance to use.
     * @param array<string, mixed> myConfig Config for a new driver.
     * @throws \Cake\Database\Exception\MissingDriverException When a driver class is missing.
     * @throws \Cake\Database\Exception\MissingExtensionException When a driver"s PHP extension is missing.
     * @return this
     */
    auto setDriver(myDriver, myConfig = []) {
        if (is_string(myDriver)) {
            /** @psalm-var class-string<\Cake\Database\IDriver>|null myClassName */
            myClassName = App::className(myDriver, "Database/Driver");
            if (myClassName === null) {
                throw new MissingDriverException(["driver" => myDriver]);
            }
            myDriver = new myClassName(myConfig);
        }
        if (!myDriver.enabled()) {
            throw new MissingExtensionException(["driver" => get_class(myDriver)]);
        }

        this._driver = myDriver;

        return this;
    }

    /**
     * Get the retry wrapper object that is allows recovery from server disconnects
     * while performing certain database actions, such as executing a query.
     *
     * @return \Cake\Core\Retry\CommandRetry The retry wrapper
     */
    auto getDisconnectRetry(): CommandRetry
    {
        return new CommandRetry(new ReconnectStrategy(this));
    }

    /**
     * Gets the driver instance.
     *
     * @return \Cake\Database\IDriver
     */
    auto getDriver(): IDriver
    {
        return this._driver;
    }

    /**
     * Connects to the configured database.
     *
     * @throws \Cake\Database\Exception\MissingConnectionException If database connection could not be established.
     * @return bool true, if the connection was already established or the attempt was successful.
     */
    bool connect() {
        try {
            return this._driver.connect();
        } catch (MissingConnectionException $e) {
            throw $e;
        } catch (Throwable $e) {
            throw new MissingConnectionException(
                [
                    "driver" => App::shortName(get_class(this._driver), "Database/Driver"),
                    "reason" => $e.getMessage(),
                ],
                null,
                $e
            );
        }
    }

    /**
     * Disconnects from database server.
     *
     * @return void
     */
    void disconnect() {
        this._driver.disconnect();
    }

    /**
     * Returns whether connection to database server was already established.
     */
    bool isConnected() {
        return this._driver.isConnected();
    }

    /**
     * Prepares a SQL statement to be executed.
     *
     * @param \Cake\Database\Query|string myQuery The SQL to convert into a prepared statement.
     * @return \Cake\Database\IStatement
     */
    function prepare(myQuery): IStatement
    {
        return this.getDisconnectRetry().run(function () use (myQuery) {
            $statement = this._driver.prepare(myQuery);

            if (this._logQueries) {
                $statement = this._newLogger($statement);
            }

            return $statement;
        });
    }

    /**
     * Executes a query using myParams for interpolating values and myTypes as a hint for each
     * those params.
     *
     * @param string mySql SQL to be executed and interpolated with myParams
     * @param array myParams list or associative array of params to be interpolated in mySql as values
     * @param array myTypes list or associative array of types to be used for casting values in query
     * @return \Cake\Database\IStatement executed statement
     */
    auto execute(string mySql, array myParams = [], array myTypes = []): IStatement
    {
        return this.getDisconnectRetry().run(function () use (mySql, myParams, myTypes) {
            $statement = this.prepare(mySql);
            if (!empty(myParams)) {
                $statement.bind(myParams, myTypes);
            }
            $statement.execute();

            return $statement;
        });
    }

    /**
     * Compiles a Query object into a SQL string according to the dialect for this
     * connection"s driver
     *
     * @param \Cake\Database\Query myQuery The query to be compiled
     * @param \Cake\Database\ValueBinder $binder Value binder
     */
    string compileQuery(Query myQuery, ValueBinder $binder) {
        return this.getDriver().compileQuery(myQuery, $binder)[1];
    }

    /**
     * Executes the provided query after compiling it for the specific driver
     * dialect and returns the executed Statement object.
     *
     * @param \Cake\Database\Query myQuery The query to be executed
     * @return \Cake\Database\IStatement executed statement
     */
    function run(Query myQuery): IStatement
    {
        return this.getDisconnectRetry().run(function () use (myQuery) {
            $statement = this.prepare(myQuery);
            myQuery.getValueBinder().attachTo($statement);
            $statement.execute();

            return $statement;
        });
    }

    /**
     * Executes a SQL statement and returns the Statement object as result.
     *
     * @param string mySql The SQL query to execute.
     * @return \Cake\Database\IStatement
     */
    function query(string mySql): IStatement
    {
        return this.getDisconnectRetry().run(function () use (mySql) {
            $statement = this.prepare(mySql);
            $statement.execute();

            return $statement;
        });
    }

    /**
     * Create a new Query instance for this connection.
     *
     * @return \Cake\Database\Query
     */
    function newQuery(): Query
    {
        return new Query(this);
    }

    /**
     * Sets a Schema\Collection object for this connection.
     *
     * @param \Cake\Database\Schema\ICollection myCollection The schema collection object
     * @return this
     */
    auto setSchemaCollection(SchemaICollection myCollection) {
        this._schemaCollection = myCollection;

        return this;
    }

    /**
     * Gets a Schema\Collection object for this connection.
     *
     * @return \Cake\Database\Schema\ICollection
     */
    auto getSchemaCollection(): SchemaICollection
    {
        if (this._schemaCollection !== null) {
            return this._schemaCollection;
        }

        if (!empty(this._config["cacheMetadata"])) {
            return this._schemaCollection = new CachedCollection(
                new SchemaCollection(this),
                empty(this._config["cacheKeyPrefix"]) ? this.configName() : this._config["cacheKeyPrefix"],
                this.getCacher()
            );
        }

        return this._schemaCollection = new SchemaCollection(this);
    }

    /**
     * Executes an INSERT query on the specified table.
     *
     * @param string myTable the table to insert values in
     * @param array myValues values to be inserted
     * @param array<string, string> myTypes list of associative array containing the types to be used for casting
     * @return \Cake\Database\IStatement
     */
    function insert(string myTable, array myValues, array myTypes = []): IStatement
    {
        return this.getDisconnectRetry().run(function () use (myTable, myValues, myTypes) {
            $columns = array_keys(myValues);

            return this.newQuery().insert($columns, myTypes)
                .into(myTable)
                .values(myValues)
                .execute();
        });
    }

    /**
     * Executes an UPDATE statement on the specified table.
     *
     * @param string myTable the table to update rows from
     * @param array myValues values to be updated
     * @param array $conditions conditions to be set for update statement
     * @param array myTypes list of associative array containing the types to be used for casting
     * @return \Cake\Database\IStatement
     */
    function update(string myTable, array myValues, array $conditions = [], array myTypes = []): IStatement
    {
        return this.getDisconnectRetry().run(function () use (myTable, myValues, $conditions, myTypes) {
            return this.newQuery().update(myTable)
                .set(myValues, myTypes)
                .where($conditions, myTypes)
                .execute();
        });
    }

    /**
     * Executes a DELETE statement on the specified table.
     *
     * @param string myTable the table to delete rows from
     * @param array $conditions conditions to be set for delete statement
     * @param array myTypes list of associative array containing the types to be used for casting
     * @return \Cake\Database\IStatement
     */
    function delete(string myTable, array $conditions = [], array myTypes = []): IStatement
    {
        return this.getDisconnectRetry().run(function () use (myTable, $conditions, myTypes) {
            return this.newQuery().delete(myTable)
                .where($conditions, myTypes)
                .execute();
        });
    }

    /**
     * Starts a new transaction.
     *
     * @return void
     */
    void begin() {
        if (!this._transactionStarted) {
            if (this._logQueries) {
                this.log("BEGIN");
            }

            this.getDisconnectRetry().run(void () {
                this._driver.beginTransaction();
            });

            this._transactionLevel = 0;
            this._transactionStarted = true;
            this.nestedTransactionRollbackException = null;

            return;
        }

        this._transactionLevel++;
        if (this.isSavePointsEnabled()) {
            this.createSavePoint((string)this._transactionLevel);
        }
    }

    /**
     * Commits current transaction.
     *
     * @return bool true on success, false otherwise
     */
    bool commit() {
        if (!this._transactionStarted) {
            return false;
        }

        if (this._transactionLevel === 0) {
            if (this.wasNestedTransactionRolledback()) {
                /** @var \Cake\Database\Exception\NestedTransactionRollbackException $e */
                $e = this.nestedTransactionRollbackException;
                this.nestedTransactionRollbackException = null;
                throw $e;
            }

            this._transactionStarted = false;
            this.nestedTransactionRollbackException = null;
            if (this._logQueries) {
                this.log("COMMIT");
            }

            return this._driver.commitTransaction();
        }
        if (this.isSavePointsEnabled()) {
            this.releaseSavePoint((string)this._transactionLevel);
        }

        this._transactionLevel--;

        return true;
    }

    /**
     * Rollback current transaction.
     *
     * @param bool|null $toBeginning Whether the transaction should be rolled back to the
     * beginning of it. Defaults to false if using savepoints, or true if not.
     * @return bool
     */
    bool rollback(?bool $toBeginning = null) {
        if (!this._transactionStarted) {
            return false;
        }

        $useSavePoint = this.isSavePointsEnabled();
        if ($toBeginning === null) {
            $toBeginning = !$useSavePoint;
        }
        if (this._transactionLevel === 0 || $toBeginning) {
            this._transactionLevel = 0;
            this._transactionStarted = false;
            this.nestedTransactionRollbackException = null;
            if (this._logQueries) {
                this.log("ROLLBACK");
            }
            this._driver.rollbackTransaction();

            return true;
        }

        $savePoint = this._transactionLevel--;
        if ($useSavePoint) {
            this.rollbackSavepoint($savePoint);
        } elseif (this.nestedTransactionRollbackException === null) {
            this.nestedTransactionRollbackException = new NestedTransactionRollbackException();
        }

        return true;
    }

    /**
     * Enables/disables the usage of savepoints, enables only if driver the allows it.
     *
     * If you are trying to enable this feature, make sure you check
     * `isSavePointsEnabled()` to verify that savepoints were enabled successfully.
     *
     * @param bool myEnable Whether save points should be used.
     * @return this
     */
    function enableSavePoints(bool myEnable = true) {
        if (myEnable === false) {
            this._useSavePoints = false;
        } else {
            this._useSavePoints = this._driver.supports(IDriver::FEATURE_SAVEPOINT);
        }

        return this;
    }

    /**
     * Disables the usage of savepoints.
     *
     * @return this
     */
    function disableSavePoints() {
        this._useSavePoints = false;

        return this;
    }

    /**
     * Returns whether this connection is using savepoints for nested transactions
     *
     * @return bool true if enabled, false otherwise
     */
    bool isSavePointsEnabled() {
        return this._useSavePoints;
    }

    /**
     * Creates a new save point for nested transactions.
     *
     * @param string|int myName Save point name or id
     * @return void
     */
    void createSavePoint(myName) {
        this.execute(this._driver.savePointSQL(myName)).closeCursor();
    }

    /**
     * Releases a save point by its name.
     *
     * @param string|int myName Save point name or id
     * @return void
     */
    void releaseSavePoint(myName) {
        mySql = this._driver.releaseSavePointSQL(myName);
        if (mySql) {
            this.execute(mySql).closeCursor();
        }
    }

    /**
     * Rollback a save point by its name.
     *
     * @param string|int myName Save point name or id
     * @return void
     */
    void rollbackSavepoint(myName) {
        this.execute(this._driver.rollbackSavePointSQL(myName)).closeCursor();
    }

    /**
     * Run driver specific SQL to disable foreign key checks.
     *
     * @return void
     */
    void disableForeignKeys() {
        this.getDisconnectRetry().run(void () {
            this.execute(this._driver.disableForeignKeySQL()).closeCursor();
        });
    }

    /**
     * Run driver specific SQL to enable foreign key checks.
     *
     * @return void
     */
    void enableForeignKeys() {
        this.getDisconnectRetry().run(void () {
            this.execute(this._driver.enableForeignKeySQL()).closeCursor();
        });
    }

    /**
     * Returns whether the driver supports adding or dropping constraints
     * to already created tables.
     *
     * @return bool true if driver supports dynamic constraints
     * @deprecated 4.3.0 Fixtures no longer dynamically drop and create constraints.
     */
    bool supportsDynamicConstraints() {
        return this._driver.supportsDynamicConstraints();
    }

    /**
     * @inheritDoc
     */
    function transactional(callable $callback) {
        this.begin();

        try {
            myResult = $callback(this);
        } catch (Throwable $e) {
            this.rollback(false);
            throw $e;
        }

        if (myResult === false) {
            this.rollback(false);

            return false;
        }

        try {
            this.commit();
        } catch (NestedTransactionRollbackException $e) {
            this.rollback(false);
            throw $e;
        }

        return myResult;
    }

    /**
     * Returns whether some nested transaction has been already rolled back.
     *
     * @return bool
     */
    protected bool wasNestedTransactionRolledback() {
        return this.nestedTransactionRollbackException instanceof NestedTransactionRollbackException;
    }

    /**
     * @inheritDoc
     */
    function disableConstraints(callable $callback) {
        return this.getDisconnectRetry().run(function () use ($callback) {
            this.disableForeignKeys();

            try {
                myResult = $callback(this);
            } finally {
                this.enableForeignKeys();
            }

            return myResult;
        });
    }

    /**
     * Checks if a transaction is running.
     *
     * @return bool True if a transaction is running else false.
     */
    bool inTransaction() {
        return this._transactionStarted;
    }

    /**
     * Quotes value to be used safely in database query.
     *
     * This uses `PDO::quote()` and requires `supportsQuoting()` to work.
     *
     * @param mixed myValue The value to quote.
     * @param \Cake\Database\TypeInterface|string|int myType Type to be used for determining kind of quoting to perform
     * @return string Quoted value
     */
    string quote(myValue, myType = "string") {
        [myValue, myType] = this.cast(myValue, myType);

        return this._driver.quote(myValue, myType);
    }

    /**
     * Checks if using `quote()` is supported.
     *
     * This is not required to use `quoteIdentifier()`.
     */
    bool supportsQuoting() {
        return this._driver.supports(IDriver::FEATURE_QUOTE);
    }

    /**
     * Quotes a database identifier (a column name, table name, etc..) to
     * be used safely in queries without the risk of using reserved words.
     *
     * This does not require `supportsQuoting()` to work.
     *
     * @param string myIdentifier The identifier to quote.
     */
    string quoteIdentifier(string myIdentifier) {
        return this._driver.quoteIdentifier(myIdentifier);
    }

    /**
     * Enables or disables metadata caching for this connection
     *
     * Changing this setting will not modify existing schema collections objects.
     *
     * @param string|bool $cache Either boolean false to disable metadata caching, or
     *   true to use `_cake_model_` or the name of the cache config to use.
     * @return void
     */
    void cacheMetadata($cache) {
        this._schemaCollection = null;
        this._config["cacheMetadata"] = $cache;
        if (is_string($cache)) {
            this.cacher = null;
        }
    }

    /**
     * @inheritDoc
     */
    auto setCacher(ICache $cacher) {
        this.cacher = $cacher;

        return this;
    }

    /**
     * @inheritDoc
     */
    auto getCacher(): ICache
    {
        if (this.cacher !== null) {
            return this.cacher;
        }

        myConfigName = this._config["cacheMetadata"] ?? "_cake_model_";
        if (!is_string(myConfigName)) {
            myConfigName = "_cake_model_";
        }

        if (!class_exists(Cache::class)) {
            throw new RuntimeException(
                "To use caching you must either set a cacher using Connection::setCacher()" .
                " or require the cakephp/cache package in your composer config."
            );
        }

        return this.cacher = Cache::pool(myConfigName);
    }

    /**
     * Enable/disable query logging
     *
     * @param bool myEnable Enable/disable query logging
     * @return this
     */
    function enableQueryLogging(bool myEnable = true) {
        this._logQueries = myEnable;

        return this;
    }

    /**
     * Disable query logging
     *
     * @return this
     */
    function disableQueryLogging() {
        this._logQueries = false;

        return this;
    }

    /**
     * Check if query logging is enabled.
     */
    bool isQueryLoggingEnabled() {
        return this._logQueries;
    }

    /**
     * Sets a logger
     *
     * @param \Psr\Log\LoggerInterface $logger Logger object
     * @return this
     * @psalm-suppress ImplementedReturnTypeMismatch
     */
    auto setLogger(LoggerInterface $logger) {
        this._logger = $logger;

        return this;
    }

    /**
     * Gets the logger object
     *
     * @return \Psr\Log\LoggerInterface logger instance
     */
    auto getLogger(): LoggerInterface
    {
        if (this._logger !== null) {
            return this._logger;
        }

        if (!class_exists(QueryLogger::class)) {
            throw new RuntimeException(
                "For logging you must either set a logger using Connection::setLogger()" .
                " or require the cakephp/log package in your composer config."
            );
        }

        return this._logger = new QueryLogger(["connection" => this.configName()]);
    }

    /**
     * Logs a Query string using the configured logger object.
     *
     * @param string mySql string to be logged
     * @return void
     */
    void log(string mySql) {
        myQuery = new LoggedQuery();
        myQuery.query = mySql;
        this.getLogger().debug((string)myQuery, ["query" => myQuery]);
    }

    /**
     * Returns a new statement object that will log the activity
     * for the passed original statement instance.
     *
     * @param \Cake\Database\IStatement $statement the instance to be decorated
     * @return \Cake\Database\Log\LoggingStatement
     */
    protected auto _newLogger(IStatement $statement): LoggingStatement
    {
        $log = new LoggingStatement($statement, this._driver);
        $log.setLogger(this.getLogger());

        return $log;
    }

    /**
     * Returns an array that can be used to describe the internal state of this
     * object.
     *
     * @return array<string, mixed>
     */
    auto __debugInfo(): array
    {
        $secrets = [
            "password" => "*****",
            "username" => "*****",
            "host" => "*****",
            "database" => "*****",
            "port" => "*****",
        ];
        $replace = array_intersect_key($secrets, this._config);
        myConfig = $replace + this._config;

        return [
            "config" => myConfig,
            "driver" => this._driver,
            "transactionLevel" => this._transactionLevel,
            "transactionStarted" => this._transactionStarted,
            "useSavePoints" => this._useSavePoints,
            "logQueries" => this._logQueries,
            "logger" => this._logger,
        ];
    }
}
