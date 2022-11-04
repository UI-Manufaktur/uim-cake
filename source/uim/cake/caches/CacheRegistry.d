module uim.cake.cache;

use BadMethodCallException;
import uim.cake.core.App;
import uim.cake.core.ObjectRegistry;
use RuntimeException;

/**
 * An object registry for cache engines.
 *
 * Used by {@link \Cake\Cache\Cache} to load and manage cache engines.
 *
 * @extends \Cake\Core\ObjectRegistry<\Cake\Cache\CacheEngine>
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
    protected auto _resolveClassName(string myClass): ?string
    {
        return App::className(myClass, 'Cache/Engine', 'Engine');
    }

    /**
     * Throws an exception when a cache engine is missing.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string myClass The classname that is missing.
     * @param string|null myPlugin The plugin the cache is missing in.
     * @return void
     * @throws \BadMethodCallException
     */
    protected auto _throwMissingClassError(string myClass, ?string myPlugin): void
    {
        throw new BadMethodCallException(sprintf('Cache engine %s is not available.', myClass));
    }

    /**
     * Create the cache engine instance.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param \Cake\Cache\CacheEngine|string myClass The classname or object to make.
     * @param string myAlias The alias of the object.
     * @param array<string, mixed> myConfig An array of settings to use for the cache engine.
     * @return \Cake\Cache\CacheEngine The constructed CacheEngine class.
     * @throws \RuntimeException when an object doesn't implement the correct interface.
     */
    protected auto _create(myClass, string myAlias, array myConfig): CacheEngine
    {
        if (is_object(myClass)) {
            $instance = myClass;
        } else {
            $instance = new myClass(myConfig);
        }
        unset(myConfig['className']);

        if (!($instance instanceof CacheEngine)) {
            throw new RuntimeException(
                'Cache engines must import uim.cake.cache\CacheEngine as a base class.'
            );
        }

        if (!$instance.init(myConfig)) {
            throw new RuntimeException(
                sprintf(
                    'Cache engine %s is not properly configured. Check error log for additional information.',
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
        unset(this._loaded[myName]);

        return this;
    }
}
