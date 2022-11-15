module uim.cake.core;

use BadMethodCallException;
use InvalidArgumentException;
use LogicException;

/**
 * A trait that provides a set of static methods to manage configuration
 * for classes that provide an adapter facade or need to have sets of
 * configuration data registered and manipulated.
 *
 * Implementing objects are expected to declare a static `$_dsnClassMap` property.
 */
trait StaticConfigTrait
{
    /**
     * Configuration sets.
     *
     * @var array<string, mixed>
     */
    protected static $_config = [];

    /**
     * This method can be used to define configuration adapters for an application.
     *
     * To change an adapter"s configuration at runtime, first drop the adapter and then
     * reconfigure it.
     *
     * Adapters will not be constructed until the first operation is done.
     *
     * ### Usage
     *
     * Assuming that the class" name is `Cache` the following scenarios
     * are supported:
     *
     * Setting a cache engine up.
     *
     * ```
     * Cache::setConfig("default", $settings);
     * ```
     *
     * Injecting a constructed adapter in:
     *
     * ```
     * Cache::setConfig("default", $instance);
     * ```
     *
     * Configure multiple adapters at once:
     *
     * ```
     * Cache::setConfig($arrayOfConfig);
     * ```
     *
     * @param array<string, mixed>|string myKey The name of the configuration, or an array of multiple configs.
     * @param object|array<string, mixed>|null myConfig An array of name => configuration data for adapter.
     * @throws \BadMethodCallException When trying to modify an existing config.
     * @throws \LogicException When trying to store an invalid structured config array.
     * @return void
     */
    static void setConfig(myKey, myConfig = null) {
        if (myConfig === null) {
            if (!is_array(myKey)) {
                throw new LogicException("If config is null, key must be an array.");
            }
            foreach (myKey as myName => $settings) {
                static::setConfig(myName, $settings);
            }

            return;
        }

        if (isset(static::$_config[myKey])) {
            /** @psalm-suppress PossiblyInvalidArgument */
            throw new BadMethodCallException(sprintf("Cannot reconfigure existing key "%s"", myKey));
        }

        if (is_object(myConfig)) {
            myConfig = ["className" => myConfig];
        }

        if (isset(myConfig["url"])) {
            $parsed = static::parseDsn(myConfig["url"]);
            unset(myConfig["url"]);
            myConfig = $parsed + myConfig;
        }

        if (isset(myConfig["engine"]) && empty(myConfig["className"])) {
            myConfig["className"] = myConfig["engine"];
            unset(myConfig["engine"]);
        }
        /** @psalm-suppress InvalidPropertyAssignmentValue */
        static::$_config[myKey] = myConfig;
    }

    /**
     * Reads existing configuration.
     *
     * @param string myKey The name of the configuration.
     * @return mixed|null Configuration data at the named key or null if the key does not exist.
     */
    static auto getConfig(string myKey) {
        return static::$_config[myKey] ?? null;
    }

    /**
     * Reads existing configuration for a specific key.
     *
     * The config value for this key must exist, it can never be null.
     *
     * @param string myKey The name of the configuration.
     * @return mixed Configuration data at the named key.
     * @throws \InvalidArgumentException If value does not exist.
     */
    static auto getConfigOrFail(string myKey) {
        if (!isset(static::$_config[myKey])) {
            throw new InvalidArgumentException(sprintf("Expected configuration `%s` not found.", myKey));
        }

        return static::$_config[myKey];
    }

    /**
     * Drops a constructed adapter.
     *
     * If you wish to modify an existing configuration, you should drop it,
     * change configuration and then re-add it.
     *
     * If the implementing objects supports a `$_registry` object the named configuration
     * will also be unloaded from the registry.
     *
     * @param string myConfig An existing configuration you wish to remove.
     * @return bool Success of the removal, returns false when the config does not exist.
     */
    static bool drop(string myConfig) {
        if (!isset(static::$_config[myConfig])) {
            return false;
        }
        /** @psalm-suppress RedundantPropertyInitializationCheck */
        if (isset(static::$_registry)) {
            static::$_registry.unload(myConfig);
        }
        unset(static::$_config[myConfig]);

        return true;
    }

    /**
     * Returns an array containing the named configurations
     *
     * @return array<string> Array of configurations.
     */
    static function configured(): array
    {
        myConfigurations = array_keys(static::$_config);

        return array_map(function (myKey) {
            return (string)myKey;
        }, myConfigurations);
    }

