module uim.cake.caches.engines.redis;

@safe:
import uim.cake;

// Redis storage engine for cache.
class RedisEngine : CacheEngine
{
    // Redis wrapper.
    protected _Redis;

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
     * - `server` URL or IP to the Redis server host.
     * - `timeout` timeout in seconds (float).
     * - `unix_socket` Path to the unix socket file (default: false)
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "database":0,
        "duration":3600,
        "groups":[],
        "password":false,
        "persistent":true,
        "port":6379,
        "prefix":"cake_",
        "host":null,
        "server":"127.0.0.1",
        "timeout":0,
        "unix_socket":false,
    ];

    /**
     * Initialize the Cache Engine
     *
     * Called automatically by the cache frontend
     *
     * @param array<string, mixed> myConfig array of setting for the engine
     * @return bool True if the engine has been successfully initialized, false if not
     */
    bool init(array myConfig = []) {
        if (!extension_loaded("redis")) {
            throw new RuntimeException("The `redis` extension must be enabled to use RedisEngine.");
        }

        if (!empty(myConfig["host"])) {
            myConfig["server"] = myConfig["host"];
        }

        super.init(myConfig);

        return _connect();
    }

    // Connects to a Redis server
    // True if Redis server was connected
    protected bool _connect() {
        try {
            _Redis = new Redis();
            if (!empty(_config["unix_socket"])) {
                result = _Redis.connect(_config["unix_socket"]);
            } elseif (empty(_config["persistent"])) {
                result = _Redis.connect(
                    _config["server"],
                    (int)_config["port"],
                    (int)_config["timeout"]
                );
            } else {
                $persistentId = _config["port"] . _config["timeout"] . _config["database"];
                result = _Redis.pconnect(
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
        if (result && _config["password"]) {
            result = _Redis.auth(_config["password"]);
        }
        if (result) {
            result = _Redis.select((int)_config["database"]);
        }

        return result;
    }

    /**
     * Write data for key into cache.
     *
     * @param string myKey Identifier for the data
     * @param mixed myValue Data to be cached
     * @param \DateInterval|int|null $ttl Optional. The TTL value of this item. If no value is sent and
     *   the driver supports TTL then the library may set a default value
     *   for it or let the driver take care of that.
     * @return bool True if the data was successfully cached, false on failure
     */
    bool set(myKey, myValue, $ttl = null) {
        myKey = _key(myKey);
        myValue = this.serialize(myValue);

        $duration = this.duration($ttl);
        if ($duration == 0) {
            return _Redis.set(myKey, myValue);
        }

        return _Redis.setEx(myKey, $duration, myValue);
    }

    /**
     * Read a key from the cache
     *
     * @param string myKey Identifier for the data
     * @param mixed $default Default value to return if the key does not exist.
     * @return mixed The cached data, or the default if the data doesn"t exist, has
     *   expired, or if there was an error fetching it
     */
    auto get(myKey, $default = null) {
        myValue = _Redis.get(_key(myKey));
        if (myValue == false) {
            return $default;
        }

        return this.unserialize(myValue);
    }

    /**
     * Increments the value of an integer cached key & update the expiry time
     *
     * @param string myKey Identifier for the data
     * @param int $offset How much to increment
     * @return int|false New incremented value, false otherwise
     */
    function increment(string myKey, int $offset = 1) {
        $duration = _config["duration"];
        myKey = _key(myKey);

        myValue = _Redis.incrBy(myKey, $offset);
        if ($duration > 0) {
            _Redis.expire(myKey, $duration);
        }

        return myValue;
    }

    /**
     * Decrements the value of an integer cached key & update the expiry time
     *
     * @param string myKey Identifier for the data
     * @param int $offset How much to subtract
     * @return int|false New decremented value, false otherwise
     */
    function decrement(string myKey, int $offset = 1) {
        $duration = _config["duration"];
        myKey = _key(myKey);

        myValue = _Redis.decrBy(myKey, $offset);
        if ($duration > 0) {
            _Redis.expire(myKey, $duration);
        }

        return myValue;
    }

    /**
     * Delete a key from the cache
     *
     * @param string myKey Identifier for the data
     * @return bool True if the value was successfully deleted, false if it didn"t exist or couldn"t be removed
     */
    bool delete(myKey) {
        myKey = _key(myKey);

        return _Redis.del(myKey) > 0;
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
            myKeys = _Redis.scan($iterator, $pattern);

            if (myKeys == false) {
                break;
            }

            foreach (myKey; myKeys) {
                $isDeleted = (_Redis.del(myKey) > 0);
                $isAllDeleted = $isAllDeleted && $isDeleted;
            }
        }

        return $isAllDeleted;
    }

    /**
     * Write data for key into cache if it doesn"t exist already.
     * If it already exists, it fails and returns false.
     *
     * @param string myKey Identifier for the data.
     * @param mixed myValue Data to be cached.
     * @return bool True if the data was successfully cached, false on failure.
     * @link https://github.com/phpredis/phpredis#set
     */
    bool add(string myKey, myValue) {
        $duration = _config["duration"];
        myKey = _key(myKey);
        myValue = this.serialize(myValue);

        if (_Redis.set(myKey, myValue, ["nx", "ex":$duration])) {
            return true;
        }

        return false;
    }

    /**
     * Returns the `group value` for each of the configured groups
     * If the group initial value was not found, then it initializes
     * the group accordingly.
     */
    string[] groups() {
        myResult = [];
        foreach (_config["groups"] as myGroup) {
            myValue = _Redis.get(_config["prefix"] . myGroup);
            if (!myValue) {
                myValue = this.serialize(1);
                _Redis.set(_config["prefix"] . myGroup, myValue);
            }
            myResult[] = myGroup . myValue;
        }

        return myResult;
    }

    /**
     * Increments the group value to simulate deletion of all keys under a group
     * old values will remain in storage until they expire.
     *
     * @param string myGroup name of the group to be cleared
     * @return bool success
     */
    bool clearGroup(string myGroup) {
        return (bool)_Redis.incr(_config["prefix"] . myGroup);
    }

    /**
     * Serialize value for saving to Redis.
     *
     * This is needed instead of using Redis" in built serialization feature
     * as it creates problems incrementing/decrementing intially set integer value.
     *
     * @param mixed myValue Value to serialize.
     * @return string
     * @link https://github.com/phpredis/phpredis/issues/81
     */
    protected string serialize(myValue) {
        if (is_int(myValue)) {
            return (string)myValue;
        }

        return serialize(myValue);
    }

    /**
     * Unserialize string value fetched from Redis.
     *
     * @param string myValue Value to unserialize.
     * @return mixed
     */
    protected auto unserialize(string myValue) {
        if (preg_match("/^[-]?\d+$/", myValue)) {
            return (int)myValue;
        }

        return unserialize(myValue);
    }

    /**
     * Disconnects from the redis server
     */
    auto __destruct() {
        if (empty(_config["persistent"]) && _Redis instanceof Redis) {
            _Redis.close();
        }
    }
}
