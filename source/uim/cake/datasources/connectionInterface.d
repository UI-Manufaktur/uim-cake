module uim.cake.datasources;

use Psr\Log\ILoggerAware;
use Psr\Log\LoggerInterface;
use Psr\SimpleCache\ICache;

/**
 * This interface defines the methods you can depend on in
 * a connection.
 *
 * @method object getDriver() Gets the driver instance. {@see \Cake\Database\Connnection::getDriver()}
 * @method this setLogger($logger) Set the current logger. {@see \Cake\Database\Connnection::setLogger()}
 * @method bool supportsDynamicConstraints() Returns whether the driver supports adding or dropping constraints to
 *   already created tables. {@see \Cake\Database\Connnection::supportsDynamicConstraints()}
 * @method \Cake\Database\Schema\Collection getSchemaCollection() Gets a Schema\Collection object for this connection.
 *    {@see \Cake\Database\Connnection::getSchemaCollection()}
 * @method \Cake\Database\Query newQuery() Create a new Query instance for this connection.
 *    {@see \Cake\Database\Connnection::newQuery()}
 * @method \Cake\Database\IStatement prepare(mySql) Prepares a SQL statement to be executed.
 *    {@see \Cake\Database\Connnection::prepare()}
 * @method \Cake\Database\IStatement execute(myQuery, myParams = [], array myTypes = []) Executes a query using
 *   `myParams` for interpolating values and myTypes as a hint for each those params.
 *   {@see \Cake\Database\Connnection::execute()}
 * @method \Cake\Database\IStatement query(string mySql) Executes a SQL statement and returns the Statement
 *   object as result. {@see \Cake\Database\Connnection::query()}
 */
interface IConnection : ILoggerAware
{
    /**
     * Gets the current logger object.
     *
     * @return \Psr\Log\LoggerInterface logger instance
     */
    auto getLogger(): LoggerInterface;

    /**
     * Set a cacher.
     *
     * @param \Psr\SimpleCache\ICache $cacher Cacher object
     * @return this
     */
    auto setCacher(ICache $cacher);

    /**
     * Get a cacher.
     *
     * @return \Psr\SimpleCache\ICache $cacher Cacher object
     */
    auto getCacher(): ICache;

    /**
     * Get the configuration name for this connection.
     */
    string configName();

    /**
     * Get the configuration data used to create the connection.
     *
     * @return array
     */
    function config(): array;

    /**
     * Executes a callable function inside a transaction, if any exception occurs
     * while executing the passed callable, the transaction will be rolled back
     * If the result of the callable function is `false`, the transaction will
     * also be rolled back. Otherwise the transaction is committed after executing
     * the callback.
     *
     * The callback will receive the connection instance as its first argument.
     *
     * ### Example:
     *
     * ```
     * myConnection.transactional(function (myConnection) {
     *   myConnection.newQuery().delete("users").execute();
     * });
     * ```
     *
     * @param callable $callback The callback to execute within a transaction.
     * @return mixed The return value of the callback.
     * @throws \Exception Will re-throw any exception raised in $callback after
     *   rolling back the transaction.
     */
    function transactional(callable $callback);

    /**
     * Run an operation with constraints disabled.
     *
     * Constraints should be re-enabled after the callback succeeds/fails.
     *
     * ### Example:
     *
     * ```
     * myConnection.disableConstraints(function (myConnection) {
     *   myConnection.newQuery().delete("users").execute();
     * });
     * ```
     *
     * @param callable $callback The callback to execute within a transaction.
     * @return mixed The return value of the callback.
     * @throws \Exception Will re-throw any exception raised in $callback after
     *   rolling back the transaction.
     */
    function disableConstraints(callable $callback);

    /**
     * Enable/disable query logging
     *
     * @param bool myEnable Enable/disable query logging
     * @return this
     */
    function enableQueryLogging(bool myEnable = true);

    /**
     * Disable query logging
     *
     * @return this
     */
    function disableQueryLogging();

    /**
     * Check if query logging is enabled.
     */
    bool isQueryLoggingEnabled();
}
