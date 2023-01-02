module uim.cake.Routing;

use BadMethodCallException;
import uim.cake.core.App;
import uim.cake.core.exceptions.MissingPluginException;
import uim.cake.core.Plugin;
import uim.cake.routings.Route\RedirectRoute;
import uim.cake.routings.Route\Route;
import uim.cake.utilities.Inflector;
use InvalidArgumentException;
use RuntimeException;

/**
 * Provides features for building routes inside scopes.
 *
 * Gives an easy to use way to build routes and append them
 * into a route collection.
 */
class RouteBuilder
{
    /**
     * Regular expression for auto increment IDs
     *
     * @var string
     */
    const ID = "[0-9]+";

    /**
     * Regular expression for UUIDs
     *
     * @var string
     */
    const UUID = "[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}";

    /**
     * Default HTTP request method: controller action map.
     *
     * @var array<string, array>
     */
    protected static $_resourceMap = [
        "index": ["action": "index", "method": "GET", "path": ""],
        "create": ["action": "add", "method": "POST", "path": ""],
        "view": ["action": "view", "method": "GET", "path": "{id}"],
        "update": ["action": "edit", "method": ["PUT", "PATCH"], "path": "{id}"],
        "delete": ["action": "delete", "method": "DELETE", "path": "{id}"],
    ];

    /**
     * Default route class to use if none is provided in connect() options.
     *
     */
    protected string $_routeClass = Route::class;

    /**
     * The extensions that should be set into the routes connected.
     *
     * @var array<string>
     */
    protected $_extensions = [];

    /**
     * The path prefix scope that this collection uses.
     *
     */
    protected string $_path;

    /**
     * The scope parameters if there are any.
     *
     * @var array
     */
    protected $_params;

    /**
     * Name prefix for connected routes.
     *
     */
    protected string $_namePrefix = "";

    /**
     * The route collection routes should be added to.
     *
     * @var uim.cake.routings.RouteCollection
     */
    protected $_collection;

    /**
     * The list of middleware that routes in this builder get
     * added during construction.
     *
     * @var array<string>
     */
    protected $middleware = [];

    /**
     * Constructor
     *
     * ### Options
     *
     * - `routeClass` - The default route class to use when adding routes.
     * - `extensions` - The extensions to connect when adding routes.
     * - `namePrefix` - The prefix to prepend to all route names.
     * - `middleware` - The names of the middleware routes should have applied.
     *
     * @param uim.cake.routings.RouteCollection $collection The route collection to append routes into.
     * @param string $path The path prefix the scope is for.
     * @param array $params The scope"s routing parameters.
     * @param array<string, mixed> $options Options list.
     */
    this(RouteCollection $collection, string $path, array $params = [], array $options = []) {
        _collection = $collection;
        _path = $path;
        _params = $params;
        if (isset($options["routeClass"])) {
            _routeClass = $options["routeClass"];
        }
        if (isset($options["extensions"])) {
            _extensions = $options["extensions"];
        }
        if (isset($options["namePrefix"])) {
            _namePrefix = $options["namePrefix"];
        }
        if (isset($options["middleware"])) {
            this.middleware = (array)$options["middleware"];
        }
    }

    /**
     * Set default route class.
     *
     * @param string $routeClass Class name.
     * @return this
     */
    function setRouteClass(string $routeClass) {
        _routeClass = $routeClass;

        return this;
    }

    /**
     * Get default route class.
     */
    string getRouteClass(): string
    {
        return _routeClass;
    }

    /**
     * Set the extensions in this route builder"s scope.
     *
     * Future routes connected in through this builder will have the connected
     * extensions applied. However, setting extensions does not modify existing routes.
     *
     * @param array<string>|string $extensions The extensions to set.
     * @return this
     */
    function setExtensions($extensions) {
        _extensions = (array)$extensions;

        return this;
    }

    /**
     * Get the extensions in this route builder"s scope.
     *
     * @return array<string>
     */
    string[] getExtensions(): array
    {
        return _extensions;
    }

    /**
     * Add additional extensions to what is already in current scope
     *
     * @param array<string>|string $extensions One or more extensions to add
     * @return this
     */
    function addExtensions($extensions) {
        $extensions = array_merge(_extensions, (array)$extensions);
        _extensions = array_unique($extensions);

        return this;
    }

