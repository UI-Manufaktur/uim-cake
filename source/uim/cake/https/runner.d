module uim.cake.https;

@safe:
import uim.cake

/**
 * Executes the middleware queue and provides the `next` callable
 * that allows the queue to be iterated.
 */
class Runner : IRequestHandler
{
    /**
     * The middleware queue being run.
     *
     * @var uim.cake.Http\MiddlewareQueue
     */
    protected queue;

    /**
     * Fallback handler to use if middleware queue does not generate response.
     *
     * @var \Psr\Http\Server\IRequestHandler|null
     */
    protected fallbackHandler;

    /**
     * @param uim.cake.Http\MiddlewareQueue $queue The middleware queue
     * @param \Psr\Http\Message\IServerRequest myRequest The Server Request
     * @param \Psr\Http\Server\IRequestHandler|null $fallbackHandler Fallback request handler.
     * @return \Psr\Http\Message\IResponse A response object
     */
    function run(
        MiddlewareQueue $queue,
        IServerRequest myRequest,
        ?IRequestHandler $fallbackHandler = null
    ): IResponse {
        this.queue = $queue;
        this.queue.rewind();
        this.fallbackHandler = $fallbackHandler;

        return this.handle(myRequest);
    }

    /**
     * Handle incoming server request and return a response.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The server request
     * @return \Psr\Http\Message\IResponse An updated response
     */
    function handle(IServerRequest myRequest): IResponse
    {
        if (this.queue.valid()) {
            $middleware = this.queue.current();
            this.queue.next();

            return $middleware.process(myRequest, this);
        }

        if (this.fallbackHandler) {
            return this.fallbackHandler.handle(myRequest);
        }

        $response = new Response([
            "body":"Middleware queue was exhausted without returning a response "
                . "and no fallback request handler was set for Runner",
            "status":500,
        ]);

        return $response;
    }
}
