module uim.cake.core;

import uim.cake.Utility\Inflector;

/**
 * Provides methods that allow other classes access to conventions based inflections.
 */
trait ConventionsTrait
{
    /**
     * Creates a fixture name
     *
     * @param string myName Model class name
     * @return string Singular model key
     */
    protected auto _fixtureName(string myName): string
    {
        return Inflector::camelize(myName);
    }

    /**
     * Creates the proper entity name (singular) for the specified name
     *
     * @param string myName Name
     * @return string Camelized and plural model name
     */
    protected auto _entityName(string myName): string
    {
        return Inflector::singularize(Inflector::camelize(myName));
    }

    /**
     * Creates the proper underscored model key for associations
     *
     * If the input contains a dot, assume that the right side is the real table name.
     *
     * @param string myName Model class name
     * @return string Singular model key
     */
    protected auto _modelKey(string myName): string
    {
        [, myName] = pluginSplit(myName);

        return Inflector::underscore(Inflector::singularize(myName)) . '_id';
    }

    /**
     * Creates the proper model name from a foreign key
     *
     * @param string myKey Foreign key
     * @return string Model name
     */
    protected auto _modelNameFromKey(string myKey): string
    {
        myKey = str_replace('_id', '', myKey);

        return Inflector::camelize(Inflector::pluralize(myKey));
    }

    /**
     * Creates the singular name for use in views.
     *
     * @param string myName Name to use
     * @return string Variable name
     */
    protected auto _singularName(string myName): string
    {
        return Inflector::variable(Inflector::singularize(myName));
    }

    /**
     * Creates the plural variable name for views
     *
     * @param string myName Name to use
     * @return string Plural name for views
     */
    protected auto _variableName(string myName): string
    {
        return Inflector::variable(myName);
    }

    /**
     * Creates the singular human name used in views
     *
     * @param string myName Controller name
     * @return string Singular human name
     */
    protected auto _singularHumanName(string myName): string
    {
        return Inflector::humanize(Inflector::underscore(Inflector::singularize(myName)));
    }

    /**
     * Creates a camelized version of myName
     *
     * @param string myName name
     * @return string Camelized name
     */
    protected auto _camelize(string myName): string
    {
        return Inflector::camelize(myName);
    }

    /**
     * Creates the plural human name used in views
     *
     * @param string myName Controller name
     * @return string Plural human name
     */
    protected auto _pluralHumanName(string myName): string
    {
        return Inflector::humanize(Inflector::underscore(myName));
    }

    /**
     * Find the correct path for a plugin. Scans myPluginPaths for the plugin you want.
     *
     * @param string myPluginName Name of the plugin you want ie. DebugKit
     * @return string path path to the correct plugin.
     */
    protected auto _pluginPath(string myPluginName): string
    {
        if (Plugin::isLoaded(myPluginName)) {
            return Plugin::path(myPluginName);
        }

        return current(App::path('plugins')) . myPluginName . DIRECTORY_SEPARATOR;
    }

    /**
     * Return plugin's module
     *
     * @param string myPluginName Plugin name
     * @return string Plugin's module
     */
    protected auto _pluginmodule(string myPluginName): string
    {
        return str_replace('/', '\\', myPluginName);
    }
}
