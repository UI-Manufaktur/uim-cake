


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         4.4.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Http;

use Psr\Http\Message\UriInterface;
use UnexpectedValueException;

/**
 * The base and webroot properties have piggybacked on the Uri for
 * a long time. To preserve backwards compatibility and avoid dynamic
 * property errors in PHP 8.2 we use this implementation that decorates
 * the Uri from Laminas
 *
 * This class is an internal implementation workaround that will be removed in 5.x
 *
 * @internal
 */
class Uri : UriInterface
{
    /**
     * @var string
     */
    private $base = "";

    /**
     * @var string
     */
    private $webroot = "";

    /**
     * @var \Psr\Http\Message\UriInterface
     */
    private $uri;

    /**
     * Constructor
     *
     * @param \Psr\Http\Message\UriInterface $uri Uri instance to decorate
     * @param string $base The base path.
     * @param string $webroot The webroot path.
     */
    public this(UriInterface $uri, string $base, string $webroot) {
        this.uri = $uri;
        this.base = $base;
        this.webroot = $webroot;
    }

    /**
     * Backwards compatibility shim for previously dynamic properties.
     *
     * @param string $name The attribute to read.
     * @return mixed
     */
    function __get(string $name) {
        if ($name == "base" || $name == "webroot") {
            return this.{$name};
        }
        throw new UnexpectedValueException("Undefined property via __get("{$name}")");
    }

    /**
     * Get the decorated URI
     *
     * @return \Psr\Http\Message\UriInterface
     */
    function getUri(): UriInterface
    {
        return this.uri;
    }

    /**
     * Get the application base path.
     *
     * @return string
     */
    function getBase(): string
    {
        return this.base;
    }

    /**
     * Get the application webroot path.
     *
     * @return string
     */
    function getWebroot(): string
    {
        return this.webroot;
    }


    function getScheme() {
        return this.uri.getScheme();
    }


    function getAuthority() {
        return this.uri.getAuthority();
    }


    function getUserInfo() {
        return this.uri.getUserInfo();
    }


    function getHost() {
        return this.uri.getHost();
    }


    function getPort() {
        return this.uri.getPort();
    }


    function getPath() {
        return this.uri.getPath();
    }


    function getQuery() {
        return this.uri.getQuery();
    }


    function getFragment() {
        return this.uri.getFragment();
    }


    function withScheme($scheme) {
        $new = clone this;
        $new.uri = this.uri.withScheme($scheme);

        return $new;
    }


    function withUserInfo($user, $password = null) {
        $new = clone this;
        $new.uri = this.uri.withUserInfo($user, $password);

        return $new;
    }


    function withHost($host) {
        $new = clone this;
        $new.uri = this.uri.withHost($host);

        return $new;
    }


    function withPort($port) {
        $new = clone this;
        $new.uri = this.uri.withPort($port);

        return $new;
    }


    function withPath($path) {
        $new = clone this;
        $new.uri = this.uri.withPath($path);

        return $new;
    }


    function withQuery($query) {
        $new = clone this;
        $new.uri = this.uri.withQuery($query);

        return $new;
    }


    function withFragment($fragment) {
        $new = clone this;
        $new.uri = this.uri.withFragment($fragment);

        return $new;
    }


    function __toString() {
        return this.uri.__toString();
    }
}
