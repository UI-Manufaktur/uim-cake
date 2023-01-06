module uim.cake.http.exceptions;

import uim.cake.core.exceptions.CakeException;

/**
 * Parent class for all the HTTP related exceptions in CakePHP.
 * All HTTP status/error related exceptions should extend this class so
 * catch blocks can be specifically typed.
 *
 * You may also use this as a meaningful bridge to {@link uim.cake.Core\exceptions.CakeException}, e.g.:
 * throw new uim.cake.Network\exceptions.HttpException("HTTP Version Not Supported", 505);
 */
class HttpException : CakeException
{

    protected _defaultCode = 500;

    /**
     * @var array<string, mixed>
     */
    protected $headers = [];

    /**
     * Set a single HTTP response header.
     *
     * @param string $header Header name
     * @param array<string>|string|null $value Header value
     */
    void setHeader(string $header, $value = null) {
        this.headers[$header] = $value;
    }

    /**
     * Sets HTTP response headers.
     *
     * @param array<string, mixed> $headers Array of header name and value pairs.
     */
    void setHeaders(array $headers) {
        this.headers = $headers;
    }

    /**
     * Returns array of response headers.
     *
     * @return array<string, mixed>
     */
    array getHeaders() {
        return this.headers;
    }
}
