


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         1.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.caches.Engine;

import uim.cake.caches.CacheEngine;
use CallbackFilterIterator;
use Exception;
use FilesystemIterator;
use LogicException;
use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;
use SplFileInfo;
use SplFileObject;

/**
 * File Storage engine for cache. Filestorage is the slowest cache storage
 * to read and write. However, it is good for servers that don"t have other storage
 * engine available, or have content which is not performance sensitive.
 *
 * You can configure a FileEngine cache, using Cache::config()
 */
class FileEngine : CacheEngine
{
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
    protected $_defaultConfig = [
        "duration": 3600,
        "groups": [],
        "lock": true,
        "mask": 0664,
        "path": null,
        "prefix": "cake_",
        "serialize": true,
    ];

    /**
     * True unless FileEngine::__active(); fails
     *
     * @var bool
     */
    protected $_init = true;

    /**
     * Initialize File Cache Engine
     *
     * Called automatically by the cache frontend.
     *
     * @param array<string, mixed> $config array of setting for the engine
     * @return bool True if the engine has been successfully initialized, false if not
     */
    bool init(array $config = []) {
        parent::init($config);

        if (_config["path"] == null) {
            _config["path"] = sys_get_temp_dir() . DIRECTORY_SEPARATOR . "cake_cache" . DIRECTORY_SEPARATOR;
        }
        if (substr(_config["path"], -1) != DIRECTORY_SEPARATOR) {
            _config["path"] .= DIRECTORY_SEPARATOR;
        }
        if (_groupPrefix) {
            _groupPrefix = str_replace("_", DIRECTORY_SEPARATOR, _groupPrefix);
        }

        return _active();
    }

