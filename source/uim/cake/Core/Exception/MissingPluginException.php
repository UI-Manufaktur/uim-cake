

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
module uim.cake.cores.Exception;

/**
 * Exception raised when a plugin could not be found
 */
class MissingPluginException : CakeException
{

    protected $_messageTemplate = "Plugin %s could not be found.";
}