    /**
     * Parses a DSN into a valid connection configuration
     *
     * This method allows setting a DSN using formatting similar to that used by PEAR::DB.
     * The following is an example of its usage:
     *
     * ```
     * $dsn = "mysql://user:pass@localhost/database?";
     * myConfig = ConnectionManager::parseDsn($dsn);
     *
     * $dsn = "Cake\Log\Engine\FileLog://?types=notice,info,debug&file=debug&path=LOGS";
     * myConfig = Log::parseDsn($dsn);
     *
     * $dsn = "smtp://user:secret@localhost:25?timeout=30&client=null&tls=null";
     * myConfig = Email::parseDsn($dsn);
     *
     * $dsn = "file:///?className=\My\Cache\Engine\FileEngine";
     * myConfig = Cache::parseDsn($dsn);
     *
     * $dsn = "File://?prefix=myapp_cake_core_&serialize=true&duration=+2 minutes&path=/tmp/persistent/";
     * myConfig = Cache::parseDsn($dsn);
     * ```
     *
     * For all classes, the value of `scheme` is set as the value of both the `className`
     * unless they have been otherwise specified.
     *
     * Note that querystring arguments are also parsed and set as values in the returned configuration.
     *
     * @param string $dsn The DSN string to convert to a configuration array
     * @return array<string, mixed> The configuration array to be stored after parsing the DSN
     * @throws \InvalidArgumentException If not passed a string, or passed an invalid string
     */
    static function parseDsn(string $dsn): array
    {
        if (empty($dsn)) {
            return [];
        }

        $pattern = <<<"REGEXP"
{
    ^
    (?P<_scheme>
        (?P<scheme>[\w\\\\]+)://
    )
    (?P<_username>
        (?P<username>.*?)
        (?P<_password>
            :(?P<password>.*?)
        )?
        @
    )?
    (?P<_host>
        (?P<host>[^?#/:@]+)
        (?P<_port>
            :(?P<port>\d+)
        )?
    )?
    (?P<_path>
        (?P<path>/[^?#]*)
    )?
    (?P<_query>
        \?(?P<query>[^#]*)
    )?
    (?P<_fragment>
        \#(?P<fragment>.*)
    )?
    $
}x
REGEXP;

        preg_match($pattern, $dsn, $parsed);

        if (!$parsed) {
            throw new InvalidArgumentException("The DSN string "{$dsn}" could not be parsed.");
        }

        $exists = [];
        foreach ($parsed as $k => $v) {
            if (is_int($k)) {
                unset($parsed[$k]);
            } elseif (strpos($k, "_") === 0) {
                $exists[substr($k, 1)] = ($v !== "");
                unset($parsed[$k]);
            } elseif ($v == "" && !$exists[$k]) {
                unset($parsed[$k]);
            }
        }

        myQuery = "";

        if (isset($parsed["query"])) {
            myQuery = $parsed["query"];
            unset($parsed["query"]);
        }

        parse_str(myQuery, myQueryArgs);

        foreach (myQueryArgs as myKey => myValue) {
            if (myValue === "true") {
                myQueryArgs[myKey] = true;
            } elseif (myValue === "false") {
                myQueryArgs[myKey] = false;
            } elseif (myValue === "null") {
                myQueryArgs[myKey] = null;
            }
        }

        $parsed = myQueryArgs + $parsed;

        if (empty($parsed["className"])) {
            myClassMap = static::getDsnClassMap();

            $parsed["className"] = $parsed["scheme"];
            if (isset(myClassMap[$parsed["scheme"]])) {
                /** @psalm-suppress PossiblyNullArrayOffset */
                $parsed["className"] = myClassMap[$parsed["scheme"]];
            }
        }

        return $parsed;
    }

    /**
     * Updates the DSN class map for this class.
     *
     * @param array<string, string> $map Additions/edits to the class map to apply.
     * @return void
     * @psalm-param array<string, class-string> $map
     */
    static void setDsnClassMap(array $map) {
        static::$_dsnClassMap = $map + static::$_dsnClassMap;
    }

    /**
     * Returns the DSN class map for this class.
     *
     * @return array<string, string>
     * @psalm-return array<string, class-string>
     */
    static auto getDsnClassMap(): array
    {
        return static::$_dsnClassMap;
    }
}
