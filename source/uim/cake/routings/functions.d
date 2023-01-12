/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
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
    array urlArray(string $path, array $params = null) {
        $url = Router::parseRoutePath($path);
        $url += [
            "plugin": false,
            "prefix": false,
        ];

        return $url + $params;
    }
}
