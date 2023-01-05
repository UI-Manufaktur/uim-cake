/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.datasources;

import uim.cake.core.StaticConfigTrait;
import uim.cake.databases.Connection;
import uim.cake.databases.Driver\Mysql;
import uim.cake.databases.Driver\Postgres;
import uim.cake.databases.Driver\Sqlite;
import uim.cake.databases.Driver\Sqlserver;
import uim.cake.datasources.exceptions.MissingDatasourceConfigException;

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
        "mysql": Mysql::class,
        "postgres": Postgres::class,
        "sqlite": Sqlite::class,
        "sqlserver": Sqlserver::class,
    ];

    /**
     * The ConnectionRegistry used by the manager.
     *
     * @var uim.cake.datasources.ConnectionRegistry
     */
    protected static $_registry;

    /**
     * Configure a new connection object.
     *
     * The connection will not be constructed until it is first used.
     *
     * @param array<string, mixed>|string aKey The name of the connection config, or an array of multiple configs.
     * @param array<string, mixed>|null $config An array of name: config data for adapter.
     * @return void
     * @throws uim.cake.Core\exceptions.CakeException When trying to modify an existing config.
     * @see uim.cake.Core\StaticConfigTrait::config()
     */
    static void setConfig($key, $config = null) {
        if (is_array($config)) {
            $config["name"] = $key;
        }

        static::_setConfig($key, $config);
    }

    /**
     * Parses a DSN into a valid connection configuration
     *
     * This method allows setting a DSN using formatting similar to that used by PEAR::DB.
     * The following is an example of its usage:
     *
     * ```
     * $dsn = "mysql://user:pass@localhost/database";
     * $config = ConnectionManager::parseDsn($dsn);
     *
     * $dsn = "Cake\databases.Driver\Mysql://localhost:3306/database?className=Cake\databases.Connection";
     * $config = ConnectionManager::parseDsn($dsn);
     *
     * $dsn = "Cake\databases.Connection://localhost:3306/database?driver=Cake\databases.Driver\Mysql";
     * $config = ConnectionManager::parseDsn($dsn);
     * ```
     *
     * For all classes, the value of `scheme` is set as the value of both the `className` and `driver`
     * unless they have been otherwise specified.
     *
     * Note that query-string arguments are also parsed and set as values in the returned configuration.
     *
     * @param string $config The DSN string to convert to a configuration array
     * @return array<string, mixed> The configuration array to be stored after parsing the DSN
     */
    static array parseDsn(string $config)
    {
        $config = static::_parseDsn($config);

        if (isset($config["path"]) && empty($config["database"])) {
            $config["database"] = substr($config["path"], 1);
        }

        if (empty($config["driver"])) {
            $config["driver"] = $config["className"];
            $config["className"] = Connection::class;
        }

        unset($config["path"]);

        return $config;
    }

    /**
     * Set one or more connection aliases.
     *
     * Connection aliases allow you to rename active connections without overwriting
     * the aliased connection. This is most useful in the test-suite for replacing
     * connections with their test variant.
     *
     * Defined aliases will take precedence over normal connection names. For example,
     * if you alias "default" to "test", fetching "default" will always return the "test"
     * connection as long as the alias is defined.
     *
     * You can remove aliases with ConnectionManager::dropAlias().
     *
     * ### Usage
     *
     * ```
     * // Make "things" resolve to "test_things" connection
     * ConnectionManager::alias("test_things", "things");
     * ```
     *
     * @param string $source The existing connection to alias.
     * @param string $alias The alias name that resolves to `$source`.
     */
    static void alias(string $source, string $alias) {
        static::$_aliasMap[$alias] = $source;
    }

    /**
     * Drop an alias.
     *
     * Removes an alias from ConnectionManager. Fetching the aliased
     * connection may fail if there is no other connection with that name.
     *
     * @param string $alias The connection alias to drop
     */
    static void dropAlias(string $alias) {
        unset(static::$_aliasMap[$alias]);
    }

    /**
     * Get a connection.
     *
     * If the connection has not been constructed an instance will be added
     * to the registry. This method will use any aliases that have been
     * defined. If you want the original unaliased connections pass `false`
     * as second parameter.
     *
     * @param string aName The connection name.
     * @param bool $useAliases Set to false to not use aliased connections.
     * @return uim.cake.Datasource\IConnection A connection object.
     * @throws uim.cake.Datasource\exceptions.MissingDatasourceConfigException When config
     * data is missing.
     */
    static function get(string aName, bool $useAliases = true) {
        if ($useAliases && isset(static::$_aliasMap[$name])) {
            $name = static::$_aliasMap[$name];
        }
        if (empty(static::$_config[$name])) {
            throw new MissingDatasourceConfigException(["name": $name]);
        }
        /** @psalm-suppress RedundantPropertyInitializationCheck */
        if (!isset(static::$_registry)) {
            static::$_registry = new ConnectionRegistry();
        }

        return static::$_registry.{$name}
            ?? static::$_registry.load($name, static::$_config[$name]);
    }
}
