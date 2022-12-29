

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.controllers.Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Used when a component cannot be found.
 */
class MissingComponentException : CakeException
{

    protected $_messageTemplate = "Component class %s could not be found.";
}
