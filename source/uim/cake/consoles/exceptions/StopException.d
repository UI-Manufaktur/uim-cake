

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *

 * @link          https://book.cakephp.org/4/en/development/errors.html#error-exception-configuration

  */module uim.cake.consoles.Exception;

/**
 * Exception class for halting errors in console tasks
 *
 * @see uim.cake.consoles.Shell::_stop()
 * @see uim.cake.consoles.Shell::error()
 * @see uim.cake.Command\BaseCommand::abort()
 */
class StopException : ConsoleException {
}
