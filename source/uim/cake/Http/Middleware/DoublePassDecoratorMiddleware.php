


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Http\Middleware;

import uim.cake.Http\Response;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;
use Psr\Http\Server\IMiddleware;
use Psr\Http\Server\RequestHandlerInterface;

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
 *   Use a `Closure` or a class which : `Psr\Http\Server\IMiddleware` instead.
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
    public this(callable $callable)
    {
        deprecationWarning(
            ""Double pass" middleware are deprecated. Use a `Closure` with the signature of"
            . " `($request, $handler)` or a class which : `Psr\Http\Server\IMiddleware` instead.",
            0
        );
        this.callable = $callable;
    }

    /**
     * Run the internal double pass callable to process an incoming server request.
     *
     * @param \Psr\Http\Message\IServerRequest $request Request instance.
     * @param \Psr\Http\Server\RequestHandlerInterface $handler Request handler instance.
     * @return \Psr\Http\Message\IResponse
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
