

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */

import uim.cake.Routing\Router;

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
