

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         1.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Routing\Route;

use InvalidArgumentException;
use Psr\Http\Message\IServerRequest;

/**
 * A single Route used by the Router to connect requests to
 * parameter maps.
 *
 * Not normally created as a standalone. Use Router::connect() to create
 * Routes for your application.
 */
class Route
{
    /**
     * An array of named segments in a Route.
     * `/{controller}/{action}/{id}` has 3 key elements
     *
     * @var array
     */
    public myKeys = [];

    /**
     * An array of additional parameters for the Route.
     *
     * @var array
     */
    public myOptions = [];

    /**
     * Default parameters for a Route
     *
     * @var array
     */
    public $defaults = [];

    /**
     * The routes template string.
     *
     * @var string
     */
    public myTemplate;

    /**
     * Is this route a greedy route? Greedy routes have a `/*` in their
     * template
     *
     * @var bool
     */
    protected $_greedy = false;

    /**
     * The compiled route regular expression
     *
     * @var string|null
     */
    protected $_compiledRoute;

    /**
     * The name for a route. Fetch with Route::getName();
     *
     * @var string|null
     */
    protected $_name;

    /**
     * List of connected extensions for this route.
     *
     * @var array<string>
     */
    protected $_extensions = [];

    /**
     * List of middleware that should be applied.
     *
     * @var array
     */
    protected $middleware = [];

    /**
     * Track whether brace keys `{var}` were used.
     *
     * @var bool
     */
    protected $braceKeys = true;

    /**
     * Valid HTTP methods.
     *
     * @var array<string>
     */
    public const VALID_METHODS = ['GET', 'PUT', 'POST', 'PATCH', 'DELETE', 'OPTIONS', 'HEAD'];

    /**
     * Regex for matching braced placholders in route template.
     *
     * @var string
     */
    protected const PLACEHOLDER_REGEX = '#\{([a-z][a-z0-9-_]*)\}#i';

    /**
     * Constructor for a Route
     *
     * ### Options
     *
     * - `_ext` - Defines the extensions used for this route.
     * - `_middleware` - Define the middleware names for this route.
     * - `pass` - Copies the listed parameters into params['pass'].
     * - `_method` - Defines the HTTP method(s) the route applies to. It can be
     *   a string or array of valid HTTP method name.
     * - `_host` - Define the host name pattern if you want this route to only match
     *   specific host names. You can use `.*` and to create wildcard subdomains/hosts
     *   e.g. `*.example.com` matches all subdomains on `example.com`.
     * - '_port` - Define the port if you want this route to only match specific port number.
     *
     * @param string myTemplate Template string with parameter placeholders
     * @param array $defaults Defaults for the route.
     * @param array<string, mixed> myOptions Array of additional options for the Route
     * @throws \InvalidArgumentException When `myOptions['_method']` are not in `VALID_METHODS` list.
     */
    this(string myTemplate, array $defaults = [], array myOptions = [])
    {
        this.template = myTemplate;
        this.defaults = $defaults;
        this.options = myOptions + ['_ext' => [], '_middleware' => []];
        this.setExtensions((array)this.options['_ext']);
        this.setMiddleware((array)this.options['_middleware']);
        unset(this.options['_middleware']);

        if (isset(this.defaults['_method'])) {
            this.defaults['_method'] = this.normalizeAndValidateMethods(this.defaults['_method']);
        }
    }

    /**
     * Set the supported extensions for this route.
     *
     * @param array<string> $extensions The extensions to set.
     * @return this
     */
    auto setExtensions(array $extensions)
    {
        this._extensions = array_map('strtolower', $extensions);

        return this;
    }

    /**
     * Get the supported extensions for this route.
     *
     * @return array<string>
     */
    auto getExtensions(): array
    {
        return this._extensions;
    }

    /**
     * Set the accepted HTTP methods for this route.
     *
     * @param array<string> $methods The HTTP methods to accept.
     * @return this
     * @throws \InvalidArgumentException When methods are not in `VALID_METHODS` list.
     */
    auto setMethods(array $methods)
    {
        this.defaults['_method'] = this.normalizeAndValidateMethods($methods);

        return this;
    }

