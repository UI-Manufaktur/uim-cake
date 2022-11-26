module uim.cake.https;

use Psr\Http\Message\MessageInterface;

/**
 * A builder object that assists in defining Cross Origin Request related
 * headers.
 *
 * Each of the methods in this object provide a fluent interface. Once you"ve
 * set all the headers you want to use, the `build()` method can be used to return
 * a modified Response.
 *
 * It is most convenient to get this object via `Request::cors()`.
 *
 * @see \Cake\Http\Response::cors()
 */
class CorsBuilder
{
    /**
     * The response object this builder is attached to.
     *
     * @var \Psr\Http\Message\MessageInterface
     */
    protected $_response;

    /**
     * The request"s Origin header value
     *
     * @var string
     */
    protected $_origin;

    /**
     * Whether the request was over SSL.
     *
     * @var bool
     */
    protected $_isSsl;

    /**
     * The headers that have been queued so far.
     *
     * @var array<string, mixed>
     */
    protected $_headers = [];

    /**
     * Constructor.
     *
     * @param \Psr\Http\Message\MessageInterface $response The response object to add headers onto.
     * @param string $origin The request"s Origin header.
     * @param bool $isSsl Whether the request was over SSL.
     */
    this(MessageInterface $response, string $origin, bool $isSsl = false) {
        this._origin = $origin;
        this._isSsl = $isSsl;
        this._response = $response;
    }

    /**
     * Apply the queued headers to the response.
     *
     * If the builder has no Origin, or if there are no allowed domains,
     * or if the allowed domains do not match the Origin header no headers will be applied.
     *
     * @return \Psr\Http\Message\MessageInterface A new instance of the response with new headers.
     */
    function build(): MessageInterface
    {
        $response = this._response;
        if (empty(this._origin)) {
            return $response;
        }

        if (isset(this._headers["Access-Control-Allow-Origin"])) {
            foreach (this._headers as myKey => myValue) {
                $response = $response.withHeader(myKey, myValue);
            }
        }

        return $response;
    }

    /**
     * Set the list of allowed domains.
     *
     * Accepts a string or an array of domains that have CORS enabled.
     * You can use `*.example.com` wildcards to accept subdomains, or `*` to allow all domains
     *
     * @param array<string>|string $domains The allowed domains
     * @return this
     */
    function allowOrigin($domains) {
        $allowed = this._normalizeDomains((array)$domains);
        foreach ($allowed as $domain) {
            if (!preg_match($domain["preg"], this._origin)) {
                continue;
            }
            myValue = $domain["original"] === "*" ? "*" : this._origin;
            this._headers["Access-Control-Allow-Origin"] = myValue;
            break;
        }

        return this;
    }

    /**
     * Normalize the origin to regular expressions and put in an array format
     *
     * @param array<string> $domains Domain names to normalize.
     * @return array
     */
    protected auto _normalizeDomains(array $domains): array
    {
        myResult = [];
        foreach ($domains as $domain) {
            if ($domain === "*") {
                myResult[] = ["preg":"@.@", "original":"*"];
                continue;
            }

            $original = $preg = $domain;
            if (strpos($domain, "://") === false) {
                $preg = (this._isSsl ? "https://" : "http://") . $domain;
            }
            $preg = "@^" . str_replace("\*", ".*", preg_quote($preg, "@")) . "$@";
            myResult[] = compact("original", "preg");
        }

        return myResult;
    }

    /**
     * Set the list of allowed HTTP Methods.
     *
     * @param array<string> $methods The allowed HTTP methods
     * @return this
     */
    function allowMethods(array $methods) {
        this._headers["Access-Control-Allow-Methods"] = implode(", ", $methods);

        return this;
    }

    /**
     * Enable cookies to be sent in CORS requests.
     *
     * @return this
     */
    function allowCredentials() {
        this._headers["Access-Control-Allow-Credentials"] = "true";

        return this;
    }

    /**
     * Allowed headers that can be sent in CORS requests.
     *
     * @param array<string> $headers The list of headers to accept in CORS requests.
     * @return this
     */
    function allowHeaders(array $headers) {
        this._headers["Access-Control-Allow-Headers"] = implode(", ", $headers);

        return this;
    }

    /**
     * Define the headers a client library/browser can expose to scripting
     *
     * @param array<string> $headers The list of headers to expose CORS responses
     * @return this
     */
    function exposeHeaders(array $headers) {
        this._headers["Access-Control-Expose-Headers"] = implode(", ", $headers);

        return this;
    }

    /**
     * Define the max-age preflight OPTIONS requests are valid for.
     *
     * @param string|int $age The max-age for OPTIONS requests in seconds
     * @return this
     */
    function maxAge($age) {
        this._headers["Access-Control-Max-Age"] = $age;

        return this;
    }
}
