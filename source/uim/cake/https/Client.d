module uim.cake.https;

@safe:
import uim.cake;

/**
 * The end user interface for doing HTTP requests.
 *
 * ### Scoped clients
 *
 * If you"re doing multiple requests to the same hostname it"s often convenient
 * to use the constructor arguments to create a scoped client. This allows you
 * to keep your code DRY and not repeat hostnames, authentication, and other options.
 *
 * ### Doing requests
 *
 * Once you"ve created an instance of Client you can do requests
 * using several methods. Each corresponds to a different HTTP method.
 *
 * - get()
 * - post()
 * - put()
 * - delete()
 * - patch()
 *
 * ### Cookie management
 *
 * Client will maintain cookies from the responses done with
 * a client instance. These cookies will be automatically added
 * to future requests to matching hosts. Cookies will respect the
 * `Expires`, `Path` and `Domain` attributes. You can get the client"s
 * CookieCollection using cookies()
 *
 * You can use the "cookieJar" constructor option to provide a custom
 * cookie jar instance you"ve restored from cache/disk. By default,
 * an empty instance of {@link \Cake\Http\Client\CookieCollection} will be created.
 *
 * ### Sending request bodies
 *
 * By default, any POST/PUT/PATCH/DELETE request with myData will
 * send their data as `application/x-www-form-urlencoded` unless
 * there are attached files. In that case `multipart/form-data`
 * will be used.
 *
 * When sending request bodies you can use the `type` option to
 * set the Content-Type for the request:
 *
 * ```
 * $http.get("/users", [], ["type":"json"]);
 * ```
 *
 * The `type` option sets both the `Content-Type` and `Accept` header, to
 * the same mime type. When using `type` you can use either a full mime
 * type or an alias. If you need different types in the Accept and Content-Type
 * headers you should set them manually and not use `type`
 *
 * ### Using authentication
 *
 * By using the `auth` key you can use authentication. The type sub option
 * can be used to specify which authentication strategy you want to use.
 * UIM comes with a few built-in strategies:
 *
 * - Basic
 * - Digest
 * - Oauth
 *
 * ### Using proxies
 *
 * By using the `proxy` key you can set authentication credentials for
 * a proxy if you need to use one. The type sub option can be used to
 * specify which authentication strategy you want to use.
 * UIM comes with built-in support for basic authentication.
 */
class Client : ClientInterface
{
    use InstanceConfigTrait;

    /**
     * Default configuration for the client.
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "adapter":null,
        "host":null,
        "port":null,
        "scheme":"http",
        "basePath":"",
        "timeout":30,
        "ssl_verify_peer":true,
        "ssl_verify_peer_name":true,
        "ssl_verify_depth":5,
        "ssl_verify_host":true,
        "redirect":false,
        "protocolVersion":"1.1",
    ];

    /**
     * List of cookies from responses made with this client.
     *
     * Cookies are indexed by the cookie"s domain or
     * request host name.
     *
     * @var \Cake\Http\Cookie\CookieCollection
     */
    protected $_cookies;

    /**
     * Mock adapter for stubbing requests in tests.
     *
     * @var \Cake\Http\Client\Adapter\Mock|null
     */
    protected static $_mockAdapter;

    /**
     * Adapter for sending requests.
     *
     * @var \Cake\Http\Client\AdapterInterface
     */
    protected $_adapter;

    /**
     * Create a new HTTP Client.
     *
     * ### Config options
     *
     * You can set the following options when creating a client:
     *
     * - host - The hostname to do requests on.
     * - port - The port to use.
     * - scheme - The default scheme/protocol to use. Defaults to http.
     * - basePath - A path to append to the domain to use. (/api/v1/)
     * - timeout - The timeout in seconds. Defaults to 30
     * - ssl_verify_peer - Whether SSL certificates should be validated.
     *   Defaults to true.
     * - ssl_verify_peer_name - Whether peer names should be validated.
     *   Defaults to true.
     * - ssl_verify_depth - The maximum certificate chain depth to traverse.
     *   Defaults to 5.
     * - ssl_verify_host - Verify that the certificate and hostname match.
     *   Defaults to true.
     * - redirect - Number of redirects to follow. Defaults to false.
     * - adapter - The adapter class name or instance. Defaults to
     *   \Cake\Http\Client\Adapter\Curl if `curl` extension is loaded else
     *   \Cake\Http\Client\Adapter\Stream.
     * - protocolVersion - The HTTP protocol version to use. Defaults to 1.1
     *
     * @param array<string, mixed> myConfig Config options for scoped clients.
     * @throws \InvalidArgumentException
     */
    this(array myConfig = []) {
        this.setConfig(myConfig);

        $adapter = this._config["adapter"];
        if ($adapter == null) {
            $adapter = Curl::class;

            if (!extension_loaded("curl")) {
                $adapter = Stream::class;
            }
        } else {
            this.setConfig("adapter", null);
        }

        if (is_string($adapter)) {
            $adapter = new $adapter();
        }

        if (!$adapter instanceof AdapterInterface) {
            throw new InvalidArgumentException("Adapter must be an instance of Cake\Http\Client\AdapterInterface");
        }
        this._adapter = $adapter;

        if (!empty(this._config["cookieJar"])) {
            this._cookies = this._config["cookieJar"];
            this.setConfig("cookieJar", null);
        } else {
            this._cookies = new CookieCollection();
        }
    }

