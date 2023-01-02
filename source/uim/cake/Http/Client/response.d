

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *



  */module uim.cake.http.Client;

import uim.cake.http.Cookie\CookieCollection;
use Laminas\Diactoros\MessageTrait;
use Laminas\Diactoros\Stream;
use Psr\Http\messages.IResponse;
use RuntimeException;
use SimpleXMLElement;

/**
 * : methods for HTTP responses.
 *
 * All the following examples assume that `$response` is an
 * instance of this class.
 *
 * ### Get header values
 *
 * Header names are case-insensitive, but normalized to Title-Case
 * when the response is parsed.
 *
 * ```
 * $val = $response.getHeaderLine("content-type");
 * ```
 *
 * Will read the Content-Type header. You can get all set
 * headers using:
 *
 * ```
 * $response.getHeaders();
 * ```
 *
 * ### Get the response body
 *
 * You can access the response body stream using:
 *
 * ```
 * $content = $response.getBody();
 * ```
 *
 * You can get the body string using:
 *
 * ```
 * $content = $response.getStringBody();
 * ```
 *
 * If your response body is in XML or JSON you can use
 * special content type specific accessors to read the decoded data.
 * JSON data will be returned as arrays, while XML data will be returned
 * as SimpleXML nodes:
 *
 * ```
 * // Get as XML
 * $content = $response.getXml()
 * // Get as JSON
 * $content = $response.getJson()
 * ```
 *
 * If the response cannot be decoded, null will be returned.
 *
 * ### Check the status code
 *
 * You can access the response status code using:
 *
 * ```
 * $content = $response.getStatusCode();
 * ```
 */
class Response : Message : IResponse
{
    use MessageTrait;

    /**
     * The status code of the response.
     *
     */
    protected int $code;

    /**
     * Cookie Collection instance
     *
     * @var uim.cake.http.Cookie\CookieCollection
     */
    protected $cookies;

    /**
     * The reason phrase for the status code
     *
     */
    protected string $reasonPhrase;

    /**
     * Cached decoded XML data.
     *
     * @var \SimpleXMLElement
     */
    protected $_xml;

    /**
     * Cached decoded JSON data.
     *
     * @var mixed
     */
    protected $_json;

    /**
     * Constructor
     *
     * @param array $headers Unparsed headers.
     * @param string $body The response body.
     */
    this(array $headers = [], string $body = "") {
        _parseHeaders($headers);
        if (this.getHeaderLine("Content-Encoding") == "gzip") {
            $body = _decodeGzipBody($body);
        }
        $stream = new Stream("php://memory", "wb+");
        $stream.write($body);
        $stream.rewind();
        this.stream = $stream;
    }

    /**
     * Uncompress a gzip response.
     *
     * Looks for gzip signatures, and if gzinflate() exists,
     * the body will be decompressed.
     *
     * @param string $body Gzip encoded body.
     * @return string
     * @throws \RuntimeException When attempting to decode gzip content without gzinflate.
     */
    protected function _decodeGzipBody(string $body): string
    {
        if (!function_exists("gzinflate")) {
            throw new RuntimeException("Cannot decompress gzip response body without gzinflate()");
        }
        $offset = 0;
        // Look for gzip "signature"
        if (substr($body, 0, 2) == "\x1f\x8b") {
            $offset = 2;
        }
        // Check the format byte
        if (substr($body, $offset, 1) == "\x08") {
            return gzinflate(substr($body, $offset + 8));
        }

        throw new RuntimeException("Invalid gzip response");
    }

    /**
     * Parses headers if necessary.
     *
     * - Decodes the status code and reasonphrase.
     * - Parses and normalizes header names + values.
     *
     * @param array $headers Headers to parse.
     */
    protected void _parseHeaders(array $headers): void
    {
        foreach ($headers as $value) {
            if (substr($value, 0, 5) == "HTTP/") {
                preg_match("/HTTP\/([\d.]+) ([0-9]+)(.*)/i", $value, $matches);
                this.protocol = $matches[1];
                this.code = (int)$matches[2];
                this.reasonPhrase = trim($matches[3]);
                continue;
            }
            if (strpos($value, ":") == false) {
                continue;
            }
            [$name, $value] = explode(":", $value, 2);
            $value = trim($value);
            /** @phpstan-var non-empty-string aName */
            $name = trim($name);

            $normalized = strtolower($name);

            if (isset(this.headers[$name])) {
                this.headers[$name][] = $value;
            } else {
                this.headers[$name] = (array)$value;
                this.headerNames[$normalized] = $name;
            }
        }
    }

    /**
     * Check if the response status code was in the 2xx/3xx range
     *
     */
    bool isOk(): bool
    {
        return this.code >= 200 && this.code <= 399;
    }

    /**
     * Check if the response status code was in the 2xx range
     *
     */
    bool isSuccess(): bool
    {
        return this.code >= 200 && this.code <= 299;
    }