    /**
     * Normalize method names to upper case and validate that they are valid HTTP methods.
     *
     * @param array<string>|string $methods Methods.
     * @return array<string>|string
     * @throws \InvalidArgumentException When methods are not in `VALID_METHODS` list.
     */
    protected auto normalizeAndValidateMethods($methods)
    {
        $methods = is_array($methods)
            ? array_map('strtoupper', $methods)
            : strtoupper($methods);

        $diff = array_diff((array)$methods, static::VALID_METHODS);
        if ($diff !== []) {
            throw new InvalidArgumentException(
                sprintf('Invalid HTTP method received. `%s` is invalid.', implode(', ', $diff))
            );
        }

        return $methods;
    }

    /**
     * Set regexp patterns for routing parameters
     *
     * If any of your patterns contain multibyte values, the `multibytePattern`
     * mode will be enabled.
     *
     * @param array<string> $patterns The patterns to apply to routing elements
     * @return this
     */
    auto setPatterns(array $patterns)
    {
        $patternValues = implode('', $patterns);
        if (mb_strlen($patternValues) < strlen($patternValues)) {
            this.options['multibytePattern'] = true;
        }
        this.options = $patterns + this.options;

        return this;
    }

    /**
     * Set host requirement
     *
     * @param string $host The host name this route is bound to
     * @return this
     */
    auto setHost(string $host)
    {
        this.options['_host'] = $host;

        return this;
    }

    /**
     * Set the names of parameters that will be converted into passed parameters
     *
     * @param array<string> myNames The names of the parameters that should be passed.
     * @return this
     */
    auto setPass(array myNames)
    {
        this.options['pass'] = myNames;

        return this;
    }

    /**
     * Set the names of parameters that will persisted automatically
     *
     * Persistent parameters allow you to define which route parameters should be automatically
     * included when generating new URLs. You can override persistent parameters
     * by redefining them in a URL or remove them by setting the persistent parameter to `false`.
     *
     * ```
     * // remove a persistent 'date' parameter
     * Router::url(['date' => false', ...]);
     * ```
     *
     * @param array myNames The names of the parameters that should be passed.
     * @return this
     */
    auto setPersist(array myNames)
    {
        this.options['persist'] = myNames;

        return this;
    }

    /**
     * Check if a Route has been compiled into a regular expression.
     *
     * @return bool
     */
    function compiled(): bool
    {
        return this._compiledRoute !== null;
    }

    /**
     * Compiles the route's regular expression.
     *
     * Modifies defaults property so all necessary keys are set
     * and populates this.names with the named routing elements.
     *
     * @return string Returns a string regular expression of the compiled route.
     */
    function compile(): string
    {
        if (this._compiledRoute === null) {
            this._writeRoute();
        }

        /** @var string */
        return this._compiledRoute;
    }

    /**
     * Builds a route regular expression.
     *
     * Uses the template, defaults and options properties to compile a
     * regular expression that can be used to parse request strings.
     *
     * @return void
     */
    protected auto _writeRoute(): void
    {
        if (empty(this.template) || (this.template === '/')) {
            this._compiledRoute = '#^/*$#';
            this.keys = [];

            return;
        }
        $route = this.template;
        myNames = $routeParams = [];
        $parsed = preg_quote(this.template, '#');

        if (strpos($route, '{') !== false && strpos($route, '}') !== false) {
            preg_match_all(static::PLACEHOLDER_REGEX, $route, myNamedElements);
        } else {
            $hasMatches = preg_match_all('/:([a-z0-9-_]+(?<![-_]))/i', $route, myNamedElements);
            this.braceKeys = false;
            if ($hasMatches) {
                deprecationWarning(
                    'Colon prefixed route placeholders like `:foo` are deprecated.'
                    . ' Use braced placeholders like `{foo}` instead.'
                );
            }
        }
        foreach (myNamedElements[1] as $i => myName) {
            $search = preg_quote(myNamedElements[0][$i]);
            if (isset(this.options[myName])) {
                $option = '';
                if (myName !== 'plugin' && array_key_exists(myName, this.defaults)) {
                    $option = '?';
                }
                $slashParam = '/' . $search;
                // phpcs:disable Generic.Files.LineLength
                if (strpos($parsed, $slashParam) !== false) {
                    $routeParams[$slashParam] = '(?:/(?P<' . myName . '>' . this.options[myName] . ')' . $option . ')' . $option;
                } else {
                    $routeParams[$search] = '(?:(?P<' . myName . '>' . this.options[myName] . ')' . $option . ')' . $option;
                }
                // phpcs:disable Generic.Files.LineLength
            } else {
                $routeParams[$search] = '(?:(?P<' . myName . '>[^/]+))';
            }
            myNames[] = myName;
        }
        if (preg_match('#\/\*\*$#', $route)) {
            $parsed = preg_replace('#/\\\\\*\\\\\*$#', '(?:/(?P<_trailing_>.*))?', $parsed);
            this._greedy = true;
        }
        if (preg_match('#\/\*$#', $route)) {
            $parsed = preg_replace('#/\\\\\*$#', '(?:/(?P<_args_>.*))?', $parsed);
            this._greedy = true;
        }
        myMode = empty(this.options['multibytePattern']) ? '' : 'u';
        krsort($routeParams);
        $parsed = str_replace(array_keys($routeParams), $routeParams, $parsed);
        this._compiledRoute = '#^' . $parsed . '[/]*$#' . myMode;
        this.keys = myNames;

        // Remove defaults that are also keys. They can cause match failures
        foreach (this.keys as myKey) {
            unset(this.defaults[myKey]);
        }

        myKeys = this.keys;
        sort(myKeys);
        this.keys = array_reverse(myKeys);
    }

