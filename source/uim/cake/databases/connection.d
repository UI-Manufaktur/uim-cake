/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.databases;

@safe:
import uim.cake;

// Represents a connection with a database server.
class Connection : IConnection {
    use TypeConverterTrait;

    /**
     * Contains the configuration params for this connection.
     *
     * @var array<string, mixed>
     */
    protected _config;

    /**
     * Driver object, responsible for creating the real connection
     * and provide specific SQL dialect.
     *
     * @var uim.cake.Database\IDriver
     */
    protected _driver;

    // Contains how many nested transactions have been started.
    protected int $_transactionLevel = 0;

    // Whether a transaction is active in this connection.
    protected bool $_transactionStarted = false;

    /**
     * Whether this connection can and should use savepoints for nested
     * transactions.
     */
    protected bool $_useSavePoints = false;

    /**
     * Whether to log queries generated during this connection.
     *
     * @var bool
     */
    protected _logQueries = false;

    /**
     * Logger object instance.
     *
     * @var \Psr\Log\LoggerInterface|null
     */
    protected _logger;

    /**
     * Cacher object instance.
     *
     * @var \Psr\SimpleCache\ICache|null
     */
    protected cacher;

    /**
     * The schema collection object
     *
     * @var uim.cake.Database\Schema\ICollection|null
     */
    protected _schemaCollection;

