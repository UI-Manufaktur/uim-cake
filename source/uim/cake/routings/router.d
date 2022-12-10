
module uim.cakeuting.router;

@safe:
import uim.cake;

/**
 * Parses the request URL into controller, action, and parameters. Uses the connected routes
 * to match the incoming URL string to parameters that will allow the request to be dispatched. Also
 * handles converting parameter lists into URL strings, using the connected routes. Routing allows you to decouple
 * the way the world interacts with your application (URLs) and the implementation (controllers and actions).
 *
 * ### Connecting routes
 *
 * Connecting routes is done using Router::connect(). When parsing incoming requests or reverse matching
 * parameters, routes are enumerated in the order they were connected. For more information on routes and
 * how to connect them see Router::connect().
 */
class Router
{
    /**
     * Default route class.
     */
    protected string static $_defaultRouteClass = Route\Route::class;

    /**
     * Contains the base string that will be applied to all generated URLs
     * For example `https://example.com`
     *
     * @var string|null
     */
    protected static $_fullBaseUrl;

    /**
     * Regular expression for action names
     */
    public const string ACTION = "index|show|add|create|edit|update|remove|del|delete|view|item";

    /**
     * Regular expression for years
     */
    public const string YEAR = "[12][0-9]{3}";

    /**
     * Regular expression for months
     */
    public const string MONTH = "0[1-9]|1[012]";

    /**
     * Regular expression for days
     */
    public const string DAY = "0[1-9]|[12][0-9]|3[01]";

    /**
     * Regular expression for auto increment IDs
     */
    public const string ID = "[0-9]+";

    /**
     * Regular expression for UUIDs
     */
    public const string UUID = "[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}";

    /**
     * The route collection routes would be added to.
     *
     * @var \Cake\Routing\RouteCollection
     */
    protected static $_collection;

    /**
     * A hash of request context data.
     *
     * @var array
     */
    protected static $_requestContext = [];

    /**
     * Named expressions
     *
     * @var array<string, string>
     */
    protected static $_namedExpressions = [
        "Action" => Router::ACTION,
        "Year" => Router::YEAR,
        "Month" => Router::MONTH,
        "Day" => Router::DAY,
        "ID" => Router::ID,
        "UUID" => Router::UUID,
    ];

    /**
     * Maintains the request object reference.
     *
     * @var \Cake\Http\ServerRequest
     */
    protected static $_request;

    /**
     * Initial state is populated the first time reload() is called which is at the bottom
     * of this file. This is a cheat as get_class_vars() returns the value of static vars even if they
     * have changed.
     *
     * @var array
     */
    protected static $_initialState = [];

    /**
     * The stack of URL filters to apply against routing URLs before passing the
     * parameters to the route collection.
     *
     * @var array<callable>
     */
    protected static $_urlFilters = [];

    /**
     * Default extensions defined with Router::extensions()
     *
     * @var array<string>
     */
    protected static $_defaultExtensions = [];

    /**
     * Cache of parsed route paths
     *
     * @var array
     */
    protected static $_routePaths = [];

    /**
     * Get or set default route class.
     *
     * @param string|null $routeClass Class name.
     * @return string|null
     */
    static function defaultRouteClass(Nullable!string $routeClass = null): Nullable!string
    {
        if ($routeClass == null) {
            return static::$_defaultRouteClass;
        }
        static::$_defaultRouteClass = $routeClass;

        return null;
    }

    /**
     * Gets the named route patterns for use in config/routes.php
     *
     * @return Named route elements
     * @see \Cake\Routing\Router::$_namedExpressions
     */
    static STRINGAA getNamedExpressions() {
        return static::$_namedExpressions;
    }

