

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         0.10.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.datasources;

import uim.baklava.core.StaticConfigTrait;
import uim.baklava.databases.Connection;
import uim.baklava.databases.Driver\Mysql;
import uim.baklava.databases.Driver\Postgres;
import uim.baklava.databases.Driver\Sqlite;
import uim.baklava.databases.Driver\Sqlserver;
import uim.baklava.datasources\Exception\MissingDatasourceConfigException;

/**
 * Manages and loads instances of Connection
 *
 * Provides an interface to loading and creating connection objects. Acts as
 * a registry for the connections defined in an application.
 *
 * Provides an interface for loading and enumerating connections defined in
 * config/app.php
 */
class ConnectionManager
{
    use StaticConfigTrait {
        setConfig as protected _setConfig;
        parseDsn as protected _parseDsn;
    }

    /**
     * A map of connection aliases.
     *
     * @var array<string>
     */
    protected static $_aliasMap = [];

    /**
     * An array mapping url schemes to fully qualified driver class names
     *
     * @var array<string, string>
     * @psalm-var array<string, class-string>
     */
    protected static $_dsnClassMap = [
        'mysql' => Mysql::class,
        'postgres' => Postgres::class,
        'sqlite' => Sqlite::class,
        'sqlserver' => Sqlserver::class,
    ];

    /**
     * The ConnectionRegistry used by the manager.
     *
     * @var \Cake\Datasource\ConnectionRegistry
     */
    protected static $_registry;

    /**
     * Configure a new connection object.
     *
     * The connection will not be constructed until it is first used.
     *
     * @param array<string, mixed>|string myKey The name of the connection config, or an array of multiple configs.
     * @param array<string, mixed>|null myConfig An array of name => config data for adapter.
     * @return void
     * @throws \Cake\Core\Exception\CakeException When trying to modify an existing config.
     * @see \Cake\Core\StaticConfigTrait::config()
     */
    static auto setConfig(myKey, myConfig = null): void
    {
        if (is_array(myConfig)) {
            myConfig['name'] = myKey;
        }

        static::_setConfig(myKey, myConfig);
    }

    /**
     * Parses a DSN into a valid connection configuration
     *
     * This method allows setting a DSN using formatting similar to that used by PEAR::DB.
     * The following is an example of its usage:
     *
     * ```
     * $dsn = 'mysql://user:pass@localhost/database';
     * myConfig = ConnectionManager::parseDsn($dsn);
     *
     * $dsn = 'Cake\Database\Driver\Mysql://localhost:3306/database?className=Cake\Database\Connection';
     * myConfig = ConnectionManager::parseDsn($dsn);
     *
     * $dsn = 'Cake\Database\Connection://localhost:3306/database?driver=Cake\Database\Driver\Mysql';
     * myConfig = ConnectionManager::parseDsn($dsn);
     * ```
     *
     * For all classes, the value of `scheme` is set as the value of both the `className` and `driver`
     * unless they have been otherwise specified.
     *
     * Note that query-string arguments are also parsed and set as values in the returned configuration.
     *
     * @param string myConfig The DSN string to convert to a configuration array
     * @return array<string, mixed> The configuration array to be stored after parsing the DSN
     */
    static function parseDsn(string myConfig): array
    {
        myConfig = static::_parseDsn(myConfig);

        if (isset(myConfig['path']) && empty(myConfig['database'])) {
            myConfig['database'] = substr(myConfig['path'], 1);
        }

        if (empty(myConfig['driver'])) {
            myConfig['driver'] = myConfig['className'];
            myConfig['className'] = Connection::class;
        }

        unset(myConfig['path']);

        return myConfig;
    }

    /**
     * Set one or more connection aliases.
     *
     * Connection aliases allow you to rename active connections without overwriting
     * the aliased connection. This is most useful in the test-suite for replacing
     * connections with their test variant.
     *
     * Defined aliases will take precedence over normal connection names. For example,
     * if you alias 'default' to 'test', fetching 'default' will always return the 'test'
     * connection as long as the alias is defined.
     *
     * You can remove aliases with ConnectionManager::dropAlias().
     *
     * ### Usage
     *
     * ```
     * // Make 'things' resolve to 'test_things' connection
     * ConnectionManager::alias('test_things', 'things');
     * ```
     *
     * @param string $source The existing connection to alias.
     * @param string myAlias The alias name that resolves to `$source`.
     * @return void
     */
    static function alias(string $source, string myAlias): void
    {
        static::$_aliasMap[myAlias] = $source;
    }

    /**
     * Drop an alias.
     *
     * Removes an alias from ConnectionManager. Fetching the aliased
     * connection may fail if there is no other connection with that name.
     *
     * @param string myAlias The connection alias to drop
     * @return void
     */
    static function dropAlias(string myAlias): void
    {
        unset(static::$_aliasMap[myAlias]);
    }

    /**
     * Get a connection.
     *
     * If the connection has not been constructed an instance will be added
     * to the registry. This method will use any aliases that have been
     * defined. If you want the original unaliased connections pass `false`
     * as second parameter.
     *
     * @param string myName The connection name.
     * @param bool $useAliases Set to false to not use aliased connections.
     * @return \Cake\Datasource\ConnectionInterface A connection object.
     * @throws \Cake\Datasource\Exception\MissingDatasourceConfigException When config
     * data is missing.
     */
    static auto get(string myName, bool $useAliases = true) {
        if ($useAliases && isset(static::$_aliasMap[myName])) {
            myName = static::$_aliasMap[myName];
        }
        if (empty(static::$_config[myName])) {
            throw new MissingDatasourceConfigException(['name' => myName]);
        }
        /** @psalm-suppress RedundantPropertyInitializationCheck */
        if (!isset(static::$_registry)) {
            static::$_registry = new ConnectionRegistry();
        }

        return static::$_registry.{myName}
            ?? static::$_registry.load(myName, static::$_config[myName]);
    }
}