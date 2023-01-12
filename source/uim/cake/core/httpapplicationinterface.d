/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.core;

@safe:
import uim.cake;

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
    void bootstrap();

    /**
     * Define the HTTP middleware layers for an application.
     *
     * @param uim.cake.http.MiddlewareQueue $middlewareQueue The middleware queue to set in your App Class
     * @return uim.cake.http.MiddlewareQueue
     */
    function middleware(MiddlewareQueue $middlewareQueue): MiddlewareQueue;
}