    /**
     * Connects a new Route in the router.
     *
     * Compatibility proxy to \Cake\Routing\RouteBuilder::connect() in the `/` scope.
     *
     * @param \Cake\Routing\Route\Route|string $route A string describing the template of the route
     * @param array|string $defaults An array describing the default route parameters.
     *   These parameters will be used by default and can supply routing parameters that are not dynamic. See above.
     * @param array<string, mixed> myOptions An array matching the named elements in the route to regular expressions which that
     *   element should match. Also contains additional parameters such as which routed parameters should be
     *   shifted into the passed arguments, supplying patterns for routing parameters and supplying the name of a
     *   custom routing class.
     * @return void
     * @throws \Cake\Core\Exception\CakeException
     * @see \Cake\Routing\RouteBuilder::connect()
     * @see \Cake\Routing\Router::scope()
     * @deprecated 4.3.0 Use the non-static method `RouteBuilder::connect()` instead.
     */
    static function connect($route, $defaults = [], myOptions = []): void
    {
        deprecationWarning(
            "`Router::connect()` is deprecated, use the non-static method `RouteBuilder::connect()` instead."
        );

        static::scope("/", function ($routes) use ($route, $defaults, myOptions): void {
            /** @var \Cake\Routing\RouteBuilder $routes */
            $routes.connect($route, $defaults, myOptions);
        });
    }

    /**
     * Get the routing parameters for the request is possible.
     *
     * @param \Cake\Http\ServerRequest myRequest The request to parse request data from.
     * @return array Parsed elements from URL.
     * @throws \Cake\Routing\Exception\MissingRouteException When a route cannot be handled
     */
    static function parseRequest(ServerRequest myRequest): array
    {
        return static::$_collection.parseRequest(myRequest);
    }

    /**
     * Set current request instance.
     *
     * @param \Cake\Http\ServerRequest myRequest request object.
     * @return void
     */
    static auto setRequest(ServerRequest myRequest): void
    {
        static::$_request = myRequest;

        static::$_requestContext["_base"] = myRequest.getAttribute("base");
        static::$_requestContext["params"] = myRequest.getAttribute("params", []);

        $uri = myRequest.getUri();
        static::$_requestContext += [
            "_scheme" => $uri.getScheme(),
            "_host" => $uri.getHost(),
            "_port" => $uri.getPort(),
        ];
    }

    /**
     * Get the current request object.
     *
     * @return \Cake\Http\ServerRequest|null
     */
    static auto getRequest(): ?ServerRequest
    {
        return static::$_request;
    }

    /**
     * Reloads default Router settings. Resets all class variables and
     * removes all connected routes.
     *
     * @return void
     */
    static function reload(): void
    {
        if (empty(static::$_initialState)) {
            static::$_collection = new RouteCollection();
            static::$_initialState = get_class_vars(static::class);

            return;
        }
        foreach (static::$_initialState as myKey => $val) {
            if (myKey !== "_initialState") {
                static::${myKey} = $val;
            }
        }
        static::$_collection = new RouteCollection();
    }

    /**
     * Reset routes and related state.
     *
     * Similar to reload() except that this doesn"t reset all global state,
     * as that leads to incorrect behavior in some plugin test case scenarios.
     *
     * This method will reset:
     *
     * - routes
     * - URL Filters
     * - the initialized property
     *
     * Extensions and default route classes will not be modified
     *
     * @internal
     * @return void
     */
    static function resetRoutes(): void
    {
        static::$_collection = new RouteCollection();
        static::$_urlFilters = [];
    }

    /**
     * Add a URL filter to Router.
     *
     * URL filter functions are applied to every array myUrl provided to
     * Router::url() before the URLs are sent to the route collection.
     *
     * Callback functions should expect the following parameters:
     *
     * - `myParams` The URL params being processed.
     * - `myRequest` The current request.
     *
     * The URL filter function should *always* return the params even if unmodified.
     *
     * ### Usage
     *
     * URL filters allow you to easily implement features like persistent parameters.
     *
     * ```
     * Router::addUrlFilter(function (myParams, myRequest) {
     *  if (myRequest.getParam("lang") && !isset(myParams["lang"])) {
     *    myParams["lang"] = myRequest.getParam("lang");
     *  }
     *  return myParams;
     * });
     * ```
     *
     * @param callable $function The function to add
     * @return void
     */
    static function addUrlFilter(callable $function): void
    {
        static::$_urlFilters[] = $function;
    }

