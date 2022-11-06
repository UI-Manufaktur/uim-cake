module uim.baklava.datasources;

import uim.baklava.core.App;
import uim.baklava.core.ObjectRegistry;
import uim.baklava.datasources\Exception\MissingDatasourceException;

/**
 * A registry object for connection instances.
 *
 * @see \Cake\Datasource\ConnectionManager
 * @extends \Cake\Core\ObjectRegistry<\Cake\Datasource\ConnectionInterface>
 */
class ConnectionRegistry : ObjectRegistry
{
    /**
     * Resolve a datasource classname.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string myClass Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string|null
     */
    protected auto _resolveClassName(string myClass): Nullable!string
    {
        return App::className(myClass, 'Datasource');
    }

    /**
     * Throws an exception when a datasource is missing
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string myClass The classname that is missing.
     * @param string|null myPlugin The plugin the datasource is missing in.
     * @return void
     * @throws \Cake\Datasource\Exception\MissingDatasourceException
     */
    protected auto _throwMissingClassError(string myClass, Nullable!string myPlugin): void
    {
        throw new MissingDatasourceException([
            'class' => myClass,
            'plugin' => myPlugin,
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
     * @param \Cake\Datasource\ConnectionInterface|callable|string myClass The classname or object to make.
     * @param string myAlias The alias of the object.
     * @param array<string, mixed> myConfig An array of settings to use for the datasource.
     * @return \Cake\Datasource\ConnectionInterface A connection with the correct settings.
     */
    protected auto _create(myClass, string myAlias, array myConfig) {
        if (is_callable(myClass)) {
            return myClass(myAlias);
        }

        if (is_object(myClass)) {
            return myClass;
        }

        unset(myConfig['className']);

        /** @var \Cake\Datasource\ConnectionInterface */
        return new myClass(myConfig);
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