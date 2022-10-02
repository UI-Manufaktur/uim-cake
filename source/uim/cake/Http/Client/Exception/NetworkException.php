

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Http\Client\Exception;

use Psr\Http\Client\NetworkExceptionInterface;
use Psr\Http\Message\RequestInterface;
use RuntimeException;
use Throwable;

/**
 * Thrown when the request cannot be completed because of network issues.
 *
 * There is no response object as this exception is thrown when no response has been received.
 *
 * Example: the target host name can not be resolved or the connection failed.
 */
class NetworkException : RuntimeException : NetworkExceptionInterface
{
    /**
     * @var \Psr\Http\Message\RequestInterface
     */
    protected myRequest;

    /**
     * Constructor.
     *
     * @param string myMessage Exeception message.
     * @param \Psr\Http\Message\RequestInterface myRequest Request instance.
     * @param \Throwable|null $previous Previous Exception
     */
    this(string myMessage, RequestInterface myRequest, ?Throwable $previous = null)
    {
        this.request = myRequest;
        super.this(myMessage, 0, $previous);
    }

    /**
     * Returns the request.
     *
     * The request object MAY be a different object from the one passed to ClientInterface::sendRequest()
     *
     * @return \Psr\Http\Message\RequestInterface
     */
    auto getRequest(): RequestInterface
    {
        return this.request;
    }
}