    /**
     * Check if the response had a redirect status code.
     *
     */
    bool isRedirect(): bool
    {
        $codes = [
            static::STATUS_MOVED_PERMANENTLY,
            static::STATUS_FOUND,
            static::STATUS_SEE_OTHER,
            static::STATUS_TEMPORARY_REDIRECT,
            static::STATUS_PERMANENT_REDIRECT,
        ];

        return in_array(this.code, $codes, true) &&
            this.getHeaderLine("Location");
    }

    /**
     * {@inheritDoc}
     *
     * @return int The status code.
     */
    function getStatusCode(): int
    {
        return this.code;
    }

    /**
     * {@inheritDoc}
     *
     * @param int $code The status code to set.
     * @param string $reasonPhrase The status reason phrase.
     * @return static A copy of the current object with an updated status code.
     */
    function withStatus($code, $reasonPhrase = "") {
        $new = clone this;
        $new.code = $code;
        $new.reasonPhrase = $reasonPhrase;

        return $new;
    }

    /**
     * {@inheritDoc}
     *
     * @return string The current reason phrase.
     */
    function getReasonPhrase(): string
    {
        return this.reasonPhrase;
    }

    /**
     * Get the encoding if it was set.
     *
     * @return string|null
     */
    function getEncoding(): ?string
    {
        $content = this.getHeaderLine("content-type");
        if (!$content) {
            return null;
        }
        preg_match("/charset\s?=\s?[\""]?([a-z0-9-_]+)[\""]?/i", $content, $matches);
        if (empty($matches[1])) {
            return null;
        }

        return $matches[1];
    }

    /**
     * Get the all cookie data.
     *
     * @return array The cookie data
     */
    function getCookies(): array
    {
        return _getCookies();
    }

    /**
     * Get the cookie collection from this response.
     *
     * This method exposes the response"s CookieCollection
     * instance allowing you to interact with cookie objects directly.
     *
     * @return uim.cake.http.Cookie\CookieCollection
     */
    function getCookieCollection(): CookieCollection
    {
        this.buildCookieCollection();

        return this.cookies;
    }

    /**
     * Get the value of a single cookie.
     *
     * @param string aName The name of the cookie value.
     * @return array|string|null Either the cookie"s value or null when the cookie is undefined.
     */
    function getCookie(string aName) {
        this.buildCookieCollection();

        if (!this.cookies.has($name)) {
            return null;
        }

        return this.cookies.get($name).getValue();
    }

    /**
     * Get the full data for a single cookie.
     *
     * @param string aName The name of the cookie value.
     * @return array|null Either the cookie"s data or null when the cookie is undefined.
     */
    function getCookieData(string aName): ?array
    {
        this.buildCookieCollection();

        if (!this.cookies.has($name)) {
            return null;
        }

        return this.cookies.get($name).toArray();
    }

    /**
     * Lazily build the CookieCollection and cookie objects from the response header
     *
     */
    protected void buildCookieCollection(): void
    {
        if (this.cookies != null) {
            return;
        }
        this.cookies = CookieCollection::createFromHeader(this.getHeader("Set-Cookie"));
    }

    /**
     * Property accessor for `this.cookies`
     *
     * @return array Array of Cookie data.
     */
    protected function _getCookies(): array
    {
        this.buildCookieCollection();

        $out = [];
        /** @var array<uim.cake.Http\Cookie\Cookie> $cookies */
        $cookies = this.cookies;
        foreach ($cookies as $cookie) {
            $out[$cookie.getName()] = $cookie.toArray();
        }

        return $out;
    }

    /**
     * Get the response body as string.
     */
    string getStringBody(): string
    {
        return _getBody();
    }

    /**
     * Get the response body as JSON decoded data.
     *
     * @return mixed
     */
    function getJson() {
        return _getJson();
    }

    /**
     * Get the response body as JSON decoded data.
     *
     * @return mixed
     */
    protected function _getJson() {
        if (_json) {
            return _json;
        }

        return _json = json_decode(_getBody(), true);
    }

    /**
     * Get the response body as XML decoded data.
     *
     * @return \SimpleXMLElement|null
     */
    function getXml(): ?SimpleXMLElement
    {
        return _getXml();
    }

    /**
     * Get the response body as XML decoded data.
     *
     * @return \SimpleXMLElement|null
     */
    protected function _getXml(): ?SimpleXMLElement
    {
        if (_xml != null) {
            return _xml;
        }
        libxml_use_internal_errors();
        $data = simplexml_load_string(_getBody());
        if ($data) {
            _xml = $data;

            return _xml;
        }

        return null;
    }

    /**
     * Provides magic __get() support.
     *
     * @return array<string>
     */
    protected function _getHeaders(): array
    {
        $out = [];
        foreach (this.headers as $key: $values) {
            $out[$key] = implode(",", $values);
        }

        return $out;
    }

    /**
     * Provides magic __get() support.
     *
     */
    protected string _getBody(): string
    {
        this.stream.rewind();

        return this.stream.getContents();
    }
}
