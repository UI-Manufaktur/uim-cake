module uim.cake.core;

@safe:
import uim.cake;

use BadMethodCallException;
use InvalidArgumentException;
use LogicException;

/**
 * A trait that provides a set of static methods to manage configuration
 * for classes that provide an adapter facade or need to have sets of
 * configuration data registered and manipulated.
 *
 * Implementing objects are expected to declare a static `_dsnClassMap` property.
 */
trait StaticConfigTrait
{
    /**
     * Configuration sets.
     *
     * @var array<string, mixed>
     */
    protected static _config = [];

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
     * @param array<string, mixed>|string aKey The name of the configuration, or an array of multiple configs.
     * @param object|array<string, mixed>|null aConfig An array of name: configuration data for adapter.
     * @throws \BadMethodCallException When trying to modify an existing config.
     * @throws \LogicException When trying to store an invalid structured config array.
     */
    static void setConfig($key, aConfig = null) {
        if (aConfig == null) {
            if (!is_array($key)) {
                throw new LogicException("If config is null, key must be an array.");
            }
            foreach ($key as $name: $settings) {
                static::setConfig($name, $settings);
            }

            return;
        }

        if (isset(static::_config[$key])) {
            /** @psalm-suppress PossiblyInvalidArgument */
            throw new BadMethodCallException(sprintf("Cannot reconfigure existing key '%s'", $key));
        }

        if (is_object(aConfig)) {
            aConfig = ["className": aConfig];
        }

        if (isset(aConfig["url"])) {
            $parsed = static::parseDsn(aConfig["url"]);
            unset(aConfig["url"]);
            aConfig = $parsed + aConfig;
        }

        if (isset(aConfig["engine"]) && empty(aConfig["className"])) {
            aConfig["className"] = aConfig["engine"];
            unset(aConfig["engine"]);
        }
        /** @psalm-suppress InvalidPropertyAssignmentValue */
        static::_config[$key] = aConfig;
    }

    /**
     * Reads existing configuration.
     *
     * @param string aKey The name of the configuration.
     * @return mixed|null Configuration data at the named key or null if the key does not exist.
     */
    static function getConfig(string aKey) {
        return static::_config[$key] ?? null;
    }

    /**
     * Reads existing configuration for a specific key.
     *
     * The config value for this key must exist, it can never be null.
     *
     * @param string aKey The name of the configuration.
     * @return mixed Configuration data at the named key.
     * @throws \InvalidArgumentException If value does not exist.
     */
    static function getConfigOrFail(string aKey) {
        if (!isset(static::_config[$key])) {
            throw new InvalidArgumentException(sprintf("Expected configuration `%s` not found.", $key));
        }

        return static::_config[$key];
    }

    /**
     * Drops a constructed adapter.
     *
     * If you wish to modify an existing configuration, you should drop it,
     * change configuration and then re-add it.
     *
     * If the implementing objects supports a `_registry` object the named configuration
     * will also be unloaded from the registry.
     *
     * @param string aConfig An existing configuration you wish to remove.
     * @return bool Success of the removal, returns false when the config does not exist.
     */
    static bool drop(string aConfig) {
        if (!isset(static::_config[aConfig])) {
            return false;
        }
        /** @psalm-suppress RedundantPropertyInitializationCheck */
        if (isset(static::_registry)) {
            static::_registry.unload(aConfig);
        }
        unset(static::_config[aConfig]);

        return true;
    }

    /**
     * Returns an array containing the named configurations
     *
     * @return array<string> Array of configurations.
     */
    static string[] configured() {
        $configurations = array_keys(static::_config);

        return array_map(function ($key) {
            return (string)$key;
        }, $configurations);
    }

    /**
     * Parses a DSN into a valid connection configuration
     *
     * This method allows setting a DSN using formatting similar to that used by PEAR::DB.
     * The following is an example of its usage:
     *
     * ```
     * $dsn = "mysql://user:pass@localhost/database?";
     * aConfig = ConnectionManager::parseDsn($dsn);
     *
     * $dsn = "Cake\logs.Engine\FileLog://?types=notice,info,debug&file=debug&path=LOGS";
     * aConfig = Log::parseDsn($dsn);
     *
     * $dsn = "smtp://user:secret@localhost:25?timeout=30&client=null&tls=null";
     * aConfig = Email::parseDsn($dsn);
     *
     * $dsn = "file:///?className=\My\Cache\Engine\FileEngine";
     * aConfig = Cache::parseDsn($dsn);
     *
     * $dsn = "File://?prefix=myapp_cake_core_&serialize=true&duration=+2 minutes&path=/tmp/persistent/";
     * aConfig = Cache::parseDsn($dsn);
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
    static array parseDsn(string $dsn) {
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
        foreach ($parsed as $k: $v) {
            if (is_int($k)) {
                unset($parsed[$k]);
            } elseif (strpos($k, "_") == 0) {
                $exists[substr($k, 1)] = ($v != "");
                unset($parsed[$k]);
            } elseif ($v == "" && !$exists[$k]) {
                unset($parsed[$k]);
            }
        }

        $query = "";

        if (isset($parsed["query"])) {
            $query = $parsed["query"];
            unset($parsed["query"]);
        }

        parse_str($query, $queryArgs);

        foreach ($queryArgs as $key: $value) {
            if ($value == "true") {
                $queryArgs[$key] = true;
            } elseif ($value == "false") {
                $queryArgs[$key] = false;
            } elseif ($value == "null") {
                $queryArgs[$key] = null;
            }
        }

        $parsed = $queryArgs + $parsed;

        if (empty($parsed["className"])) {
            $classMap = static::getDsnClassMap();

            $parsed["className"] = $parsed["scheme"];
            if (isset($classMap[$parsed["scheme"]])) {
                /** @psalm-suppress PossiblyNullArrayOffset */
                $parsed["className"] = $classMap[$parsed["scheme"]];
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
        static::_dsnClassMap = $map + static::_dsnClassMap;
    }

    /**
     * Returns the DSN class map for this class.
     */
    static STRINGAA getDsnClassMap() {
        return static::_dsnClassMap;
    }
}