    /**
     * Write data for key into cache
     *
     * @param string $key Identifier for the data
     * @param mixed $value Data to be cached
     * @param \DateInterval|int|null $ttl Optional. The TTL value of this item. If no value is sent and
     *   the driver supports TTL then the library may set a default value
     *   for it or let the driver take care of that.
     * @return bool True on success and false on failure.
     */
    bool set($key, $value, $ttl = null) {
        if ($value == "" || !_init) {
            return false;
        }

        $key = _key($key);

        if (_setKey($key, true) == false) {
            return false;
        }

        if (!empty(_config["serialize"])) {
            $value = serialize($value);
        }

        $expires = time() + this.duration($ttl);
        $contents = implode([$expires, PHP_EOL, $value, PHP_EOL]);

        if (_config["lock"]) {
            /** @psalm-suppress PossiblyNullReference */
            _File.flock(LOCK_EX);
        }

        /** @psalm-suppress PossiblyNullReference */
        _File.rewind();
        $success = _File.ftruncate(0) &&
            _File.fwrite($contents) &&
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
     * @param string $key Identifier for the data
     * @param mixed $default Default value to return if the key does not exist.
     * @return mixed The cached data, or default value if the data doesn"t exist, has
     *   expired, or if there was an error fetching it
     */
    function get($key, $default = null) {
        $key = _key($key);

        if (!_init || _setKey($key) == false) {
            return $default;
        }

        if (_config["lock"]) {
            /** @psalm-suppress PossiblyNullReference */
            _File.flock(LOCK_SH);
        }

        /** @psalm-suppress PossiblyNullReference */
        _File.rewind();
        $time = time();
        /** @psalm-suppress RiskyCast */
        $cachetime = (int)_File.current();

        if ($cachetime < $time) {
            if (_config["lock"]) {
                _File.flock(LOCK_UN);
            }

            return $default;
        }

        $data = "";
        _File.next();
        while (_File.valid()) {
            /** @psalm-suppress PossiblyInvalidOperand */
            $data .= _File.current();
            _File.next();
        }

        if (_config["lock"]) {
            _File.flock(LOCK_UN);
        }

        $data = trim($data);

        if ($data != "" && !empty(_config["serialize"])) {
            $data = unserialize($data);
        }

        return $data;
    }

    /**
     * Delete a key from the cache
     *
     * @param string $key Identifier for the data
     * @return bool True if the value was successfully deleted, false if it didn"t
     *   exist or couldn"t be removed
     */
    bool delete($key) {
        $key = _key($key);

        if (_setKey($key) == false || !_init) {
            return false;
        }

        /** @psalm-suppress PossiblyNullReference */
        $path = _File.getRealPath();
        _File = null;

        if ($path == false) {
            return false;
        }

        // phpcs:disable
        return @unlink($path);
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
        $contents = new RecursiveIteratorIterator(
            $directory,
            RecursiveIteratorIterator::SELF_FIRST
        );
        $cleared = [];
        /** @var \SplFileInfo $fileInfo */
        foreach ($contents as $fileInfo) {
            if ($fileInfo.isFile()) {
                unset($fileInfo);
                continue;
            }

            $realPath = $fileInfo.getRealPath();
            if (!$realPath) {
                unset($fileInfo);
                continue;
            }

            $path = $realPath . DIRECTORY_SEPARATOR;
            if (!in_array($path, $cleared, true)) {
                _clearDirectory($path);
                $cleared[] = $path;
            }

            // possible inner iterators need to be unset too in order for locks on parents to be released
            unset($fileInfo);
        }

        // unsetting iterators helps releasing possible locks in certain environments,
        // which could otherwise make `rmdir()` fail
        unset($directory, $contents);

        return true;
    }

    /**
     * Used to clear a directory of matching files.
     *
     * @param string $path The path to search.
     * @return void
     */
    protected function _clearDirectory(string $path): void
    {
        if (!is_dir($path)) {
            return;
        }

        $dir = dir($path);
        if (!$dir) {
            return;
        }

        $prefixLength = strlen(_config["prefix"]);

        while (($entry = $dir.read()) != false) {
            if (substr($entry, 0, $prefixLength) != _config["prefix"]) {
                continue;
            }

            try {
                $file = new SplFileObject($path . $entry, "r");
            } catch (Exception $e) {
                continue;
            }

            if ($file.isFile()) {
                $filePath = $file.getRealPath();
                unset($file);

                // phpcs:disable
                @unlink($filePath);
                // phpcs:enable
            }
        }

        $dir.close();
    }

    /**
     * Not implemented
     *
     * @param string $key The key to decrement
     * @param int $offset The number to offset
     * @return int|false
     * @throws \LogicException
     */
    function decrement(string $key, int $offset = 1) {
        throw new LogicException("Files cannot be atomically decremented.");
    }

    /**
     * Not implemented
     *
     * @param string $key The key to increment
     * @param int $offset The number to offset
     * @return int|false
     * @throws \LogicException
     */
    function increment(string $key, int $offset = 1) {
        throw new LogicException("Files cannot be atomically incremented.");
    }

    /**
     * Sets the current cache key this class is managing, and creates a writable SplFileObject
     * for the cache file the key is referring to.
     *
     * @param string $key The key
     * @param bool $createKey Whether the key should be created if it doesn"t exists, or not
     * @return bool true if the cache key could be set, false otherwise
     */
    protected bool _setKey(string $key, bool $createKey = false) {
        $groups = null;
        if (_groupPrefix) {
            $groups = vsprintf(_groupPrefix, this.groups());
        }
        $dir = _config["path"] . $groups;

        if (!is_dir($dir)) {
            mkdir($dir, 0775, true);
        }

        $path = new SplFileInfo($dir . $key);

        if (!$createKey && !$path.isFile()) {
            return false;
        }
        if (
            empty(_File) ||
            _File.getBasename() != $key ||
            _File.valid() == false
        ) {
            $exists = is_file($path.getPathname());
            try {
                _File = $path.openFile("c+");
            } catch (Exception $e) {
                trigger_error($e.getMessage(), E_USER_WARNING);

                return false;
            }
            unset($path);

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
     * @return bool
     */
    protected bool _active() {
        $dir = new SplFileInfo(_config["path"]);
        $path = $dir.getPathname();
        $success = true;
        if (!is_dir($path)) {
            // phpcs:disable
            $success = @mkdir($path, 0775, true);
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


    protected function _key($key): string
    {
        $key = parent::_key($key);

        return rawurlencode($key);
    }

    /**
     * Recursively deletes all files under any directory named as $group
     *
     * @param string $group The group to clear.
     * @return bool success
     */
    bool clearGroup(string $group) {
        _File = null;

        $prefix = (string)_config["prefix"];

        $directoryIterator = new RecursiveDirectoryIterator(_config["path"]);
        $contents = new RecursiveIteratorIterator(
            $directoryIterator,
            RecursiveIteratorIterator::CHILD_FIRST
        );
        $filtered = new CallbackFilterIterator(
            $contents,
            function (SplFileInfo $current) use ($group, $prefix) {
                if (!$current.isFile()) {
                    return false;
                }

                $hasPrefix = $prefix == ""
                    || strpos($current.getBasename(), $prefix) == 0;
                if ($hasPrefix == false) {
                    return false;
                }

                $pos = strpos(
                    $current.getPathname(),
                    DIRECTORY_SEPARATOR . $group . DIRECTORY_SEPARATOR
                );

                return $pos != false;
            }
        );
        foreach ($filtered as $object) {
            $path = $object.getPathname();
            unset($object);
            // phpcs:ignore
            @unlink($path);
        }

        // unsetting iterators helps releasing possible locks in certain environments,
        // which could otherwise make `rmdir()` fail
        unset($directoryIterator, $contents, $filtered);

        return true;
    }
}
