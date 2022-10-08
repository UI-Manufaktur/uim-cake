module uim.cake.database.Schema;

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
     * @var \Cake\Database\Schema\ICollection
     */
    protected myCollection;

    /**
     * The cache key prefix
     *
     * @var string
     */
    protected $prefix;

    /**
     * Constructor.
     *
     * @param \Cake\Database\Schema\ICollection myCollection The collection to wrap.
     * @param string $prefix The cache key prefix to use. Typically the connection name.
     * @param \Psr\SimpleCache\ICache $cacher Cacher instance.
     */
    this(ICollection myCollection, string $prefix, ICache $cacher) {
        this.collection = myCollection;
        this.prefix = $prefix;
        this.cacher = $cacher;
    }


    function listTables(): array
    {
        return this.collection.listTables();
    }


    function describe(string myName, array myOptions = []): TableSchemaInterface
    {
        myOptions += ['forceRefresh' => false];
        $cacheKey = this.cacheKey(myName);

        if (!myOptions['forceRefresh']) {
            $cached = this.cacher.get($cacheKey);
            if ($cached !== null) {
                return $cached;
            }
        }

        myTable = this.collection.describe(myName, myOptions);
        this.cacher.set($cacheKey, myTable);

        return myTable;
    }

    /**
     * Get the cache key for a given name.
     *
     * @param string myName The name to get a cache key for.
     * @return string The cache key.
     */
    function cacheKey(string myName): string
    {
        return this.prefix . '_' . myName;
    }

    /**
     * Set a cacher.
     *
     * @param \Psr\SimpleCache\ICache $cacher Cacher object
     * @return this
     */
    auto setCacher(ICache $cacher) {
        this.cacher = $cacher;

        return this;
    }

    /**
     * Get a cacher.
     *
     * @return \Psr\SimpleCache\ICache $cacher Cacher object
     */
    auto getCacher(): ICache
    {
        return this.cacher;
    }
}
