module uim.cakerors;

import uim.cakere.exceptions\CakeException;
use Throwable;

/**
 * Represents a fatal error
 */
class FatalErrorException : CakeException
{
    /**
     * Constructor
     *
     * @param string myMessage Message string.
     * @param int|null $code Code.
     * @param string|null myfile File name.
     * @param int|null $line Line number.
     * @param \Throwable|null $previous The previous exception.
     */
    this(
        string myMessage,
        Nullable!int $code = null,
        Nullable!string myfile = null,
        Nullable!int $line = null,
        ?Throwable $previous = null
    ) {
        super.this(myMessage, $code, $previous);
        if (myfile) {
            this.file = myfile;
        }
        if ($line) {
            this.line = $line;
        }
    }
}
