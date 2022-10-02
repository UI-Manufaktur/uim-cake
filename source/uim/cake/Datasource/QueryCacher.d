module uim.cake.Datasource;

import uim.cake.cache\Cache;
use Closure;
use Psr\SimpleCache\ICache;
use RuntimeException;
use Traversable;

/**
 * Handles caching queries and loading results from the cache.
 *
 * Used by {@link \Cake\Datasource\QueryTrait} internally.
 *
 * @internal
 * @see \Cake\Datasource\QueryTrait::cache() for the public interface.
 */
class QueryCacher
{
    /**
     * The key or function to generate a key.
     *
     * @var \Closure|string
     */
    protected $_key;

    /**
     * Config for cache engine.
     *
     * @var \Psr\SimpleCache\ICache|string
     */
    protected $_config;

    /**
     * Constructor.
     *
     * @param \Closure|string myKey The key or function to generate a key.
     * @param \Psr\SimpleCache\ICache|string myConfig The cache config name or cache engine instance.
     * @throws \RuntimeException
     */
    this(myKey, myConfig)
    {
        if (!is_string(myKey) && !(myKey instanceof Closure)) {
            throw new RuntimeException('Cache keys must be strings or callables.');
        }
        this._key = myKey;

        if (!is_string(myConfig) && !(myConfig instanceof ICache)) {
            throw new RuntimeException('Cache configs must be strings or \Psr\SimpleCache\ICache instances.');
        }
        this._config = myConfig;
    }

    /**
     * Load the cached results from the cache or run the query.
     *
     * @param object myQuery The query the cache read is for.
     * @return mixed|null Either the cached results or null.
     */
    function fetch(object myQuery)
    {
        myKey = this._resolveKey(myQuery);
        $storage = this._resolveCacher();
        myResult = $storage.get(myKey);
        if (empty(myResult)) {
            return null;
        }

        return myResult;
    }

    /**
     * Store the result set into the cache.
     *
     * @param object myQuery The query the cache read is for.
     * @param \Traversable myResults The result set to store.
     * @return bool True if the data was successfully cached, false on failure
     */
    function store(object myQuery, Traversable myResults): bool
    {
        myKey = this._resolveKey(myQuery);
        $storage = this._resolveCacher();

        return $storage.set(myKey, myResults);
    }

    /**
     * Get/generate the cache key.
     *
     * @param object myQuery The query to generate a key for.
     * @return string
     * @throws \RuntimeException
     */
    protected auto _resolveKey(object myQuery): string
    {
        if (is_string(this._key)) {
            return this._key;
        }
        $func = this._key;
        myKey = $func(myQuery);
        if (!is_string(myKey)) {
            $msg = sprintf('Cache key functions must return a string. Got %s.', var_export(myKey, true));
            throw new RuntimeException($msg);
        }

        return myKey;
    }

    /**
     * Get the cache engine.
     *
     * @return \Psr\SimpleCache\ICache
     */
    protected auto _resolveCacher() {
        if (is_string(this._config)) {
            return Cache::pool(this._config);
        }

        return this._config;
    }
}