    /**
     * NestedTransactionRollbackException object instance, will be stored if
     * the rollback method is called in some nested transaction.
     *
     * @var uim.cake.Database\Exception\NestedTransactionRollbackException|null
     */
    protected nestedTransactionRollbackException;

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
        _config = myConfig;

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
        if (_transactionStarted && class_exists(Log::class)) {
            Log::warning("The connection is going to be closed but there is an active transaction.");
        }
    }

    array config() {
        return _config;
    }

    string configName() {
        return _config["name"] ?? "";
    }

    /**
     * Sets the driver instance. If a string is passed it will be treated
     * as a class name and will be instantiated.
     *
     * @param uim.cake.Database\IDriver|string myDriver The driver instance to use.
     * @param array<string, mixed> myConfig Config for a new driver.
     * @throws \Cake\Database\Exception\MissingDriverException When a driver class is missing.
     * @throws \Cake\Database\Exception\MissingExtensionException When a driver"s PHP extension is missing.
     * @return this
     */
    auto setDriver(myDriver, myConfig = []) {
        if (is_string(myDriver)) {
            /** @psalm-var class-string<\Cake\Database\IDriver>|null myClassName */
            myClassName = App::className(myDriver, "Database/Driver");
            if (myClassName is null) {
                throw new MissingDriverException(["driver":myDriver]);
            }
            myDriver = new myClassName(myConfig);
        }
        if (!myDriver.enabled()) {
            throw new MissingExtensionException(["driver":get_class(myDriver)]);
        }

        _driver = myDriver;

        return this;
    }

    /**
     * Get the retry wrapper object that is allows recovery from server disconnects
     * while performing certain database actions, such as executing a query.
     *
     * @return uim.cake.Core\Retry\CommandRetry The retry wrapper
     */
    CommandRetry getDisconnectRetry() {
        return new CommandRetry(new ReconnectStrategy(this));
    }

    /**
     * Gets the driver instance.
     *
     * @return uim.cake.Database\IDriver
     */
    auto getDriver(): IDriver
    {
        return _driver;
    }

    /**
     * Connects to the configured database.
     *
     * @throws \Cake\Database\Exception\MissingConnectionException If database connection could not be established.
     * @return bool true, if the connection was already established or the attempt was successful.
     */
    bool connect() {
        try {
            return _driver.connect();
        } catch (MissingConnectionException $e) {
            throw $e;
        } catch (Throwable $e) {
            throw new MissingConnectionException(
                [
                    "driver":App::shortName(get_class(_driver), "Database/Driver"),
                    "reason":$e.getMessage(),
                ],
                null,
                $e
            );
        }
    }

    /**
     * Disconnects from database server.
     *
     */
    void disconnect() {
        _driver.disconnect();
    }

    /**
     * Returns whether connection to database server was already established.
     */
    bool isConnected() {
        return _driver.isConnected();
    }

    /**
     * Prepares a SQL statement to be executed.
     *
     * @param uim.cake.Database\Query|string myQuery The SQL to convert into a prepared statement.
     * @return uim.cake.Database\IStatement
     */
    function prepare(myQuery): IStatement
    {
        return this.getDisconnectRetry().run(function () use (myQuery) {
            $statement = _driver.prepare(myQuery);

            if (_logQueries) {
                $statement = _newLogger($statement);
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
     * @return uim.cake.Database\IStatement executed statement
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
     * @param uim.cake.Database\Query myQuery The query to be compiled
     * @param uim.cake.Database\ValueBinder $binder Value binder
     */
    string compileQuery(Query myQuery, ValueBinder $binder) {
        return this.getDriver().compileQuery(myQuery, $binder)[1];
    }

    /**
     * Executes the provided query after compiling it for the specific driver
     * dialect and returns the executed Statement object.
     *
     * @param uim.cake.Database\Query myQuery The query to be executed
     * @return uim.cake.Database\IStatement executed statement
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
     * @return uim.cake.Database\IStatement
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
     * @return uim.cake.Database\Query
     */
    function newQuery(): Query
    {
        return new Query(this);
    }

    /**
     * Sets a Schema\Collection object for this connection.
     *
     * @param uim.cake.Database\Schema\ICollection myCollection The schema collection object
     * @return this
     */
    auto setSchemaCollection(SchemaICollection myCollection) {
        _schemaCollection = myCollection;

        return this;
    }

    /**
     * Gets a Schema\Collection object for this connection.
     *
     * @return uim.cake.Database\Schema\ICollection
     */
    auto getSchemaCollection(): SchemaICollection
    {
        if (_schemaCollection  !is null) {
            return _schemaCollection;
        }

        if (!empty(_config["cacheMetadata"])) {
            return _schemaCollection = new CachedCollection(
                new SchemaCollection(this),
                empty(_config["cacheKeyPrefix"]) ? this.configName() : _config["cacheKeyPrefix"],
                this.getCacher()
            );
        }

        return _schemaCollection = new SchemaCollection(this);
    }

    /**
     * Executes an INSERT query on the specified table.
     *
     * @param string myTable the table to insert values in
     * @param array myValues values to be inserted
     * @param array<string, string> myTypes list of associative array containing the types to be used for casting
     * @return uim.cake.Database\IStatement
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
     * @return uim.cake.Database\IStatement
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
     * @return uim.cake.Database\IStatement
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
     */
    void begin() {
        if (!_transactionStarted) {
            if (_logQueries) {
                this.log("BEGIN");
            }

            this.getDisconnectRetry().run(void () {
                _driver.beginTransaction();
            });

            _transactionLevel = 0;
            _transactionStarted = true;
            this.nestedTransactionRollbackException = null;

            return;
        }

        _transactionLevel++;
        if (this.isSavePointsEnabled()) {
            this.createSavePoint((string)_transactionLevel);
        }
    }

    /**
     * Commits current transaction.
     *
     * @return bool true on success, false otherwise
     */
    bool commit() {
        if (!_transactionStarted) {
            return false;
        }

        if (_transactionLevel == 0) {
            if (this.wasNestedTransactionRolledback()) {
                /** @var uim.cake.Database\Exception\NestedTransactionRollbackException $e */
                $e = this.nestedTransactionRollbackException;
                this.nestedTransactionRollbackException = null;
                throw $e;
            }

            _transactionStarted = false;
            this.nestedTransactionRollbackException = null;
            if (_logQueries) {
                this.log("COMMIT");
            }

            return _driver.commitTransaction();
        }
        if (this.isSavePointsEnabled()) {
            this.releaseSavePoint((string)_transactionLevel);
        }

        _transactionLevel--;

        return true;
    }

    /**
     * Rollback current transaction.
     *
     * @param bool|null $toBeginning Whether the transaction should be rolled back to the
     * beginning of it. Defaults to false if using savepoints, or true if not.
     */
    bool rollback(?bool $toBeginning = null) {
        if (!_transactionStarted) {
            return false;
        }

        $useSavePoint = this.isSavePointsEnabled();
        if ($toBeginning is null) {
            $toBeginning = !$useSavePoint;
        }
        if (_transactionLevel == 0 || $toBeginning) {
            _transactionLevel = 0;
            _transactionStarted = false;
            this.nestedTransactionRollbackException = null;
            if (_logQueries) {
                this.log("ROLLBACK");
            }
            _driver.rollbackTransaction();

            return true;
        }

        $savePoint = _transactionLevel--;
        if ($useSavePoint) {
            this.rollbackSavepoint($savePoint);
        } elseif (this.nestedTransactionRollbackException is null) {
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
        if (myEnable == false) {
            _useSavePoints = false;
        } else {
            _useSavePoints = _driver.supports(IDriver::FEATURE_SAVEPOINT);
        }

        return this;
    }

    /**
     * Disables the usage of savepoints.
     *
     * @return this
     */
    function disableSavePoints() {
        _useSavePoints = false;

        return this;
    }

    /**
     * Returns whether this connection is using savepoints for nested transactions
     *
     * @return bool true if enabled, false otherwise
     */
    bool isSavePointsEnabled() {
        return _useSavePoints;
    }

    /**
     * Creates a new save point for nested transactions.
     *
     * @param string|int myName Save point name or id
     */
    void createSavePoint(myName) {
        this.execute(_driver.savePointSQL(myName)).closeCursor();
    }

    /**
     * Releases a save point by its name.
     *
     * @param string|int myName Save point name or id
     */
    void releaseSavePoint(myName) {
        mySql = _driver.releaseSavePointSQL(myName);
        if (mySql) {
            this.execute(mySql).closeCursor();
        }
    }

    /**
     * Rollback a save point by its name.
     *
     * @param string|int myName Save point name or id
     */
    void rollbackSavepoint(myName) {
        this.execute(_driver.rollbackSavePointSQL(myName)).closeCursor();
    }

    /**
     * Run driver specific SQL to disable foreign key checks.
     *
     */
    void disableForeignKeys() {
        this.getDisconnectRetry().run(void () {
            this.execute(_driver.disableForeignKeySQL()).closeCursor();
        });
    }

    /**
     * Run driver specific SQL to enable foreign key checks.
     *
     */
    void enableForeignKeys() {
        this.getDisconnectRetry().run(void () {
            this.execute(_driver.enableForeignKeySQL()).closeCursor();
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
        return _driver.supportsDynamicConstraints();
    }

    
    function transactional(callable $callback) {
        this.begin();

        try {
            myResult = $callback(this);
        } catch (Throwable $e) {
            this.rollback(false);
            throw $e;
        }

        if (myResult == false) {
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
     */
    protected bool wasNestedTransactionRolledback() {
        return this.nestedTransactionRollbackException instanceof NestedTransactionRollbackException;
    }

    
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
        return _transactionStarted;
    }

    /**
     * Quotes value to be used safely in database query.
     *
     * This uses `PDO::quote()` and requires `supportsQuoting()` to work.
     *
     * @param mixed myValue The value to quote.
     * @param uim.cake.Database\IType|string|int myType Type to be used for determining kind of quoting to perform
     * @return  Quoted value
     */
    string quote(myValue, myType = "string") {
        [myValue, myType] = this.cast(myValue, myType);

        return _driver.quote(myValue, myType);
    }

    /**
     * Checks if using `quote()` is supported.
     *
     * This is not required to use `quoteIdentifier()`.
     */
    bool supportsQuoting() {
        return _driver.supports(IDriver::FEATURE_QUOTE);
    }

    /**
     * Quotes a database identifier (a column name, table name, etc..) to
     * be used safely in queries without the risk of using reserved words.
     *
     * This does not require `supportsQuoting()` to work.
     *
     * @param myIdentifier The identifier to quote.
     */
    string quoteIdentifier(string myIdentifier) {
        return _driver.quoteIdentifier(myIdentifier);
    }

    /**
     * Enables or disables metadata caching for this connection
     *
     * Changing this setting will not modify existing schema collections objects.
     *
     * @param string|bool $cache Either boolean false to disable metadata caching, or
     *   true to use `_cake_model_` or the name of the cache config to use.
     */
    void cacheMetadata($cache) {
        _schemaCollection = null;
        _config["cacheMetadata"] = $cache;
        if (is_string($cache)) {
            this.cacher = null;
        }
    }

    
    auto setCacher(ICache $cacher) {
        this.cacher = $cacher;

        return this;
    }

    
    auto getCacher(): ICache
    {
        if (this.cacher  !is null) {
            return this.cacher;
        }

        myConfigName = _config["cacheMetadata"] ?? "_cake_model_";
        if (!is_string(myConfigName)) {
            myConfigName = "_cake_model_";
        }

        if (!class_exists(Cache::class)) {
            throw new RuntimeException(
                "To use caching you must either set a cacher using Connection::setCacher()" .
                " or require the UIM/cache package in your composer config."
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
        _logQueries = myEnable;

        return this;
    }

    /**
     * Disable query logging
     *
     * @return this
     */
    function disableQueryLogging() {
        _logQueries = false;

        return this;
    }

    /**
     * Check if query logging is enabled.
     */
    bool isQueryLoggingEnabled() {
        return _logQueries;
    }

    /**
     * Sets a logger
     *
     * @param \Psr\Log\LoggerInterface $logger Logger object
     * @return this
     * @psalm-suppress ImplementedReturnTypeMismatch
     */
    auto setLogger(LoggerInterface $logger) {
        _logger = $logger;

        return this;
    }

    /**
     * Gets the logger object
     *
     * @return \Psr\Log\LoggerInterface logger instance
     */
    auto getLogger(): LoggerInterface
    {
        if (_logger  !is null) {
            return _logger;
        }

        if (!class_exists(QueryLogger::class)) {
            throw new RuntimeException(
                "For logging you must either set a logger using Connection::setLogger()" .
                " or require the UIM/log package in your composer config."
            );
        }

        return _logger = new QueryLogger(["connection":this.configName()]);
    }

    /**
     * Logs a Query string using the configured logger object.
     *
     * @param string mySql string to be logged
     */
    void log(string mySql) {
        myQuery = new LoggedQuery();
        myQuery.query = mySql;
        this.getLogger().debug((string)myQuery, ["query":myQuery]);
    }

    /**
     * Returns a new statement object that will log the activity
     * for the passed original statement instance.
     *
     * @param uim.cake.Database\IStatement $statement the instance to be decorated
     * @return uim.cake.Database\Log\LoggingStatement
     */
    protected auto _newLogger(IStatement $statement): LoggingStatement
    {
        $log = new LoggingStatement($statement, _driver);
        $log.setLogger(this.getLogger());

        return $log;
    }

    /**
     * Returns an array that can be used to describe the internal state of this
     * object.
     *
     * @return array<string, mixed>
     */
    array __debugInfo() {
        $secrets = [
            "password":"*****",
            "username":"*****",
            "host":"*****",
            "database":"*****",
            "port":"*****",
        ];
        $replace = array_intersect_key($secrets, _config);
        myConfig = $replace + _config;

        return [
            "config":myConfig,
            "driver":_driver,
            "transactionLevel":_transactionLevel,
            "transactionStarted":_transactionStarted,
            "useSavePoints":_useSavePoints,
            "logQueries":_logQueries,
            "logger":_logger,
        ];
    }
}
