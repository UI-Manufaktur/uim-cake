


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Routing;

/**
 * Interface for applications that use routing.
 */
interface IRoutingApplication
{
    /**
     * Define the routes for an application.
     *
     * Use the provided RouteBuilder to define an application"s routing.
     *
     * @param \Cake\Routing\RouteBuilder $routes A route builder to add routes into.
     * @return void
     */
    function routes(RouteBuilder $routes): void;
}
