module uim.cake.https\Middleware;

@safe:
import uim.cake

/**
 * Decorate closures as PSR-15 middleware.
 *
 * Decorates closures with the following signature:
 *
 * ```
 * function (
 *     IServerRequest myRequest,
 *     IRequestHandler $handler
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
     * @param \Psr\Http\Message\IServerRequest myRequest Request instance.
     * @param \Psr\Http\Server\IRequestHandler $handler Request handler instance.
     * @return \Psr\Http\Message\IResponse
     */
    function process(IServerRequest myRequest, IRequestHandler $handler): IResponse
    {
        return (this.callable)(
            myRequest,
            $handler
        );
    }

    /**
     * @internal
     * @return callable
     */
    auto getCallable(): callable
    {
        return this.callable;
    }
}