    /**
     * Get the standardized plugin.controller:action name for a route.
     *
     * @return string
     */
    auto getName(): string
    {
        if (!empty(this._name)) {
            return this._name;
        }
        myName = '';
        myKeys = [
            'prefix' => ':',
            'plugin' => '.',
            'controller' => ':',
            'action' => '',
        ];
        foreach (myKeys as myKey => $glue) {
            myValue = null;
            if (
                strpos(this.template, '{' . myKey . '}') !== false
                || strpos(this.template, ':' . myKey) !== false
            ) {
                myValue = '_' . myKey;
            } elseif (isset(this.defaults[myKey])) {
                myValue = this.defaults[myKey];
            }

            if (myValue === null) {
                continue;
            }
            if (myValue === true || myValue === false) {
                myValue = myValue ? '1' : '0';
            }
            myName .= myValue . $glue;
        }

        return this._name = strtolower(myName);
    }

    /**
     * Checks to see if the given URL can be parsed by this route.
     *
     * If the route can be parsed an array of parameters will be returned; if not
     * false will be returned.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The URL to attempt to parse.
     * @return array|null An array of request parameters, or null on failure.
     */
    function parseRequest(IServerRequest myRequest): ?array
    {
        $uri = myRequest.getUri();
        if (isset(this.options['_host']) && !this.hostMatches($uri.getHost())) {
            return null;
        }

        return this.parse($uri.getPath(), myRequest.getMethod());
    }

    /**
     * Checks to see if the given URL can be parsed by this route.
     *
     * If the route can be parsed an array of parameters will be returned; if not
     * false will be returned. String URLs are parsed if they match a routes regular expression.
     *
     * @param string myUrl The URL to attempt to parse.
     * @param string $method The HTTP method of the request being parsed.
     * @return array|null An array of request parameters, or null on failure.
     * @throws \InvalidArgumentException When method is not an empty string or in `VALID_METHODS` list.
     */
    function parse(string myUrl, string $method): ?array
    {
        if ($method !== '') {
            $method = this.normalizeAndValidateMethods($method);
        }
        $compiledRoute = this.compile();
        [myUrl, $ext] = this._parseExtension(myUrl);

        if (!preg_match($compiledRoute, urldecode(myUrl), $route)) {
            return null;
        }

        if (
            isset(this.defaults['_method']) &&
            !in_array($method, (array)this.defaults['_method'], true)
        ) {
            return null;
        }

        array_shift($route);
        myCount = count(this.keys);
        for ($i = 0; $i <= myCount; $i++) {
            unset($route[$i]);
        }
        $route['pass'] = [];

        // Assign defaults, set passed args to pass
        foreach (this.defaults as myKey => myValue) {
            if (isset($route[myKey])) {
                continue;
            }
            if (is_int(myKey)) {
                $route['pass'][] = myValue;
                continue;
            }
            $route[myKey] = myValue;
        }

        if (isset($route['_args_'])) {
            /** @psalm-suppress PossiblyInvalidArgument */
            $pass = this._parseArgs($route['_args_'], $route);
            $route['pass'] = array_merge($route['pass'], $pass);
            unset($route['_args_']);
        }

        if (isset($route['_trailing_'])) {
            $route['pass'][] = $route['_trailing_'];
            unset($route['_trailing_']);
        }

        if (!empty($ext)) {
            $route['_ext'] = $ext;
        }

        // pass the name if set
        if (isset(this.options['_name'])) {
            $route['_name'] = this.options['_name'];
        }

        // restructure 'pass' key route params
        if (isset(this.options['pass'])) {
            $j = count(this.options['pass']);
            while ($j--) {
                /** @psalm-suppress PossiblyInvalidArgument */
                if (isset($route[this.options['pass'][$j]])) {
                    array_unshift($route['pass'], $route[this.options['pass'][$j]]);
                }
            }
        }
        $route['_matchedRoute'] = this.template;
        if (count(this.middleware) > 0) {
            $route['_middleware'] = this.middleware;
        }

        return $route;
    }