    /**
     * Client instance returned is scoped to the domain, port, and scheme parsed from the passed URL string. The passed
     * string must have a scheme and a domain. Optionally, if a port is included in the string, the port will be scoped
     * too. If a path is included in the URL, the client instance will build urls with it prepended.
     * Other parts of the url string are ignored.
     *
     * @param string myUrl A string URL e.g. https://example.com
     * @return static
     * @throws \InvalidArgumentException
     */
    static function createFromUrl(string myUrl) {
        $parts = parse_url(myUrl);

        if ($parts == false) {
            throw new InvalidArgumentException("String " . myUrl . " did not parse");
        }

        myConfig = array_intersect_key($parts, ["scheme":"", "port":"", "host":"", "path":""]);

        if (empty(myConfig["scheme"]) || empty(myConfig["host"])) {
            throw new InvalidArgumentException("The URL was parsed but did not contain a scheme or host");
        }

        if (isset(myConfig["path"])) {
            myConfig["basePath"] = myConfig["path"];
            unset(myConfig["path"]);
        }

        return new static(myConfig);
    }

    /**
     * Get the cookies stored in the Client.
     *
     * @return \Cake\Http\Cookie\CookieCollection
     */
    function cookies(): CookieCollection
    {
        return this._cookies;
    }

    /**
     * Adds a cookie to the Client collection.
     *
     * @param \Cake\Http\Cookie\ICookie $cookie Cookie object.
     * @return this
     * @throws \InvalidArgumentException
     */
    function addCookie(ICookie $cookie) {
        if (!$cookie.getDomain() || !$cookie.getPath()) {
            throw new InvalidArgumentException("Cookie must have a domain and a path set.");
        }
        this._cookies = this._cookies.add($cookie);

        return this;
    }

    /**
     * Do a GET request.
     *
     * The myData argument supports a special `_content` key
     * for providing a request body in a GET request. This is
     * generally not used, but services like ElasticSearch use
     * this feature.
     *
     * @param string myUrl The url or path you want to request.
     * @param array|string myData The query data you want to send.
     * @param array<string, mixed> myOptions Additional options for the request.
     * @return \Cake\Http\Client\Response
     */
    auto get(string myUrl, myData = [], array myOptions = []): Response
    {
        myOptions = this._mergeOptions(myOptions);
        $body = null;
        if (is_array(myData) && isset(myData["_content"])) {
            $body = myData["_content"];
            unset(myData["_content"]);
        }
        myUrl = this.buildUrl(myUrl, myData, myOptions);

        return this._doRequest(
            Request::METHOD_GET,
            myUrl,
            $body,
            myOptions
        );
    }

    /**
     * Do a POST request.
     *
     * @param string myUrl The url or path you want to request.
     * @param mixed myData The post data you want to send.
     * @param array<string, mixed> myOptions Additional options for the request.
     * @return \Cake\Http\Client\Response
     */
    function post(string myUrl, myData = [], array myOptions = []): Response
    {
        myOptions = this._mergeOptions(myOptions);
        myUrl = this.buildUrl(myUrl, [], myOptions);

        return this._doRequest(Request::METHOD_POST, myUrl, myData, myOptions);
    }

    /**
     * Do a PUT request.
     *
     * @param string myUrl The url or path you want to request.
     * @param mixed myData The request data you want to send.
     * @param array<string, mixed> myOptions Additional options for the request.
     * @return \Cake\Http\Client\Response
     */
    function put(string myUrl, myData = [], array myOptions = []): Response
    {
        myOptions = this._mergeOptions(myOptions);
        myUrl = this.buildUrl(myUrl, [], myOptions);

        return this._doRequest(Request::METHOD_PUT, myUrl, myData, myOptions);
    }

