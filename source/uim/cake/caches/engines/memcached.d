/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.caches.engines.memcached;

@safe:
import uim.cake;

/**
 * Memcached storage engine for cache. Memcached has some limitations in the amount of
 * control you have over expire times far in the future. See MemcachedEngine::write() for
 * more information.
 *
 * Memcached engine supports binary protocol and igbinary
 * serialization (if memcached extension is compiled with --enable-igbinary).
 * Compressed keys can also be incremented/decremented.
 */
class MemcachedEngine : CacheEngine {
    /**
     * memcached wrapper.
     *
     * @var \Memcached
     */
    protected _Memcached;

    /**
     * The default config used unless overridden by runtime configuration
     *
     * - `compress` Whether to compress data
     * - `duration` Specify how long items in this cache configuration last.
     * - `groups` List of groups or "tags" associated to every key stored in this config.
     *    handy for deleting a complete group from cache.
     * - `username` Login to access the Memcache server
     * - `password` Password to access the Memcache server
     * - `persistent` The name of the persistent connection. All configurations using
     *    the same persistent value will share a single underlying connection.
     * - `prefix` Prepended to all entries. Good for when you need to share a keyspace
     *    with either another cache config or another application.
     * - `serialize` The serializer engine used to serialize data. Available engines are "php",
     *    "igbinary" and "json". Beside "php", the memcached extension must be compiled with the
     *    appropriate serializer support.
     * - `servers` String or array of memcached servers. If an array MemcacheEngine will use
     *    them as a pool.
     * - `options` - Additional options for the memcached client. Should be an array of option: value.
     *    Use the \Memcached::OPT_* constants as keys.
     *
     * @var array<string, mixed>
     */
    protected _defaultConfig = [
        "compress": false,
        "duration": 3600,
        "groups": [],
        "host": null,
        "username": null,
        "password": null,
        "persistent": null,
        "port": null,
        "prefix": "cake_",
        "serialize": "php",
        "servers": ["127.0.0.1"],
        "options": [],
    ];

    /**
     * List of available serializer engines
     *
     * Memcached must be compiled with JSON and igbinary support to use these engines
     *
     * @var array<string, int>
     */
    protected _serializers = null;

    /**
     * @var array<string>
     */
    protected string[] _compiledGroupNames = null;

    /**
     * Initialize the Cache Engine
     *
     * Called automatically by the cache frontend
     *
     * @param array<string, mixed> aConfig array of setting for the engine
     * @return bool True if the engine has been successfully initialized, false if not
     * @throws \InvalidArgumentException When you try use authentication without
     *   Memcached compiled with SASL support
     */
    bool init(Json aConfig = null) {
        if (!extension_loaded("memcached")) {
            throw new RuntimeException("The `memcached` extension must be enabled to use MemcachedEngine.");
        }

        _serializers = [
            "igbinary": Memcached::SERIALIZER_IGBINARY,
            "json": Memcached::SERIALIZER_JSON,
            "php": Memcached::SERIALIZER_PHP,
        ];
        if (defined("Memcached::HAVE_MSGPACK")) {
            _serializers["msgpack"] = Memcached::SERIALIZER_MSGPACK;
        }

        super.init(aConfig);

        if (!empty(aConfig["host"])) {
            if (empty(aConfig["port"])) {
                aConfig["servers"] = [aConfig["host"]];
            } else {
                aConfig["servers"] = [sprintf("%s:%d", aConfig["host"], aConfig["port"])];
            }
        }

        if (isset(aConfig["servers"])) {
            this.setConfig("servers", aConfig["servers"], false);
        }

        if (!is_array(_config["servers"])) {
            _config["servers"] = [_config["servers"]];
        }

        if (_config["persistent"]) {
            _Memcached = new Memcached(_config["persistent"]);
        } else {
            _Memcached = new Memcached();
        }
        _setOptions();

        $serverList = _Memcached.getServerList();
        if ($serverList) {
            if (_Memcached.isPersistent()) {
                foreach ($serverList as $server) {
                    if (!hasAllValues($server["host"] ~ ":" ~ $server["port"], _config["servers"], true)) {
                        throw new InvalidArgumentException(
                            "Invalid cache configuration. Multiple persistent cache configurations are detected" ~
                            " with different `servers` values. `servers` values for persistent cache configurations" ~
                            " must be the same when using the same persistence id."
                        );
                    }
                }
            }

            return true;
        }

        $servers = null;
        foreach (_config["servers"] as $server) {
            $servers[] = this.parseServerString($server);
        }

        if (!_Memcached.addServers($servers)) {
            return false;
        }

        if (is_array(_config["options"])) {
            foreach (_config["options"] as $opt: $value) {
                _Memcached.setOption($opt, $value);
            }
        }

        if (empty(_config["username"]) && !empty(_config["login"])) {
            throw new InvalidArgumentException(
                "Please pass "username" instead of "login" for connecting to Memcached"
            );
        }

        if (_config["username"] != null && _config["password"] != null) {
            if (!method_exists(_Memcached, "setSaslAuthData")) {
                throw new InvalidArgumentException(
                    "Memcached extension is not built with SASL support"
                );
            }
            _Memcached.setOption(Memcached::OPT_BINARY_PROTOCOL, true);
            _Memcached.setSaslAuthData(
                _config["username"],
                _config["password"]
            );
        }

        return true;
    }

