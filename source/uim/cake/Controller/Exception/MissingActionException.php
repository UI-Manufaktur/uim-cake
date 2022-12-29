

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


  */
module uim.cake.controllers.Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Missing Action exception - used when a controller action
 * cannot be found, or when the controller"s isAction() method returns false.
 */
class MissingActionException : CakeException
{

    protected $_messageTemplate = "Action %s::%s() could not be found, or is not accessible.";
}
