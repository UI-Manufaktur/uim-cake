module uim.cake.databases;

@safe:
import uim.cake;

/**
 * Interface for database driver.
 *
 * @method int|null getMaxAliasLength() Returns the maximum alias length allowed.
 * @method int getConnectRetries() Returns the number of connection retry attempts made.
 * @method bool supports(string $feature) Checks whether a feature is supported by the driver.
 * @method bool inTransaction() Returns whether a transaction is active.
 */
interface IDriver
{
    /**
     * Common Table Expressions (with clause) support.
     *
     * @var string
     */
    const FEATURE_CTE = "cte";

    /**
     * Disabling constraints without being in transaction support.
     *
     * @var string
     */
    const FEATURE_DISABLE_CONSTRAINT_WITHOUT_TRANSACTION = "disable-constraint-without-transaction";

    /**
     * Native JSON data type support.
     *
     * @var string
     */
    const FEATURE_JSON = "json";

    /**
     * PDO::quote() support.
     *
     * @var string
     */
    const FEATURE_QUOTE = "quote";

    /**
     * Transaction savepoint support.
     *
     * @var string
     */
    const FEATURE_SAVEPOINT = "savepoint";

    /**
     * Truncate with foreign keys attached support.
     *
     * @var string
     */
    const FEATURE_TRUNCATE_WITH_CONSTRAINTS = "truncate-with-constraints";

    /**
     * Window function support (all or partial clauses).
     *
     * @var string
     */
    const FEATURE_WINDOW = "window";

    /**
     * Establishes a connection to the database server.
     *
     * @throws uim.cake.databases.exceptions.MissingConnectionException If database connection could not be established.
     * @return bool True on success, false on failure.
     */
    function connect(): bool;

    /**
     * Disconnects from database server.
     */
    void disconnect(): void;

    /**
     * Returns correct connection resource or object that is internally used.
     *
     * @return object Connection object used internally.
     */
    function getConnection();

    /**
     * Set the internal connection object.
     *
     * @param object $connection The connection instance.
     * @return this
     */
    function setConnection($connection);

    /**
     * Returns whether php is able to use this driver for connecting to database.
     *
     * @return bool True if it is valid to use this driver.
     */
    function enabled(): bool;

    /**
     * Prepares a sql statement to be executed.
     *
     * @param uim.cake.databases.Query|string $query The query to turn into a prepared statement.
     * @return uim.cake.databases.IStatement
     */
    function prepare($query): IStatement;

    /**
     * Starts a transaction.
     *
     * @return bool True on success, false otherwise.
     */
    function beginTransaction(): bool;

    /**
     * Commits a transaction.
     *
     * @return bool True on success, false otherwise.
     */
    function commitTransaction(): bool;

    /**
     * Rollbacks a transaction.
     *
     * @return bool True on success, false otherwise.
     */
    function rollbackTransaction(): bool;

    /**
     * Get the SQL for releasing a save point.
     *
     * @param string|int $name Save point name or id
     */
    string releaseSavePointSQL($name);

    /**
     * Get the SQL for creating a save point.
     *
     * @param string|int $name Save point name or id
     */
    string savePointSQL($name);

    /**
     * Get the SQL for rollingback a save point.
     *
     * @param string|int $name Save point name or id
     */
    string rollbackSavePointSQL($name);

    /**
     * Get the SQL for disabling foreign keys.
     */
    string disableForeignKeySQL();

    /**
     * Get the SQL for enabling foreign keys.
     */
    string enableForeignKeySQL();

    /**
     * Returns whether the driver supports adding or dropping constraints
     * to already created tables.
     *
     * @return bool True if driver supports dynamic constraints.
     * @deprecated 4.3.0 Fixtures no longer dynamically drop and create constraints.
     */
    function supportsDynamicConstraints(): bool;

    /**
     * Returns whether this driver supports save points for nested transactions.
     *
     * @return bool True if save points are supported, false otherwise.
     * @deprecated 4.3.0 Use `supports(IDriver::FEATURE_SAVEPOINT)` instead
     */
    function supportsSavePoints(): bool;

    /**
     * Returns a value in a safe representation to be used in a query string
     *
     * @param mixed $value The value to quote.
     * @param int $type Must be one of the \PDO::PARAM_* constants
     */
    string quote($value, $type);

    /**
     * Checks if the driver supports quoting.
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(IDriver::FEATURE_QUOTE)` instead
     */
    function supportsQuoting(): bool;

    /**
     * Returns a callable function that will be used to transform a passed Query object.
     * This function, in turn, will return an instance of a Query object that has been
     * transformed to accommodate any specificities of the SQL dialect in use.
     *
     * @param string $type The type of query to be transformed
     * (select, insert, update, delete).
     * @return \Closure
     */
    function queryTranslator(string $type): Closure;

    /**
     * Get the schema dialect.
     *
     * Used by {@link uim.cake.databases.Schema} package to reflect schema and
     * generate schema.
     *
     * If all the tables that use this Driver specify their
     * own schemas, then this may return null.
     *
     * @return uim.cake.databases.Schema\SchemaDialect
     */
    function schemaDialect(): SchemaDialect;

    /**
     * Quotes a database identifier (a column name, table name, etc..) to
     * be used safely in queries without the risk of using reserved words.
     *
     * @param string $identifier The identifier expression to quote.
     */
    string quoteIdentifier(string $identifier);

    /**
     * Escapes values for use in schema definitions.
     *
     * @param mixed $value The value to escape.
     * @return string String for use in schema definitions.
     */
    string schemaValue($value);

    /**
     * Returns the schema name that"s being used.
     */
    string schema();

    /**
     * Returns last id generated for a table or sequence in database.
     *
     * @param string|null $table table name or sequence to get last insert value from.
     * @param string|null $column the name of the column representing the primary key.
     * @return string|int
     */
    function lastInsertId(?string $table = null, ?string $column = null);

    /**
     * Checks whether the driver is connected.
     *
     */
    bool isConnected(): bool;

    /**
     * Sets whether this driver should automatically quote identifiers
     * in queries.
     *
     * @param bool $enable Whether to enable auto quoting
     * @return this
     */
    function enableAutoQuoting(bool $enable = true);

    /**
     * Disable auto quoting of identifiers in queries.
     *
     * @return this
     */
    function disableAutoQuoting();

    /**
     * Returns whether this driver should automatically quote identifiers
     * in queries.
     *
     */
    bool isAutoQuotingEnabled(): bool;

    /**
     * Transforms the passed query to this Driver"s dialect and returns an instance
     * of the transformed query and the full compiled SQL string.
     *
     * @param uim.cake.databases.Query $query The query to compile.
     * @param uim.cake.databases.ValueBinder aBinder The value binder to use.
     * @return array containing 2 entries. The first entity is the transformed query
     * and the second one the compiled SQL.
     */
    function compileQuery(Query $query, ValueBinder aBinder): array;

    /**
     * Returns an instance of a QueryCompiler.
     *
     * @return uim.cake.databases.QueryCompiler
     */
    function newCompiler(): QueryCompiler;

    /**
     * Constructs new TableSchema.
     *
     * @param string $table The table name.
     * @param array $columns The list of columns for the schema.
     * @return uim.cake.databases.Schema\TableSchema
     */
    function newTableSchema(string $table, array $columns = []): TableSchema;
}
