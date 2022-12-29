

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


  */
module uim.cake.routings.Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Exception raised when a Dispatcher filter could not be found
 */
class MissingDispatcherFilterException : CakeException
{

    protected $_messageTemplate = "Dispatcher filter %s could not be found.";
}
