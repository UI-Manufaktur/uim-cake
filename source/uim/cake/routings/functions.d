module uim.cake.routings.functions;

@safe:
import uim.cake;

if (!function_exists("urlArray")) {
    /**
     * Returns an array URL from a route path string.
     *
     * @param string $path Route path.
     * @param array $params An array specifying any additional parameters.
     *   Can be also any special parameters supported by `Router::url()`.
     * @return array URL
     * @see uim.cake.routings.Router::pathUrl()
     */
    array urlArray(string $path, array $params = []) {
        $url = Router::parseRoutePath($path);
        $url += [
            "plugin": false,
            "prefix": false,
        ];

        return $url + $params;
    }
}
