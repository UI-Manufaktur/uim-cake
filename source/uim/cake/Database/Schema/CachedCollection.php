


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
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
     * @var \Cake\Database\Schema\ICollection
     */
    protected $collection;

    /**
     * The cache key prefix
     *
     * @var string
     */
    protected $prefix;

    /**
     * Constructor.
     *
     * @param \Cake\Database\Schema\ICollection $collection The collection to wrap.
     * @param string $prefix The cache key prefix to use. Typically the connection name.
     * @param \Psr\SimpleCache\ICache $cacher Cacher instance.
     */
    public this(ICollection $collection, string $prefix, ICache $cacher) {
        this.collection = $collection;
        this.prefix = $prefix;
        this.cacher = $cacher;
    }

    /**
     * @inheritDoc
     */
    function listTablesWithoutViews(): array
    {
        return this.collection.listTablesWithoutViews();
    }

    /**
     * @inheritDoc
     */
    function listTables(): array
    {
        return this.collection.listTables();
    }

    /**
     * @inheritDoc
     */
    function describe(string $name, array $options = []): TableSchemaInterface
    {
        $options += ['forceRefresh': false];
        $cacheKey = this.cacheKey($name);

        if (!$options['forceRefresh']) {
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
     * @param string $name The name to get a cache key for.
     * @return string The cache key.
     */
    function cacheKey(string $name): string
    {
        return this.prefix . '_' . $name;
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
