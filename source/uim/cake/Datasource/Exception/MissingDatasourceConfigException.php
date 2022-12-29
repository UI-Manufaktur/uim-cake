

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
module uim.cake.Datasource\Exception;

import uim.cake.cores.exceptions.CakeException;

/**
 * Exception class to be thrown when a datasource configuration is not found
 */
class MissingDatasourceConfigException : CakeException
{
    /**
     * @var string
     */
    protected $_messageTemplate = "The datasource configuration "%s" was not found.";
}
