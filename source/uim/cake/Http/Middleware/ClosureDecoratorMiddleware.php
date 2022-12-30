module uim.cake.http.Middleware;

use Closure;
use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;
use Psr\Http\servers.IMiddleware;
use Psr\Http\servers.RequestHandlerInterface;

/**
 * Decorate closures as PSR-15 middleware.
 *
 * Decorates closures with the following signature:
 *
 * ```
 * function (
 *     IServerRequest $request,
 *     RequestHandlerInterface $handler
 * ): IResponse
 * ```
 *
 * such that it will operate as PSR-15 middleware.
 */
class ClosureDecoratorMiddleware : IMiddleware
{
    /**
     * A Closure.
     *
     * @var \Closure
     */
    protected $callable;

    /**
     * Constructor
     *
     * @param \Closure $callable A closure.
     */
    this(Closure $callable) {
        this.callable = $callable;
    }

    /**
     * Run the callable to process an incoming server request.
     *
     * @param \Psr\Http\messages.IServerRequest $request Request instance.
     * @param \Psr\Http\servers.RequestHandlerInterface $handler Request handler instance.
     * @return \Psr\Http\messages.IResponse
     */
    function process(IServerRequest $request, RequestHandlerInterface $handler): IResponse
    {
        return (this.callable)(
            $request,
            $handler
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
