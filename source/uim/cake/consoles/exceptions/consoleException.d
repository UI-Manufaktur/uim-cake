module uim.cake.console\Exception;

import uim.cake.console.commandInterface;
import uim.cakere.exceptions\CakeException;

/**
 * Exception class for Console libraries. This exception will be thrown from Console library
 * classes when they encounter an error.
 */
class ConsoleException : CakeException
{
    /**
     * Default exception code
     *
     * @var int
     */
    protected $_defaultCode = ICommand::CODE_ERROR;
}
