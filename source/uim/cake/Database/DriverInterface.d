module uim.cake.databases;

import uim.cake.databases.Schema\SchemaDialect;
import uim.cake.databases.Schema\TableSchema;
use Closure;

/**
 * Interface for database driver.
 *
 * @method int|null getMaxAliasLength() Returns the maximum alias length allowed.
 * @method int getConnectRetries() Returns the number of connection retry attempts made.
 * @method bool supports(string $feature) Checks whether a feature is supported by the driver.
 * @method bool inTransaction() Returns whether a transaction is active.
 */
interface IDriver {
    /**
     * Common Table Expressions (with clause) support.
     *
     * @var string
     */
    public const FEATURE_CTE = 'cte';

    /**
     * Disabling constraints without being in transaction support.
     *
     * @var string
     */
    public const FEATURE_DISABLE_CONSTRAINT_WITHOUT_TRANSACTION = 'disable-constraint-without-transaction';

    /**
     * Native JSON data type support.
     *
     * @var string
     */
    public const FEATURE_JSON = 'json';

    /**
     * PDO::quote() support.
     *
     * @var string
     */
    public const FEATURE_QUOTE = 'quote';

    /**
     * Transaction savepoint support.
     *
     * @var string
     */
    public const FEATURE_SAVEPOINT = 'savepoint';

    /**
     * Truncate with foreign keys attached support.
     *
     * @var string
     */
    public const FEATURE_TRUNCATE_WITH_CONSTRAINTS = 'truncate-with-constraints';

    /**
     * Window function support (all or partial clauses).
     *
     * @var string
     */
    public const FEATURE_WINDOW = 'window';

    /**
     * Establishes a connection to the database server.
     *
     * @throws \Cake\Database\Exception\MissingConnectionException If database connection could not be established.
     * @return bool True on success, false on failure.
     */
    bool connect();

    /**
     * Disconnects from database server.
     *
     * @return void
     */
    void disconnect() void;

    /**
     * Returns correct connection resource or object that is internally used.
     *
     * @return object Connection object used internally.
     */
    auto getConnection();

    /**
     * Set the internal connection object.
     *
     * @param object myConnection The connection instance.
     * @return this
     */
    auto setConnection(myConnection);

    /**
     * Returns whether php is able to use this driver for connecting to database.
     *
     * @return bool True if it is valid to use this driver.
     */
    bool enabled();

    /**
     * Prepares a sql statement to be executed.
     *
     * @param \Cake\Database\Query|string myQuery The query to turn into a prepared statement.
     * @return \Cake\Database\IStatement
     */
    IStatement prepare(myQuery);

    /**
     * Starts a transaction.
     *
     * @return bool True on success, false otherwise.
     */
    bool beginTransaction();

    // Commits a transaction - True on success, false otherwise.
    bool commitTransaction();

    // Rollbacks a transaction - True on success, false otherwise.
    bool rollbackTransaction();

    // Get the SQL for releasing a save point - myName Save point name or myid
     */
    string releaseSavePointSQL(UUID myId);
    string releaseSavePointSQL(string myName);

    /**
     * Get the SQL for creating a save point.
     *
     * @param string|int myName Save point name or id
     * @return string
     */
    string savePointSQL(myName);

    /**
     * Get the SQL for rollingback a save point.
     *
     * @param string|int myName Save point name or id
     */
    string rollbackSavePointSQL(myName);

    /**
     * Get the SQL for disabling foreign keys.
     */
    string disableForeignKeySQL();

    /**
     * Get the SQL for enabling foreign keys.
     *
     * @return string
     */
    string enableForeignKeySQL();

    /**
     * Returns whether the driver supports adding or dropping constraints
     * to already created tables.
     *
     * @return bool True if driver supports dynamic constraints.
     * @deprecated 4.3.0 Fixtures no longer dynamically drop and create constraints.
     */
    bool supportsDynamicConstraints();

    /**
     * Returns whether this driver supports save points for nested transactions.
     *
     * @return bool True if save points are supported, false otherwise.
     * @deprecated 4.3.0 Use `supports(IDriver::FEATURE_SAVEPOINT)` instead
     */
    bool supportsSavePoints();

    /**
     * Returns a value in a safe representation to be used in a query string
     *
     * @param mixed myValue The value to quote.
     * @param int myType Must be one of the \PDO::PARAM_* constants
     * @return string
     */
    string quote(myValue, myType);

    /**
     * Checks if the driver supports quoting.
     *
     * @return bool
     * @deprecated 4.3.0 Use `supports(IDriver::FEATURE_QUOTE)` instead
     */
    bool supportsQuoting();

    /**
     * Returns a callable function that will be used to transform a passed Query object.
     * This function, in turn, will return an instance of a Query object that has been
     * transformed to accommodate any specificities of the SQL dialect in use.
     *
     * @param string myType The type of query to be transformed
     * (select, insert, update, delete).
     * @return \Closure
     */
    Closure queryTranslator(string myType);

    /**
     * Get the schema dialect.
     *
     * Used by {@link \Cake\Database\Schema} package to reflect schema and
     * generate schema.
     *
     * If all the tables that use this Driver specify their
     * own schemas, then this may return null.
     *
     * @return \Cake\Database\Schema\SchemaDialect
     */
    SchemaDialect schemaDialect();

    /**
     * Quotes a database identifier (a column name, table name, etc..) to
     * be used safely in queries without the risk of using reserved words.
     *
     * @param string myIdentifier The identifier expression to quote.
     * @return string
     */
    function quoteIdentifier(string myIdentifier): string;

    /**
     * Escapes values for use in schema definitions.
     *
     * @param mixed myValue The value to escape.
     * @return string String for use in schema definitions.
     */
    function schemaValue(myValue): string;

    // Returns the schema name that's being used.
    string schema();

    /**
     * Returns last id generated for a table or sequence in database.
     *
     * @param string|null myTable table name or sequence to get last insert value from.
     * @param string|null $column the name of the column representing the primary key.
     * @return string|int
     */
    function lastInsertId(?string myTable = null, ?string $column = null);

    // Checks whether the driver is connected.
    bool isConnected();

    /**
     * Sets whether this driver should automatically quote identifiers
     * in queries.
     *
     * @param bool myEnable Whether to enable auto quoting
     */
    O enableAutoQuoting(this O)(bool myEnable = true);

    // Disable auto quoting of identifiers in queries.
    O disableAutoQuoting(this O)();

    // Returns whether this driver should automatically quote identifiers in queries.
    bool isAutoQuotingEnabled();

    /**
     * Transforms the passed query to this Driver's dialect and returns an instance
     * of the transformed query and the full compiled SQL string.
     *
     * @param \Cake\Database\Query myQuery The query to compile.
     * @param \Cake\Database\ValueBinder $binder The value binder to use.
     * @return array containing 2 entries. The first entity is the transformed query
     * and the second one the compiled SQL.
     */
    function compileQuery(Query myQuery, ValueBinder $binder): array;

    // Returns an instance of a QueryCompiler.
    QueryCompiler newCompiler();

    /**
     * Constructs new TableSchema.
     *
     * @param string myTable The table name.
     * @param array $columns The list of columns for the schema.
     * @return \Cake\Database\Schema\TableSchema
     */
    TableSchema newTableSchema(string myTable, array $columns = []);
}
