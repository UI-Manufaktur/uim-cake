module uim.cake.Routing\Route;

import uim.cake.Utility\Inflector;

/**
 * This route class will transparently inflect the controller and plugin routing
 * parameters, so that requesting `/my_controller` is parsed as `['controller' => 'MyController']`
 */
class InflectedRoute : Route
{
    /**
     * Flag for tracking whether the defaults have been inflected.
     *
     * Default values need to be inflected so that they match the inflections that match()
     * will create.
     *
     * @var bool
     */
    protected $_inflectedDefaults = false;

    /**
     * Parses a string URL into an array. If it matches, it will convert the prefix, controller and
     * plugin keys to their camelized form.
     *
     * @param string myUrl The URL to parse
     * @param string $method The HTTP method being matched.
     * @return array|null An array of request parameters, or null on failure.
     */
    function parse(string myUrl, string $method = ''): ?array
    {
        myParams = super.parse(myUrl, $method);
        if (!myParams) {
            return null;
        }
        if (!empty(myParams['controller'])) {
            myParams['controller'] = Inflector::camelize(myParams['controller']);
        }
        if (!empty(myParams['plugin'])) {
            if (strpos(myParams['plugin'], '/') === false) {
                myParams['plugin'] = Inflector::camelize(myParams['plugin']);
            } else {
                [$vendor, myPlugin] = explode('/', myParams['plugin'], 2);
                myParams['plugin'] = Inflector::camelize($vendor) . '/' . Inflector::camelize(myPlugin);
            }
        }

        return myParams;
    }

    /**
     * Underscores the prefix, controller and plugin params before passing them on to the
     * parent class
     *
     * @param array myUrl Array of parameters to convert to a string.
     * @param array $context An array of the current request context.
     *   Contains information such as the current host, scheme, port, and base
     *   directory.
     * @return string|null Either a string URL for the parameters if they match or null.
     */
    function match(array myUrl, array $context = []): ?string
    {
        myUrl = this._underscore(myUrl);
        if (!this._inflectedDefaults) {
            this._inflectedDefaults = true;
            this.defaults = this._underscore(this.defaults);
        }

        return super.match(myUrl, $context);
    }

    /**
     * Helper method for underscoring keys in a URL array.
     *
     * @param array myUrl An array of URL keys.
     * @return array
     */
    protected auto _underscore(array myUrl): array
    {
        if (!empty(myUrl['controller'])) {
            myUrl['controller'] = Inflector::underscore(myUrl['controller']);
        }
        if (!empty(myUrl['plugin'])) {
            myUrl['plugin'] = Inflector::underscore(myUrl['plugin']);
        }

        return myUrl;
    }
}
