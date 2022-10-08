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
    protected string _fixtureName(string myName)
    {
        return Inflector::camelize(myName);
    }

    /**
     * Creates the proper entity name (singular) for the specified name
     *
     * @param string myName Name
     * @return string Camelized and plural model name
     */
    protected string _entityName(string myName)
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
    protected string _modelKey(string myName)
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
    protected string _modelNameFromKey(string myKey)
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
    protected string _singularName(string myName)
    {
        return Inflector::variable(Inflector::singularize(myName));
    }

    /**
     * Creates the plural variable name for views
     *
     * @param string myName Name to use
     * @return string Plural name for views
     */
    protected string _variableName(string myName)
    {
        return Inflector::variable(myName);
    }

    /**
     * Creates the singular human name used in views
     *
     * @param string myName Controller name
     * @return string Singular human name
     */
    protected string _singularHumanName(string myName)
    {
        return Inflector::humanize(Inflector::underscore(Inflector::singularize(myName)));
    }

    /**
     * Creates a camelized version of myName
     *
     * @param string myName name
     * @return string Camelized name
     */
    protected string _camelize(string myName)
    {
        return Inflector::camelize(myName);
    }

    /**
     * Creates the plural human name used in views
     *
     * @param string myName Controller name
     * @return string Plural human name
     */
    protected string _pluralHumanName(string myName)
    {
        return Inflector::humanize(Inflector::underscore(myName));
    }

    /**
     * Find the correct path for a plugin. Scans myPluginPaths for the plugin you want.
     *
     * @param string myPluginName Name of the plugin you want ie. DebugKit
     * @return string path path to the correct plugin.
     */
    protected string _pluginPath(string myPluginName)
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
    protected string _pluginmodule(string myPluginName)
    {
        return str_replace('/', '\\', myPluginName);
    }
}