    /**
     * Do a PATCH request.
     *
     * @param string myUrl The url or path you want to request.
     * @param mixed myData The request data you want to send.
     * @param array<string, mixed> myOptions Additional options for the request.
     * @return \Cake\Http\Client\Response
     */
    function patch(string myUrl, myData = [], array myOptions = []): Response
    {
        myOptions = this._mergeOptions(myOptions);
        myUrl = this.buildUrl(myUrl, [], myOptions);

        return this._doRequest(Request::METHOD_PATCH, myUrl, myData, myOptions);
    }

    /**
     * Do an OPTIONS request.
     *
     * @param string myUrl The url or path you want to request.
     * @param mixed myData The request data you want to send.
     * @param array<string, mixed> myOptions Additional options for the request.
     * @return \Cake\Http\Client\Response
     */
    function options(string myUrl, myData = [], array myOptions = []): Response
    {
        myOptions = this._mergeOptions(myOptions);
        myUrl = this.buildUrl(myUrl, [], myOptions);

        return this._doRequest(Request::METHOD_OPTIONS, myUrl, myData, myOptions);
    }

    /**
     * Do a TRACE request.
     *
     * @param string myUrl The url or path you want to request.
     * @param mixed myData The request data you want to send.
     * @param array<string, mixed> myOptions Additional options for the request.
     * @return \Cake\Http\Client\Response
     */
    function trace(string myUrl, myData = [], array myOptions = []): Response
    {
        myOptions = this._mergeOptions(myOptions);
        myUrl = this.buildUrl(myUrl, [], myOptions);

        return this._doRequest(Request::METHOD_TRACE, myUrl, myData, myOptions);
    }

    /**
     * Do a DELETE request.
     *
     * @param string myUrl The url or path you want to request.
     * @param mixed myData The request data you want to send.
     * @param array<string, mixed> myOptions Additional options for the request.
     * @return \Cake\Http\Client\Response
     */
    function delete(string myUrl, myData = [], array myOptions = []): Response
    {
        myOptions = this._mergeOptions(myOptions);
        myUrl = this.buildUrl(myUrl, [], myOptions);

        return this._doRequest(Request::METHOD_DELETE, myUrl, myData, myOptions);
    }

    /**
     * Do a HEAD request.
     *
     * @param string myUrl The url or path you want to request.
     * @param array myData The query string data you want to send.
     * @param array<string, mixed> myOptions Additional options for the request.
     * @return \Cake\Http\Client\Response
     */
    function head(string myUrl, array myData = [], array myOptions = []): Response
    {
        myOptions = this._mergeOptions(myOptions);
        myUrl = this.buildUrl(myUrl, myData, myOptions);

        return this._doRequest(Request::METHOD_HEAD, myUrl, "", myOptions);
    }

    /**
     * Helper method for doing non-GET requests.
     *
     * @param string $method HTTP method.
     * @param string myUrl URL to request.
     * @param mixed myData The request body.
     * @param array<string, mixed> myOptions The options to use. Contains auth, proxy, etc.
     * @return \Cake\Http\Client\Response
     */
    protected auto _doRequest(string $method, string myUrl, myData, myOptions): Response
    {
        myRequest = this._createRequest(
            $method,
            myUrl,
            myData,
            myOptions
        );

        return this.send(myRequest, myOptions);
    }

    /**
     * Does a recursive merge of the parameter with the scope config.
     *
     * @param array<string, mixed> myOptions Options to merge.
     * @return array Options merged with set config.
     */
    protected auto _mergeOptions(array myOptions): array
    {
        return Hash::merge(this._config, myOptions);
    }

    /**
     * Sends a PSR-7 request and returns a PSR-7 response.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest Request instance.
     * @return \Psr\Http\Message\IResponse Response instance.
     * @throws \Psr\Http\Client\ClientExceptionInterface If an error happens while processing the request.
     */
    function sendRequest(RequestInterface myRequest): IResponse
    {
        return this.send(myRequest, this._config);
    }