    /**
     * Get the path this scope is for.
     */
    string path(): string
    {
        $routeKey = strpos(_path, "{");
        if ($routeKey != false && strpos(_path, "}") != false) {
            return substr(_path, 0, $routeKey);
        }

        $routeKey = strpos(_path, ":");
        if ($routeKey != false) {
            return substr(_path, 0, $routeKey);
        }

        return _path;
    }

    /**
     * Get the parameter names/values for this scope.
     */
    array params(): array
    {
        return _params;
    }

    /**
     * Checks if there is already a route with a given name.
     *
     * @param string aName Name.
     */
    bool nameExists(string aName): bool
    {
        return array_key_exists($name, _collection.named());
    }

    /**
     * Get/set the name prefix for this scope.
     *
     * Modifying the name prefix will only change the prefix
     * used for routes connected after the prefix is changed.
     *
     * @param string|null $value Either the value to set or null.
     */
    string namePrefix(?string $value = null): string
    {
        if ($value != null) {
            _namePrefix = $value;
        }

        return _namePrefix;
    }

    /**
     * Generate REST resource routes for the given controller(s).
     *
     * A quick way to generate a default routes to a set of REST resources (controller(s)).
     *
     * ### Usage
     *
     * Connect resource routes for an app controller:
     *
     * ```
     * $routes.resources("Posts");
     * ```
     *
     * Connect resource routes for the Comments controller in the
     * Comments plugin:
     *
     * ```
     * Router::plugin("Comments", function ($routes) {
     *   $routes.resources("Comments");
     * });
     * ```
     *
     * Plugins will create lowercase dasherized resource routes. e.g
     * `/comments/comments`
     *
     * Connect resource routes for the Articles controller in the
     * Admin prefix:
     *
     * ```
     * Router::prefix("Admin", function ($routes) {
     *   $routes.resources("Articles");
     * });
     * ```
     *
     * Prefixes will create lowercase dasherized resource routes. e.g
     * `/admin/posts`
     *
     * You can create nested resources by passing a callback in:
     *
     * ```
     * $routes.resources("Articles", function ($routes) {
     *   $routes.resources("Comments");
     * });
     * ```
     *
     * The above would generate both resource routes for `/articles`, and `/articles/{article_id}/comments`.
     * You can use the `map` option to connect additional resource methods:
     *
     * ```
     * $routes.resources("Articles", [
     *   "map": ["deleteAll": ["action": "deleteAll", "method": "DELETE"]]
     * ]);
     * ```
     *
     * In addition to the default routes, this would also connect a route for `/articles/delete_all`.
     * By default, the path segment will match the key name. You can use the "path" key inside the resource
     * definition to customize the path name.
     *
     * You can use the `inflect` option to change how path segments are generated:
     *
     * ```
     * $routes.resources("PaymentTypes", ["inflect": "underscore"]);
     * ```
     *
     * Will generate routes like `/payment-types` instead of `/payment_types`
     *
     * ### Options:
     *
     * - "id" - The regular expression fragment to use when matching IDs. By default, matches
     *    integer values and UUIDs.
     * - "inflect" - Choose the inflection method used on the resource name. Defaults to "dasherize".
     * - "only" - Only connect the specific list of actions.
     * - "actions" - Override the method names used for connecting actions.
     * - "map" - Additional resource routes that should be connected. If you define "only" and "map",
     *   make sure that your mapped methods are also in the "only" list.
     * - "prefix" - Define a routing prefix for the resource controller. If the current scope
     *   defines a prefix, this prefix will be appended to it.
     * - "connectOptions" - Custom options for connecting the routes.
     * - "path" - Change the path so it doesn"t match the resource name. E.g ArticlesController
     *   is available at `/posts`
     *
     * @param string aName A controller name to connect resource routes for.
     * @param callable|array $options Options to use when generating REST routes, or a callback.
     * @param callable|null $callback An optional callback to be executed in a nested scope. Nested
     *   scopes inherit the existing path and "id" parameter.
     * @return this
     */
    function resources(string aName, $options = [], $callback = null) {
        if (!is_array($options)) {
            $callback = $options;
            $options = [];
        }
        $options += [
            "connectOptions": [],
            "inflect": "dasherize",
            "id": static::ID ~ "|" ~ static::UUID,
            "only": [],
            "actions": [],
            "map": [],
            "prefix": null,
            "path": null,
        ];

        foreach ($options["map"] as $k: $mapped) {
            $options["map"][$k] += ["method": "GET", "path": $k, "action": ""];
        }

        $ext = null;
        if (!empty($options["_ext"])) {
            $ext = $options["_ext"];
        }

        $connectOptions = $options["connectOptions"];
        if (empty($options["path"])) {
            $method = $options["inflect"];
            $options["path"] = Inflector::$method($name);
        }
        $resourceMap = array_merge(static::$_resourceMap, $options["map"]);

        $only = (array)$options["only"];
        if (empty($only)) {
            $only = array_keys($resourceMap);
        }

        $prefix = "";
        if ($options["prefix"]) {
            $prefix = $options["prefix"];
        }
        if (isset(_params["prefix"]) && $prefix) {
            $prefix = _params["prefix"] ~ "/" ~ $prefix;
        }

        foreach ($resourceMap as $method: $params) {
            if (!in_array($method, $only, true)) {
                continue;
            }

            $action = $options["actions"][$method] ?? $params["action"];

            $url = "/" ~ implode("/", array_filter([$options["path"], $params["path"]]));
            $params = [
                "controller": $name,
                "action": $action,
                "_method": $params["method"],
            ];
            if ($prefix) {
                $params["prefix"] = $prefix;
            }
            $routeOptions = $connectOptions + [
                "id": $options["id"],
                "pass": ["id"],
                "_ext": $ext,
            ];
            this.connect($url, $params, $routeOptions);
        }

        if ($callback != null) {
            $idName = Inflector::singularize(Inflector::underscore($name)) ~ "_id";
            $path = "/" ~ $options["path"] ~ "/{" ~ $idName ~ "}";
            this.scope($path, [], $callback);
        }

        return this;
    }

