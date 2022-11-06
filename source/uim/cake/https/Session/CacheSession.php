

/**
 * Cache Session save handler. Allows saving session information into Cache.
 *

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.caketps\Session;

import uim.cakeches\Cache;
use InvalidArgumentException;
use SessionHandlerInterface;

/**
 * CacheSession provides method for saving sessions into a Cache engine. Used with Session
 *
 * @see \Cake\Http\Session for configuration information.
 */
class CacheSession : SessionHandlerInterface
{
    /**
     * Options for this session engine
     *
     * @var array
     */
    protected $_options = [];

    /**
     * Constructor.
     *
     * @param array<string, mixed> myConfig The configuration to use for this engine
     * It requires the key 'config' which is the name of the Cache config to use for
     * storing the session
     * @throws \InvalidArgumentException if the 'config' key is not provided
     */
    this(array myConfig = []) {
        if (empty(myConfig['config'])) {
            throw new InvalidArgumentException('The cache configuration name to use is required');
        }
        this._options = myConfig;
    }

    /**
     * Method called on open of a database session.
     *
     * @param string myPath The path where to store/retrieve the session.
     * @param string myName The session name.
     * @return bool Success
     */
    function open(myPath, myName): bool
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
        myValue = Cache::read($id, this._options['config']);

        if (myValue === null) {
            return '';
        }

        return myValue;
    }

    /**
     * Helper function called on write for cache sessions.
     *
     * @param string $id ID that uniquely identifies session in cache.
     * @param string myData The data to be saved.
     * @return bool True for successful write, false otherwise.
     */
    function write($id, myData): bool
    {
        if (!$id) {
            return false;
        }

        return Cache::write($id, myData, this._options['config']);
    }

    /**
     * Method called on the destruction of a cache session.
     *
     * @param string $id ID that uniquely identifies session in cache.
     * @return bool Always true.
     */
    function destroy($id): bool
    {
        Cache::delete($id, this._options['config']);

        return true;
    }

    /**
     * No-op method. Always returns 0 since cache engine don't have garbage collection.
     *
     * @param int $maxlifetime Sessions that have not updated for the last maxlifetime seconds will be removed.
     * @return int|false
     */
    #[\ReturnTypeWillChange]
    function gc($maxlifetime) {
        return 0;
    }
}