    /**
     * Send a request.
     *
     * Used internally by other methods, but can also be used to send
     * handcrafted Request objects.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request to send.
     * @param array<string, mixed> myOptions Additional options to use.
     * @return \Cake\Http\Client\Response
     */
    function send(RequestInterface myRequest, array myOptions = []): Response
    {
        $redirects = 0;
        if (isset(myOptions["redirect"])) {
            $redirects = (int)myOptions["redirect"];
            unset(myOptions["redirect"]);
        }

        do {
            $response = this._sendRequest(myRequest, myOptions);

            $handleRedirect = $response.isRedirect() && $redirects-- > 0;
            if ($handleRedirect) {
                myUrl = myRequest.getUri();

                myLocation = $response.getHeaderLine("Location");
                myLocationUrl = this.buildUrl(myLocation, [], [
                    "host":myUrl.getHost(),
                    "port":myUrl.getPort(),
                    "scheme":myUrl.getScheme(),
                    "protocolRelative":true,
                ]);
                myRequest = myRequest.withUri(new Uri(myLocationUrl));
                myRequest = this._cookies.addToRequest(myRequest, []);
            }
        } while ($handleRedirect);

        return $response;
    }

    /**
     * Clear all mocked responses
     *
     * @return void
     */
    static function clearMockResponses(): void
    {
        static::$_mockAdapter = null;
    }

    /**
     * Add a mocked response.
     *
     * Mocked responses are stored in an adapter that is called
     * _before_ the network adapter is called.
     *
     * ### Matching Requests
     *
     * TODO finish this.
     *
     * ### Options
     *
     * - `match` An additional closure to match requests with.
     *
     * @param string $method The HTTP method being mocked.
     * @param string myUrl The URL being matched. See above for examples.
     * @param \Cake\Http\Client\Response $response The response that matches the request.
     * @param array<string, mixed> myOptions See above.
     * @return void
     */
    static function addMockResponse(string $method, string myUrl, Response $response, array myOptions = []): void
    {
        if (!static::$_mockAdapter) {
            static::$_mockAdapter = new MockAdapter();
        }
        myRequest = new Request(myUrl, $method);
        static::$_mockAdapter.addResponse(myRequest, $response, myOptions);
    }

    /**
     * Send a request without redirection.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request to send.
     * @param array<string, mixed> myOptions Additional options to use.
     * @return \Cake\Http\Client\Response
     */
    protected auto _sendRequest(RequestInterface myRequest, array myOptions): Response
    {
        if (static::$_mockAdapter) {
            $responses = static::$_mockAdapter.send(myRequest, myOptions);
        }
        if (empty($responses)) {
            $responses = this._adapter.send(myRequest, myOptions);
        }
        foreach ($responses as $response) {
            this._cookies = this._cookies.addFromResponse($response, myRequest);
        }

        return array_pop($responses);
    }

    /**
     * Generate a URL based on the scoped client options.
     *
     * @param string myUrl Either a full URL or just the path.
     * @param array|string myQuery The query data for the URL.
     * @param array<string, mixed> myOptions The config options stored with Client::config()
     * @return string A complete url with scheme, port, host, and path.
     */
    string buildUrl(string myUrl, myQuery = [], array myOptions = []) {
        if (empty(myOptions) && empty(myQuery)) {
            return myUrl;
        }
        $defaults = [
            "host":null,
            "port":null,
            "scheme":"http",
            "basePath":"",
            "protocolRelative":false,
        ];
        myOptions += $defaults;

        if (myQuery) {
            $q = strpos(myUrl, "?") == false ? "?" : "&";
            myUrl .= $q;
            myUrl .= is_string(myQuery) ? myQuery : http_build_query(myQuery, "", "&", PHP_QUERY_RFC3986);
        }

        if (myOptions["protocolRelative"] && preg_match("#^//#", myUrl)) {
            myUrl = myOptions["scheme"] . ":" . myUrl;
        }
        if (preg_match("#^https?://#", myUrl)) {
            return myUrl;
        }

        $defaultPorts = [
            "http":80,
            "https":443,
        ];
        $out = myOptions["scheme"] . "://" . myOptions["host"];
        if (myOptions["port"] && (int)myOptions["port"] !== $defaultPorts[myOptions["scheme"]]) {
            $out .= ":" . myOptions["port"];
        }
        if (!empty(myOptions["basePath"])) {
            $out .= "/" . trim(myOptions["basePath"], "/");
        }
        $out .= "/" . ltrim(myUrl, "/");

        return $out;
    }

