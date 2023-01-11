


 *


 * @since         3.3.0
  */module uim.cake.Http;

use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;
use Psr\Http\servers.RequestHandlerInterface;

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
     * @var \Psr\Http\servers.RequestHandlerInterface|null
     */
    protected $fallbackHandler;

    /**
     * @param uim.cake.http.MiddlewareQueue $queue The middleware queue
     * @param \Psr\Http\messages.IServerRequest $request The Server Request
     * @param \Psr\Http\servers.RequestHandlerInterface|null $fallbackHandler Fallback request handler.
     * @return \Psr\Http\messages.IResponse A response object
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
     * @param \Psr\Http\messages.IServerRequest $request The server request
     * @return \Psr\Http\messages.IResponse An updated response
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
                ~ "and no fallback request handler was set for Runner",
            "status": 500,
        ]);
    }
}
