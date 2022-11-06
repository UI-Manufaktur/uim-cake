module uim.cakeutings;

/**
 * Interface for applications that use routing.
 */
interface RoutingApplicationInterface
{
    /**
     * Define the routes for an application.
     *
     * Use the provided RouteBuilder to define an application's routing.
     *
     * @param \Cake\Routing\RouteBuilder $routes A route builder to add routes into.
     * @return void
     */
    function routes(RouteBuilder $routes): void;
}
