module uim.cake.Routing;

import uim.cake.routings.exceptions.DuplicateNamedRouteException;
import uim.cake.routings.exceptions.MissingRouteException;
import uim.cake.routings.Route\Route;
use Psr\Http\messages.IServerRequest;
use RuntimeException;

/**
 * Contains a collection of routes.
 *
 * Provides an interface for adding/removing routes
 * and parsing/generating URLs with the routes it contains.
 *
 * @internal
 */
class RouteCollection
{
    /**
     * The routes connected to this collection.
     *
     * @var array<string, array<uim.cake.routings.Route\Route>>
     */
    protected $_routeTable = [];

    /**
     * The hash map of named routes that are in this collection.
     *
     * @var array<uim.cake.routings.Route\Route>
     */
    protected $_named = [];

    /**
     * Routes indexed by path prefix.
     *
     * @var array<string, array<uim.cake.routings.Route\Route>>
     */
    protected $_paths = [];

    /**
     * A map of middleware names and the related objects.
     *
     * @var array
     */
    protected $_middleware = [];

    /**
     * A map of middleware group names and the related middleware names.
     *
     * @var array
     */
    protected $_middlewareGroups = [];

    /**
     * Route extensions
     *
     * @var array<string>
     */
    protected $_extensions = [];

    /**
     * Add a route to the collection.
     *
     * @param uim.cake.routings.Route\Route $route The route object to add.
     * @param array<string, mixed> $options Additional options for the route. Primarily for the
     *   `_name` option, which enables named routes.
     */
    void add(Route $route, array $options = []): void
    {
        // Explicit names
        if (isset($options["_name"])) {
            if (isset(_named[$options["_name"]])) {
                $matched = _named[$options["_name"]];
                throw new DuplicateNamedRouteException([
                    "name": $options["_name"],
                    "url": $matched.template,
                    "duplicate": $matched,
                ]);
            }
            _named[$options["_name"]] = $route;
        }

        // Generated names.
        $name = $route.getName();
        _routeTable[$name] = _routeTable[$name] ?? [];
        _routeTable[$name][] = $route;

        // Index path prefixes (for parsing)
        $path = $route.staticPath();
        _paths[$path][] = $route;

        $extensions = $route.getExtensions();
        if (count($extensions) > 0) {
            this.setExtensions($extensions);
        }
    }

    /**
     * Takes the URL string and iterates the routes until one is able to parse the route.
     *
     * @param string $url URL to parse.
     * @param string $method The HTTP method to use.
     * @return array An array of request parameters parsed from the URL.
     * @throws uim.cake.routings.exceptions.MissingRouteException When a URL has no matching route.
     */
    function parse(string $url, string $method = ""): array
    {
        $decoded = urldecode($url);

        // Sort path segments matching longest paths first.
        krsort(_paths);

        foreach (_paths as $path: $routes) {
            if (strpos($decoded, $path) != 0) {
                continue;
            }

            $queryParameters = [];
            if (strpos($url, "?") != false) {
                [$url, $qs] = explode("?", $url, 2);
                parse_str($qs, $queryParameters);
            }

            foreach ($routes as $route) {
                $r = $route.parse($url, $method);
                if ($r == null) {
                    continue;
                }
                if ($queryParameters) {
                    $r["?"] = $queryParameters;
                }

                return $r;
            }
        }

        $exceptionProperties = ["url": $url];
        if ($method != "") {
            // Ensure that if the method is included, it is the first element of
            // the array, to match the order that the strings are printed in the
            // MissingRouteException error message, $_messageTemplateWithMethod.
            $exceptionProperties = array_merge(["method": $method], $exceptionProperties);
        }
        throw new MissingRouteException($exceptionProperties);
    }

    /**
     * Takes the IServerRequest, iterates the routes until one is able to parse the route.
     *
     * @param \Psr\Http\messages.IServerRequest $request The request to parse route data from.
     * @return array An array of request parameters parsed from the URL.
     * @throws uim.cake.routings.exceptions.MissingRouteException When a URL has no matching route.
     */
    function parseRequest(IServerRequest $request): array
    {
        $uri = $request.getUri();
        $urlPath = urldecode($uri.getPath());

        // Sort path segments matching longest paths first.
        krsort(_paths);

        foreach (_paths as $path: $routes) {
            if (strpos($urlPath, $path) != 0) {
                continue;
            }

            foreach ($routes as $route) {
                $r = $route.parseRequest($request);
                if ($r == null) {
                    continue;
                }
                if ($uri.getQuery()) {
                    parse_str($uri.getQuery(), $queryParameters);
                    $r["?"] = $queryParameters;
                }

                return $r;
            }
        }
        throw new MissingRouteException(["url": $urlPath]);
    }

