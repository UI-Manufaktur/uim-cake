module uim.cake.https;

import uim.cake.core.IHttpApplication;
use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;

/**
 * Base class for standalone HTTP applications
 *
 * Provides a base class to inherit from for applications using
 * only the http package. This class defines a fallback handler
 * that renders a simple 404 response.
 *
 * You can overload the `handle` method to provide your own logic
 * to run when no middleware generates a response.
 */
abstract class MiddlewareApplication : IHttpApplication
{

    abstract void bootstrap();


    abstract MiddlewareQueue middleware(MiddlewareQueue $middlewareQueue);

    /**
     * Generate a 404 response as no middleware handled the request.
     *
     * @param \Psr\Http\messages.IServerRequest myRequest The request
     * @return \Psr\Http\messages.IResponse
     */
    IResponse handle(
        IServerRequest myRequest
    ):  {
        return new Response(["body":"Not found", "status":404]);
    }
}
