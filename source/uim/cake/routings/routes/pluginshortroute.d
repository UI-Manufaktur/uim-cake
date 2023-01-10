


 *


 * @since         1.3.0
  */module uim.cake.routings.Route;

/**
 * Plugin short route, that copies the plugin param to the controller parameters
 * It is used for supporting /{plugin} routes.
 */
class PluginShortRoute : InflectedRoute
{
    /**
     * Parses a string URL into an array. If a plugin key is found, it will be copied to the
     * controller parameter.
     *
     * @param string $url The URL to parse
     * @param string $method The HTTP method
     * @return array|null An array of request parameters, or null on failure.
     */
    function parse(string $url, string $method = ""): ?array
    {
        $params = super.parse($url, $method);
        if (!$params) {
            return null;
        }
        $params["controller"] = $params["plugin"];

        return $params;
    }

    /**
     * Reverses route plugin shortcut URLs. If the plugin and controller
     * are not the same the match is an auto fail.
     *
     * @param array $url Array of parameters to convert to a string.
     * @param array $context An array of the current request context.
     *   Contains information such as the current host, scheme, port, and base
     *   directory.
     * @return string|null Either a string URL for the parameters if they match or null.
     */
    Nullable!string match(array $url, array $context = null) {
        if (isset($url["controller"], $url["plugin"]) && $url["plugin"] != $url["controller"]) {
            return null;
        }
        this.defaults["controller"] = $url["controller"];
        $result = super.match($url, $context);
        unset(this.defaults["controller"]);

        return $result;
    }
}