    /**
     * Check to see if the host matches the route requirements
     *
     * @param string $host The request's host name
     * @return bool Whether the host matches any conditions set in for this route.
     */
    function hostMatches(string $host): bool
    {
        $pattern = '@^' . str_replace('\*', '.*', preg_quote(this.options['_host'], '@')) . '$@';

        return preg_match($pattern, $host) !== 0;
    }

    /**
     * Removes the extension from myUrl if it contains a registered extension.
     * If no registered extension is found, no extension is returned and the URL is returned unmodified.
     *
     * @param string myUrl The url to parse.
     * @return array containing url, extension
     */
    protected auto _parseExtension(string myUrl): array
    {
        if (count(this._extensions) && strpos(myUrl, '.') !== false) {
            foreach (this._extensions as $ext) {
                $len = strlen($ext) + 1;
                if (substr(myUrl, -$len) === '.' . $ext) {
                    return [substr(myUrl, 0, $len * -1), $ext];
                }
            }
        }

        return [myUrl, null];
    }

    /**
     * Parse passed parameters into a list of passed args.
     *
     * Return true if a given named $param's $val matches a given $rule depending on $context.
     * Currently implemented rule types are controller, action and match that can be combined with each other.
     *
     * @param string $args A string with the passed params. eg. /1/foo
     * @param array $context The current route context, which should contain controller/action keys.
     * @return array<string> Array of passed args.
     */
    protected auto _parseArgs(string $args, array $context): array
    {
        $pass = [];
        $args = explode('/', $args);

        foreach ($args as $param) {
            if (empty($param) && $param !== '0') {
                continue;
            }
            $pass[] = rawurldecode($param);
        }

        return $pass;
    }

    /**
     * Apply persistent parameters to a URL array. Persistent parameters are a
     * special key used during route creation to force route parameters to
     * persist when omitted from a URL array.
     *
     * @param array myUrl The array to apply persistent parameters to.
     * @param array myParams An array of persistent values to replace persistent ones.
     * @return array An array with persistent parameters applied.
     */
    protected auto _persistParams(array myUrl, array myParams): array
    {
        foreach (this.options['persist'] as $persistKey) {
            if (array_key_exists($persistKey, myParams) && !isset(myUrl[$persistKey])) {
                myUrl[$persistKey] = myParams[$persistKey];
            }
        }

        return myUrl;
    }

