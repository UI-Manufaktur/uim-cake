module uim.cake.https.clients;

/**
 * Base class for other HTTP requests/responses
 *
 * Defines some common helper methods, constants
 * and properties.
 */
class Message
{
    /**
     * HTTP 200 code
    */
    public const int STATUS_OK = 200;

    /**
     * HTTP 201 code
    */
    public const int STATUS_CREATED = 201;

    /**
     * HTTP 202 code
    */
    public const int STATUS_ACCEPTED = 202;

    /**
     * HTTP 203 code
    */
    public const int STATUS_NON_AUTHORITATIVE_INFORMATION = 203;

    /**
     * HTTP 204 code
    */
    public const int STATUS_NO_CONTENT = 204;

    /**
     * HTTP 301 code
    */
    public const int STATUS_MOVED_PERMANENTLY = 301;

    /**
     * HTTP 302 code
    */
    public const int STATUS_FOUND = 302;

    /**
     * HTTP 303 code
    */
    public const int STATUS_SEE_OTHER = 303;

    /**
     * HTTP 307 code
    */
    public const int STATUS_TEMPORARY_REDIRECT = 307;

    /**
     * HTTP GET method
     */
    public const string METHOD_GET = "GET";

    /**
     * HTTP POST method
     */
    public const string METHOD_POST = "POST";

    /**
     * HTTP PUT method
     */
    public const string METHOD_PUT = "PUT";

    /**
     * HTTP DELETE method
     */
    public const string METHOD_DELETE = "DELETE";

    /**
     * HTTP PATCH method
     */
    public const string METHOD_PATCH = "PATCH";

    /**
     * HTTP OPTIONS method
     */
    public const string METHOD_OPTIONS = "OPTIONS";

    /**
     * HTTP TRACE method
     */
    public const string METHOD_TRACE = "TRACE";

    /**
     * HTTP HEAD method
     */
    public const string METHOD_HEAD = "HEAD";

    /**
     * The array of cookies in the response.
     *
     * @var array
     */
    protected $_cookies = [];

    /**
     * Get all cookies
     *
     * @return array
     */
    function cookies(): array
    {
        return this._cookies;
    }
}
