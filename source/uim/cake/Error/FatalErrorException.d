

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.errors;

import uim.cake.core.Exception\CakeException;
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
        ?int $code = null,
        ?string myfile = null,
        ?int $line = null,
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
