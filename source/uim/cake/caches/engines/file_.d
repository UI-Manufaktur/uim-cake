/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.caches.engines.file_;

@safe:
import uim.cake;

/**
 * File Storage engine for cache. Filestorage is the slowest cache storage
 * to read and write. However, it is good for servers that don"t have other storage
 * engine available, or have content which is not performance sensitive.
 *
 * You can configure a FileEngine cache, using Cache::config()
 */
class FileEngine : CacheEngine {
    /**
     * Instance of SplFileObject class
     *
     * @var \SplFileObject|null
     */
    protected $_File;

    /**
     * The default config used unless overridden by runtime configuration
     *
     * - `duration` Specify how long items in this cache configuration last.
     * - `groups` List of groups or "tags" associated to every key stored in this config.
     *    handy for deleting a complete group from cache.
     * - `lock` Used by FileCache. Should files be locked before writing to them?
     * - `mask` The mask used for created files
     * - `path` Path to where cachefiles should be saved. Defaults to system"s temp dir.
     * - `prefix` Prepended to all entries. Good for when you need to share a keyspace
     *    with either another cache config or another application.
     *    cache::gc from ever being called automatically.
     * - `serialize` Should cache objects be serialized first.
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "duration":3600,
        "groups":[],
        "lock":true,
        "mask":0664,
        "path":null,
        "prefix":"cake_",
        "serialize":true,
    ];

    // True unless FileEngine::__active(); fails
    protected bool $_init = true;

    /**
     * Initialize File Cache Engine
     *
     * Called automatically by the cache frontend.
     *
     * @param array<string, mixed> myConfig array of setting for the engine
     * @return bool True if the engine has been successfully initialized, false if not
     */
    bool init(array myConfig = []) {
      super.init(myConfig);

      if (_config["path"] == null) {
          _config["path"] = sys_get_temp_dir() . DIRECTORY_SEPARATOR . "cake_cache" . DIRECTORY_SEPARATOR;
      }
      if (substr(_config["path"], -1) !== DIRECTORY_SEPARATOR) {
          _config["path"] .= DIRECTORY_SEPARATOR;
      }
      if (_groupPrefix) {
          _groupPrefix = _groupPrefix.replace("_", DIRECTORY_SEPARATOR);
      }

      return _active();
    }

    /**
     * Write data for key into cache
     *
     * @param string myKey Identifier for the data
     * @param mixed myValue Data to be cached
     * @param \DateInterval|int|null $ttl Optional. The TTL value of this item. If no value is sent and
     *   the driver supports TTL then the library may set a default value
     *   for it or let the driver take care of that.
     * @return bool True on success and false on failure.
     */
    bool set(string myDataId, myValue, $ttl = null) {
        if (myValue == "" || !_init) {
            return false;
        }

        myDataId = _key(myDataId);

        if (_setKey(myDataId, true) == false) {
            return false;
        }

        if (!empty(_config["serialize"])) {
            myValue = serialize(myValue);
        }

        $expires = time() + this.duration($ttl);
        myContentss = implode([$expires, PHP_EOL, myValue, PHP_EOL]);

        if (_config["lock"]) {
            /** @psalm-suppress PossiblyNullReference */
            _File.flock(LOCK_EX);
        }

        /** @psalm-suppress PossiblyNullReference */
        _File.rewind();
        $success = _File.ftruncate(0) &&
            _File.fwrite(myContentss) &&
            _File.fflush();

        if (_config["lock"]) {
            _File.flock(LOCK_UN);
        }
        _File = null;

        return $success;
    }

