module uim.cake.routings.Middleware;

@safe:
import uim.cake;

use Exception;
use Laminas\Diactoros\Response\RedirectResponse;
use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;
use Psr\Http\servers.IMiddleware;
use Psr\Http\servers.RequestHandlerInterface;

/**
 * Applies routing rules to the request and creates the controller
 * instance if possible.
 */
class RoutingMiddleware : IMiddleware
{
    /**
     * Key used to store the route collection in the cache engine
     */
    const string ROUTE_COLLECTION_CACHE_KEY = "routeCollection";

    /**
     * The application that will have its routing hook invoked.
     *
     * @var uim.cake.routings.IRoutingApplication
     */
    protected $app;

    /**
     * The cache configuration name to use for route collection caching,
     * null to disable caching
     *
     */
    protected Nullable!string cacheConfig;

    /**
     * Constructor
     *
     * @param uim.cake.routings.IRoutingApplication $app The application instance that routes are defined on.
     * @param string|null $cacheConfig The cache config name to use or null to disable routes cache
     */
    this(IRoutingApplication $app, Nullable!string $cacheConfig = null) {
        if ($cacheConfig != null) {
            deprecationWarning(
                "Use of routing cache is deprecated and will be removed in 5.0~ " ~
                "Upgrade to the new `CakeDC/CachedRouting` plugin~ " ~
                "See https://github.com/CakeDC/cakephp-cached-routing"
            );
        }
        this.app = $app;
        this.cacheConfig = $cacheConfig;
    }

    /**
     * Trigger the application"s routes() hook if the application exists and Router isn"t initialized.
     * Uses the routes cache if enabled via configuration param "Router.cache"
     *
     * If the middleware is created without an Application, routes will be
     * loaded via the automatic route loading that pre-dates the routes() hook.
     */
    protected void loadRoutes() {
        $routeCollection = this.buildRouteCollection();
        Router::setRouteCollection($routeCollection);
    }

    /**
     * Check if route cache is enabled and use the configured Cache to "remember" the route collection
     *
     * @return uim.cake.routings.RouteCollection
     */
    protected function buildRouteCollection(): RouteCollection
    {
        if (Cache::enabled() && this.cacheConfig != null) {
            try {
                return Cache::remember(static::ROUTE_COLLECTION_CACHE_KEY, function () {
                    return this.prepareRouteCollection();
                }, this.cacheConfig);
            } catch (InvalidArgumentException $e) {
                throw $e;
            } catch (Exception $e) {
                throw new FailedRouteCacheException(
                    "Unable to cache route collection. Cached routes must be serializable. Check for route-specific
                    middleware or other unserializable settings in your routes. The original exception message can
                    show what type of object failed to serialize.",
                    null,
                    $e
                );
            }
        }

        return this.prepareRouteCollection();
    }

    /**
     * Generate the route collection using the builder
     *
     * @return uim.cake.routings.RouteCollection
     */
    protected function prepareRouteCollection(): RouteCollection
    {
        $builder = Router::createRouteBuilder("/");
        this.app.routes($builder);
        if (this.app instanceof IPluginApplication) {
            this.app.pluginRoutes($builder);
        }

        return Router::getRouteCollection();
    }

    /**
     * Apply routing and update the request.
     *
     * Any route/path specific middleware will be wrapped around $next and then the new middleware stack will be
     * invoked.
     *
     * @param \Psr\Http\messages.IServerRequest $request The request.
     * @param \Psr\Http\servers.RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\messages.IResponse A response.
     */
    function process(IServerRequest $request, RequestHandlerInterface $handler): IResponse
    {
        this.loadRoutes();
        try {
            Router::setRequest($request);
            $params = (array)$request.getAttribute("params", []);
            $middleware = null;
            if (empty($params["controller"])) {
                $params = Router::parseRequest($request) + $params;
                if (isset($params["_middleware"])) {
                    $middleware = $params["_middleware"];
                }
                $route = $params["_route"];
                unset($params["_middleware"], $params["_route"]);

                $request = $request.withAttribute("route", $route);
                /** @var uim.cake.http.ServerRequest $request */
                $request = $request.withAttribute("params", $params);
                Router::setRequest($request);
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
            return $handler.handle($request);
        }

        $middleware = new MiddlewareQueue($matching);
        $runner = new Runner();

        return $runner.run($middleware, $request, $handler);
    }
}
