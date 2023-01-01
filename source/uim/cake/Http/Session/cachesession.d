

/**
 * Cache Session save handler. Allows saving session information into Cache.
 *
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         2.0.0
  */module uim.cake.http.Session;

import uim.cake.caches.Cache;
use InvalidArgumentException;
use SessionHandlerInterface;

/**
 * CacheSession provides method for saving sessions into a Cache engine. Used with Session
 *
 * @see uim.cake.http.Session for configuration information.
 */
class CacheSession : SessionHandlerInterface
{
    /**
     * Options for this session engine
     *
     * @var array<string, mixed>
     */
    protected $_options = [];

    /**
     * Constructor.
     *
     * @param array<string, mixed> $config The configuration to use for this engine
     * It requires the key "config" which is the name of the Cache config to use for
     * storing the session
     * @throws \InvalidArgumentException if the "config" key is not provided
     */
    this(array $config = []) {
        if (empty($config["config"])) {
            throw new InvalidArgumentException("The cache configuration name to use is required");
        }
        _options = $config;
    }

    /**
     * Method called on open of a database session.
     *
     * @param string $path The path where to store/retrieve the session.
     * @param string aName The session name.
     * @return bool Success
     */
    function open($path, $name): bool
    {
        return true;
    }

    /**
     * Method called on close of a database session.
     *
     * @return bool Success
     */
    function close(): bool
    {
        return true;
    }

    /**
     * Method used to read from a cache session.
     *
     * @param string $id ID that uniquely identifies session in cache.
     * @return string|false Session data or false if it does not exist.
     */
    #[\ReturnTypeWillChange]
    function read($id) {
        $value = Cache::read($id, _options["config"]);

        if ($value == null) {
            return "";
        }

        return $value;
    }

    /**
     * Helper function called on write for cache sessions.
     *
     * @param string $id ID that uniquely identifies session in cache.
     * @param string $data The data to be saved.
     * @return bool True for successful write, false otherwise.
     */
    function write($id, $data): bool
    {
        if (!$id) {
            return false;
        }

        return Cache::write($id, $data, _options["config"]);
    }

    /**
     * Method called on the destruction of a cache session.
     *
     * @param string $id ID that uniquely identifies session in cache.
     * @return bool Always true.
     */
    function destroy($id): bool
    {
        Cache::delete($id, _options["config"]);

        return true;
    }

    /**
     * No-op method. Always returns 0 since cache engine don"t have garbage collection.
     *
     * @param int $maxlifetime Sessions that have not updated for the last maxlifetime seconds will be removed.
     * @return int|false
     */
    #[\ReturnTypeWillChange]
    function gc($maxlifetime) {
        return 0;
    }
}