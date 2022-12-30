
module uim.cake.Datasource;

use Psr\Log\LoggerAwareInterface;
use Psr\Log\LoggerInterface;
use Psr\SimpleCache\ICache;

/**
 * This interface defines the methods you can depend on in
 * a connection.
 *
 * @method object getDriver() Gets the driver instance. {@see uim.cake.databases.Connnection::getDriver()}
 * @method this setLogger($logger) Set the current logger. {@see uim.cake.databases.Connnection::setLogger()}
 * @method bool supportsDynamicConstraints() Returns whether the driver supports adding or dropping constraints to
 *   already created tables. {@see uim.cake.databases.Connnection::supportsDynamicConstraints()}
 * @method uim.cake.databases.Schema\Collection getSchemaCollection() Gets a Schema\Collection object for this connection.
 *    {@see uim.cake.databases.Connnection::getSchemaCollection()}
 * @method uim.cake.databases.Query newQuery() Create a new Query instance for this connection.
 *    {@see uim.cake.databases.Connnection::newQuery()}
 * @method uim.cake.databases.StatementInterface prepare($sql) Prepares a SQL statement to be executed.
 *    {@see uim.cake.databases.Connnection::prepare()}
 * @method uim.cake.databases.StatementInterface execute($query, $params = [], array $types = []) Executes a query using
 *   `$params` for interpolating values and $types as a hint for each those params.
 *   {@see uim.cake.databases.Connnection::execute()}
 * @method uim.cake.databases.StatementInterface query(string $sql) Executes a SQL statement and returns the Statement
 *   object as result. {@see uim.cake.databases.Connnection::query()}
 */
interface ConnectionInterface : LoggerAwareInterface
{
    /**
     * Gets the current logger object.
     *
     * @return \Psr\Log\LoggerInterface logger instance
     */
    function getLogger(): LoggerInterface;

    /**
     * Set a cacher.
     *
     * @param \Psr\SimpleCache\ICache $cacher Cacher object
     * @return this
     */
    function setCacher(ICache $cacher);

    /**
     * Get a cacher.
     *
     * @return \Psr\SimpleCache\ICache $cacher Cacher object
     */
    function getCacher(): ICache;

    /**
     * Get the configuration name for this connection.
     */
    string configName(): string;

    /**
     * Get the configuration data used to create the connection.
     *
     * @return array<string, mixed>
     */
    function config(): array;

    /**
     * Executes a callable function inside a transaction, if any exception occurs
     * while executing the passed callable, the transaction will be rolled back
     * If the result of the callable function is `false`, the transaction will
     * also be rolled back. Otherwise, the transaction is committed after executing
     * the callback.
     *
     * The callback will receive the connection instance as its first argument.
     *
     * ### Example:
     *
     * ```
     * $connection.transactional(function ($connection) {
     *   $connection.newQuery().delete("users").execute();
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
     * $connection.disableConstraints(function ($connection) {
     *   $connection.newQuery().delete("users").execute();
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
     * @param bool $enable Enable/disable query logging
     * @return this
     */
    function enableQueryLogging(bool $enable = true);

    /**
     * Disable query logging
     *
     * @return this
     */
    function disableQueryLogging();

    /**
     * Check if query logging is enabled.
     *
     * @return bool
     */
    function isQueryLoggingEnabled(): bool;
}
