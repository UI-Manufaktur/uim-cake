

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         1.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.Routing\Route;

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
     * @param string myUrl The URL to parse
     * @param string $method The HTTP method
     * @return array|null An array of request parameters, or null on failure.
     */
    function parse(string myUrl, string $method = ''): ?array
    {
        myParams = super.parse(myUrl, $method);
        if (!myParams) {
            return null;
        }
        myParams['controller'] = myParams['plugin'];

        return myParams;
    }

    /**
     * Reverses route plugin shortcut URLs. If the plugin and controller
     * are not the same the match is an auto fail.
     *
     * @param array myUrl Array of parameters to convert to a string.
     * @param array $context An array of the current request context.
     *   Contains information such as the current host, scheme, port, and base
     *   directory.
     * @return string|null Either a string URL for the parameters if they match or null.
     */
    function match(array myUrl, array $context = []): ?string
    {
        if (isset(myUrl['controller'], myUrl['plugin']) && myUrl['plugin'] !== myUrl['controller']) {
            return null;
        }
        this.defaults['controller'] = myUrl['controller'];
        myResult = super.match(myUrl, $context);
        unset(this.defaults['controller']);

        return myResult;
    }
}
