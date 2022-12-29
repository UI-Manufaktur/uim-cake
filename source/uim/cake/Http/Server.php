


 *


 * @since         3.3.0
  */
module uim.cake.Http;

import uim.cake.core.IHttpApplication;
import uim.cake.core.IPluginApplication;
import uim.cake.events.EventDispatcherInterface;
import uim.cake.events.EventDispatcherTrait;
import uim.cake.events.EventManager;
import uim.cake.events.IEventManager;
use InvalidArgumentException;
use Laminas\HttpHandlerRunner\Emitter\EmitterInterface;
use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;

/**
 * Runs an application invoking all the PSR7 middleware and the registered application.
 */
class Server : EventDispatcherInterface
{
    use EventDispatcherTrait;

    /**
     * @var uim.cake.Core\IHttpApplication
     */
    protected $app;

    /**
     * @var uim.cake.http.Runner
     */
    protected $runner;

    /**
     * Constructor
     *
     * @param uim.cake.Core\IHttpApplication $app The application to use.
     * @param uim.cake.http.Runner|null $runner Application runner.
     */
    this(IHttpApplication $app, ?Runner $runner = null) {
        this.app = $app;
        this.runner = $runner ?? new Runner();
    }

    /**
     * Run the request/response through the Application and its middleware.
     *
     * This will invoke the following methods:
     *
     * - App.bootstrap() - Perform any bootstrapping logic for your application here.
     * - App.middleware() - Attach any application middleware here.
     * - Trigger the "Server.buildMiddleware" event. You can use this to modify the
     *   from event listeners.
     * - Run the middleware queue including the application.
     *
     * @param \Psr\Http\messages.IServerRequest|null $request The request to use or null.
     * @param uim.cake.http.MiddlewareQueue|null $middlewareQueue MiddlewareQueue or null.
     * @return \Psr\Http\messages.IResponse
     * @throws \RuntimeException When the application does not make a response.
     */
    function run(
        ?IServerRequest $request = null,
        ?MiddlewareQueue $middlewareQueue = null
    ): IResponse {
        this.bootstrap();

        $request = $request ?: ServerRequestFactory::fromGlobals();

        $middleware = this.app.middleware($middlewareQueue ?? new MiddlewareQueue());
        if (this.app instanceof IPluginApplication) {
            $middleware = this.app.pluginMiddleware($middleware);
        }

        this.dispatchEvent("Server.buildMiddleware", ["middleware": $middleware]);

        $response = this.runner.run($middleware, $request, this.app);

        if ($request instanceof ServerRequest) {
            $request.getSession().close();
        }

        return $response;
    }

    /**
     * Application bootstrap wrapper.
     *
     * Calls the application"s `bootstrap()` hook. After the application the
     * plugins are bootstrapped.
     *
     * @return void
     */
    protected function bootstrap(): void
    {
        this.app.bootstrap();
        if (this.app instanceof IPluginApplication) {
            this.app.pluginBootstrap();
        }
    }

    /**
     * Emit the response using the PHP SAPI.
     *
     * @param \Psr\Http\messages.IResponse $response The response to emit
     * @param \Laminas\HttpHandlerRunner\Emitter\EmitterInterface|null $emitter The emitter to use.
     *   When null, a SAPI Stream Emitter will be used.
     * @return void
     */
    void emit(IResponse $response, ?EmitterInterface $emitter = null): void
    {
        if (!$emitter) {
            $emitter = new ResponseEmitter();
        }
        $emitter.emit($response);
    }

    /**
     * Get the current application.
     *
     * @return uim.cake.Core\IHttpApplication The application that will be run.
     */
    function getApp(): IHttpApplication
    {
        return this.app;
    }

    /**
     * Get the application"s event manager or the global one.
     *
     * @return uim.cake.events.IEventManager
     */
    function getEventManager(): IEventManager
    {
        if (this.app instanceof EventDispatcherInterface) {
            return this.app.getEventManager();
        }

        return EventManager::instance();
    }

    /**
     * Set the application"s event manager.
     *
     * If the application does not support events, an exception will be raised.
     *
     * @param uim.cake.events.IEventManager $eventManager The event manager to set.
     * @return this
     * @throws \InvalidArgumentException
     */
    function setEventManager(IEventManager $eventManager) {
        if (this.app instanceof EventDispatcherInterface) {
            this.app.setEventManager($eventManager);

            return this;
        }

        throw new InvalidArgumentException("Cannot set the event manager, the application does not support events.");
    }
}