    /**
     * Applies all the connected URL filters to the URL.
     *
     * @param array myUrl The URL array being modified.
     * @return array The modified URL.
     * @see \Cake\Routing\Router::url()
     * @see \Cake\Routing\Router::addUrlFilter()
     */
    protected static auto _applyUrlFilters(array myUrl): array
    {
        myRequest = static::getRequest();
        foreach (static::$_urlFilters as $filter) {
            try {
                myUrl = $filter(myUrl, myRequest);
            } catch (Throwable $e) {
                if (is_array($filter)) {
                    $ref = new ReflectionMethod($filter[0], $filter[1]);
                } else {
                    /** @psalm-var \Closure|callable-string $filter */
                    $ref = new ReflectionFunction($filter);
                }
                myMessage = sprintf(
                    "URL filter defined in %s on line %s could not be applied. The filter failed with: %s",
                    $ref.getFileName(),
                    $ref.getStartLine(),
                    $e.getMessage()
                );
                throw new RuntimeException(myMessage, (int)$e.getCode(), $e);
            }
        }

        return myUrl;
    }

    /**
     * Finds URL for specified action.
     *
     * Returns a URL pointing to a combination of controller and action.
     *
     * ### Usage
     *
     * - `Router::url("/posts/edit/1");` Returns the string with the base dir prepended.
     *   This usage does not use reverser routing.
     * - `Router::url(["controller" => "Posts", "action" => "edit"]);` Returns a URL
     *   generated through reverse routing.
     * - `Router::url(["_name" => "custom-name", ...]);` Returns a URL generated
     *   through reverse routing. This form allows you to leverage named routes.
     *
     * There are a few "special" parameters that can change the final URL string that is generated
     *
     * - `_base` - Set to false to remove the base path from the generated URL. If your application
     *   is not in the root directory, this can be used to generate URLs that are "cake relative".
     *   cake relative URLs are required when using requestAction.
     * - `_scheme` - Set to create links on different schemes like `webcal` or `ftp`. Defaults
     *   to the current scheme.
     * - `_host` - Set the host to use for the link. Defaults to the current host.
     * - `_port` - Set the port if you need to create links on non-standard ports.
     * - `_full` - If true output of `Router::fullBaseUrl()` will be prepended to generated URLs.
     * - `#` - Allows you to set URL hash fragments.
     * - `_ssl` - Set to true to convert the generated URL to https, or false to force http.
     * - `_name` - Name of route. If you have setup named routes you can use this key
     *   to specify it.
     *
     * @param \Psr\Http\Message\UriInterface|array|string|null myUrl An array specifying any of the following:
     *   "controller", "action", "plugin" additionally, you can provide routed
     *   elements or query string parameters. If string it can be name any valid url
     *   string or it can be an UriInterface instance.
     * @param bool $full If true, the full base URL will be prepended to the result.
     *   Default is false.
     * @return string Full translated URL with base path.
     * @throws \Cake\Core\Exception\CakeException When the route name is not found
     */
    static string url(myUrl = null, bool $full = false) {
        $context = static::$_requestContext;
        myRequest = static::getRequest();

        $context["_base"] = $context["_base"] ?? Configure::read("App.base") ?: "";

        if (empty(myUrl)) {
            $here = myRequest ? myRequest.getRequestTarget() : "/";
            $output = $context["_base"] . $here;
            if ($full) {
                $output = static::fullBaseUrl() . $output;
            }

            return $output;
        }

        myParams = [
            "plugin" => null,
            "controller" => null,
            "action" => "index",
            "_ext" => null,
        ];
        if (!empty($context["params"])) {
            myParams = $context["params"];
        }

        $frag = "";

        if (is_array(myUrl)) {
            if (isset(myUrl["_path"])) {
                myUrl = self::unwrapShortString(myUrl);
            }

            if (isset(myUrl["_ssl"])) {
                myUrl["_scheme"] = myUrl["_ssl"] == true ? "https" : "http";
            }

            if (isset(myUrl["_full"]) && myUrl["_full"] == true) {
                $full = true;
            }
            if (isset(myUrl["#"])) {
                $frag = "#" . myUrl["#"];
            }
            unset(myUrl["_ssl"], myUrl["_full"], myUrl["#"]);

            myUrl = static::_applyUrlFilters(myUrl);

            if (!isset(myUrl["_name"])) {
                // Copy the current action if the controller is the current one.
                if (
                    empty(myUrl["action"]) &&
                    (
                        empty(myUrl["controller"]) ||
                        myParams["controller"] == myUrl["controller"]
                    )
                ) {
                    myUrl["action"] = myParams["action"];
                }

                // Keep the current prefix around if none set.
                if (isset(myParams["prefix"]) && !isset(myUrl["prefix"])) {
                    myUrl["prefix"] = myParams["prefix"];
                }

                myUrl += [
                    "plugin" => myParams["plugin"],
                    "controller" => myParams["controller"],
                    "action" => "index",
                    "_ext" => null,
                ];
            }

            // If a full URL is requested with a scheme the host should default
            // to App.fullBaseUrl to avoid corrupt URLs
            if ($full && isset(myUrl["_scheme"]) && !isset(myUrl["_host"])) {
                myUrl["_host"] = $context["_host"];
            }
            $context["params"] = myParams;

            $output = static::$_collection.match(myUrl, $context);
        } else {
            myUrl = (string)myUrl;

            $plainString = (
                strpos(myUrl, "javascript:") == 0 ||
                strpos(myUrl, "mailto:") == 0 ||
                strpos(myUrl, "tel:") == 0 ||
                strpos(myUrl, "sms:") == 0 ||
                strpos(myUrl, "#") == 0 ||
                strpos(myUrl, "?") == 0 ||
                strpos(myUrl, "//") == 0 ||
                strpos(myUrl, "://") !== false
            );

            if ($plainString) {
                return myUrl;
            }
            $output = $context["_base"] . myUrl;
        }

        $protocol = preg_match("#^[a-z][a-z0-9+\-.]*\://#i", $output);
        if ($protocol == 0) {
            $output = str_replace("//", "/", "/" . $output);
            if ($full) {
                $output = static::fullBaseUrl() . $output;
            }
        }

        return $output . $frag;
    }

