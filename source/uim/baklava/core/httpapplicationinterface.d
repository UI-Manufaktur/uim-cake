module uim.baklava.core;

import uim.baklava.https\MiddlewareQueue;
use Psr\Http\Server\RequestHandlerInterface;

/**
 * An interface defining the methods that the
 * http server depend on.
 */
interface HttpApplicationInterface : RequestHandlerInterface
{
    /**
     * Load all the application configuration and bootstrap logic.
     *
     * Override this method to add additional bootstrap logic for your application.
     *
     * @return void
     */
    function bootstrap(): void;

    /**
     * Define the HTTP middleware layers for an application.
     *
     * @param \Cake\Http\MiddlewareQueue $middlewareQueue The middleware queue to set in your App Class
     * @return \Cake\Http\MiddlewareQueue
     */
    function middleware(MiddlewareQueue $middlewareQueue): MiddlewareQueue;
}
