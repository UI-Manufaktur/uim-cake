/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.caches.engines.redis;

@safe:
import uim.cake;

// Redis storage engine for cache.
class RedisEngine : CacheEngine {
    /**
     * Redis wrapper.
     *
     * @var \Redis
     */
    protected $_Redis;

    /**
     * The default config used unless overridden by runtime configuration
     *
     * - `database` database number to use for connection.
     * - `duration` Specify how long items in this cache configuration last.
     * - `groups` List of groups or "tags" associated to every key stored in this config.
     *    handy for deleting a complete group from cache.
     * - `password` Redis server password.
     * - `persistent` Connect to the Redis server with a persistent connection
     * - `port` port number to the Redis server.
     * - `prefix` Prefix appended to all entries. Good for when you need to share a keyspace
     *    with either another cache config or another application.
     * - `scanCount` Number of keys to ask for each scan (default: 10)
     * - `server` URL or IP to the Redis server host.
     * - `timeout` timeout in seconds (float).
     * - `unix_socket` Path to the unix socket file (default: false)
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        "database": 0,
        "duration": 3600,
        "groups": [],
        "password": false,
        "persistent": true,
        "port": 6379,
        "prefix": "cake_",
        "host": null,
        "server": "127.0.0.1",
        "timeout": 0,
        "unix_socket": false,
        "scanCount": 10,
    ];

    /**
     * Initialize the Cache Engine
     *
     * Called automatically by the cache frontend
     *
     * @param array<string, mixed> $config array of setting for the engine
     * @return bool True if the engine has been successfully initialized, false if not
     */
    bool init(array $config = []) {
        if (!extension_loaded("redis")) {
            throw new RuntimeException("The `redis` extension must be enabled to use RedisEngine.");
        }

        if (!empty($config["host"])) {
            $config["server"] = $config["host"];
        }

        super.init($config);

        return _connect();
    }

    /**
     * Connects to a Redis server
     *
     * @return bool True if Redis server was connected
     */
    protected bool _connect() {
        try {
            _Redis = new Redis();
            if (!empty(_config["unix_socket"])) {
                $return = _Redis.connect(_config["unix_socket"]);
            } elseif (empty(_config["persistent"])) {
                $return = _Redis.connect(
                    _config["server"],
                    (int)_config["port"],
                    (int)_config["timeout"]
                );
            } else {
                $persistentId = _config["port"] . _config["timeout"] . _config["database"];
                $return = _Redis.pconnect(
                    _config["server"],
                    (int)_config["port"],
                    (int)_config["timeout"],
                    $persistentId
                );
            }
        } catch (RedisException $e) {
            if (class_exists(Log::class)) {
                Log::error("RedisEngine could not connect. Got error: " ~ $e.getMessage());
            }

            return false;
        }
        if ($return && _config["password"]) {
            $return = _Redis.auth(_config["password"]);
        }
        if ($return) {
            $return = _Redis.select((int)_config["database"]);
        }

        return $return;
    }

    /**
     * Write data for key into cache.
     *
     * @param string aKey Identifier for the data
     * @param mixed $value Data to be cached
     * @param \DateInterval|int|null $ttl Optional. The TTL value of this item. If no value is sent and
     *   the driver supports TTL then the library may set a default value
     *   for it or let the driver take care of that.
     * @return bool True if the data was successfully cached, false on failure
     */
    bool set(string aKey, $value, $ttl = null) {
        $key = _key($key);
        $value = this.serialize($value);

        $duration = this.duration($ttl);
        if ($duration == 0) {
            return _Redis.set(string aKey, $value);
        }

        return _Redis.setEx($key, $duration, $value);
    }

    /**
     * Read a key from the cache
     *
     * @param string aKey Identifier for the data
     * @param mixed $default Default value to return if the key does not exist.
     * @return mixed The cached data, or the default if the data doesn"t exist, has
     *   expired, or if there was an error fetching it
     */
    function get($key, $default = null) {
        $value = _Redis.get(_key($key));
        if ($value == false) {
            return $default;
        }

        return this.unserialize($value);
    }

    /**
     * Increments the value of an integer cached key & update the expiry time
     *
     * @param string aKey Identifier for the data
     * @param int $offset How much to increment
     * @return int|false New incremented value, false otherwise
     */
    function increment(string aKey, int $offset = 1) {
        $duration = _config["duration"];
        $key = _key($key);

        $value = _Redis.incrBy($key, $offset);
        if ($duration > 0) {
            _Redis.expire($key, $duration);
        }

        return $value;
    }

