/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.http.exceptions;

@safe:
import uim.cake;

// Represents an HTTP 500 error.
class InternalErrorException : HttpException {
    /**
     * Constructor
     *
     * @param string|null myMessage If no message is given "Internal Server Error" will be the message
     * @param int|null $code Status code, defaults to 500
     * @param \Throwable|null $previous The previous exception.
     */
    this(Nullable!string myMessage = null, Nullable!int $code = null, ?Throwable $previous = null) {
        if (empty(myMessage)) {
            myMessage = "Internal Server Error";
        }
        super.this(myMessage, $code, $previous);
    }
}