    /**
     * Generate URL for route path.
     *
     * Route path examples:
     * - Bookmarks::view
     * - Admin/Bookmarks::view
     * - Cms.Articles::edit
     * - Vendor/Cms.Management/Admin/Articles::view
     *
     * @param string myPath Route path specifying controller and action, optionally with plugin and prefix.
     * @param array myParams An array specifying any additional parameters.
     *   Can be also any special parameters supported by `Router::url()`.
     * @param bool $full If true, the full base URL will be prepended to the result.
     *   Default is false.
     * @return string Full translated URL with base path.
     */
    static string pathUrl(string myPath, array myParams = [], bool $full = false) {
        return static::url(["_path" => myPath] + myParams, $full);
    }

    /**
     * Finds URL for specified action.
     *
     * Returns a bool if the url exists
     *
     * ### Usage
     *
     * @see Router::url()
     * @param array|string|null myUrl An array specifying any of the following:
     *   "controller", "action", "plugin" additionally, you can provide routed
     *   elements or query string parameters. If string it can be name any valid url
     *   string.
     * @param bool $full If true, the full base URL will be prepended to the result.
     *   Default is false.
     * @return bool
     */
    static bool routeExists(myUrl = null, bool $full = false) {
        try {
            static::url(myUrl, $full);

            return true;
        } catch (MissingRouteException $e) {
            return false;
        }
    }

    /**
     * Sets the full base URL that will be used as a prefix for generating
     * fully qualified URLs for this application. If no parameters are passed,
     * the currently configured value is returned.
     *
     * ### Note:
     *
     * If you change the configuration value `App.fullBaseUrl` during runtime
     * and expect the router to produce links using the new setting, you are
     * required to call this method passing such value again.
     *
     * @param string|null $base the prefix for URLs generated containing the domain.
     * For example: `http://example.com`
     * @return string
     */
    static string fullBaseUrl(Nullable!string $base = null) {
        if ($base == null && static::$_fullBaseUrl !== null) {
            return static::$_fullBaseUrl;
        }

        if ($base !== null) {
            static::$_fullBaseUrl = $base;
            Configure.write("App.fullBaseUrl", $base);
        } else {
            $base = (string)Configure::read("App.fullBaseUrl");

            // If App.fullBaseUrl is empty but context is set from request through setRequest()
            if (!$base && !empty(static::$_requestContext["_host"])) {
                $base = sprintf(
                    "%s://%s",
                    static::$_requestContext["_scheme"],
                    static::$_requestContext["_host"]
                );
                if (!empty(static::$_requestContext["_port"])) {
                    $base .= ":" . static::$_requestContext["_port"];
                }

                Configure.write("App.fullBaseUrl", $base);

                return static::$_fullBaseUrl = $base;
            }

            static::$_fullBaseUrl = $base;
        }

        $parts = parse_url(static::$_fullBaseUrl);
        static::$_requestContext = [
            "_scheme" => $parts["scheme"] ?? null,
            "_host" => $parts["host"] ?? null,
            "_port" => $parts["port"] ?? null,
        ] + static::$_requestContext;

        return static::$_fullBaseUrl;
    }

