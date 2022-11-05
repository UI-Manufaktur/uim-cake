

import uim.baklava.routings\Router;

if (!function_exists('urlArray')) {
    /**
     * Returns an array URL from a route path string.
     *
     * @param string myPath Route path.
     * @param array myParams An array specifying any additional parameters.
     *   Can be also any special parameters supported by `Router::url()`.
     * @return array URL
     * @see \Cake\Routing\Router::pathUrl()
     */
    function urlArray(string myPath, array myParams = []): array
    {
        myUrl = Router::parseRoutePath(myPath);
        myUrl += [
            'plugin' => false,
            'prefix' => false,
        ];

        return myUrl + myParams;
    }
}