    /**
     * Create a route that only responds to GET requests.
     *
     * @param string $template The URL template to use.
     * @param array|string $target An array describing the target route parameters. These parameters
     *   should indicate the plugin, prefix, controller, and action that this route points to.
     * @param string|null $name The name of the route.
     * @return uim.cake.routings.Route\Route
     */
    function get(string $template, $target, ?string aName = null): Route
    {
        return _methodRoute("GET", $template, $target, $name);
    }

    /**
     * Create a route that only responds to POST requests.
     *
     * @param string $template The URL template to use.
     * @param array|string $target An array describing the target route parameters. These parameters
     *   should indicate the plugin, prefix, controller, and action that this route points to.
     * @param string|null $name The name of the route.
     * @return uim.cake.routings.Route\Route
     */
    function post(string $template, $target, ?string aName = null): Route
    {
        return _methodRoute("POST", $template, $target, $name);
    }

    /**
     * Create a route that only responds to PUT requests.
     *
     * @param string $template The URL template to use.
     * @param array|string $target An array describing the target route parameters. These parameters
     *   should indicate the plugin, prefix, controller, and action that this route points to.
     * @param string|null $name The name of the route.
     * @return uim.cake.routings.Route\Route
     */
    function put(string $template, $target, ?string aName = null): Route
    {
        return _methodRoute("PUT", $template, $target, $name);
    }

    /**
     * Create a route that only responds to PATCH requests.
     *
     * @param string $template The URL template to use.
     * @param array|string $target An array describing the target route parameters. These parameters
     *   should indicate the plugin, prefix, controller, and action that this route points to.
     * @param string|null $name The name of the route.
     * @return uim.cake.routings.Route\Route
     */
    function patch(string $template, $target, ?string aName = null): Route
    {
        return _methodRoute("PATCH", $template, $target, $name);
    }

    /**
     * Create a route that only responds to DELETE requests.
     *
     * @param string $template The URL template to use.
     * @param array|string $target An array describing the target route parameters. These parameters
     *   should indicate the plugin, prefix, controller, and action that this route points to.
     * @param string|null $name The name of the route.
     * @return uim.cake.routings.Route\Route
     */
    function delete(string $template, $target, ?string aName = null): Route
    {
        return _methodRoute("DELETE", $template, $target, $name);
    }

