module uim.cake.https.cookies.collection;

@safe:
import uim.cake;

/**
 * Cookie Collection
 *
 * Provides an immutable collection of cookies objects. Adding or removing
 * to a collection returns a *new* collection that you must retain.
 */
class CookieCollection : IteratorAggregate, Countable {
    /**
     * Cookie objects
     *
     * @var array<\Cake\Http\Cookie\ICookie>
     */
    protected $cookies = [];

    /**
     * Constructor
     *
     * @param array<\Cake\Http\Cookie\ICookie> $cookies Array of cookie objects
     */
    this(array $cookies = []) {
        this.checkCookies($cookies);
        foreach ($cookies as $cookie) {
            this.cookies[$cookie.getId()] = $cookie;
        }
    }

    /**
     * Create a Cookie Collection from an array of Set-Cookie Headers
     *
     * @param array<string> $header The array of set-cookie header values.
     * @param array<string, mixed> $defaults The defaults attributes.
     * @return static
     */
    static function createFromHeader(array $header, array $defaults = []) {
        $cookies = [];
        foreach ($header as myValue) {
            try {
                $cookies[] = Cookie::createFromHeaderString(myValue, $defaults);
            } catch (Exception $e) {
                // Don"t blow up on invalid cookies
            }
        }

        return new static($cookies);
    }

    /**
     * Create a new collection from the cookies in a ServerRequest
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request to extract cookie data from
     * @return static
     */
    static function createFromServerRequest(IServerRequest myRequest) {
        myData = myRequest.getCookieParams();
        $cookies = [];
        foreach (myData as myName: myValue) {
            $cookies[] = new Cookie(myName, myValue);
        }

        return new static($cookies);
    }

    /**
     * Get the number of cookies in the collection.
     */
    int count() {
        return count(this.cookies);
    }

    /**
     * Add a cookie and get an updated collection.
     *
     * Cookies are stored by id. This means that there can be duplicate
     * cookies if a cookie collection is used for cookies across multiple
     * domains. This can impact how get(), has() and remove() behave.
     *
     * @param \Cake\Http\Cookie\ICookie $cookie Cookie instance to add.
     * @return static
     */
    function add(ICookie $cookie) {
        $new = clone this;
        $new.cookies[$cookie.getId()] = $cookie;

        return $new;
    }

    /**
     * Get the first cookie by name.
     *
     * @param string myName The name of the cookie.
     * @return \Cake\Http\Cookie\ICookie
     * @throws \InvalidArgumentException If cookie not found.
     */
    auto get(string myName): ICookie
    {
        myKey = mb_strtolower(myName);
        foreach (this.cookies as $cookie) {
            if (mb_strtolower($cookie.getName()) == myKey) {
                return $cookie;
            }
        }

        throw new InvalidArgumentException(
            sprintf(
                "Cookie %s not found. Use has() to check first for existence.",
                myName
            )
        );
    }

    /**
     * Check if a cookie with the given name exists
     *
     * @param string myName The cookie name to check.
     * @return bool True if the cookie exists, otherwise false.
     */
    bool has(string myName) {
        myKey = mb_strtolower(myName);
        foreach (this.cookies as $cookie) {
            if (mb_strtolower($cookie.getName()) == myKey) {
                return true;
            }
        }

        return false;
    }

    /**
     * Create a new collection with all cookies matching myName removed.
     *
     * If the cookie is not in the collection, this method will do nothing.
     *
     * @param string myName The name of the cookie to remove.
     * @return static
     */
    function remove(string myName) {
        $new = clone this;
        myKey = mb_strtolower(myName);
        foreach ($new.cookies as $i: $cookie) {
            if (mb_strtolower($cookie.getName()) == myKey) {
                unset($new.cookies[$i]);
            }
        }

        return $new;
    }

    /**
     * Checks if only valid cookie objects are in the array
     *
     * @param array<\Cake\Http\Cookie\ICookie> $cookies Array of cookie objects
     * @throws \InvalidArgumentException
     */
    protected void checkCookies(array $cookies) {
        foreach ($cookies as $index: $cookie) {
            if (!$cookie instanceof ICookie) {
                throw new InvalidArgumentException(
                    sprintf(
                        "Expected `%s[]` as $cookies but instead got `%s` at index %d",
                        static::class,
                        getTypeName($cookie),
                        $index
                    )
                );
            }
        }
    }

