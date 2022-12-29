

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
module uim.cake.Routing\Exception;

import uim.cake.cores.exceptions.CakeException;

/**
 * Exception raised when a Dispatcher filter could not be found
 */
class MissingDispatcherFilterException : CakeException
{

    protected $_messageTemplate = "Dispatcher filter %s could not be found.";
}
