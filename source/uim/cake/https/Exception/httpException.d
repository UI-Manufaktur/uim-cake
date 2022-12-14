

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.https\Exception;

import uim.cake.core.exceptions\CakeException;

/**
 * Parent class for all the HTTP related exceptions in UIM.
 * All HTTP status/error related exceptions should extend this class so
 * catch blocks can be specifically typed.
 *
 * You may also use this as a meaningful bridge to {@link \Cake\Core\Exception\CakeException}, e.g.:
 * throw new \Cake\Network\Exception\HttpException("HTTP Version Not Supported", 505);
 */
class HttpException : CakeException
{

    protected $_defaultCode = 500;

    /**
     * @var array
     */
    protected $headers = [];

    /**
     * Set a single HTTP response header.
     *
     * @param string $header Header name
     * @param array<string>|string|null myValue Header value
     */
    void setHeader(string aHeader, myValue = null) {
        this.headers[aHeader] = myValue;
    }

    /**
     * Sets HTTP response headers.
     *
     * @param array $headers Array of header name and value pairs.
     */
    void setHeaders(array $headers) {
        this.headers = $headers;
    }

    /**
     * Returns array of response headers.
     *
     * @return array
     */
    auto getHeaders(): array
    {
        return this.headers;
    }
}
