

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cakensole\Exception;

/**
 * Used when a Task cannot be found.
 */
class MissingTaskException : ConsoleException
{
    /**
     * @var string
     */
    protected $_messageTemplate = 'Task class %s could not be found.';
}
