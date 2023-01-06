module uim.cake.caches;

use BadMethodCallException;
import uim.cake.core.App;
import uim.cake.core.ObjectRegistry;
use RuntimeException;

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
     * @param string $class Partial classname to resolve.
     * @return string|null Either the correct classname or null.
     */
    protected Nullable!string _resolveClassName(string $class) {
        return App::className($class, "Cache/Engine", "Engine");
    }

    /**
     * Throws an exception when a cache engine is missing.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string $class The classname that is missing.
     * @param string|null $plugin The plugin the cache is missing in.
     * @return void
     * @throws \BadMethodCallException
     */
    protected void _throwMissingClassError(string $class, Nullable!string $plugin) {
        throw new BadMethodCallException(sprintf("Cache engine %s is not available.", $class));
    }

    /**
     * Create the cache engine instance.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param uim.cake.Cache\CacheEngine|string $class The classname or object to make.
     * @param string $alias The alias of the object.
     * @param array<string, mixed> aConfig An array of settings to use for the cache engine.
     * @return uim.cake.Cache\CacheEngine The constructed CacheEngine class.
     * @throws \RuntimeException when an object doesn"t implement the correct interface.
     */
    protected CacheEngine _create($class, string $alias, Json aConfig) {
        if (is_object($class)) {
            $instance = $class;
        } else {
            $instance = new $class(aConfig);
        }
        unset(aConfig["className"]);

        if (!($instance instanceof CacheEngine)) {
            throw new RuntimeException(
                "Cache engines must import uim.cake.caches.CacheEngine as a base class."
            );
        }

        if (!$instance.init(aConfig)) {
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
     * @param string aName The adapter name.
     * @return this
     */
    function unload(string aName) {
        unset(_loaded[$name]);

        return this;
    }
}
