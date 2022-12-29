


 *


 * @since         3.0.0
  */
module uim.cake.Datasource;

import uim.cake.core.App;
import uim.cake.core.ObjectRegistry;
import uim.cake.datasources.Exception\MissingDatasourceException;

/**
 * A registry object for connection instances.
 *
 * @see uim.cake.datasources.ConnectionManager
 * @: \Cake\Core\ObjectRegistry<\Cake\Datasource\ConnectionInterface>
 */
class ConnectionRegistry : ObjectRegistry
{
    /**
     * Resolve a datasource classname.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string $class Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string|null
     */
    protected function _resolveClassName(string $class): ?string
    {
        return App::className($class, "Datasource");
    }

    /**
     * Throws an exception when a datasource is missing
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string $class The classname that is missing.
     * @param string|null $plugin The plugin the datasource is missing in.
     * @return void
     * @throws uim.cake.Datasource\Exception\MissingDatasourceException
     */
    protected function _throwMissingClassError(string $class, ?string $plugin): void
    {
        throw new MissingDatasourceException([
            "class": $class,
            "plugin": $plugin,
        ]);
    }

    /**
     * Create the connection object with the correct settings.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * If a callable is passed as first argument, The returned value of this
     * function will be the result of the callable.
     *
     * @param uim.cake.Datasource\ConnectionInterface|callable|string $class The classname or object to make.
     * @param string $alias The alias of the object.
     * @param array<string, mixed> $config An array of settings to use for the datasource.
     * @return uim.cake.Datasource\ConnectionInterface A connection with the correct settings.
     */
    protected function _create($class, string $alias, array $config) {
        if (is_callable($class)) {
            return $class($alias);
        }

        if (is_object($class)) {
            return $class;
        }

        unset($config["className"]);

        /** @var uim.cake.datasources.ConnectionInterface */
        return new $class($config);
    }

    /**
     * Remove a single adapter from the registry.
     *
     * @param string $name The adapter name.
     * @return this
     */
    function unload(string $name) {
        unset(_loaded[$name]);

        return this;
    }
}
