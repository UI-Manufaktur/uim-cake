

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.https\Exception;

import uim.baklava.core.Exception\CakeException;

/**
 * Parent class for all the HTTP related exceptions in CakePHP.
 * All HTTP status/error related exceptions should extend this class so
 * catch blocks can be specifically typed.
 *
 * You may also use this as a meaningful bridge to {@link \Cake\Core\Exception\CakeException}, e.g.:
 * throw new \Cake\Network\Exception\HttpException('HTTP Version Not Supported', 505);
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
     * @return void
     */
    auto setHeader(string $header, myValue = null): void
    {
        this.headers[$header] = myValue;
    }

    /**
     * Sets HTTP response headers.
     *
     * @param array $headers Array of header name and value pairs.
     * @return void
     */
    auto setHeaders(array $headers): void
    {
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
