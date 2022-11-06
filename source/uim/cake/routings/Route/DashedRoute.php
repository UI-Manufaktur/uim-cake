module uim.cakeutings\Route;

import uim.cakeilities.Inflector;

/**
 * This route class will transparently inflect the controller, action and plugin
 * routing parameters, so that requesting `/my-plugin/my-controller/my-action`
 * is parsed as `['plugin' => 'MyPlugin', 'controller' => 'MyController', 'action' => 'myAction']`
 */
class DashedRoute : Route
{
    /**
     * Flag for tracking whether the defaults have been inflected.
     *
     * Default values need to be inflected so that they match the inflections that
     * match() will create.
     *
     * @var bool
     */
    protected $_inflectedDefaults = false;

    /**
     * Camelizes the previously dashed plugin route taking into account plugin vendors
     *
     * @param string myPlugin Plugin name
     * @return string
     */
    protected auto _camelizePlugin(string myPlugin): string
    {
        myPlugin = str_replace('-', '_', myPlugin);
        if (strpos(myPlugin, '/') === false) {
            return Inflector::camelize(myPlugin);
        }
        [$vendor, myPlugin] = explode('/', myPlugin, 2);

        return Inflector::camelize($vendor) . '/' . Inflector::camelize(myPlugin);
    }

    /**
     * Parses a string URL into an array. If it matches, it will convert the
     * controller and plugin keys to their CamelCased form and action key to
     * camelBacked form.
     *
     * @param string myUrl The URL to parse
     * @param string $method The HTTP method.
     * @return array|null An array of request parameters, or null on failure.
     */
    function parse(string myUrl, string $method = ''): ?array
    {
        myParams = super.parse(myUrl, $method);
        if (!myParams) {
            return null;
        }
        if (!empty(myParams['controller'])) {
            myParams['controller'] = Inflector::camelize(myParams['controller'], '-');
        }
        if (!empty(myParams['plugin'])) {
            myParams['plugin'] = this._camelizePlugin(myParams['plugin']);
        }
        if (!empty(myParams['action'])) {
            myParams['action'] = Inflector::variable(str_replace(
                '-',
                '_',
                myParams['action']
            ));
        }

        return myParams;
    }

    /**
     * Dasherizes the controller, action and plugin params before passing them on
     * to the parent class.
     *
     * @param array myUrl Array of parameters to convert to a string.
     * @param array $context An array of the current request context.
     *   Contains information such as the current host, scheme, port, and base
     *   directory.
     * @return string|null Either a string URL or null.
     */
    function match(array myUrl, array $context = []): Nullable!string
    {
        myUrl = this._dasherize(myUrl);
        if (!this._inflectedDefaults) {
            this._inflectedDefaults = true;
            this.defaults = this._dasherize(this.defaults);
        }

        return super.match(myUrl, $context);
    }

    /**
     * Helper method for dasherizing keys in a URL array.
     *
     * @param array myUrl An array of URL keys.
     * @return array
     */
    protected auto _dasherize(array myUrl): array
    {
        foreach (['controller', 'plugin', 'action'] as $element) {
            if (!empty(myUrl[$element])) {
                myUrl[$element] = Inflector::dasherize(myUrl[$element]);
            }
        }

        return myUrl;
    }
}
