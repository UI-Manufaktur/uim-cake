module uim.cake.core;

import uim.caketps\MiddlewareQueue;
use Psr\Http\Server\IRequestHandler;

/**
 * An interface defining the methods that the
 * http server depend on.
 */
interface IHttpApplication : IRequestHandler
{
    /**
     * Load all the application configuration and bootstrap logic.
     *
     * Override this method to add additional bootstrap logic for your application.
     *
     */
    void bootstrap();

    /**
     * Define the HTTP middleware layers for an application.
     *
     * @param \Cake\Http\MiddlewareQueue $middlewareQueue The middleware queue to set in your App Class
     * @return \Cake\Http\MiddlewareQueue
     */
    function middleware(MiddlewareQueue $middlewareQueue): MiddlewareQueue;
}