    /**
     * Creates a new request object based on the parameters.
     *
     * @param string $method HTTP method name.
     * @param string myUrl The url including query string.
     * @param mixed myData The request body.
     * @param array<string, mixed> myOptions The options to use. Contains auth, proxy, etc.
     * @return \Cake\Http\Client\Request
     */
    protected auto _createRequest(string $method, string myUrl, myData, myOptions): Request
    {
        /** @var array<non-empty-string, non-empty-string> $headers */
        $headers = (array)(myOptions["headers"] ?? []);
        if (isset(myOptions["type"])) {
            $headers = array_merge($headers, this._typeHeaders(myOptions["type"]));
        }
        if (is_string(myData) && !isset($headers["Content-Type"]) && !isset($headers["content-type"])) {
            $headers["Content-Type"] = "application/x-www-form-urlencoded";
        }

        myRequest = new Request(myUrl, $method, $headers, myData);
        /** @var \Cake\Http\Client\Request myRequest */
        myRequest = myRequest.withProtocolVersion(this.getConfig("protocolVersion"));
        $cookies = myOptions["cookies"] ?? [];
        /** @var \Cake\Http\Client\Request myRequest */
        myRequest = this._cookies.addToRequest(myRequest, $cookies);
        if (isset(myOptions["auth"])) {
            myRequest = this._addAuthentication(myRequest, myOptions);
        }
        if (isset(myOptions["proxy"])) {
            myRequest = this._addProxy(myRequest, myOptions);
        }

        return myRequest;
    }

    /**
     * Returns headers for Accept/Content-Type based on a short type
     * or full mime-type.
     *
     * @phpstan-param non-empty-string myType
     * @param string myType short type alias or full mimetype.
     * @return Headers to set on the request.
     * @throws \Cake\Core\Exception\CakeException When an unknown type alias is used.
     * @psalm-return array<non-empty-string, non-empty-string>
     */
    protected STRINGAA _typeHeaders(string myType) {
        if (strpos(myType, "/") !== false) {
            return [
                "Accept":myType,
                "Content-Type":myType,
            ];
        }
        myTypeMap = [
            "json":"application/json",
            "xml":"application/xml",
        ];
        if (!isset(myTypeMap[myType])) {
            throw new CakeException("Unknown type alias "myType".");
        }

        return [
            "Accept":myTypeMap[myType],
            "Content-Type":myTypeMap[myType],
        ];
    }

    /**
     * Add authentication headers to the request.
     *
     * Uses the authentication type to choose the correct strategy
     * and use its methods to add headers.
     *
     * @param \Cake\Http\Client\Request myRequest The request to modify.
     * @param array<string, mixed> myOptions Array of options containing the "auth" key.
     * @return \Cake\Http\Client\Request The updated request object.
     */
    protected auto _addAuthentication(Request myRequest, array myOptions): Request
    {
        $auth = myOptions["auth"];
        /** @var \Cake\Http\Client\Auth\Basic $adapter */
        $adapter = this._createAuth($auth, myOptions);

        return $adapter.authentication(myRequest, myOptions["auth"]);
    }

    /**
     * Add proxy authentication headers.
     *
     * Uses the authentication type to choose the correct strategy
     * and use its methods to add headers.
     *
     * @param \Cake\Http\Client\Request myRequest The request to modify.
     * @param array<string, mixed> myOptions Array of options containing the "proxy" key.
     * @return \Cake\Http\Client\Request The updated request object.
     */
    protected auto _addProxy(Request myRequest, array myOptions): Request
    {
        $auth = myOptions["proxy"];
        /** @var \Cake\Http\Client\Auth\Basic $adapter */
        $adapter = this._createAuth($auth, myOptions);

        return $adapter.proxyAuthentication(myRequest, myOptions["proxy"]);
    }

    /**
     * Create the authentication strategy.
     *
     * Use the configuration options to create the correct
     * authentication strategy handler.
     *
     * @param array $auth The authentication options to use.
     * @param array<string, mixed> myOptions The overall request options to use.
     * @return object Authentication strategy instance.
     * @throws \Cake\Core\Exception\CakeException when an invalid strategy is chosen.
     */
    protected auto _createAuth(array $auth, array myOptions) {
        if (empty($auth["type"])) {
            $auth["type"] = "basic";
        }
        myName = ucfirst($auth["type"]);
        myClass = App::className(myName, "Http/Client/Auth");
        if (!myClass) {
            throw new CakeException(
                sprintf("Invalid authentication type %s", myName)
            );
        }

        return new myClass(this, myOptions);
    }
}