    /**
     * Create a route that only responds to HEAD requests.
     *
     * @param string $template The URL template to use.
     * @param array|string $target An array describing the target route parameters. These parameters
     *   should indicate the plugin, prefix, controller, and action that this route points to.
     * @param string|null $name The name of the route.
     * @return uim.cake.routings.Route\Route
     */
    function head(string $template, $target, ?string aName = null): Route
    {
        return _methodRoute("HEAD", $template, $target, $name);
    }

    /**
     * Create a route that only responds to OPTIONS requests.
     *
     * @param string $template The URL template to use.
     * @param array|string $target An array describing the target route parameters. These parameters
     *   should indicate the plugin, prefix, controller, and action that this route points to.
     * @param string|null $name The name of the route.
     * @return uim.cake.routings.Route\Route
     */
    function options(string $template, $target, ?string aName = null): Route
    {
        return _methodRoute("OPTIONS", $template, $target, $name);
    }

    /**
     * Helper to create routes that only respond to a single HTTP method.
     *
     * @param string $method The HTTP method name to match.
     * @param string $template The URL template to use.
     * @param array|string $target An array describing the target route parameters. These parameters
     *   should indicate the plugin, prefix, controller, and action that this route points to.
     * @param string|null $name The name of the route.
     * @return uim.cake.routings.Route\Route
     */
    protected function _methodRoute(string $method, string $template, $target, ?string aName): Route
    {
        if ($name != null) {
            $name = _namePrefix . $name;
        }
        $options = [
            "_name": $name,
            "_ext": _extensions,
            "_middleware": this.middleware,
            "routeClass": _routeClass,
        ];

        $target = this.parseDefaults($target);
        $target["_method"] = $method;

        $route = _makeRoute($template, $target, $options);
        _collection.add($route, $options);

        return $route;
    }

    /**
     * Load routes from a plugin.
     *
     * The routes file will have a local variable named `$routes` made available which contains
     * the current RouteBuilder instance.
     *
     * @param string aName The plugin name
     * @return this
     * @throws uim.cake.Core\exceptions.MissingPluginException When the plugin has not been loaded.
     * @throws \InvalidArgumentException When the plugin does not have a routes file.
     */
    function loadPlugin(string aName) {
        $plugins = Plugin::getCollection();
        if (!$plugins.has($name)) {
            throw new MissingPluginException(["plugin": $name]);
        }
        $plugin = $plugins.get($name);
        $plugin.routes(this);

        // Disable the routes hook to prevent duplicate route issues.
        $plugin.disable("routes");

        return this;
    }