    /**
     * Reverses a parsed parameter array into an array.
     *
     * Works similarly to Router::url(), but since parsed URL"s contain additional
     * keys like "pass", "_matchedRoute" etc. those keys need to be specially
     * handled in order to reverse a params array into a string URL.
     *
     * @param \Cake\Http\ServerRequest|array myParams The params array or
     *     Cake\Http\ServerRequest object that needs to be reversed.
     * @return array The URL array ready to be used for redirect or HTML link.
     */
    static function reverseToArray(myParams): array
    {
        if (myParams instanceof ServerRequest) {
            myQueryString = myParams.getQueryParams();
            myParams = myParams.getAttribute("params");
            myParams["?"] = myQueryString;
        }
        $pass = myParams["pass"] ?? [];

        unset(
            myParams["pass"],
            myParams["_matchedRoute"],
            myParams["_name"]
        );
        myParams = array_merge(myParams, $pass);

        return myParams;
    }

    /**
     * Reverses a parsed parameter array into a string.
     *
     * Works similarly to Router::url(), but since parsed URL"s contain additional
     * keys like "pass", "_matchedRoute" etc. those keys need to be specially
     * handled in order to reverse a params array into a string URL.
     *
     * @param \Cake\Http\ServerRequest|array myParams The params array or
     *     Cake\Http\ServerRequest object that needs to be reversed.
     * @param bool $full Set to true to include the full URL including the
     *     protocol when reversing the URL.
     * @return string The string that is the reversed result of the array
     */
    static string reverse(myParams, $full = false) {
        myParams = static::reverseToArray(myParams);

        return static::url(myParams, $full);
    }

    /**
     * Normalizes a URL for purposes of comparison.
     *
     * Will strip the base path off and replace any double /"s.
     * It will not unify the casing and underscoring of the input value.
     *
     * @param array|string myUrl URL to normalize Either an array or a string URL.
     * @return string Normalized URL
     */
    static string normalize(myUrl = "/") {
        if (is_array(myUrl)) {
            myUrl = static::url(myUrl);
        }
        if (preg_match("/^[a-z\-]+:\/\//", myUrl)) {
            return myUrl;
        }
        myRequest = static::getRequest();

        if (myRequest) {
            $base = myRequest.getAttribute("base", "");
            if ($base !== "" && stristr(myUrl, $base)) {
                myUrl = preg_replace("/^" . preg_quote($base, "/") . "/", "", myUrl, 1);
            }
        }
        myUrl = "/" . myUrl;

        while (strpos(myUrl, "//") !== false) {
            myUrl = str_replace("//", "/", myUrl);
        }
        myUrl = preg_replace("/(?:(\/$))/", "", myUrl);

        if (empty(myUrl)) {
            return "/";
        }

        return myUrl;
    }

    /**
     * Get or set valid extensions for all routes connected later.
     *
     * Instructs the router to parse out file extensions
     * from the URL. For example, http://example.com/posts.rss would yield a file
     * extension of "rss". The file extension itself is made available in the
     * controller as `this.request.getParam("_ext")`, and is used by the RequestHandler
     * component to automatically switch to alternate layouts and templates, and
     * load helpers corresponding to the given content, i.e. RssHelper. Switching
     * layouts and helpers requires that the chosen extension has a defined mime type
     * in `Cake\Http\Response`.
     *
     * A string or an array of valid extensions can be passed to this method.
     * If called without any parameters it will return current list of set extensions.
     *
     * @param array<string>|string|null $extensions List of extensions to be added.
     * @param bool myMerge Whether to merge with or override existing extensions.
     *   Defaults to `true`.
     * @return Array of extensions Router is configured to parse.
     */
    static string[] extensions($extensions = null, myMerge = true) {
        myCollection = static::$_collection;
        if ($extensions == null) {
            return array_unique(array_merge(static::$_defaultExtensions, myCollection.getExtensions()));
        }

        $extensions = (array)$extensions;
        if (myMerge) {
            $extensions = array_unique(array_merge(static::$_defaultExtensions, $extensions));
        }

        return static::$_defaultExtensions = $extensions;
    }

