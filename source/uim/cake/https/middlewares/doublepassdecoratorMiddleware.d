module uim.cake.https\Middleware;

@safe:
import uim.cake;

/**
 * Decorate double-pass middleware as PSR-15 middleware.
 *
 * The callable can be a closure with the following signature:
 *
 * ```
 * function (
 *     IServerRequest myRequest,
 *     IResponse $response,
 *     callable $next
 * )IResponse
 * ```
 *
 * or a class with `__invoke()` method with same signature as above.
 *
 * Neither the arguments nor the return value need be typehinted.
 *
 * @deprecated 4.3.0 "Double pass" middleware are deprecated.
 *   Use a `Closure` or a class which : `Psr\Http\servers.IMiddleware` instead.
 */
class DoublePassDecoratorMiddleware : IMiddleware
{
    /**
     * A closure or invokable object.
     *
     * @var callable
     */
    protected callable;

    /**
     * Constructor
     *
     * @param callable $callable A closure.
     */
    this(callable $callable) {
        deprecationWarning(
            ""Double pass" middleware are deprecated. Use a `Closure` with the signature of"
            . " `(myRequest, $handler)` or a class which : `Psr\Http\servers.IMiddleware` instead.",
            0
        );
        this.callable = $callable;
    }

    /**
     * Run the internal double pass callable to process an incoming server request.
     *
     * @param \Psr\Http\messages.IServerRequest myRequest Request instance.
     * @param \Psr\Http\servers.IRequestHandler $handler Request handler instance.
     * @return \Psr\Http\messages.IResponse
     */
    IResponse process(IServerRequest myRequest, IRequestHandler $handler) {
        return (this.callable)(
            myRequest,
            new Response(),
            function (myRequest, $res) use ($handler) {
                return $handler.handle(myRequest);
            }
        );
    }

    /**
     * @internal
     * @return callable
     */
    callable getCallable() {
        return this.callable;
    }
}