    /**
     * Settings the memcached instance
     *
     * @return void
     * @throws \InvalidArgumentException When the Memcached extension is not built
     *   with the desired serializer engine.
     */
    protected void _setOptions() {
        _Memcached.setOption(Memcached::OPT_LIBKETAMA_COMPATIBLE, true);

        $serializer = strtolower(_config["serialize"]);
        if (!isset(_serializers[$serializer])) {
            throw new InvalidArgumentException(
                sprintf("%s is not a valid serializer engine for Memcached", $serializer)
            );
        }

        if (
            $serializer != "php" &&
            !constant("Memcached::HAVE_" ~ strtoupper($serializer))
        ) {
            throw new InvalidArgumentException(
                sprintf("Memcached extension is not compiled with %s support", $serializer)
            );
        }

        _Memcached.setOption(
            Memcached::OPT_SERIALIZER,
            _serializers[$serializer]
        );

        // Check for Amazon ElastiCache instance
        if (
            defined("Memcached::OPT_CLIENT_MODE") &&
            defined("Memcached::DYNAMIC_CLIENT_MODE")
        ) {
            _Memcached.setOption(
                Memcached::OPT_CLIENT_MODE,
                Memcached::DYNAMIC_CLIENT_MODE
            );
        }

        _Memcached.setOption(
            Memcached::OPT_COMPRESSION,
            (bool)_config["compress"]
        );
    }

    /**
     * Parses the server address into the host/port. Handles both IPv6 and IPv4
     * addresses and Unix sockets
     *
     * @param string $server The server address string.
     * @return array Array containing host, port
     */
    array parseServerString(string $server): 
    {
        $socketTransport = "unix://";
        if (strpos($server, $socketTransport) == 0) {
            return [substr($server, strlen($socketTransport)), 0];
        }
        if (substr($server, 0, 1) == "[") {
            $position = strpos($server, "]:");
            if ($position != false) {
                $position++;
            }
        } else {
            $position = strpos($server, ":");
        }
        $port = 11211;
        $host = $server;
        if ($position != false) {
            $host = substr($server, 0, $position);
            $port = substr($server, $position + 1);
        }

        return [$host, (int)$port];
    }

    /**
     * Read an option value from the memcached connection.
     *
     * @param int $name The option name to read.
     * @return string|int|bool|null
     * @see https://secure.php.net/manual/en/memcached.getoption.php
     */
    function getOption(int $name) {
        return _Memcached.getOption($name);
    }

    /**
     * Write data for key into cache. When using memcached as your cache engine
     * remember that the Memcached pecl extension does not support cache expiry
     * times greater than 30 days in the future. Any duration greater than 30 days
     * will be treated as real Unix time value rather than an offset from current time.
     *
     * @param string aKey Identifier for the data
     * @param mixed $value Data to be cached
     * @param \DateInterval|int|null $ttl Optional. The TTL value of this item. If no value is sent and
     *   the driver supports TTL then the library may set a default value
     *   for it or let the driver take care of that.
     * @return bool True if the data was successfully cached, false on failure
     * @see https://www.php.net/manual/en/memcached.set.php
     */
    bool set(string aKey, $value, $ttl = null) {
        $duration = this.duration($ttl);

        return _Memcached.set(_key($key), $value, $duration);
    }

    /**
     * Write many cache entries to the cache at once
     *
     * @param iterable $values An array of data to be stored in the cache
     * @param \DateInterval|int|null $ttl Optional. The TTL value of this item. If no value is sent and
     *   the driver supports TTL then the library may set a default value
     *   for it or let the driver take care of that.
     * @return bool Whether the write was successful or not.
     */
    bool setMultiple($values, $ttl = null) {
        $cacheData = null;
        foreach ($values as $key: $value) {
            $cacheData[_key($key)] = $value;
        }
        $duration = this.duration($ttl);

        return _Memcached.setMulti($cacheData, $duration);
    }

