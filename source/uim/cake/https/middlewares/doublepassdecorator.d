module uim.cake.https\Middleware;

@safe:
import uim.cake;

use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;
use Psr\Http\servers.IMiddleware;
use Psr\Http\servers.RequestHandlerInterface;

/**
 * Decorate double-pass middleware as PSR-15 middleware.
 *
 * The callable can be a closure with the following signature:
 *
 * ```
 * function (
 *     IServerRequest $request,
 *     IResponse $response,
 *     callable $next
 * ): IResponse
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
    protected $callable;

    /**
     * Constructor
     *
     * @param callable $callable A closure.
     */
    this(callable $callable) {
        deprecationWarning(
            ""Double pass" middleware are deprecated. Use a `Closure` with the signature of"
            ~ " `($request, $handler)` or a class which : `Psr\Http\servers.IMiddleware` instead.",
            0
        );
        this.callable = $callable;
    }

    /**
     * Run the internal double pass callable to process an incoming server request.
     *
     * @param \Psr\Http\messages.IServerRequest $request Request instance.
     * @param \Psr\Http\servers.RequestHandlerInterface $handler Request handler instance.
     * @return \Psr\Http\messages.IResponse
     */
    function process(IServerRequest $request, RequestHandlerInterface $handler): IResponse
    {
        return (this.callable)(
            $request,
            new Response(),
            function ($request, $res) use ($handler) {
                return $handler.handle($request);
            }
        );
    }

    /**
     * @internal
     * @return callable
     */
    function getCallable(): callable
    {
        return this.callable;
    }
}