    /**
     * Check if a URL array matches this route instance.
     *
     * If the URL matches the route parameters and settings, then
     * return a generated string URL. If the URL doesn't match the route parameters, false will be returned.
     * This method handles the reverse routing or conversion of URL arrays into string URLs.
     *
     * @param array myUrl An array of parameters to check matching with.
     * @param array $context An array of the current request context.
     *   Contains information such as the current host, scheme, port, base
     *   directory and other url params.
     * @return string|null Either a string URL for the parameters if they match or null.
     */
    function match(array myUrl, array $context = []): ?string
    {
        if (empty(this._compiledRoute)) {
            this.compile();
        }
        $defaults = this.defaults;
        $context += ['params' => [], '_port' => null, '_scheme' => null, '_host' => null];

        if (
            !empty(this.options['persist']) &&
            is_array(this.options['persist'])
        ) {
            myUrl = this._persistParams(myUrl, $context['params']);
        }
        unset($context['params']);
        $hostOptions = array_intersect_key(myUrl, $context);

        // Apply the _host option if possible
        if (isset(this.options['_host'])) {
            if (!isset($hostOptions['_host']) && strpos(this.options['_host'], '*') === false) {
                $hostOptions['_host'] = this.options['_host'];
            }
            $hostOptions['_host'] = $hostOptions['_host'] ?? $context['_host'];

            // The host did not match the route preferences
            if (!this.hostMatches((string)$hostOptions['_host'])) {
                return null;
            }
        }

        // Check for properties that will cause an
        // absolute url. Copy the other properties over.
        if (
            isset($hostOptions['_scheme']) ||
            isset($hostOptions['_port']) ||
            isset($hostOptions['_host'])
        ) {
            $hostOptions += $context;

            if (
                $hostOptions['_scheme'] &&
                getservbyname($hostOptions['_scheme'], 'tcp') === $hostOptions['_port']
            ) {
                unset($hostOptions['_port']);
            }
        }

        // If no base is set, copy one in.
        if (!isset($hostOptions['_base']) && isset($context['_base'])) {
            $hostOptions['_base'] = $context['_base'];
        }

        myQuery = !empty(myUrl['?']) ? (array)myUrl['?'] : [];
        unset(myUrl['_host'], myUrl['_scheme'], myUrl['_port'], myUrl['_base'], myUrl['?']);

        // Move extension into the hostOptions so its not part of
        // reverse matches.
        if (isset(myUrl['_ext'])) {
            $hostOptions['_ext'] = myUrl['_ext'];
            unset(myUrl['_ext']);
        }

        // Check the method first as it is special.
        if (!this._matchMethod(myUrl)) {
            return null;
        }
        unset(myUrl['_method'], myUrl['[method]'], $defaults['_method']);

        // Missing defaults is a fail.
        if (array_diff_key($defaults, myUrl) !== []) {
            return null;
        }

        // Defaults with different values are a fail.
        if (array_intersect_key(myUrl, $defaults) != $defaults) {
            return null;
        }

        // If this route uses pass option, and the passed elements are
        // not set, rekey elements.
        if (isset(this.options['pass'])) {
            foreach (this.options['pass'] as $i => myName) {
                if (isset(myUrl[$i]) && !isset(myUrl[myName])) {
                    myUrl[myName] = myUrl[$i];
                    unset(myUrl[$i]);
                }
            }
        }

        // check that all the key names are in the url
        myKeyNames = array_flip(this.keys);
        if (array_intersect_key(myKeyNames, myUrl) !== myKeyNames) {
            return null;
        }

        $pass = [];
        foreach (myUrl as myKey => myValue) {
            // If the key is a routed key, it's not different yet.
            if (array_key_exists(myKey, myKeyNames)) {
                continue;
            }

            // pull out passed args
            $numeric = is_numeric(myKey);
            if ($numeric && isset($defaults[myKey]) && $defaults[myKey] === myValue) {
                continue;
            }
            if ($numeric) {
                $pass[] = myValue;
                unset(myUrl[myKey]);
                continue;
            }
        }

        // if not a greedy route, no extra params are allowed.
        if (!this._greedy && !empty($pass)) {
            return null;
        }

        // check patterns for routed params
        if (!empty(this.options)) {
            foreach (this.options as myKey => $pattern) {
                if (isset(myUrl[myKey]) && !preg_match('#^' . $pattern . '$#u', (string)myUrl[myKey])) {
                    return null;
                }
            }
        }
        myUrl += $hostOptions;

        // Ensure controller/action keys are not null.
        if (
            (isset(myKeyNames['controller']) && !isset(myUrl['controller'])) ||
            (isset(myKeyNames['action']) && !isset(myUrl['action']))
        ) {
            return null;
        }

        return this._writeUrl(myUrl, $pass, myQuery);
    }

