/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.routings;

@safe:
import uim.cake;

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
     * @var array<string, array<\Cake\Routing\Route\Route>>
     */
    protected _routeTable = [];

    /**
     * The hash map of named routes that are in this collection.
     *
     * @var array<\Cake\Routing\Route\Route>
     */
    protected _named = [];

    /**
     * Routes indexed by path prefix.
     *
     * @var array<string, array<\Cake\Routing\Route\Route>>
     */
    protected _paths = [];

    /**
     * A map of middleware names and the related objects.
     *
     * @var array
     */
    protected _middleware = [];

    /**
     * A map of middleware group names and the related middleware names.
     *
     * @var array
     */
    protected _middlewareGroups = [];

    /**
     * Route extensions
     *
     * @var array<string>
     */
    protected _extensions = [];

    /**
     * Add a route to the collection.
     *
     * @param uim.cake.Routing\Route\Route $route The route object to add.
     * @param array<string, mixed> myOptions Additional options for the route. Primarily for the
     *   `_name` option, which enables named routes.
     */
    void add(Route $route, array myOptions = []) {
        // Explicit names
        if (isset(myOptions["_name"])) {
            if (isset(_named[myOptions["_name"]])) {
                $matched = _named[myOptions["_name"]];
                throw new DuplicateNamedRouteException([
                    "name": myOptions["_name"],
                    "url": $matched.template,
                    "duplicate": $matched,
                ]);
            }
            _named[myOptions["_name"]] = $route;
        }

        // Generated names.
        myName = $route.getName();
        _routeTable[myName] = _routeTable[myName] ?? [];
        _routeTable[myName][] = $route;

        // Index path prefixes (for parsing)
        myPath = $route.staticPath();
        _paths[myPath][] = $route;

        $extensions = $route.getExtensions();
        if (count($extensions) > 0) {
            this.setExtensions($extensions);
        }
    }

    /**
     * Takes the URL string and iterates the routes until one is able to parse the route.
     *
     * @param string myUrl URL to parse.
     * @param string method The HTTP method to use.
     * @return array An array of request parameters parsed from the URL.
     * @throws uim.cake.Routing\Exception\MissingRouteException When a URL has no matching route.
     */
    function parse(string myUrl, string method = ""): array
    {
        $decoded = urldecode(myUrl);

        // Sort path segments matching longest paths first.
        krsort(_paths);

        foreach (_paths as myPath: $routes) {
            if (indexOf($decoded, myPath) != 0) {
                continue;
            }

            myQueryParameters = [];
            if (indexOf(myUrl, "?") != false) {
                [myUrl, $qs] = explode("?", myUrl, 2);
                parse_str($qs, myQueryParameters);
            }

            foreach ($routes as $route) {
                $r = $route.parse(myUrl, $method);
                if ($r is null) {
                    continue;
                }
                if (myQueryParameters) {
                    $r["?"] = myQueryParameters;
                }

                return $r;
            }
        }

        myExceptionProperties = ["url": myUrl];
        if ($method != "") {
            // Ensure that if the method is included, it is the first element of
            // the array, to match the order that the strings are printed in the
            // MissingRouteException error message, $_messageTemplateWithMethod.
            myExceptionProperties = array_merge(["method": $method], myExceptionProperties);
        }
        throw new MissingRouteException(myExceptionProperties);
    }

    /**
     * Takes the IServerRequest, iterates the routes until one is able to parse the route.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request to parse route data from.
     * @return array An array of request parameters parsed from the URL.
     * @throws uim.cake.Routing\Exception\MissingRouteException When a URL has no matching route.
     */
    function parseRequest(IServerRequest myRequest): array
    {
        $uri = myRequest.getUri();
        myUrlPath = urldecode($uri.getPath());

        // Sort path segments matching longest paths first.
        krsort(_paths);

        foreach (_paths as myPath: $routes) {
            if (indexOf(myUrlPath, myPath) != 0) {
                continue;
            }

            foreach ($routes as $route) {
                $r = $route.parseRequest(myRequest);
                if ($r is null) {
                    continue;
                }
                if ($uri.getQuery()) {
                    parse_str($uri.getQuery(), myQueryParameters);
                    $r["?"] = myQueryParameters;
                }

                return $r;
            }
        }
        throw new MissingRouteException(["url": myUrlPath]);
    }

    /**
     * Get the set of names from the myUrl. Accepts both older style array urls,
     * and newer style urls containing "_name"
     *
     * @param array myUrl The url to match.
     * @return The set of names of the url
     */
    protected string[] _getNames(array myUrl) {
        myPlugin = false;
        if (isset(myUrl["plugin"]) && myUrl["plugin"] != false) {
            myPlugin = strtolower(myUrl["plugin"]);
        }
        $prefix = false;
        if (isset(myUrl["prefix"]) && myUrl["prefix"] != false) {
            $prefix = strtolower(myUrl["prefix"]);
        }
        $controller = isset(myUrl["controller"]) ? strtolower(myUrl["controller"]) : null;
        $action = strtolower(myUrl["action"]);

        myNames = [
            "${controller}:${action}",
            "${controller}:_action",
            "_controller:${action}",
            "_controller:_action",
        ];

        // No prefix, no plugin
        if ($prefix == false && myPlugin == false) {
            return myNames;
        }

        // Only a plugin
        if ($prefix == false) {
            return [
                "${plugin}.${controller}:${action}",
                "${plugin}.${controller}:_action",
                "${plugin}._controller:${action}",
                "${plugin}._controller:_action",
                "_plugin.${controller}:${action}",
                "_plugin.${controller}:_action",
                "_plugin._controller:${action}",
                "_plugin._controller:_action",
            ];
        }

        // Only a prefix
        if (myPlugin == false) {
            return [
                "${prefix}:${controller}:${action}",
                "${prefix}:${controller}:_action",
                "${prefix}:_controller:${action}",
                "${prefix}:_controller:_action",
                "_prefix:${controller}:${action}",
                "_prefix:${controller}:_action",
                "_prefix:_controller:${action}",
                "_prefix:_controller:_action",
            ];
        }

        // Prefix and plugin has the most options
        // as there are 4 factors.
        return [
            "${prefix}:${plugin}.${controller}:${action}",
            "${prefix}:${plugin}.${controller}:_action",
            "${prefix}:${plugin}._controller:${action}",
            "${prefix}:${plugin}._controller:_action",
            "${prefix}:_plugin.${controller}:${action}",
            "${prefix}:_plugin.${controller}:_action",
            "${prefix}:_plugin._controller:${action}",
            "${prefix}:_plugin._controller:_action",
            "_prefix:${plugin}.${controller}:${action}",
            "_prefix:${plugin}.${controller}:_action",
            "_prefix:${plugin}._controller:${action}",
            "_prefix:${plugin}._controller:_action",
            "_prefix:_plugin.${controller}:${action}",
            "_prefix:_plugin.${controller}:_action",
            "_prefix:_plugin._controller:${action}",
            "_prefix:_plugin._controller:_action",
        ];
    }

    /**
     * Reverse route or match a myUrl array with the connected routes.
     *
     * Returns either the URL string generated by the route,
     * or throws an exception on failure.
     *
     * @param array myUrl The URL to match.
     * @param array $context The request context to use. Contains _base, _port,
     *    _host, _scheme and params keys.
     * @return string The URL string on match.
     * @throws uim.cake.Routing\Exception\MissingRouteException When no route could be matched.
     */
    string match(array myUrl, array $context) {
        // Named routes support optimization.
        if (isset(myUrl["_name"])) {
            myName = myUrl["_name"];
            unset(myUrl["_name"]);
            if (isset(_named[myName])) {
                $route = _named[myName];
                $out = $route.match(myUrl + $route.defaults, $context);
                if ($out) {
                    return $out;
                }
                throw new MissingRouteException([
                    "url": myName,
                    "context": $context,
                    "message": "A named route was found for `{myName}`, but matching failed.",
                ]);
            }
            throw new MissingRouteException(["url": myName, "context": $context]);
        }

        foreach (_getNames(myUrl) as myName) {
            if (empty(_routeTable[myName])) {
                continue;
            }
            foreach (_routeTable[myName] as $route) {
                $match = $route.match(myUrl, $context);
                if ($match) {
                    return $match == "/" ? $match : trim($match, "/");
                }
            }
        }
        throw new MissingRouteException(["url": var_export(myUrl, true), "context": $context]);
    }

    /**
     * Get all the connected routes as a flat list.
     *
     * @return array<\Cake\Routing\Route\Route>
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

    // Get the connected named routes.
    Route[] named() {
        return _named;
    }

    /**
     * Get the extensions that can be handled.
     *
     * @return The valid extensions.
     */
    string[] getExtensions() {
        return _extensions;
    }

    /**
     * Set the extensions that the route collection can handle.
     *
     * @param $extensions The list of extensions to set.
     * @param bool myMerge Whether to merge with or override existing extensions.
     *   Defaults to `true`.
     * @return this
     */
    auto setExtensions(string[] $extensions, bool myMerge = true) {
        if (myMerge) {
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
     * @param string myName The name of the middleware. Used when applying middleware to a scope.
     * @param \Psr\Http\Server\IMiddleware|\Closure|string middleware The middleware to register.
     * @return this
     * @throws \RuntimeException
     */
    function registerMiddleware(string myName, $middleware) {
        _middleware[myName] = $middleware;

        return this;
    }

    /**
     * Add middleware to a middleware group
     *
     * @param string myName Name of the middleware group
     * @param $middlewareNames Names of the middleware
     * @return this
     * @throws \RuntimeException
     */
    function middlewareGroup(string myName, string[] $middlewareNames) {
        if (this.hasMiddleware(myName)) {
            myMessage = "Cannot add middleware group "myName". A middleware by this name has already been registered.";
            throw new RuntimeException(myMessage);
        }

        foreach ($middlewareNames as $middlewareName) {
            if (!this.hasMiddleware($middlewareName)) {
                myMessage = "Cannot add "$middlewareName" middleware to group "myName". It has not been registered.";
                throw new RuntimeException(myMessage);
            }
        }

        _middlewareGroups[myName] = $middlewareNames;

        return this;
    }

    /**
     * Check if the named middleware group has been created.
     *
     * @param string myName The name of the middleware group to check.
     */
    bool hasMiddlewareGroup(string myName) {
        return array_key_exists(myName, _middlewareGroups);
    }

    /**
     * Check if the named middleware has been registered.
     *
     * @param string myName The name of the middleware to check.
     */
    bool hasMiddleware(string myName) {
        return isset(_middleware[myName]);
    }

    /**
     * Check if the named middleware or middleware group has been registered.
     *
     * @param string myName The name of the middleware to check.
     */
    bool middlewareExists(string myName) {
        return this.hasMiddleware(myName) || this.hasMiddlewareGroup(myName);
    }

    /**
     * Get an array of middleware given a list of names
     *
     * @param myNames The names of the middleware or groups to fetch
     * @return array An array of middleware. If any of the passed names are groups,
     *   the groups middleware will be flattened into the returned list.
     * @throws \RuntimeException when a requested middleware does not exist.
     */
    auto getMiddleware(string[] myNames): array
    {
        $out = [];
        foreach (myNames as myName) {
            if (this.hasMiddlewareGroup(myName)) {
                $out = array_merge($out, this.getMiddleware(_middlewareGroups[myName]));
                continue;
            }
            if (!this.hasMiddleware(myName)) {
                throw new RuntimeException(sprintf(
                    "The middleware named "%s" has not been registered. Use registerMiddleware() to define it.",
                    myName
                ));
            }
            $out[] = _middleware[myName];
        }

        return $out;
    }
}
