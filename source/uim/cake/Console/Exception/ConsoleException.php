

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *

 * @link          https://book.cakephp.org/4/en/development/errors.html#error-exception-configuration

  */module uim.cake.consoles.Exception;

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
