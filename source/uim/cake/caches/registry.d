/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.caches.registry;

@safe:
import uim.cake;

/**
 * An object registry for cache engines.
 *
 * Used by {@link uim.cake.Cache\Cache} to load and manage cache engines.
 *
 * @: uim.cake.Core\ObjectRegistry<uim.cake.Cache\CacheEngine>
 */
class CacheRegistry : ObjectRegistry
{
    /**
     * Resolve a cache engine classname.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string myClass Partial classname to resolve.
     * @return string|null Either the correct classname or null.
     * @psalm-return class-string|null
     */
    protected Nullable!string _resolveClassName(string myClass) {
        return App::className(myClass, "Cache/Engine", "Engine");
    }

    /**
     * Throws an exception when a cache engine is missing.
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string myClass The classname that is missing.
     * @param string|null myPlugin The plugin the cache is missing in.
     * @throws \BadMethodCallException
     */
    protected void _throwMissingClassError(string myClass, Nullable!string myPlugin) {
      throw new BadMethodCallException(sprintf("Cache engine %s is not available.", myClass));
    }

    /**
     * Create the cache engine instance.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param uim.cake.Cache\CacheEngine|string myClass The classname or object to make.
     * @param string aliasName The alias of the object.
     * @param array<string, mixed> myConfig An array of settings to use for the cache engine.
     * @return uim.cake.Cache\CacheEngine The constructed CacheEngine class.
     * @throws \RuntimeException when an object doesn"t implement the correct interface.
     */
    protected CacheEngine _create(myClass, string aliasName, array myConfig) {
      if (is_object(myClass)) {
          $instance = myClass;
      } else {
          $instance = new myClass(myConfig);
      }
      unset(myConfig["className"]);

      if (!($instance instanceof CacheEngine)) {
          throw new RuntimeException(
              "Cache engines must import uim.cake.caches\CacheEngine as a base class."
          );
      }

      if (!$instance.init(myConfig)) {
          throw new RuntimeException(
              sprintf(
                  "Cache engine %s is not properly configured. Check error log for additional information.",
                  get_class($instance)
              )
          );
      }

      return $instance;
    }

    /**
     * Remove a single adapter from the registry.
     *
     * @param string myName The adapter name.
     * @return this
     */
    function unload(string myName) {
      unset(_loaded[myName]);

      return this;
    }
}
