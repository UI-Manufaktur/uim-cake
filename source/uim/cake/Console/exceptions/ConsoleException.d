module uim.cake.consoles.Exception;

import uim.cake.consoles.ICommand;
import uim.cake.core.exceptions.CakeException;

/**
 * Exception class for Console libraries. This exception will be thrown from Console library
 * classes when they encounter an error.
 */
class ConsoleException : CakeException
{
    /**
     * Default exception code
     *
     */
    protected int $_defaultCode = ICommand::CODE_ERROR;
}
