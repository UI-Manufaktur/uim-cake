

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


  */
module uim.cake.core.Exception;

/**
 * Exception raised when a plugin could not be found
 */
class MissingPluginException : CakeException
{

    protected $_messageTemplate = "Plugin %s could not be found.";
}
