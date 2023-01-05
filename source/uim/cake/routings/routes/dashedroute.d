module uim.cake.routings.Route;

import uim.cake.utilities.Inflector;

/**
 * This route class will transparently inflect the controller, action and plugin
 * routing parameters, so that requesting `/my-plugin/my-controller/my-action`
 * is parsed as `["plugin": "MyPlugin", "controller": "MyController", "action": "myAction"]`
 */
class DashedRoute : Route
{
    /**
     * Flag for tracking whether the defaults have been inflected.
     *
     * Default values need to be inflected so that they match the inflections that
     * match() will create.
     */
    protected bool $_inflectedDefaults = false;

    /**
     * Camelizes the previously dashed plugin route taking into account plugin vendors
     *
     * @param string $plugin Plugin name
     */
    protected string _camelizePlugin(string $plugin) {
        $plugin = str_replace("-", "_", $plugin);
        if (strpos($plugin, "/") == false) {
            return Inflector::camelize($plugin);
        }
        [$vendor, $plugin] = explode("/", $plugin, 2);

        return Inflector::camelize($vendor) ~ "/" ~ Inflector::camelize($plugin);
    }

    /**
     * Parses a string URL into an array. If it matches, it will convert the
     * controller and plugin keys to their CamelCased form and action key to
     * camelBacked form.
     *
     * @param string $url The URL to parse
     * @param string $method The HTTP method.
     * @return array|null An array of request parameters, or null on failure.
     */
    function parse(string $url, string $method = ""): ?array
    {
        $params = super.parse($url, $method);
        if (!$params) {
            return null;
        }
        if (!empty($params["controller"])) {
            $params["controller"] = Inflector::camelize($params["controller"], "-");
        }
        if (!empty($params["plugin"])) {
            $params["plugin"] = _camelizePlugin($params["plugin"]);
        }
        if (!empty($params["action"])) {
            $params["action"] = Inflector::variable(str_replace(
                "-",
                "_",
                $params["action"]
            ));
        }

        return $params;
    }

    /**
     * Dasherizes the controller, action and plugin params before passing them on
     * to the parent class.
     *
     * @param array $url Array of parameters to convert to a string.
     * @param array $context An array of the current request context.
     *   Contains information such as the current host, scheme, port, and base
     *   directory.
     * @return string|null Either a string URL or null.
     */
    function match(array $url, array $context = []): ?string
    {
        $url = _dasherize($url);
        if (!_inflectedDefaults) {
            _inflectedDefaults = true;
            this.defaults = _dasherize(this.defaults);
        }

        return super.match($url, $context);
    }

    /**
     * Helper method for dasherizing keys in a URL array.
     *
     * @param array $url An array of URL keys.
     */
    protected array _dasherize(array $url) {
        foreach (["controller", "plugin", "action"] as $element) {
            if (!empty($url[$element])) {
                $url[$element] = Inflector::dasherize($url[$element]);
            }
        }

        return $url;
    }
}
