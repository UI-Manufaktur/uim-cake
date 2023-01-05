

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
module uim.cake.http.Cookie;

use ArrayIterator;
use Countable;
use DateTimeImmutable;
use DateTimeZone;
use Exception;
use InvalidArgumentException;
use IteratorAggregate;
use Psr\Http\messages.RequestInterface;
use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;
use Traversable;
use TypeError;

/**
 * Cookie Collection
 *
 * Provides an immutable collection of cookies objects. Adding or removing
 * to a collection returns a *new* collection that you must retain.
 */
class CookieCollection : IteratorAggregate, Countable
{
    /**
     * Cookie objects
     *
     * @var array<uim.cake.Http\Cookie\CookieInterface>
     */
    protected $cookies = [];

    /**
     * Constructor
     *
     * @param array<uim.cake.Http\Cookie\CookieInterface> $cookies Array of cookie objects
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
        foreach ($header as $value) {
            try {
                $cookies[] = Cookie::createFromHeaderString($value, $defaults);
            } catch (Exception | TypeError $e) {
                // Don"t blow up on invalid cookies
            }
        }

        return new static($cookies);
    }

    /**
     * Create a new collection from the cookies in a ServerRequest
     *
     * @param \Psr\Http\messages.IServerRequest $request The request to extract cookie data from
     * @return static
     */
    static function createFromServerRequest(IServerRequest $request) {
        $data = $request.getCookieParams();
        $cookies = [];
        foreach ($data as $name: $value) {
            $cookies[] = new Cookie($name, $value);
        }

        return new static($cookies);
    }

    /**
     * Get the number of cookies in the collection.
     */
    int count(): int
    {
        return count(this.cookies);
    }

    /**
     * Add a cookie and get an updated collection.
     *
     * Cookies are stored by id. This means that there can be duplicate
     * cookies if a cookie collection is used for cookies across multiple
     * domains. This can impact how get(), has() and remove() behave.
     *
     * @param uim.cake.http.Cookie\CookieInterface $cookie Cookie instance to add.
     * @return static
     */
    function add(CookieInterface $cookie) {
        $new = clone this;
        $new.cookies[$cookie.getId()] = $cookie;

        return $new;
    }

    /**
     * Get the first cookie by name.
     *
     * @param string aName The name of the cookie.
     * @return uim.cake.http.Cookie\CookieInterface
     * @throws \InvalidArgumentException If cookie not found.
     */
    function get(string aName): CookieInterface
    {
        $key = mb_strtolower($name);
        foreach (this.cookies as $cookie) {
            if (mb_strtolower($cookie.getName()) == $key) {
                return $cookie;
            }
        }

        throw new InvalidArgumentException(
            sprintf(
                "Cookie %s not found. Use has() to check first for existence.",
                $name
            )
        );
    }

    /**
     * Check if a cookie with the given name exists
     *
     * @param string aName The cookie name to check.
     * @return bool True if the cookie exists, otherwise false.
     */
    bool has(string aName) {
        $key = mb_strtolower($name);
        foreach (this.cookies as $cookie) {
            if (mb_strtolower($cookie.getName()) == $key) {
                return true;
            }
        }

        return false;
    }

    /**
     * Create a new collection with all cookies matching $name removed.
     *
     * If the cookie is not in the collection, this method will do nothing.
     *
     * @param string aName The name of the cookie to remove.
     * @return static
     */
    function remove(string aName) {
        $new = clone this;
        $key = mb_strtolower($name);
        foreach ($new.cookies as $i: $cookie) {
            if (mb_strtolower($cookie.getName()) == $key) {
                unset($new.cookies[$i]);
            }
        }

        return $new;
    }