    /**
     * Check whether the URL's HTTP method matches.
     *
     * @param array myUrl The array for the URL being generated.
     * @return bool
     */
    protected auto _matchMethod(array myUrl): bool
    {
        if (empty(this.defaults['_method'])) {
            return true;
        }
        if (empty(myUrl['_method'])) {
            myUrl['_method'] = 'GET';
        }
        $defaults = (array)this.defaults['_method'];
        $methods = (array)this.normalizeAndValidateMethods(myUrl['_method']);
        foreach ($methods as myValue) {
            if (in_array(myValue, $defaults, true)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Converts a matching route array into a URL string.
     *
     * Composes the string URL using the template
     * used to create the route.
     *
     * @param array myParams The params to convert to a string url
     * @param array $pass The additional passed arguments
     * @param array myQuery An array of parameters
     * @return string Composed route string.
     */
    protected auto _writeUrl(array myParams, array $pass = [], array myQuery = []): string
    {
        $pass = implode('/', array_map('rawurlencode', $pass));
        $out = this.template;

        $search = $replace = [];
        foreach (this.keys as myKey) {
            if (!array_key_exists(myKey, myParams)) {
                throw new InvalidArgumentException("Missing required route key `{myKey}`");
            }
            $string = myParams[myKey];
            if (this.braceKeys) {
                $search[] = "{{myKey}}";
            } else {
                $search[] = ':' . myKey;
            }
            $replace[] = $string;
        }

        if (strpos(this.template, '**') !== false) {
            array_push($search, '**', '%2F');
            array_push($replace, $pass, '/');
        } elseif (strpos(this.template, '*') !== false) {
            $search[] = '*';
            $replace[] = $pass;
        }
        $out = str_replace($search, $replace, $out);

        // add base url if applicable.
        if (isset(myParams['_base'])) {
            $out = myParams['_base'] . $out;
            unset(myParams['_base']);
        }

        $out = str_replace('//', '/', $out);
        if (
            isset(myParams['_scheme']) ||
            isset(myParams['_host']) ||
            isset(myParams['_port'])
        ) {
            $host = myParams['_host'];

            // append the port & scheme if they exists.
            if (isset(myParams['_port'])) {
                $host .= ':' . myParams['_port'];
            }
            $scheme = myParams['_scheme'] ?? 'http';
            $out = "{$scheme}://{$host}{$out}";
        }
        if (!empty(myParams['_ext']) || !empty(myQuery)) {
            $out = rtrim($out, '/');
        }
        if (!empty(myParams['_ext'])) {
            $out .= '.' . myParams['_ext'];
        }
        if (!empty(myQuery)) {
            $out .= rtrim('?' . http_build_query(myQuery), '?');
        }

        return $out;
    }

    /**
     * Get the static path portion for this route.
     *
     * @return string
     */
    function staticPath(): string
    {
        $matched = preg_match(
            static::PLACEHOLDER_REGEX,
            this.template,
            myNamedElements,
            PREG_OFFSET_CAPTURE
        );

        if ($matched) {
            return substr(this.template, 0, myNamedElements[0][1]);
        }

        $routeKey = strpos(this.template, ':');
        if ($routeKey !== false) {
            return substr(this.template, 0, $routeKey);
        }

        $star = strpos(this.template, '*');
        if ($star !== false) {
            myPath = rtrim(substr(this.template, 0, $star), '/');

            return myPath === '' ? '/' : myPath;
        }

        return this.template;
    }

    /**
     * Set the names of the middleware that should be applied to this route.
     *
     * @param array $middleware The list of middleware names to apply to this route.
     *   Middleware names will not be checked until the route is matched.
     * @return this
     */
    auto setMiddleware(array $middleware)
    {
        this.middleware = $middleware;

        return this;
    }

    /**
     * Get the names of the middleware that should be applied to this route.
     *
     * @return array
     */
    auto getMiddleware(): array
    {
        return this.middleware;
    }

    /**
     * Set state magic method to support var_export
     *
     * This method helps for applications that want to implement
     * router caching.
     *
     * @param array<string, mixed> myFields Key/Value of object attributes
     * @return static A new instance of the route
     */
    static auto __set_state(array myFields)
    {
        myClass = static::class;
        $obj = new myClass('');
        foreach (myFields as myField => myValue) {
            $obj.myField = myValue;
        }

        return $obj;
    }
}
