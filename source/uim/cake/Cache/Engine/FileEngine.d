module uim.cake.cache\Engine;

import uim.cake.cache\CacheEngine;
import uim.cake.cache\InvalidArgumentException;
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
 * to read and write. However, it is good for servers that don't have other storage
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
     * - `groups` List of groups or 'tags' associated to every key stored in this config.
     *    handy for deleting a complete group from cache.
     * - `lock` Used by FileCache. Should files be locked before writing to them?
     * - `mask` The mask used for created files
     * - `path` Path to where cachefiles should be saved. Defaults to system's temp dir.
     * - `prefix` Prepended to all entries. Good for when you need to share a keyspace
     *    with either another cache config or another application.
     *    cache::gc from ever being called automatically.
     * - `serialize` Should cache objects be serialized first.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'duration' => 3600,
        'groups' => [],
        'lock' => true,
        'mask' => 0664,
        'path' => null,
        'prefix' => 'cake_',
        'serialize' => true,
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
     * @param array<string, mixed> myConfig array of setting for the engine
     * @return bool True if the engine has been successfully initialized, false if not
     */
    bool init(array myConfig = []) {
        super.init(myConfig);

        if (this._config['path'] === null) {
            this._config['path'] = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'cake_cache' . DIRECTORY_SEPARATOR;
        }
        if (substr(this._config['path'], -1) !== DIRECTORY_SEPARATOR) {
            this._config['path'] .= DIRECTORY_SEPARATOR;
        }
        if (this._groupPrefix) {
            this._groupPrefix = this._groupPrefix.replace('_', DIRECTORY_SEPARATOR);
        }

        return this._active();
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
        if (myValue === '' || !this._init) {
            return false;
        }

        myDataId = this._key(myDataId);

        if (this._setKey(myDataId, true) === false) {
            return false;
        }

        if (!empty(this._config['serialize'])) {
            myValue = serialize(myValue);
        }

        $expires = time() + this.duration($ttl);
        myContentss = implode([$expires, PHP_EOL, myValue, PHP_EOL]);

        if (this._config['lock']) {
            /** @psalm-suppress PossiblyNullReference */
            this._File.flock(LOCK_EX);
        }

        /** @psalm-suppress PossiblyNullReference */
        this._File.rewind();
        $success = this._File.ftruncate(0) &&
            this._File.fwrite(myContentss) &&
            this._File.fflush();

        if (this._config['lock']) {
            this._File.flock(LOCK_UN);
        }
        this._File = null;

        return $success;
    }

    /**
     * Read a key from the cache
     *
     * @param string myDataId Identifier for the data
     * @param mixed $default Default value to return if the key does not exist.
     * @return mixed The cached data, or default value if the data doesn't exist, has
     *   expired, or if there was an error fetching it
     */
    auto get(myDataId, $default = null) {
        myDataId = this._key(myDataId);

        if (!this._init || this._setKey(myDataId) === false) {
            return $default;
        }

        if (this._config['lock']) {
            /** @psalm-suppress PossiblyNullReference */
            this._File.flock(LOCK_SH);
        }

        /** @psalm-suppress PossiblyNullReference */
        this._File.rewind();
        $time = time();
        $cachetime = (int)this._File.current();

        if ($cachetime < $time) {
            if (this._config['lock']) {
                this._File.flock(LOCK_UN);
            }

            return $default;
        }

        myData = '';
        this._File.next();
        while (this._File.valid()) {
            /** @psalm-suppress PossiblyInvalidOperand */
            myData .= this._File.current();
            this._File.next();
        }

        if (this._config['lock']) {
            this._File.flock(LOCK_UN);
        }

        myData = trim(myData);

        if (myData !== '' && !empty(this._config['serialize'])) {
            myData = unserialize(myData);
        }

        return myData;
    }

    /**
     * Delete a key from the cache
     *
     * @param string myDataId Identifier for the data
     * @return bool True if the value was successfully deleted, false if it didn't
     *   exist or couldn't be removed
     */
    bool delete(myDataId) {
        myDataId = this._key(myDataId);

        if (this._setKey(myDataId) === false || !this._init) {
            return false;
        }

        /** @psalm-suppress PossiblyNullReference */
        myPath = this._File.getRealPath();
        this._File = null;

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
        if (!this._init) {
            return false;
        }
        this._File = null;

        this._clearDirectory(this._config['path']);

        $directory = new RecursiveDirectoryIterator(
            this._config['path'],
            FilesystemIterator::SKIP_DOTS
        );
        myContentss = new RecursiveIteratorIterator(
            $directory,
            RecursiveIteratorIterator::SELF_FIRST
        );
        $cleared = [];
        /** @var \SplFileInfo $fileInfo */
        foreach (myContentss as $fileInfo) {
            if ($fileInfo.isFile()) {
                unset($fileInfo);
                continue;
            }

            $realPath = $fileInfo.getRealPath();
            if (!$realPath) {
                unset($fileInfo);
                continue;
            }

            myPath = $realPath . DIRECTORY_SEPARATOR;
            if (!in_array(myPath, $cleared, true)) {
                this._clearDirectory(myPath);
                $cleared[] = myPath;
            }

            // possible inner iterators need to be unset too in order for locks on parents to be released
            unset($fileInfo);
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
     * @return void
     */
    protected auto _clearDirectory(string myPath): void
    {
        if (!is_dir(myPath)) {
            return;
        }

        $dir = dir(myPath);
        if (!$dir) {
            return;
        }

        $prefixLength = strlen(this._config['prefix']);

        while (($entry = $dir.read()) !== false) {
            if (substr($entry, 0, $prefixLength) !== this._config['prefix']) {
                continue;
            }

            try {
                $file = new SplFileObject(myPath . $entry, 'r');
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
     * @param string myKey The key to decrement
     * @param int $offset The number to offset
     * @return int|false
     * @throws \LogicException
     */
    function decrement(string myKey, int $offset = 1) {
        throw new LogicException('Files cannot be atomically decremented.');
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
        throw new LogicException('Files cannot be atomically incremented.');
    }

    /**
     * Sets the current cache key this class is managing, and creates a writable SplFileObject
     * for the cache file the key is referring to.
     *
     * @param string myKey The key
     * @param bool $createKey Whether the key should be created if it doesn't exists, or not
     * @return bool true if the cache key could be set, false otherwise
     */
    protected bool _setKey(string myKey, bool $createKey = false) {
        $groups = null;
        if (this._groupPrefix) {
            $groups = vsprintf(this._groupPrefix, this.groups());
        }
        $dir = this._config['path'] . $groups;

        if (!is_dir($dir)) {
            mkdir($dir, 0775, true);
        }

        myPath = new SplFileInfo($dir . myKey);

        if (!$createKey && !myPath.isFile()) {
            return false;
        }
        if (
            empty(this._File) ||
            this._File.getBasename() !== myKey ||
            this._File.valid() === false
        ) {
            $exists = is_file(myPath.getPathname());
            try {
                this._File = myPath.openFile('c+');
            } catch (Exception $e) {
                trigger_error($e.getMessage(), E_USER_WARNING);

                return false;
            }
            unset(myPath);

            if (!$exists && !chmod(this._File.getPathname(), (int)this._config['mask'])) {
                trigger_error(sprintf(
                    'Could not apply permission mask "%s" on cache file "%s"',
                    this._File.getPathname(),
                    this._config['mask']
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
        $dir = new SplFileInfo(this._config['path']);
        myPath = $dir.getPathname();
        $success = true;
        if (!is_dir(myPath)) {
            // phpcs:disable
            $success = @mkdir(myPath, 0775, true);
            // phpcs:enable
        }

        $isWritableDir = ($dir.isDir() && $dir.isWritable());
        if (!$success || (this._init && !$isWritableDir)) {
            this._init = false;
            trigger_error(sprintf(
                '%s is not writable',
                this._config['path']
            ), E_USER_WARNING);
        }

        return $success;
    }


    protected auto _key(myKey): string
    {
        myKey = super._key(myKey);

        if (preg_match('/[\/\\<>?:|*"]/', myKey)) {
            throw new InvalidArgumentException(
                "Cache key `{myKey}` contains invalid characters. " .
                'You cannot use /, \\, <, >, ?, :, |, *, or " in cache keys.'
            );
        }

        return myKey;
    }

    /**
     * Recursively deletes all files under any directory named as $group
     *
     * @param string $group The group to clear.
     * @return bool success
     */
    bool clearGroup(string $group) {
        this._File = null;

        $prefix = (string)this._config['prefix'];

        $directoryIterator = new RecursiveDirectoryIterator(this._config['path']);
        myContentss = new RecursiveIteratorIterator(
            $directoryIterator,
            RecursiveIteratorIterator::CHILD_FIRST
        );
        $filtered = new CallbackFilterIterator(
            myContentss,
            function (SplFileInfo $current) use ($group, $prefix) {
                if (!$current.isFile()) {
                    return false;
                }

                $hasPrefix = $prefix === ''
                    || strpos($current.getBasename(), $prefix) === 0;
                if ($hasPrefix === false) {
                    return false;
                }

                $pos = strpos(
                    $current.getPathname(),
                    DIRECTORY_SEPARATOR . $group . DIRECTORY_SEPARATOR
                );

                return $pos !== false;
            }
        );
        foreach ($filtered as $object) {
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