    /**
     * Connects a new Route.
     *
     * Routes are a way of connecting request URLs to objects in your application.
     * At their core routes are a set or regular expressions that are used to
     * match requests to destinations.
     *
     * Examples:
     *
     * ```
     * $routes.connect("/{controller}/{action}/*");
     * ```
     *
     * The first parameter will be used as a controller name while the second is
     * used as the action name. The "/*" syntax makes this route greedy in that
     * it will match requests like `/posts/index` as well as requests
     * like `/posts/edit/1/foo/bar`.
     *
     * ```
     * $routes.connect("/home-page", ["controller": "Pages", "action": "display", "home"]);
     * ```
     *
     * The above shows the use of route parameter defaults. And providing routing
     * parameters for a static route.
     *
     * ```
     * $routes.connect(
     *   "/{lang}/{controller}/{action}/{id}",
     *   [],
     *   ["id": "[0-9]+", "lang": "[a-z]{3}"]
     * );
     * ```
     *
     * Shows connecting a route with custom route parameters as well as
     * providing patterns for those parameters. Patterns for routing parameters
     * do not need capturing groups, as one will be added for each route params.
     *
     * $options offers several "special" keys that have special meaning
     * in the $options array.
     *
     * - `routeClass` is used to extend and change how individual routes parse requests
     *   and handle reverse routing, via a custom routing class.
     *   Ex. `"routeClass": "SlugRoute"`
     * - `pass` is used to define which of the routed parameters should be shifted
     *   into the pass array. Adding a parameter to pass will remove it from the
     *   regular route array. Ex. `"pass": ["slug"]`.
     * -  `persist` is used to define which route parameters should be automatically
     *   included when generating new URLs. You can override persistent parameters
     *   by redefining them in a URL or remove them by setting the parameter to `false`.
     *   Ex. `"persist": ["lang"]`
     * - `multibytePattern` Set to true to enable multibyte pattern support in route
     *   parameter patterns.
     * - `_name` is used to define a specific name for routes. This can be used to optimize
     *   reverse routing lookups. If undefined a name will be generated for each
     *   connected route.
     * - `_ext` is an array of filename extensions that will be parsed out of the url if present.
     *   See {@link uim.cake.routings.RouteCollection::setExtensions()}.
     * - `_method` Only match requests with specific HTTP verbs.
     * - `_host` - Define the host name pattern if you want this route to only match
     *   specific host names. You can use `.*` and to create wildcard subdomains/hosts
     *   e.g. `*.example.com` matches all subdomains on `example.com`.
     * - "_port` - Define the port if you want this route to only match specific port number.
     *
     * Example of using the `_method` condition:
     *
     * ```
     * $routes.connect("/tasks", ["controller": "Tasks", "action": "index", "_method": "GET"]);
     * ```
     *
     * The above route will only be matched for GET requests. POST requests will fail to match this route.
     *
     * @param uim.cake.routings.Route\Route|string $route A string describing the template of the route
     * @param array|string $defaults An array describing the default route parameters.
     *   These parameters will be used by default and can supply routing parameters that are not dynamic. See above.
     * @param array<string, mixed> $options An array matching the named elements in the route to regular expressions which that
     *   element should match. Also contains additional parameters such as which routed parameters should be
     *   shifted into the passed arguments, supplying patterns for routing parameters and supplying the name of a
     *   custom routing class.
     * @return uim.cake.routings.Route\Route
     * @throws \InvalidArgumentException
     * @throws \BadMethodCallException
     */
    function connect($route, $defaults = [], array $options = []): Route
    {
        $defaults = this.parseDefaults($defaults);
        if (empty($options["_ext"])) {
            $options["_ext"] = _extensions;
        }
        if (empty($options["routeClass"])) {
            $options["routeClass"] = _routeClass;
        }
        if (isset($options["_name"]) && _namePrefix) {
            $options["_name"] = _namePrefix . $options["_name"];
        }
        if (empty($options["_middleware"])) {
            $options["_middleware"] = this.middleware;
        }

        $route = _makeRoute($route, $defaults, $options);
        _collection.add($route, $options);

        return $route;
    }

    /**
     * Parse the defaults if they"re a string
     *
     * @param array|string $defaults Defaults array from the connect() method.
     * @return array
     */
    protected function parseDefaults($defaults): array
    {
        if (!is_string($defaults)) {
            return $defaults;
        }

        return Router::parseRoutePath($defaults);
    }

    /**
     * Create a route object, or return the provided object.
     *
     * @param uim.cake.routings.Route\Route|string $route The route template or route object.
     * @param array $defaults Default parameters.
     * @param array<string, mixed> $options Additional options parameters.
     * @return uim.cake.routings.Route\Route
     * @throws \InvalidArgumentException when route class or route object is invalid.
     * @throws \BadMethodCallException when the route to make conflicts with the current scope
     */
    protected function _makeRoute($route, $defaults, $options): Route
    {
        if (is_string($route)) {
            /** @var class-string<uim.cake.routings.Route\Route>|null $routeClass */
            $routeClass = App::className($options["routeClass"], "Routing/Route");
            if ($routeClass == null) {
                throw new InvalidArgumentException(sprintf(
                    "Cannot find route class %s",
                    $options["routeClass"]
                ));
            }

            $route = str_replace("//", "/", _path . $route);
            if ($route != "/") {
                $route = rtrim($route, "/");
            }

            foreach (_params as $param: $val) {
                if (isset($defaults[$param]) && $param != "prefix" && $defaults[$param] != $val) {
                    $msg = "You cannot define routes that conflict with the scope~ " ~
                        "Scope had %s = %s, while route had %s = %s";
                    throw new BadMethodCallException(sprintf(
                        $msg,
                        $param,
                        $val,
                        $param,
                        $defaults[$param]
                    ));
                }
            }
            $defaults += _params + ["plugin": null];
            if (!isset($defaults["action"]) && !isset($options["action"])) {
                $defaults["action"] = "index";
            }

            $route = new $routeClass($route, $defaults, $options);
        }

        return $route;
    }

