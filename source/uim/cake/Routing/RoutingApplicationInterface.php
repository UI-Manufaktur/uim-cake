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
     * @param uim.cake.routings.RouteBuilder $routes A route builder to add routes into.
     */
    void routes(RouteBuilder $routes): void;
}
