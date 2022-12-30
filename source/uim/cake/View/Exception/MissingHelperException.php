

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


  */module uim.cake.View\Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Used when a helper cannot be found.
 */
class MissingHelperException : CakeException
{

    protected $_messageTemplate = "Helper class %s could not be found.";
}