    /**
     * Connects a new redirection Route in the router.
     *
     * Redirection routes are different from normal routes as they perform an actual
     * header redirection if a match is found. The redirection can occur within your
     * application or redirect to an outside location.
     *
     * Examples:
     *
     * ```
     * $routes.redirect("/home/*", ["controller": "Posts", "action": "view"]);
     * ```
     *
     * Redirects /home/* to /posts/view and passes the parameters to /posts/view. Using an array as the
     * redirect destination allows you to use other routes to define where a URL string should be redirected to.
     *
     * ```
     * $routes.redirect("/posts/*", "http://google.com", ["status": 302]);
     * ```
     *
     * Redirects /posts/* to http://google.com with a HTTP status of 302
     *
     * ### Options:
     *
     * - `status` Sets the HTTP status (default 301)
     * - `persist` Passes the params to the redirected route, if it can. This is useful with greedy routes,
     *   routes that end in `*` are greedy. As you can remap URLs and not lose any passed args.
     *
     * @param string $route A string describing the template of the route
     * @param array|string $url A URL to redirect to. Can be a string or a Cake array-based URL
     * @param array<string, mixed> $options An array matching the named elements in the route to regular expressions which that
     *   element should match. Also contains additional parameters such as which routed parameters should be
     *   shifted into the passed arguments. As well as supplying patterns for routing parameters.
     * @return uim.cake.routings.Route\Route|uim.cake.routings.Route\RedirectRoute
     */
    function redirect(string $route, $url, array $options = []): Route
    {
        $options["routeClass"] = $options["routeClass"] ?? RedirectRoute::class;
        if (is_string($url)) {
            $url = ["redirect": $url];
        }

        return this.connect($route, $url, $options);
    }

    /**
     * Add prefixed routes.
     *
     * This method creates a scoped route collection that includes
     * relevant prefix information.
     *
     * The $name parameter is used to generate the routing parameter name.
     * For example a path of `admin` would result in `"prefix": "admin"` being
     * applied to all connected routes.
     *
     * You can re-open a prefix as many times as necessary, as well as nest prefixes.
     * Nested prefixes will result in prefix values like `admin/api` which translates
     * to the `Controller\Admin\Api\` namespace.
     *
     * If you need to have prefix with dots, eg: "/api/v1.0", use "path" key
     * for $params argument:
     *
     * ```
     * $route.prefix("Api", function($route) {
     *     $route.prefix("V10", ["path": "/v1.0"], function($route) {
     *         // Translates to `Controller\Api\V10\` namespace
     *     });
     * });
     * ```
     *
     * @param string aName The prefix name to use.
     * @param callable|array $params An array of routing defaults to add to each connected route.
     *   If you have no parameters, this argument can be a callable.
     * @param callable|null $callback The callback to invoke that builds the prefixed routes.
     * @return this
     * @throws \InvalidArgumentException If a valid callback is not passed
     */
    function prefix(string aName, $params = [], $callback = null) {
        if (!is_array($params)) {
            $callback = $params;
            $params = [];
        }
        $path = "/" ~ Inflector::dasherize($name);
        $name = Inflector::camelize($name);
        if (isset($params["path"])) {
            $path = $params["path"];
            unset($params["path"]);
        }
        if (isset(_params["prefix"])) {
            $name = _params["prefix"] ~ "/" ~ $name;
        }
        $params = array_merge($params, ["prefix": $name]);
        this.scope($path, $params, $callback);

        return this;
    }

