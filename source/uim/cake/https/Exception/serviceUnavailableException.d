/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.https\Exception;

use Throwable;

/**
 * Represents an HTTP 503 error.
 */
class ServiceUnavailableException : HttpException
{

    protected $_defaultCode = 503;

    /**
     * Constructor
     *
     * @param string|null myMessage If no message is given "Service Unavailable" will be the message
     * @param int|null $code Status code, defaults to 503
     * @param \Throwable|null $previous The previous exception.
     */
    this(Nullable!string myMessage = null, Nullable!int $code = null, ?Throwable $previous = null) {
        if (empty(myMessage)) {
            myMessage = "Service Unavailable";
        }
        super.this(myMessage, $code, $previous);
    }
}
