

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *



  */
module uim.cake.http.Client\Exception;

use Psr\Http\Client\RequestExceptionInterface;
use Psr\Http\messages.RequestInterface;
use RuntimeException;
use Throwable;

/**
 * Exception for when a request failed.
 *
 * Examples:
 *
 *   - Request is invalid (e.g. method is missing)
 *   - Runtime request errors (e.g. the body stream is not seekable)
 */
class RequestException : RuntimeException : RequestExceptionInterface
{
    /**
     * @var \Psr\Http\messages.RequestInterface
     */
    protected $request;

    /**
     * Constructor.
     *
     * @param string $message Exeception message.
     * @param \Psr\Http\messages.RequestInterface $request Request instance.
     * @param \Throwable|null $previous Previous Exception
     */
    this(string $message, RequestInterface $request, ?Throwable $previous = null) {
        this.request = $request;
        super(($message, 0, $previous);
    }

    /**
     * Returns the request.
     *
     * The request object MAY be a different object from the one passed to ClientInterface::sendRequest()
     *
     * @return \Psr\Http\messages.RequestInterface
     */
    function getRequest(): RequestInterface
    {
        return this.request;
    }
}