    /**
     * Get the set of names from the $url. Accepts both older style array urls,
     * and newer style urls containing "_name"
     *
     * @param array $url The url to match.
     * @return array<string> The set of names of the url
     */
    protected string[] _getNames(array $url): array
    {
        $plugin = false;
        if (isset($url["plugin"]) && $url["plugin"] != false) {
            $plugin = strtolower($url["plugin"]);
        }
        $prefix = false;
        if (isset($url["prefix"]) && $url["prefix"] != false) {
            $prefix = strtolower($url["prefix"]);
        }
        $controller = isset($url["controller"]) ? strtolower($url["controller"]) : null;
        $action = strtolower($url["action"]);

        $names = [
            "{$controller}:{$action}",
            "{$controller}:_action",
            "_controller:{$action}",
            "_controller:_action",
        ];

        // No prefix, no plugin
        if ($prefix == false && $plugin == false) {
            return $names;
        }

        // Only a plugin
        if ($prefix == false) {
            return [
                "{$plugin}.{$controller}:{$action}",
                "{$plugin}.{$controller}:_action",
                "{$plugin}._controller:{$action}",
                "{$plugin}._controller:_action",
                "_plugin.{$controller}:{$action}",
                "_plugin.{$controller}:_action",
                "_plugin._controller:{$action}",
                "_plugin._controller:_action",
            ];
        }

        // Only a prefix
        if ($plugin == false) {
            return [
                "{$prefix}:{$controller}:{$action}",
                "{$prefix}:{$controller}:_action",
                "{$prefix}:_controller:{$action}",
                "{$prefix}:_controller:_action",
                "_prefix:{$controller}:{$action}",
                "_prefix:{$controller}:_action",
                "_prefix:_controller:{$action}",
                "_prefix:_controller:_action",
            ];
        }

        // Prefix and plugin has the most options
        // as there are 4 factors.
        return [
            "{$prefix}:{$plugin}.{$controller}:{$action}",
            "{$prefix}:{$plugin}.{$controller}:_action",
            "{$prefix}:{$plugin}._controller:{$action}",
            "{$prefix}:{$plugin}._controller:_action",
            "{$prefix}:_plugin.{$controller}:{$action}",
            "{$prefix}:_plugin.{$controller}:_action",
            "{$prefix}:_plugin._controller:{$action}",
            "{$prefix}:_plugin._controller:_action",
            "_prefix:{$plugin}.{$controller}:{$action}",
            "_prefix:{$plugin}.{$controller}:_action",
            "_prefix:{$plugin}._controller:{$action}",
            "_prefix:{$plugin}._controller:_action",
            "_prefix:_plugin.{$controller}:{$action}",
            "_prefix:_plugin.{$controller}:_action",
            "_prefix:_plugin._controller:{$action}",
            "_prefix:_plugin._controller:_action",
        ];
    }

    /**
     * Reverse route or match a $url array with the connected routes.
     *
     * Returns either the URL string generated by the route,
     * or throws an exception on failure.
     *
     * @param array $url The URL to match.
     * @param array $context The request context to use. Contains _base, _port,
     *    _host, _scheme and params keys.
     * @return string The URL string on match.
     * @throws uim.cake.routings.exceptions.MissingRouteException When no route could be matched.
     */
    function match(array $url, array $context): string
    {
        // Named routes support optimization.
        if (isset($url["_name"])) {
            $name = $url["_name"];
            unset($url["_name"]);
            if (isset(_named[$name])) {
                $route = _named[$name];
                $out = $route.match($url + $route.defaults, $context);
                if ($out) {
                    return $out;
                }
                throw new MissingRouteException([
                    "url": $name,
                    "context": $context,
                    "message": "A named route was found for `{$name}`, but matching failed.",
                ]);
            }
            throw new MissingRouteException(["url": $name, "context": $context]);
        }

        foreach (_getNames($url) as $name) {
            if (empty(_routeTable[$name])) {
                continue;
            }
            foreach (_routeTable[$name] as $route) {
                $match = $route.match($url, $context);
                if ($match) {
                    return $match == "/" ? $match : trim($match, "/");
                }
            }
        }
        throw new MissingRouteException(["url": var_export($url, true), "context": $context]);
    }

