

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *

 * @since         3.0.0
  */
module uim.cake.consoles.Exception;

/**
 * Used when a shell method cannot be found.
 */
class MissingShellMethodException : ConsoleException
{
    /**
     * @var string
     */
    protected $_messageTemplate = "Unknown command %1\$s %2\$s.\nFor usage try `cake %1\$s --help`";
}