    /**
     * Create a RouteBuilder for the provided path.
     *
     * @param string myPath The path to set the builder to.
     * @param array<string, mixed> myOptions The options for the builder
     * @return \Cake\Routing\RouteBuilder
     */
    static function createRouteBuilder(string myPath, array myOptions = []): RouteBuilder
    {
        $defaults = [
            "routeClass" => static::defaultRouteClass(),
            "extensions" => static::$_defaultExtensions,
        ];
        myOptions += $defaults;

        return new RouteBuilder(static::$_collection, myPath, [], [
            "routeClass" => myOptions["routeClass"],
            "extensions" => myOptions["extensions"],
        ]);
    }

    /**
     * Create a routing scope.
     *
     * Routing scopes allow you to keep your routes DRY and avoid repeating
     * common path prefixes, and or parameter sets.
     *
     * Scoped collections will be indexed by path for faster route parsing. If you
     * re-open or re-use a scope the connected routes will be merged with the
     * existing ones.
     *
     * ### Options
     *
     * The `myParams` array allows you to define options for the routing scope.
     * The options listed below *are not* available to be used as routing defaults
     *
     * - `routeClass` The route class to use in this scope. Defaults to
     *   `Router::defaultRouteClass()`
     * - `extensions` The extensions to enable in this scope. Defaults to the globally
     *   enabled extensions set with `Router::extensions()`
     *
     * ### Example
     *
     * ```
     * Router::scope("/blog", ["plugin" => "Blog"], function ($routes) {
     *    $routes.connect("/", ["controller" => "Articles"]);
     * });
     * ```
     *
     * The above would result in a `/blog/` route being created, with both the
     * plugin & controller default parameters set.
     *
     * You can use `Router::plugin()` and `Router::prefix()` as shortcuts to creating
     * specific kinds of scopes.
     *
     * @param string myPath The path prefix for the scope. This path will be prepended
     *   to all routes connected in the scoped collection.
     * @param callable|array myParams An array of routing defaults to add to each connected route.
     *   If you have no parameters, this argument can be a callable.
     * @param callable|null $callback The callback to invoke with the scoped collection.
     * @throws \InvalidArgumentException When an invalid callable is provided.
     * @return void
     * @deprecated 4.3.0 Use the non-static method `RouteBuilder::scope()` instead.
     */
    static function scope(string myPath, myParams = [], $callback = null): void
    {
        deprecationWarning(
            "`Router::scope()` is deprecated, use the non-static method `RouteBuilder::scope()` instead."
        );

        myOptions = [];
        if (is_array(myParams)) {
            myOptions = myParams;
            unset(myParams["routeClass"], myParams["extensions"]);
        }
        myBuilder = static::createRouteBuilder("/", myOptions);
        myBuilder.scope(myPath, myParams, $callback);
    }

    /**
     * Create prefixed routes.
     *
     * This method creates a scoped route collection that includes
     * relevant prefix information.
     *
     * The path parameter is used to generate the routing parameter name.
     * For example a path of `admin` would result in `"prefix" => "Admin"` being
     * applied to all connected routes.
     *
     * The prefix name will be inflected to the dasherized version to create
     * the routing path. If you want a custom path name, use the `path` option.
     *
     * You can re-open a prefix as many times as necessary, as well as nest prefixes.
     * Nested prefixes will result in prefix values like `Admin/Api` which translates
     * to the `Controller\Admin\Api\` module.
     *
     * @param string myName The prefix name to use.
     * @param callable|array myParams An array of routing defaults to add to each connected route.
     *   If you have no parameters, this argument can be a callable.
     * @param callable|null $callback The callback to invoke that builds the prefixed routes.
     * @return void
     * @deprecated 4.3.0 Use the non-static method `RouteBuilder::prefix()` instead.
     */
    static function prefix(string myName, myParams = [], $callback = null): void
    {
        deprecationWarning(
            "`Router::prefix()` is deprecated, use the non-static method `RouteBuilder::prefix()` instead."
        );

        if (!is_array(myParams)) {
            $callback = myParams;
            myParams = [];
        }

        myPath = myParams["path"] ?? "/" . Inflector::dasherize(myName);
        unset(myParams["path"]);

        myParams = array_merge(myParams, ["prefix" => Inflector::camelize(myName)]);
        static::scope(myPath, myParams, $callback);
    }

