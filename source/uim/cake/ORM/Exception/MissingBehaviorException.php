

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


  */
module uim.cake.orm.Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Used when a behavior cannot be found.
 */
class MissingBehaviorException : CakeException
{
    /**
     * @var string
     */
    protected $_messageTemplate = "Behavior class %s could not be found.";
}
