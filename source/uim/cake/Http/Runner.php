


 *


 * @since         3.3.0
  */
module uim.cake.Http;

use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;
use Psr\Http\Server\RequestHandlerInterface;

/**
 * Executes the middleware queue and provides the `next` callable
 * that allows the queue to be iterated.
 */
class Runner : RequestHandlerInterface
{
    /**
     * The middleware queue being run.
     *
     * @var uim.cake.http.MiddlewareQueue
     */
    protected $queue;

    /**
     * Fallback handler to use if middleware queue does not generate response.
     *
     * @var \Psr\Http\Server\RequestHandlerInterface|null
     */
    protected $fallbackHandler;

    /**
     * @param uim.cake.http.MiddlewareQueue $queue The middleware queue
     * @param \Psr\Http\Message\IServerRequest $request The Server Request
     * @param \Psr\Http\Server\RequestHandlerInterface|null $fallbackHandler Fallback request handler.
     * @return \Psr\Http\Message\IResponse A response object
     */
    function run(
        MiddlewareQueue $queue,
        IServerRequest $request,
        ?RequestHandlerInterface $fallbackHandler = null
    ): IResponse {
        this.queue = $queue;
        this.queue.rewind();
        this.fallbackHandler = $fallbackHandler;

        return this.handle($request);
    }

    /**
     * Handle incoming server request and return a response.
     *
     * @param \Psr\Http\Message\IServerRequest $request The server request
     * @return \Psr\Http\Message\IResponse An updated response
     */
    function handle(IServerRequest $request): IResponse
    {
        if (this.queue.valid()) {
            $middleware = this.queue.current();
            this.queue.next();

            return $middleware.process($request, this);
        }

        if (this.fallbackHandler) {
            return this.fallbackHandler.handle($request);
        }

        return new Response([
            "body": "Middleware queue was exhausted without returning a response "
                . "and no fallback request handler was set for Runner",
            "status": 500,
        ]);
    }
}
