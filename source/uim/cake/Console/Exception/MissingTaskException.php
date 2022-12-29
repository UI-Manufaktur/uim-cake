

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


  */
module uim.cake.consoles.Exception;

/**
 * Used when a Task cannot be found.
 */
class MissingTaskException : ConsoleException
{
    /**
     * @var string
     */
    protected $_messageTemplate = "Task class %s could not be found.";
}
