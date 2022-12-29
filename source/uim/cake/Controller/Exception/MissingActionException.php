

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.controllers.Exception;

import uim.cake.cores.exceptions.CakeException;

/**
 * Missing Action exception - used when a controller action
 * cannot be found, or when the controller's isAction() method returns false.
 */
class MissingActionException : CakeException
{
    /**
     * @inheritDoc
     */
    protected $_messageTemplate = 'Action %s::%s() could not be found, or is not accessible.';
}
