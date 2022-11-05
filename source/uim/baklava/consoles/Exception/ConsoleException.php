module uim.baklava.console\Exception;

import uim.baklava.console.commandInterface;
import uim.baklava.core.exceptions\CakeException;

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