    /**
     * Read a key from the cache
     *
     * @param string myDataId Identifier for the data
     * @param mixed $default Default value to return if the key does not exist.
     * @return mixed The cached data, or default value if the data doesn"t exist, has
     *   expired, or if there was an error fetching it
     */
    auto get(myDataId, $default = null) {
        myDataId = _key(myDataId);

        if (!_init || _setKey(myDataId) == false) {
            return $default;
        }

        if (_config["lock"]) {
            /** @psalm-suppress PossiblyNullReference */
            _File.flock(LOCK_SH);
        }

        /** @psalm-suppress PossiblyNullReference */
        _File.rewind();
        $time = time();
        $cachetime = (int)_File.current();

        if ($cachetime < $time) {
            if (_config["lock"]) {
                _File.flock(LOCK_UN);
            }

            return $default;
        }

        myData = "";
        _File.next();
        while (_File.valid()) {
            /** @psalm-suppress PossiblyInvalidOperand */
            myData .= _File.current();
            _File.next();
        }

        if (_config["lock"]) {
            _File.flock(LOCK_UN);
        }

        myData = trim(myData);

        if (myData !== "" && !empty(_config["serialize"])) {
            myData = unserialize(myData);
        }

        return myData;
    }

    /**
     * Delete a key from the cache
     *
     * @param string myDataId Identifier for the data
     * @return bool True if the value was successfully deleted, false if it didn"t
     *   exist or couldn"t be removed
     */
    bool delete(myDataId) {
        myDataId = _key(myDataId);

        if (_setKey(myDataId) == false || !_init) {
            return false;
        }

        /** @psalm-suppress PossiblyNullReference */
        myPath = _File.getRealPath();
        _File = null;

        // phpcs:disable
        return @unlink(myPath);
        // phpcs:enable
    }

    /**
     * Delete all values from the cache
     *
     * @return bool True if the cache was successfully cleared, false otherwise
     */
    bool clear() {
        if (!_init) {
            return false;
        }
        _File = null;

        _clearDirectory(_config["path"]);

        $directory = new RecursiveDirectoryIterator(
            _config["path"],
            FilesystemIterator::SKIP_DOTS
        );
        myContentss = new RecursiveIteratorIterator(
            $directory,
            RecursiveIteratorIterator::SELF_FIRST
        );
        $cleared = [];
        /** @var \SplFileInfo myfileInfo */
        foreach (myContentss as myfileInfo) {
            if (myfileInfo.isFile()) {
                unset(myfileInfo);
                continue;
            }

            $realPath = myfileInfo.getRealPath();
            if (!$realPath) {
                unset(myfileInfo);
                continue;
            }

            myPath = $realPath . DIRECTORY_SEPARATOR;
            if (!in_array(myPath, $cleared, true)) {
                _clearDirectory(myPath);
                $cleared[] = myPath;
            }

            // possible inner iterators need to be unset too in order for locks on parents to be released
            unset(myfileInfo);
        }

        // unsetting iterators helps releasing possible locks in certain environments,
        // which could otherwise make `rmdir()` fail
        unset($directory, myContentss);

        return true;
    }

    /**
     * Used to clear a directory of matching files.
     *
     * @param string myPath The path to search.
     */
    protected void _clearDirectory(string myPath) {
        if (!is_dir(myPath)) {
            return;
        }

        $dir = dir(myPath);
        if (!$dir) {
            return;
        }

        $prefixLength = strlen(_config["prefix"]);

        while (($entry = $dir.read()) !== false) {
            if (substr($entry, 0, $prefixLength) !== _config["prefix"]) {
                continue;
            }

            try {
                myfile = new SplFileObject(myPath . $entry, "r");
            } catch (Exception $e) {
                continue;
            }

            if (myfile.isFile()) {
                myfilePath = myfile.getRealPath();
                unset(myfile);

                // phpcs:disable
                @unlink(myfilePath);
                // phpcs:enable
            }
        }

        $dir.close();
    }

    /**
     * Not implemented
     *
     * @param string myKey The key to decrement
     * @param int $offset The number to offset
     * @return int|false
     * @throws \LogicException
     */
    function decrement(string myKey, int $offset = 1) {
        throw new LogicException("Files cannot be atomically decremented.");
    }

