/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.https;

import uim.cake.core.IHttpApplication;
import uim.cake.core.IPluginApplication;
import uim.cake.events\IEventDispatcher;
import uim.cake.events\EventDispatcherTrait;
import uim.cake.events\EventManager;
import uim.cake.events\IEventManager;
use InvalidArgumentException;
use Laminas\HttpHandlerRunner\Emitter\EmitterInterface;
use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;

/**
 * Runs an application invoking all the PSR7 middleware and the registered application.
 */
class Server : IEventDispatcher
{
    use EventDispatcherTrait;

    /**
     * @var uim.cake.Core\IHttpApplication
     */
    protected app;

    /**
     * @var uim.cake.http.Runner
     */
    protected runner;

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
     * @param \Psr\Http\messages.IServerRequest|null myRequest The request to use or null.
     * @param uim.cake.http.MiddlewareQueue|null $middlewareQueue MiddlewareQueue or null.
     * @return \Psr\Http\messages.IResponse
     * @throws \RuntimeException When the application does not make a response.
     */
    function run(
        ?IServerRequest myRequest = null,
        ?MiddlewareQueue $middlewareQueue = null
    ): IResponse {
        this.bootstrap();

        myRequest = myRequest ?: ServerRequestFactory::fromGlobals();

        $middleware = this.app.middleware($middlewareQueue ?? new MiddlewareQueue());
        if (this.app instanceof IPluginApplication) {
            $middleware = this.app.pluginMiddleware($middleware);
        }

        this.dispatchEvent("Server.buildMiddleware", ["middleware":$middleware]);

        $response = this.runner.run($middleware, myRequest, this.app);

        if (myRequest instanceof ServerRequest) {
            myRequest.getSession().close();
        }

        return $response;
    }

    /**
     * Application bootstrap wrapper.
     *
     * Calls the application"s `bootstrap()` hook. After the application the
     * plugins are bootstrapped.
     *
     */
    protected void bootstrap() {
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
     */
    void emit(IResponse $response, ?EmitterInterface $emitter = null) {
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
    auto getApp(): IHttpApplication
    {
        return this.app;
    }

    /**
     * Get the application"s event manager or the global one.
     *
     * @return uim.cake.events.IEventManager
     */
    auto getEventManager(): IEventManager
    {
        if (this.app instanceof IEventDispatcher) {
            return this.app.getEventManager();
        }

        return EventManager::instance();
    }

    /**
     * Set the application"s event manager.
     *
     * If the application does not support events, an exception will be raised.
     *
     * @param uim.cake.events.IEventManager myEventManager The event manager to set.
     * @return this
     * @throws \InvalidArgumentException
     */
    auto setEventManager(IEventManager myEventManager) {
        if (this.app instanceof IEventDispatcher) {
            this.app.setEventManager(myEventManager);

            return this;
        }

        throw new InvalidArgumentException("Cannot set the event manager, the application does not support events.");
    }
}