    /**
     * Read a key from the cache
     *
     * @param string aKey Identifier for the data
     * @param mixed $default Default value to return if the key does not exist.
     * @return mixed The cached data, or default value if the data doesn"t exist, has
     * expired, or if there was an error fetching it.
     */
    function get(string aKey, $default = null) {
        $key = _key($key);
        $value = _Memcached.get(string aKey);
        if (_Memcached.getResultCode() == Memcached::RES_NOTFOUND) {
            return $default;
        }

        return $value;
    }

    /**
     * Read many keys from the cache at once
     *
     * @param iterable $keys An array of identifiers for the data
     * @param mixed $default Default value to return for keys that do not exist.
     * @return array An array containing, for each of the given $keys, the cached data or
     *   false if cached data could not be retrieved.
     */
    array getMultiple($keys, $default = null) {
        $cacheKeys = null;
        foreach ($keys as $key) {
            $cacheKeys[$key] = _key($key);
        }

        $values = _Memcached.getMulti($cacheKeys);
        $return = null;
        foreach ($cacheKeys as $original: $prefixed) {
            $return[$original] = $values[$prefixed] ?? $default;
        }

        return $return;
    }

    /**
     * Increments the value of an integer cached key
     *
     * @param string aKey Identifier for the data
     * @param int $offset How much to increment
     * @return int|false New incremented value, false otherwise
     */
    function increment(string aKey, int $offset = 1) {
        return _Memcached.increment(_key($key), $offset);
    }

    /**
     * Decrements the value of an integer cached key
     *
     * @param string aKey Identifier for the data
     * @param int $offset How much to subtract
     * @return int|false New decremented value, false otherwise
     */
    function decrement(string aKey, int $offset = 1) {
        return _Memcached.decrement(_key($key), $offset);
    }

    /**
     * Delete a key from the cache
     *
     * @param string aKey Identifier for the data
     * @return bool True if the value was successfully deleted, false if it didn"t
     *   exist or couldn"t be removed.
     */
    bool delete($key) {
        return _Memcached.delete(_key($key));
    }

    /**
     * Delete many keys from the cache at once
     *
     * @param iterable $keys An array of identifiers for the data
     * @return bool of boolean values that are true if the key was successfully
     *   deleted, false if it didn"t exist or couldn"t be removed.
     */
    bool deleteMultiple($keys) {
        $cacheKeys = null;
        foreach ($keys as $key) {
            $cacheKeys[] = _key($key);
        }

        return (bool)_Memcached.deleteMulti($cacheKeys);
    }

    /**
     * Delete all keys from the cache
     *
     * @return bool True if the cache was successfully cleared, false otherwise
     */
    bool clear() {
        $keys = _Memcached.getAllKeys();
        if ($keys == false) {
            return false;
        }

        foreach ($keys as $key) {
            if (strpos($key, _config["prefix"]) == 0) {
                _Memcached.delete($key);
            }
        }

        return true;
    }

    /**
     * Add a key to the cache if it does not already exist.
     *
     * @param string aKey Identifier for the data.
     * @param mixed $value Data to be cached.
     * @return bool True if the data was successfully cached, false on failure.
     */
    bool add(string aKey, $value) {
        $duration = _config["duration"];
        $key = _key($key);

        return _Memcached.add($key, $value, $duration);
    }

    /**
     * Returns the `group value` for each of the configured groups
     * If the group initial value was not found, then it initializes
     * the group accordingly.
     */
    string[] groups() {
        if (empty(_compiledGroupNames)) {
            foreach (_config["groups"] as $group) {
                _compiledGroupNames[] = _config["prefix"] . $group;
            }
        }

        $groups = _Memcached.getMulti(_compiledGroupNames) ?: [];
        if (count($groups) != count(_config["groups"])) {
            foreach (_compiledGroupNames as $group) {
                if (!isset($groups[$group])) {
                    _Memcached.set($group, 1, 0);
                    $groups[$group] = 1;
                }
            }
            ksort($groups);
        }

        $result = null;
        $groups = array_values($groups);
        foreach (_config["groups"] as $i: $group) {
            $result[] = $group . $groups[$i];
        }

        return $result;
    }

    /**
     * Increments the group value to simulate deletion of all keys under a group
     * old values will remain in storage until they expire.
     *
     * @param string $group name of the group to be cleared
     * @return bool success
     */
    bool clearGroup(string $group) {
        return (bool)_Memcached.increment(_config["prefix"] . $group);
    }
}
