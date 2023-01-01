module uim.cake.Core;

import uim.cake.utilities.Inflector;

/**
 * Provides methods that allow other classes access to conventions based inflections.
 */
trait ConventionsTrait
{
    /**
     * Creates a fixture name
     *
     * @param string aName Model class name
     * @return string Singular model key
     */
    protected string _fixtureName(string aName) {
        return Inflector::camelize($name);
    }

    /**
     * Creates the proper entity name (singular) for the specified name
     *
     * @param string aName Name
     * @return string Camelized and plural model name
     */
    protected string _entityName(string aName) {
        return Inflector::singularize(Inflector::camelize($name));
    }

    /**
     * Creates the proper underscored model key for associations
     *
     * If the input contains a dot, assume that the right side is the real table name.
     *
     * @param string aName Model class name
     * @return string Singular model key
     */
    protected string _modelKey(string aName) {
        [, $name] = pluginSplit($name);

        return Inflector::underscore(Inflector::singularize($name)) ~ "_id";
    }

    /**
     * Creates the proper model name from a foreign key
     *
     * @param string aKey Foreign key
     * @return string Model name
     */
    protected string _modelNameFromKey(string aKey) {
        $key = str_replace("_id", "", $key);

        return Inflector::camelize(Inflector::pluralize($key));
    }

    /**
     * Creates the singular name for use in views.
     *
     * @param string aName Name to use
     * @return string Variable name
     */
    protected string _singularName(string aName) {
        return Inflector::variable(Inflector::singularize($name));
    }

    /**
     * Creates the plural variable name for views
     *
     * @param string aName Name to use
     * @return string Plural name for views
     */
    protected string _variableName(string aName) {
        return Inflector::variable($name);
    }

    /**
     * Creates the singular human name used in views
     *
     * @param string aName Controller name
     * @return string Singular human name
     */
    protected string _singularHumanName(string aName) {
        return Inflector::humanize(Inflector::underscore(Inflector::singularize($name)));
    }

    /**
     * Creates a camelized version of $name
     *
     * @param string aName name
     * @return string Camelized name
     */
    protected string _camelize(string aName) {
        return Inflector::camelize($name);
    }

    /**
     * Creates the plural human name used in views
     *
     * @param string aName Controller name
     * @return string Plural human name
     */
    protected string _pluralHumanName(string aName) {
        return Inflector::humanize(Inflector::underscore($name));
    }

    /**
     * Find the correct path for a plugin. Scans $pluginPaths for the plugin you want.
     *
     * @param string $pluginName Name of the plugin you want ie. DebugKit
     * @return string path path to the correct plugin.
     */
    protected string _pluginPath(string $pluginName) {
        if (Plugin::isLoaded($pluginName)) {
            return Plugin::path($pluginName);
        }

        return current(App::path("plugins")) . $pluginName . DIRECTORY_SEPARATOR;
    }

    /**
     * Return plugin"s namespace
     *
     * @param string $pluginName Plugin name
     * @return string Plugin"s namespace
     */
    protected string _pluginNamespace(string $pluginName) {
        return str_replace("/", "\\", $pluginName);
    }
}
