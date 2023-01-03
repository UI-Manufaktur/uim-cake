


 *


 * @since         4.1.0
  */

import uim.cake.routings.Router;

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
    function urlArray(string $path, array $params = []): array
    {
        $url = Router::parseRoutePath($path);
        $url += [
            "plugin": false,
            "prefix": false,
        ];

        return $url + $params;
    }
}