    /**
     * Decrements the value of an integer cached key & update the expiry time
     *
     * @param string aKey Identifier for the data
     * @param int $offset How much to subtract
     * @return int|false New decremented value, false otherwise
     */
    function decrement(string aKey, int $offset = 1) {
        $duration = _config["duration"];
        $key = _key($key);

        $value = _Redis.decrBy($key, $offset);
        if ($duration > 0) {
            _Redis.expire($key, $duration);
        }

        return $value;
    }

    /**
     * Delete a key from the cache
     *
     * @param string aKey Identifier for the data
     * @return bool True if the value was successfully deleted, false if it didn"t exist or couldn"t be removed
     */
    bool delete($key) {
        $key = _key($key);

        return _Redis.del($key) > 0;
    }

    /**
     * Delete a key from the cache asynchronously
     *
     * Just unlink a key from the cache. The actual removal will happen later asynchronously.
     *
     * @param string aKey Identifier for the data
     * @return bool True if the value was successfully deleted, false if it didn"t exist or couldn"t be removed
     */
    bool deleteAsync(string aKey) {
        $key = _key($key);

        return _Redis.unlink($key) > 0;
    }

    /**
     * Delete all keys from the cache
     *
     * @return bool True if the cache was successfully cleared, false otherwise
     */
    bool clear() {
        _Redis.setOption(Redis::OPT_SCAN, (string)Redis::SCAN_RETRY);

        $isAllDeleted = true;
        $iterator = null;
        $pattern = _config["prefix"] ~ "*";

        while (true) {
            $keys = _Redis.scan($iterator, $pattern, (int)_config["scanCount"]);

            if ($keys == false) {
                break;
            }

            foreach ($keys as $key) {
                $isDeleted = (_Redis.del($key) > 0);
                $isAllDeleted = $isAllDeleted && $isDeleted;
            }
        }

        return $isAllDeleted;
    }

    /**
     * Delete all keys from the cache by a blocking operation
     *
     * Faster than clear() using unlink method.
     *
     * @return bool True if the cache was successfully cleared, false otherwise
     */
    bool clearBlocking() {
        _Redis.setOption(Redis::OPT_SCAN, (string)Redis::SCAN_RETRY);

        $isAllDeleted = true;
        $iterator = null;
        $pattern = _config["prefix"] ~ "*";

        while (true) {
            $keys = _Redis.scan($iterator, $pattern, (int)_config["scanCount"]);

            if ($keys == false) {
                break;
            }

            foreach ($keys as $key) {
                $isDeleted = (_Redis.unlink($key) > 0);
                $isAllDeleted = $isAllDeleted && $isDeleted;
            }
        }

        return $isAllDeleted;
    }

    /**
     * Write data for key into cache if it doesn"t exist already.
     * If it already exists, it fails and returns false.
     *
     * @param string aKey Identifier for the data.
     * @param mixed $value Data to be cached.
     * @return bool True if the data was successfully cached, false on failure.
     * @link https://github.com/phpredis/phpredis#set
     */
    bool add(string aKey, $value) {
        $duration = _config["duration"];
        $key = _key($key);
        $value = this.serialize($value);

        if (_Redis.set(string aKey, $value, ["nx", "ex": $duration])) {
            return true;
        }

        return false;
    }

    /**
     * Returns the `group value` for each of the configured groups
     * If the group initial value was not found, then it initializes
     * the group accordingly.
     *
     * @return array<string>
     */
    string[] groups() {
        $result = [];
        foreach (_config["groups"] as $group) {
            $value = _Redis.get(_config["prefix"] . $group);
            if (!$value) {
                $value = this.serialize(1);
                _Redis.set(_config["prefix"] . $group, $value);
            }
            $result[] = $group . $value;
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
        return (bool)_Redis.incr(_config["prefix"] . $group);
    }

    /**
     * Serialize value for saving to Redis.
     *
     * This is needed instead of using Redis" in built serialization feature
     * as it creates problems incrementing/decrementing intially set integer value.
     *
     * @param mixed $value Value to serialize.
     * @return string
     * @link https://github.com/phpredis/phpredis/issues/81
     */
    protected string serialize($value) {
        if (is_int($value)) {
            return (string)$value;
        }

        return serialize($value);
    }

    /**
     * Unserialize string value fetched from Redis.
     *
     * @param string $value Value to unserialize.
     * @return mixed
     */
    protected function unserialize(string $value) {
        if (preg_match("/^[-]?\d+$/", $value)) {
            return (int)$value;
        }

        return unserialize($value);
    }

    /**
     * Disconnects from the redis server
     */
    function __destruct() {
        if (empty(_config["persistent"]) && _Redis instanceof Redis) {
            _Redis.close();
        }
    }
}
