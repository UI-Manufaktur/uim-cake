

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://book.cakephp.org/4/en/development/errors.html#error-exception-configuration
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.console\Exception;

import uim.cake.console.commandInterface;
import uim.cake.core.Exception\CakeException;

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
