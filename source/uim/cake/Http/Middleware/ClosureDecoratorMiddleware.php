


 *



 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.http.Middleware;

use Closure;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;
use Psr\Http\Server\IMiddleware;
use Psr\Http\Server\RequestHandlerInterface;

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
    public this(Closure $callable) {
        this.callable = $callable;
    }

    /**
     * Run the callable to process an incoming server request.
     *
     * @param \Psr\Http\Message\IServerRequest $request Request instance.
     * @param \Psr\Http\Server\RequestHandlerInterface $handler Request handler instance.
     * @return \Psr\Http\Message\IResponse
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
