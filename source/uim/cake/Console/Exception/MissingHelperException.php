

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


  */module uim.cake.consoles.Exception;

/**
 * Used when a Helper cannot be found.
 */
class MissingHelperException : ConsoleException
{
    /**
     */
    protected string $_messageTemplate = "Helper class %s could not be found.";
}