    /**
     * Get all the connected routes as a flat list.
     *
     * @return array<uim.cake.routings.Route\Route>
     */
    function routes(): array
    {
        krsort(_paths);

        return array_reduce(
            _paths,
            "array_merge",
            []
        );
    }

    /**
     * Get the connected named routes.
     *
     * @return array<uim.cake.routings.Route\Route>
     */
    function named(): array
    {
        return _named;
    }

    /**
     * Get the extensions that can be handled.
     *
     * @return array<string> The valid extensions.
     */
    string[] getExtensions(): array
    {
        return _extensions;
    }

    /**
     * Set the extensions that the route collection can handle.
     *
     * @param array<string> $extensions The list of extensions to set.
     * @param bool $merge Whether to merge with or override existing extensions.
     *   Defaults to `true`.
     * @return this
     */
    function setExtensions(array $extensions, bool $merge = true) {
        if ($merge) {
            $extensions = array_unique(array_merge(
                _extensions,
                $extensions
            ));
        }
        _extensions = $extensions;

        return this;
    }

    /**
     * Register a middleware with the RouteCollection.
     *
     * Once middleware has been registered, it can be applied to the current routing
     * scope or any child scopes that share the same RouteCollection.
     *
     * @param string aName The name of the middleware. Used when applying middleware to a scope.
     * @param \Psr\Http\servers.IMiddleware|\Closure|string $middleware The middleware to register.
     * @return this
     * @throws \RuntimeException
     */
    function registerMiddleware(string aName, $middleware) {
        _middleware[$name] = $middleware;

        return this;
    }

    /**
     * Add middleware to a middleware group
     *
     * @param string aName Name of the middleware group
     * @param array<string> $middlewareNames Names of the middleware
     * @return this
     * @throws \RuntimeException
     */
    function middlewareGroup(string aName, array $middlewareNames) {
        if (this.hasMiddleware($name)) {
            $message = "Cannot add middleware group "$name". A middleware by this name has already been registered.";
            throw new RuntimeException($message);
        }

        foreach ($middlewareNames as $middlewareName) {
            if (!this.hasMiddleware($middlewareName)) {
                $message = "Cannot add "$middlewareName" middleware to group "$name". It has not been registered.";
                throw new RuntimeException($message);
            }
        }

        _middlewareGroups[$name] = $middlewareNames;

        return this;
    }

    /**
     * Check if the named middleware group has been created.
     *
     * @param string aName The name of the middleware group to check.
     * @return bool
     */
    function hasMiddlewareGroup(string aName): bool
    {
        return array_key_exists($name, _middlewareGroups);
    }

    /**
     * Check if the named middleware has been registered.
     *
     * @param string aName The name of the middleware to check.
     * @return bool
     */
    function hasMiddleware(string aName): bool
    {
        return isset(_middleware[$name]);
    }

    /**
     * Check if the named middleware or middleware group has been registered.
     *
     * @param string aName The name of the middleware to check.
     * @return bool
     */
    function middlewareExists(string aName): bool
    {
        return this.hasMiddleware($name) || this.hasMiddlewareGroup($name);
    }

    /**
     * Get an array of middleware given a list of names
     *
     * @param array<string> $names The names of the middleware or groups to fetch
     * @return array An array of middleware. If any of the passed names are groups,
     *   the groups middleware will be flattened into the returned list.
     * @throws \RuntimeException when a requested middleware does not exist.
     */
    function getMiddleware(array $names): array
    {
        $out = [];
        foreach ($names as $name) {
            if (this.hasMiddlewareGroup($name)) {
                $out = array_merge($out, this.getMiddleware(_middlewareGroups[$name]));
                continue;
            }
            if (!this.hasMiddleware($name)) {
                throw new RuntimeException(sprintf(
                    "The middleware named "%s" has not been registered. Use registerMiddleware() to define it.",
                    $name
                ));
            }
            $out[] = _middleware[$name];
        }

        return $out;
    }
}
