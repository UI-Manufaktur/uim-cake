

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *



  */
module uim.cake.http.Client;

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
     *
     * @var int
     */
    const STATUS_OK = 200;

    /**
     * HTTP 201 code
     *
     * @var int
     */
    const STATUS_CREATED = 201;

    /**
     * HTTP 202 code
     *
     * @var int
     */
    const STATUS_ACCEPTED = 202;

    /**
     * HTTP 203 code
     *
     * @var int
     */
    const STATUS_NON_AUTHORITATIVE_INFORMATION = 203;

    /**
     * HTTP 204 code
     *
     * @var int
     */
    const STATUS_NO_CONTENT = 204;

    /**
     * HTTP 301 code
     *
     * @var int
     */
    const STATUS_MOVED_PERMANENTLY = 301;

    /**
     * HTTP 302 code
     *
     * @var int
     */
    const STATUS_FOUND = 302;

    /**
     * HTTP 303 code
     *
     * @var int
     */
    const STATUS_SEE_OTHER = 303;

    /**
     * HTTP 307 code
     *
     * @var int
     */
    const STATUS_TEMPORARY_REDIRECT = 307;

    /**
     * HTTP 308 code
     *
     * @var int
     */
    const STATUS_PERMANENT_REDIRECT = 308;

    /**
     * HTTP GET method
     *
     * @var string
     */
    const METHOD_GET = "GET";

    /**
     * HTTP POST method
     *
     * @var string
     */
    const METHOD_POST = "POST";

    /**
     * HTTP PUT method
     *
     * @var string
     */
    const METHOD_PUT = "PUT";

    /**
     * HTTP DELETE method
     *
     * @var string
     */
    const METHOD_DELETE = "DELETE";

    /**
     * HTTP PATCH method
     *
     * @var string
     */
    const METHOD_PATCH = "PATCH";

    /**
     * HTTP OPTIONS method
     *
     * @var string
     */
    const METHOD_OPTIONS = "OPTIONS";

    /**
     * HTTP TRACE method
     *
     * @var string
     */
    const METHOD_TRACE = "TRACE";

    /**
     * HTTP HEAD method
     *
     * @var string
     */
    const METHOD_HEAD = "HEAD";

    /**
     * The array of cookies in the response.
     *
     * @var array
     */
    protected $_cookies = [];

    /**
     * Get all cookies
     */
    array cookies(): array
    {
        return _cookies;
    }
}
