module uim.cake.databases.Schema;

use Psr\SimpleCache\ICache;

/**
 * Decorates a schema collection and adds caching
 */
class CachedCollection : ICollection
{
    /**
     * Cacher instance.
     *
     * @var \Psr\SimpleCache\ICache
     */
    protected $cacher;

    /**
     * The decorated schema collection
     *
     * @var uim.cake.databases.Schema\ICollection
     */
    protected $collection;

    /**
     * The cache key prefix
     */
    protected string $prefix;

    /**
     * Constructor.
     *
     * @param uim.cake.databases.Schema\ICollection $collection The collection to wrap.
     * @param string $prefix The cache key prefix to use. Typically the connection name.
     * @param \Psr\SimpleCache\ICache $cacher Cacher instance.
     */
    this(ICollection $collection, string $prefix, ICache $cacher) {
        this.collection = $collection;
        this.prefix = $prefix;
        this.cacher = $cacher;
    }


    array listTablesWithoutViews()
    {
        return this.collection.listTablesWithoutViews();
    }


    array listTables()
    {
        return this.collection.listTables();
    }


    function describe(string aName, array $options = []): TableISchema
    {
        $options += ["forceRefresh": false];
        $cacheKey = this.cacheKey($name);

        if (!$options["forceRefresh"]) {
            $cached = this.cacher.get($cacheKey);
            if ($cached != null) {
                return $cached;
            }
        }

        $table = this.collection.describe($name, $options);
        this.cacher.set($cacheKey, $table);

        return $table;
    }

    /**
     * Get the cache key for a given name.
     *
     * @param string aName The name to get a cache key for.
     * @return string The cache key.
     */
    string cacheKey(string aName) {
        return this.prefix ~ "_" ~ $name;
    }

    /**
     * Set a cacher.
     *
     * @param \Psr\SimpleCache\ICache $cacher Cacher object
     * @return this
     */
    function setCacher(ICache $cacher) {
        this.cacher = $cacher;

        return this;
    }

    /**
     * Get a cacher.
     *
     * @return \Psr\SimpleCache\ICache $cacher Cacher object
     */
    function getCacher(): ICache
    {
        return this.cacher;
    }
}
