

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://book.cakephp.org/4/en/development/errors.html#error-exception-configuration
 * @since         3.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cakensole\Exception;

/**
 * Exception class for halting errors in console tasks
 *
 * @see \Cake\Console\Shell::_stop()
 * @see \Cake\Console\Shell::error()
 * @see \Cake\Command\BaseCommand::abort()
 */
class StopException : ConsoleException
{
}
