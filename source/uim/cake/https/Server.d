

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.https;

import uim.cake.core.HttpApplicationInterface;
import uim.cake.core.PluginApplicationInterface;
import uim.cake.events\IEventDispatcher;
import uim.cake.events\EventDispatcherTrait;
import uim.cake.events\EventManager;
import uim.cake.events\IEventManager;
use InvalidArgumentException;
use Laminas\HttpHandlerRunner\Emitter\EmitterInterface;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;

/**
 * Runs an application invoking all the PSR7 middleware and the registered application.
 */
class Server : IEventDispatcher
{
    use EventDispatcherTrait;

    /**
     * @var \Cake\Core\HttpApplicationInterface
     */
    protected $app;

    /**
     * @var \Cake\Http\Runner
     */
    protected $runner;

    /**
     * Constructor
     *
     * @param \Cake\Core\HttpApplicationInterface $app The application to use.
     * @param \Cake\Http\Runner|null $runner Application runner.
     */
    this(HttpApplicationInterface $app, ?Runner $runner = null) {
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
     * - Trigger the 'Server.buildMiddleware' event. You can use this to modify the
     *   from event listeners.
     * - Run the middleware queue including the application.
     *
     * @param \Psr\Http\Message\IServerRequest|null myRequest The request to use or null.
     * @param \Cake\Http\MiddlewareQueue|null $middlewareQueue MiddlewareQueue or null.
     * @return \Psr\Http\Message\IResponse
     * @throws \RuntimeException When the application does not make a response.
     */
    function run(
        ?IServerRequest myRequest = null,
        ?MiddlewareQueue $middlewareQueue = null
    ): IResponse {
        this.bootstrap();

        myRequest = myRequest ?: ServerRequestFactory::fromGlobals();

        $middleware = this.app.middleware($middlewareQueue ?? new MiddlewareQueue());
        if (this.app instanceof PluginApplicationInterface) {
            $middleware = this.app.pluginMiddleware($middleware);
        }

        this.dispatchEvent('Server.buildMiddleware', ['middleware' => $middleware]);

        $response = this.runner.run($middleware, myRequest, this.app);

        if (myRequest instanceof ServerRequest) {
            myRequest.getSession().close();
        }

        return $response;
    }

    /**
     * Application bootstrap wrapper.
     *
     * Calls the application's `bootstrap()` hook. After the application the
     * plugins are bootstrapped.
     *
     * @return void
     */
    protected auto bootstrap(): void
    {
        this.app.bootstrap();
        if (this.app instanceof PluginApplicationInterface) {
            this.app.pluginBootstrap();
        }
    }

    /**
     * Emit the response using the PHP SAPI.
     *
     * @param \Psr\Http\Message\IResponse $response The response to emit
     * @param \Laminas\HttpHandlerRunner\Emitter\EmitterInterface|null $emitter The emitter to use.
     *   When null, a SAPI Stream Emitter will be used.
     * @return void
     */
    function emit(IResponse $response, ?EmitterInterface $emitter = null): void
    {
        if (!$emitter) {
            $emitter = new ResponseEmitter();
        }
        $emitter.emit($response);
    }

    /**
     * Get the current application.
     *
     * @return \Cake\Core\HttpApplicationInterface The application that will be run.
     */
    auto getApp(): HttpApplicationInterface
    {
        return this.app;
    }

    /**
     * Get the application's event manager or the global one.
     *
     * @return \Cake\Event\IEventManager
     */
    auto getEventManager(): IEventManager
    {
        if (this.app instanceof IEventDispatcher) {
            return this.app.getEventManager();
        }

        return EventManager::instance();
    }

    /**
     * Set the application's event manager.
     *
     * If the application does not support events, an exception will be raised.
     *
     * @param \Cake\Event\IEventManager myEventManager The event manager to set.
     * @return this
     * @throws \InvalidArgumentException
     */
    auto setEventManager(IEventManager myEventManager) {
        if (this.app instanceof IEventDispatcher) {
            this.app.setEventManager(myEventManager);

            return this;
        }

        throw new InvalidArgumentException('Cannot set the event manager, the application does not support events.');
    }
}
