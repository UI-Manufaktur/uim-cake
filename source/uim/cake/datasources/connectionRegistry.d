module uim.cake.datasources;

import uim.cake.core.App;
import uim.cake.core.ObjectRegistry;
import uim.cake.datasources.exceptions\MissingDatasourceException;

/**
 * A registry object for connection instances.
 *
 * @see \Cake\Datasource\ConnectionManager
 * @extends \Cake\Core\ObjectRegistry<\Cake\Datasource\IConnection>
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
    protected Nullable!string _resolveClassName(string myClass) {
        return App::className(myClass, "Datasource");
    }

    /**
     * Throws an exception when a datasource is missing
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string myClass The classname that is missing.
     * @param string|null myPlugin The plugin the datasource is missing in.
     * @throws \Cake\Datasource\Exception\MissingDatasourceException
     */
    protected void _throwMissingClassError(string myClass, Nullable!string myPlugin) {
        throw new MissingDatasourceException([
            "class": myClass,
            "plugin": myPlugin,
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
     * @param \Cake\Datasource\IConnection|callable|string myClass The classname or object to make.
     * @param string myAlias The alias of the object.
     * @param array<string, mixed> myConfig An array of settings to use for the datasource.
     * @return \Cake\Datasource\IConnection A connection with the correct settings.
     */
    protected auto _create(myClass, string myAlias, array myConfig) {
        if (is_callable(myClass)) {
            return myClass(myAlias);
        }

        if (is_object(myClass)) {
            return myClass;
        }

        unset(myConfig["className"]);

        /** @var \Cake\Datasource\IConnection */
        return new myClass(myConfig);
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
