

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Routing\Middleware;

import uim.cake.cache\Cache;
import uim.cake.core.PluginApplicationInterface;
import uim.cake.Http\Exception\RedirectException;
import uim.cake.Http\MiddlewareQueue;
import uim.cake.Http\Runner;
import uim.cake.Routing\Exception\RedirectException as DeprecatedRedirectException;
import uim.cake.Routing\RouteCollection;
import uim.cake.Routing\Router;
import uim.cake.Routing\RoutingApplicationInterface;
use Laminas\Diactoros\Response\RedirectResponse;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;

/**
 * Applies routing rules to the request and creates the controller
 * instance if possible.
 */
class RoutingMiddleware : MiddlewareInterface
{
    /**
     * Key used to store the route collection in the cache engine
     *
     * @var string
     */
    public const ROUTE_COLLECTION_CACHE_KEY = 'routeCollection';

    /**
     * The application that will have its routing hook invoked.
     *
     * @var \Cake\Routing\RoutingApplicationInterface
     */
    protected $app;

    /**
     * The cache configuration name to use for route collection caching,
     * null to disable caching
     *
     * @var string|null
     */
    protected $cacheConfig;

    /**
     * Constructor
     *
     * @param \Cake\Routing\RoutingApplicationInterface $app The application instance that routes are defined on.
     * @param string|null $cacheConfig The cache config name to use or null to disable routes cache
     */
    this(RoutingApplicationInterface $app, ?string $cacheConfig = null)
    {
        this.app = $app;
        this.cacheConfig = $cacheConfig;
    }

    /**
     * Trigger the application's routes() hook if the application exists and Router isn't initialized.
     * Uses the routes cache if enabled via configuration param "Router.cache"
     *
     * If the middleware is created without an Application, routes will be
     * loaded via the automatic route loading that pre-dates the routes() hook.
     *
     * @return void
     */
    protected auto loadRoutes(): void
    {
        $routeCollection = this.buildRouteCollection();
        Router::setRouteCollection($routeCollection);
    }

    /**
     * Check if route cache is enabled and use the configured Cache to 'remember' the route collection
     *
     * @return \Cake\Routing\RouteCollection
     */
    protected auto buildRouteCollection(): RouteCollection
    {
        if (Cache::enabled() && this.cacheConfig !== null) {
            return Cache::remember(static::ROUTE_COLLECTION_CACHE_KEY, function () {
                return this.prepareRouteCollection();
            }, this.cacheConfig);
        }

        return this.prepareRouteCollection();
    }

    /**
     * Generate the route collection using the builder
     *
     * @return \Cake\Routing\RouteCollection
     */
    protected auto prepareRouteCollection(): RouteCollection
    {
        myBuilder = Router::createRouteBuilder('/');
        this.app.routes(myBuilder);
        if (this.app instanceof PluginApplicationInterface) {
            this.app.pluginRoutes(myBuilder);
        }

        return Router::getRouteCollection();
    }

    /**
     * Apply routing and update the request.
     *
     * Any route/path specific middleware will be wrapped around $next and then the new middleware stack will be
     * invoked.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request.
     * @param \Psr\Http\Server\RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\Message\IResponse A response.
     */
    function process(IServerRequest myRequest, RequestHandlerInterface $handler): IResponse
    {
        this.loadRoutes();
        try {
            Router::setRequest(myRequest);
            myParams = (array)myRequest.getAttribute('params', []);
            $middleware = [];
            if (empty(myParams['controller'])) {
                myParams = Router::parseRequest(myRequest) + myParams;
                if (isset(myParams['_middleware'])) {
                    $middleware = myParams['_middleware'];
                    unset(myParams['_middleware']);
                }
                /** @var \Cake\Http\ServerRequest myRequest */
                myRequest = myRequest.withAttribute('params', myParams);
                Router::setRequest(myRequest);
            }
        } catch (RedirectException $e) {
            return new RedirectResponse(
                $e.getMessage(),
                $e.getCode()
            );
        } catch (DeprecatedRedirectException $e) {
            return new RedirectResponse(
                $e.getMessage(),
                $e.getCode()
            );
        }
        $matching = Router::getRouteCollection().getMiddleware($middleware);
        if (!$matching) {
            return $handler.handle(myRequest);
        }

        $middleware = new MiddlewareQueue($matching);
        $runner = new Runner();

        return $runner.run($middleware, myRequest, $handler);
    }
}
