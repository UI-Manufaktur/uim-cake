module uim.cake.databases.schemas;

use Psr\SimpleCache\ICache;

/**
 * Decorates a schema collection and adds caching
 */
class CachedCollection : ICollection {
  // The decorated schema collection
  protected ICollection $collection;

  // The cache key prefix
  protected string $prefix;

  /**
    * Constructor.
    *
    * @param uim.cake.databases.Schema\ICollection $collection The collection to wrap.
    * @param string $prefix The cache key prefix to use. Typically the connection name.
    * @param \Psr\SimpleCache\ICache $cacher Cacher instance.
    */
  this(ICollection aCollection, string $prefix, ICache $cacher) {
      _collection = aCollection;
      _prefix = $prefix;
      _cacher = $cacher;
  }


  array listTablesWithoutViews() {
      return this.collection.listTablesWithoutViews();
  }


  array listTables() {
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

  // Set and get a cacher.
  mixin(OProperty!("ICache", "cacher"));
}