    /**
     * Add plugin routes.
     *
     * This method creates a scoped route collection that includes
     * relevant plugin information.
     *
     * The plugin name will be inflected to the dasherized version to create
     * the routing path. If you want a custom path name, use the `path` option.
     *
     * Routes connected in the scoped collection will have the correct path segment
     * prepended, and have a matching plugin routing key set.
     *
     * @param string myName The plugin name to build routes for
     * @param callable|array myOptions Either the options to use, or a callback
     * @param callable|null $callback The callback to invoke that builds the plugin routes.
     *   Only required when myOptions is defined
     * @return void
     * @deprecated 4.3.0 Use the non-static method `RouteBuilder::plugin()` instead.
     */
    static function plugin(string myName, myOptions = [], $callback = null): void
    {
        deprecationWarning(
            "`Router::plugin()` is deprecated, use the non-static method `RouteBuilder::plugin()` instead."
        );

        if (!is_array(myOptions)) {
            $callback = myOptions;
            myOptions = [];
        }
        myParams = ["plugin" => myName];
        myPath = myOptions["path"] ?? "/" . Inflector::dasherize(myName);
        if (isset(myOptions["_namePrefix"])) {
            myParams["_namePrefix"] = myOptions["_namePrefix"];
        }
        static::scope(myPath, myParams, $callback);
    }

    /**
     * Get the route scopes and their connected routes.
     *
     * @return array<\Cake\Routing\Route\Route>
     */
    static function routes(): array
    {
        return static::$_collection.routes();
    }

    /**
     * Get the RouteCollection inside the Router
     *
     * @return \Cake\Routing\RouteCollection
     */
    static auto getRouteCollection(): RouteCollection
    {
        return static::$_collection;
    }

    /**
     * Set the RouteCollection inside the Router
     *
     * @param \Cake\Routing\RouteCollection $routeCollection route collection
     * @return void
     */
    static auto setRouteCollection(RouteCollection $routeCollection): void
    {
        static::$_collection = $routeCollection;
    }

    /**
     * Inject route defaults from `_path` key
     *
     * @param array myUrl Route array with `_path` key
     * @return array
     */
    protected static function unwrapShortString(array myUrl) {
        foreach (["plugin", "prefix", "controller", "action"] as myKey) {
            if (array_key_exists(myKey, myUrl)) {
                throw new InvalidArgumentException(
                    "`myKey` cannot be used when defining route targets with a string route path."
                );
            }
        }
        myUrl += static::parseRoutePath(myUrl["_path"]);
        myUrl += [
            "plugin" => false,
            "prefix" => false,
        ];
        unset(myUrl["_path"]);

        return myUrl;
    }

    /**
     * Parse a string route path
     *
     * String examples:
     * - Bookmarks::view
     * - Admin/Bookmarks::view
     * - Cms.Articles::edit
     * - Vendor/Cms.Management/Admin/Articles::view
     *
     * @param string myUrl Route path in [Plugin.][Prefix/]Controller::action format
     */
    static STRINGAA parseRoutePath(string myUrl): array
    {
        if (isset(static::$_routePaths[myUrl])) {
            return static::$_routePaths[myUrl];
        }

        $regex = "#^
            (?:(?<plugin>[a-z0-9]+(?:/[a-z0-9]+)*)\.)?
            (?:(?<prefix>[a-z0-9]+(?:/[a-z0-9]+)*)/)?
            (?<controller>[a-z0-9]+)
            ::
            (?<action>[a-z0-9_]+)
            $#ix";

        if (!preg_match($regex, myUrl, $matches)) {
            throw new InvalidArgumentException("Could not parse a string route path `{myUrl}`.");
        }

        $defaults = [];

        if ($matches["plugin"] !== "") {
            $defaults["plugin"] = $matches["plugin"];
        }
        if ($matches["prefix"] !== "") {
            $defaults["prefix"] = $matches["prefix"];
        }
        $defaults["controller"] = $matches["controller"];
        $defaults["action"] = $matches["action"];

        static::$_routePaths[myUrl] = $defaults;

        return $defaults;
    }
}
