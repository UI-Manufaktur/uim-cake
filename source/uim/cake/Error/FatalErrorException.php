

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Error;

import uim.cake.cores.exceptions.CakeException;
use Throwable;

/**
 * Represents a fatal error
 */
class FatalErrorException : CakeException
{
    /**
     * Constructor
     *
     * @param string $message Message string.
     * @param int|null $code Code.
     * @param string|null $file File name.
     * @param int|null $line Line number.
     * @param \Throwable|null $previous The previous exception.
     */
    public this(
        string $message,
        ?int $code = null,
        ?string $file = null,
        ?int $line = null,
        ?Throwable $previous = null
    ) {
        super(($message, $code, $previous);
        if ($file) {
            this.file = $file;
        }
        if ($line) {
            this.line = $line;
        }
    }
}
