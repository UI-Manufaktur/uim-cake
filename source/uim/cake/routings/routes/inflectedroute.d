module uim.cake.routings.Route;

import uim.cake.utilities.Inflector;

/**
 * This route class will transparently inflect the controller and plugin routing
 * parameters, so that requesting `/my_controller` is parsed as `["controller": "MyController"]`
 */
class InflectedRoute : Route
{
    /**
     * Flag for tracking whether the defaults have been inflected.
     *
     * Default values need to be inflected so that they match the inflections that match()
     * will create.
     */
    protected bool _inflectedDefaults = false;

    /**
     * Parses a string URL into an array. If it matches, it will convert the prefix, controller and
     * plugin keys to their camelized form.
     *
     * @param string $url The URL to parse
     * @param string $method The HTTP method being matched.
     * @return array|null An array of request parameters, or null on failure.
     */
    function parse(string $url, string $method = ""): ?array
    {
        $params = super.parse($url, $method);
        if (!$params) {
            return null;
        }
        if (!empty($params["controller"])) {
            $params["controller"] = Inflector::camelize($params["controller"]);
        }
        if (!empty($params["plugin"])) {
            if (strpos($params["plugin"], "/") == false) {
                $params["plugin"] = Inflector::camelize($params["plugin"]);
            } else {
                [$vendor, $plugin] = explode("/", $params["plugin"], 2);
                $params["plugin"] = Inflector::camelize($vendor) ~ "/" ~ Inflector::camelize($plugin);
            }
        }

        return $params;
    }

    /**
     * Underscores the prefix, controller and plugin params before passing them on to the
     * parent class
     *
     * @param array $url Array of parameters to convert to a string.
     * @param array $context An array of the current request context.
     *   Contains information such as the current host, scheme, port, and base
     *   directory.
     * @return string|null Either a string URL for the parameters if they match or null.
     */
    Nullable!string match(array $url, array $context = null) {
        $url = _underscore($url);
        if (!_inflectedDefaults) {
            _inflectedDefaults = true;
            this.defaults = _underscore(this.defaults);
        }

        return super.match($url, $context);
    }

    /**
     * Helper method for underscoring keys in a URL array.
     *
     * @param array $url An array of URL keys.
     */
    protected array _underscore(array $url) {
        if (!empty($url["controller"])) {
            $url["controller"] = Inflector::underscore($url["controller"]);
        }
        if (!empty($url["plugin"])) {
            $url["plugin"] = Inflector::underscore($url["plugin"]);
        }

        return $url;
    }
}