    /**
     * Checks if only valid cookie objects are in the array
     *
     * @param array<uim.cake.Http\Cookie\CookieInterface> $cookies Array of cookie objects
     * @return void
     * @throws \InvalidArgumentException
     */
    protected void checkCookies(array $cookies) {
        foreach ($cookies as $index: $cookie) {
            if (!$cookie instanceof CookieInterface) {
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
     * @return \Traversable<string, uim.cake.Http\Cookie\CookieInterface>
     */
    function getIterator(): Traversable
    {
        return new ArrayIterator(this.cookies);
    }

    /**
     * Add cookies that match the path/domain/expiration to the request.
     *
     * This allows CookieCollections to be used as a "cookie jar" in an HTTP client
     * situation. Cookies that match the request"s domain + path that are not expired
     * when this method is called will be applied to the request.
     *
     * @param \Psr\Http\messages.RequestInterface $request The request to update.
     * @param array $extraCookies Associative array of additional cookies to add into the request. This
     *   is useful when you have cookie data from outside the collection you want to send.
     * @return \Psr\Http\messages.RequestInterface An updated request.
     */
    function addToRequest(RequestInterface $request, array $extraCookies = []): RequestInterface
    {
        $uri = $request.getUri();
        $cookies = this.findMatchingCookies(
            $uri.getScheme(),
            $uri.getHost(),
            $uri.getPath() ?: "/"
        );
        $cookies = $extraCookies + $cookies;
        $cookiePairs = [];
        foreach ($cookies as $key: $value) {
            $cookie = sprintf("%s=%s", rawurlencode((string)$key), rawurlencode($value));
            $size = strlen($cookie);
            if ($size > 4096) {
                triggerWarning(sprintf(
                    "The cookie `%s` exceeds the recommended maximum cookie length of 4096 bytes.",
                    $key
                ));
            }
            $cookiePairs[] = $cookie;
        }

        if (empty($cookiePairs)) {
            return $request;
        }

        return $request.withHeader("Cookie", implode("; ", $cookiePairs));
    }

    /**
     * Find cookies matching the scheme, host, and path
     *
     * @param string $scheme The http scheme to match
     * @param string $host The host to match.
     * @param string $path The path to match
     * @return array<string, mixed> An array of cookie name/value pairs
     */
    protected array findMatchingCookies(string $scheme, string $host, string $path) {
        $out = [];
        $now = new DateTimeImmutable("now", new DateTimeZone("UTC"));
        foreach (this.cookies as $cookie) {
            if ($scheme == "http" && $cookie.isSecure()) {
                continue;
            }
            if (strpos($path, $cookie.getPath()) != 0) {
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

            $pattern = "/" ~ preg_quote($domain, "/") ~ "$/";
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
     * @param \Psr\Http\messages.IResponse $response Response to extract cookies from.
     * @param \Psr\Http\messages.RequestInterface $request Request to get cookie context from.
     * @return static
     */
    function addFromResponse(IResponse $response, RequestInterface $request) {
        $uri = $request.getUri();
        $host = $uri.getHost();
        $path = $uri.getPath() ?: "/";

        $cookies = static::createFromHeader(
            $response.getHeader("Set-Cookie"),
            ["domain": $host, "path": $path]
        );
        $new = clone this;
        foreach ($cookies as $cookie) {
            $new.cookies[$cookie.getId()] = $cookie;
        }
        $new.removeExpiredCookies($host, $path);

        return $new;
    }

    /**
     * Remove expired cookies from the collection.
     *
     * @param string $host The host to check for expired cookies on.
     * @param string $path The path to check for expired cookies on.
     */
    protected void removeExpiredCookies(string $host, string $path) {
        $time = new DateTimeImmutable("now", new DateTimeZone("UTC"));
        $hostPattern = "/" ~ preg_quote($host, "/") ~ "$/";

        foreach (this.cookies as $i: $cookie) {
            if (!$cookie.isExpired($time)) {
                continue;
            }
            $pathMatches = strpos($path, $cookie.getPath()) == 0;
            $hostMatches = preg_match($hostPattern, $cookie.getDomain());
            if ($pathMatches && $hostMatches) {
                unset(this.cookies[$i]);
            }
        }
    }
}