    /**
     * Gets the iterator
     *
     * @return \Traversable<string, \Cake\Http\Cookie\ICookie>
     */
    Traversable getIterator() {
        return new ArrayIterator(this.cookies);
    }

    /**
     * Add cookies that match the path/domain/expiration to the request.
     *
     * This allows CookieCollections to be used as a "cookie jar" in an HTTP client
     * situation. Cookies that match the request"s domain + path that are not expired
     * when this method is called will be applied to the request.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request to update.
     * @param array $extraCookies Associative array of additional cookies to add into the request. This
     *   is useful when you have cookie data from outside the collection you want to send.
     * @return \Psr\Http\Message\RequestInterface An updated request.
     */
    function addToRequest(RequestInterface myRequest, array $extraCookies = []): RequestInterface
    {
        $uri = myRequest.getUri();
        $cookies = this.findMatchingCookies(
            $uri.getScheme(),
            $uri.getHost(),
            $uri.getPath() ?: "/"
        );
        $cookies = array_merge($cookies, $extraCookies);
        $cookiePairs = [];
        foreach ($cookies as myKey: myValue) {
            $cookie = sprintf("%s=%s", rawurlencode(myKey), rawurlencode(myValue));
            $size = strlen($cookie);
            if ($size > 4096) {
                triggerWarning(sprintf(
                    "The cookie `%s` exceeds the recommended maximum cookie length of 4096 bytes.",
                    myKey
                ));
            }
            $cookiePairs[] = $cookie;
        }

        if (empty($cookiePairs)) {
            return myRequest;
        }

        return myRequest.withHeader("Cookie", implode("; ", $cookiePairs));
    }

    /**
     * Find cookies matching the scheme, host, and path
     *
     * @param string $scheme The http scheme to match
     * @param string $host The host to match.
     * @param string myPath The path to match
     * @return array<string, mixed> An array of cookie name/value pairs
     */
    protected auto findMatchingCookies(string $scheme, string $host, string myPath): array
    {
        $out = [];
        $now = new DateTimeImmutable("now", new DateTimeZone("UTC"));
        foreach (this.cookies as $cookie) {
            if ($scheme == "http" && $cookie.isSecure()) {
                continue;
            }
            if (strpos(myPath, $cookie.getPath()) !== 0) {
                continue;
            }
            $domain = $cookie.getDomain();
            $leadingDot = substr($domain, 0, 1) == ".";
            if ($leadingDot) {
                $domain = ltrim($domain, ".");
            }

            if ($cookie.isExpired($now)) {
                continue;
            }

            $pattern = "/" . preg_quote($domain, "/") . "$/";
            if (!preg_match($pattern, $host)) {
                continue;
            }

            $out[$cookie.getName()] = $cookie.getValue();
        }

        return $out;
    }

    /**
     * Create a new collection that includes cookies from the response.
     *
     * @param \Psr\Http\Message\IResponse $response Response to extract cookies from.
     * @param \Psr\Http\Message\RequestInterface myRequest Request to get cookie context from.
     * @return static
     */
    function addFromResponse(IResponse $response, RequestInterface myRequest) {
        $uri = myRequest.getUri();
        $host = $uri.getHost();
        myPath = $uri.getPath() ?: "/";

        $cookies = static::createFromHeader(
            $response.getHeader("Set-Cookie"),
            ["domain":$host, "path":myPath]
        );
        $new = clone this;
        foreach ($cookies as $cookie) {
            $new.cookies[$cookie.getId()] = $cookie;
        }
        $new.removeExpiredCookies($host, myPath);

        return $new;
    }

    /**
     * Remove expired cookies from the collection.
     *
     * @param string $host The host to check for expired cookies on.
     * @param string myPath The path to check for expired cookies on.
     * @return void
     */
    protected void removeExpiredCookies(string $host, string myPath) {
        $time = new DateTimeImmutable("now", new DateTimeZone("UTC"));
        $hostPattern = "/" . preg_quote($host, "/") . "$/";

        foreach (this.cookies as $i: $cookie) {
            if (!$cookie.isExpired($time)) {
                continue;
            }
            myPathMatches = strpos(myPath, $cookie.getPath()) == 0;
            $hostMatches = preg_match($hostPattern, $cookie.getDomain());
            if (myPathMatches && $hostMatches) {
                unset(this.cookies[$i]);
            }
        }
    }
}