    /**
     * Not implemented
     *
     * @param string myKey The key to increment
     * @param int $offset The number to offset
     * @return int|false
     * @throws \LogicException
     */
    function increment(string myKey, int $offset = 1) {
        throw new LogicException("Files cannot be atomically incremented.");
    }

    /**
     * Sets the current cache key this class is managing, and creates a writable SplFileObject
     * for the cache file the key is referring to.
     *
     * @param string myKey The key
     * @param bool $createKey Whether the key should be created if it doesn"t exists, or not
     * @return bool true if the cache key could be set, false otherwise
     */
    protected bool _setKey(string myKey, bool $createKey = false) {
        myGroups = null;
        if (_groupPrefix) {
            myGroups = vsprintf(_groupPrefix, this.groups());
        }
        $dir = _config["path"] . myGroups;

        if (!is_dir($dir)) {
            mkdir($dir, 0775, true);
        }

        myPath = new SplFileInfo($dir . myKey);

        if (!$createKey && !myPath.isFile()) {
            return false;
        }
        if (
            empty(_File) ||
            _File.getBasename() !== myKey ||
            _File.valid() == false
        ) {
            $exists = is_file(myPath.getPathname());
            try {
                _File = myPath.openFile("c+");
            } catch (Exception $e) {
                trigger_error($e.getMessage(), E_USER_WARNING);

                return false;
            }
            unset(myPath);

            if (!$exists && !chmod(_File.getPathname(), (int)_config["mask"])) {
                trigger_error(sprintf(
                    "Could not apply permission mask "%s" on cache file "%s"",
                    _File.getPathname(),
                    _config["mask"]
                ), E_USER_WARNING);
            }
        }

        return true;
    }

    /**
     * Determine if cache directory is writable
     *
     */
    protected bool _active() {
        $dir = new SplFileInfo(_config["path"]);
        myPath = $dir.getPathname();
        $success = true;
        if (!is_dir(myPath)) {
            // phpcs:disable
            $success = @mkdir(myPath, 0775, true);
            // phpcs:enable
        }

        $isWritableDir = ($dir.isDir() && $dir.isWritable());
        if (!$success || (_init && !$isWritableDir)) {
            _init = false;
            trigger_error(sprintf(
                "%s is not writable",
                _config["path"]
            ), E_USER_WARNING);
        }

        return $success;
    }

    
    protected string _key(myKey) {
        myKey = super._key(myKey);

        if (preg_match("/[\/\\<>?:|*"]/", myKey)) {
            throw new InvalidArgumentException(
                "Cache key `{myKey}` contains invalid characters. " .
                "You cannot use /, \\, <, >, ?, :, |, *, or " in cache keys."
            );
        }

        return myKey;
    }

    /**
     * Recursively deletes all files under any directory named as myGroup
     *
     * @param string myGroup The group to clear.
     * @return bool success
     */
    bool clearGroup(string myGroup) {
        _File = null;

        $prefix = (string)_config["prefix"];

        $directoryIterator = new RecursiveDirectoryIterator(_config["path"]);
        myContentss = new RecursiveIteratorIterator(
            $directoryIterator,
            RecursiveIteratorIterator::CHILD_FIRST
        );
        $filtered = new CallbackFilterIterator(
            myContentss,
            function (SplFileInfo $current) use (myGroup, $prefix) {
                if (!$current.isFile()) {
                    return false;
                }

                $hasPrefix = $prefix == ""
                    || indexOf($current.getBasename(), $prefix) == 0;
                if ($hasPrefix == false) {
                    return false;
                }

                $pos = indexOf(
                    $current.getPathname(),
                    DIRECTORY_SEPARATOR . myGroup . DIRECTORY_SEPARATOR
                );

                return $pos !== false;
            }
        );
        foreach ($object; $filtered) {
            myPath = $object.getPathname();
            unset($object);
            // phpcs:ignore
            @unlink(myPath);
        }

        // unsetting iterators helps releasing possible locks in certain environments,
        // which could otherwise make `rmdir()` fail
        unset($directoryIterator, myContentss, $filtered);

        return true;
    }
}