    /**
     * Add plugin routes.
     *
     * This method creates a new scoped route collection that includes
     * relevant plugin information.
     *
     * The plugin name will be inflected to the underscore version to create
     * the routing path. If you want a custom path name, use the `path` option.
     *
     * Routes connected in the scoped collection will have the correct path segment
     * prepended, and have a matching plugin routing key set.
     *
     * ### Options
     *
     * - `path` The path prefix to use. Defaults to `Inflector::dasherize($name)`.
     * - `_namePrefix` Set a prefix used for named routes. The prefix is prepended to the
     *   name of any route created in a scope callback.
     *
     * @param string aName The plugin name to build routes for
     * @param callable|array $options Either the options to use, or a callback to build routes.
     * @param callable|null $callback The callback to invoke that builds the plugin routes
     *   Only required when $options is defined.
     * @return this
     */
    function plugin(string aName, $options = [], $callback = null) {
        if (!is_array($options)) {
            $callback = $options;
            $options = [];
        }

        $path = $options["path"] ?? "/" ~ Inflector::dasherize($name);
        unset($options["path"]);
        $options = ["plugin": $name] + $options;
        this.scope($path, $options, $callback);

        return this;
    }

    /**
     * Create a new routing scope.
     *
     * Scopes created with this method will inherit the properties of the scope they are
     * added to. This means that both the current path and parameters will be appended
     * to the supplied parameters.
     *
     * ### Special Keys in $params
     *
     * - `_namePrefix` Set a prefix used for named routes. The prefix is prepended to the
     *   name of any route created in a scope callback.
     *
     * @param string $path The path to create a scope for.
     * @param callable|array $params Either the parameters to add to routes, or a callback.
     * @param callable|null $callback The callback to invoke that builds the plugin routes.
     *   Only required when $params is defined.
     * @return this
     * @throws \InvalidArgumentException when there is no callable parameter.
     */
    function scope(string $path, $params, $callback = null) {
        if (!is_array($params)) {
            $callback = $params;
            $params = [];
        }
        if (!is_callable($callback)) {
            throw new InvalidArgumentException(sprintf(
                "Need a valid callable to connect routes. Got `%s` instead.",
                getTypeName($callback)
            ));
        }

        if (_path != "/") {
            $path = _path . $path;
        }
        $namePrefix = _namePrefix;
        if (isset($params["_namePrefix"])) {
            $namePrefix .= $params["_namePrefix"];
        }
        unset($params["_namePrefix"]);

        $params += _params;
        $builder = new static(_collection, $path, $params, [
            "routeClass": _routeClass,
            "extensions": _extensions,
            "namePrefix": $namePrefix,
            "middleware": this.middleware,
        ]);
        $callback($builder);

        return this;
    }

    /**
     * Connect the `/{controller}` and `/{controller}/{action}/*` fallback routes.
     *
     * This is a shortcut method for connecting fallback routes in a given scope.
     *
     * @param string|null $routeClass the route class to use, uses the default routeClass
     *   if not specified
     * @return this
     */
    function fallbacks(?string $routeClass = null) {
        $routeClass = $routeClass ?: _routeClass;
        this.connect("/{controller}", ["action": "index"], compact("routeClass"));
        this.connect("/{controller}/{action}/*", [], compact("routeClass"));

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
     * @see uim.cake.routings.RouteCollection
     */
    function registerMiddleware(string aName, $middleware) {
        _collection.registerMiddleware($name, $middleware);

        return this;
    }

    /**
     * Apply a middleware to the current route scope.
     *
     * Requires middleware to be registered via `registerMiddleware()`
     *
     * @param string ...$names The names of the middleware to apply to the current scope.
     * @return this
     * @throws \RuntimeException
     * @see uim.cake.routings.RouteCollection::addMiddlewareToScope()
     */
    function applyMiddleware(string ...$names) {
        foreach ($names as $name) {
            if (!_collection.middlewareExists($name)) {
                $message = "Cannot apply "$name" middleware or middleware group~ " ~
                    "Use registerMiddleware() to register middleware.";
                throw new RuntimeException($message);
            }
        }
        this.middleware = array_unique(array_merge(this.middleware, $names));

        return this;
    }

    /**
     * Get the middleware that this builder will apply to routes.
     */
    array getMiddleware(): array
    {
        return this.middleware;
    }

    /**
     * Apply a set of middleware to a group
     *
     * @param string aName Name of the middleware group
     * @param array<string> $middlewareNames Names of the middleware
     * @return this
     */
    function middlewareGroup(string aName, array $middlewareNames) {
        _collection.middlewareGroup($name, $middlewareNames);

        return this;
    }
}
