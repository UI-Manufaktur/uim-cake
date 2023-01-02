module uim.cake.core;

import uim.cake.http.MiddlewareQueue;
use Psr\Http\servers.RequestHandlerInterface;

/**
 * An interface defining the methods that the
 * http server depend on.
 */
interface IHttpApplication : RequestHandlerInterface
{
    /**
     * Load all the application configuration and bootstrap logic.
     *
     * Override this method to add additional bootstrap logic for your application.
     */
    void bootstrap(): void;

    /**
     * Define the HTTP middleware layers for an application.
     *
     * @param uim.cake.http.MiddlewareQueue $middlewareQueue The middleware queue to set in your App Class
     * @return uim.cake.http.MiddlewareQueue
     */
    function middleware(MiddlewareQueue $middlewareQueue): MiddlewareQueue;
}
