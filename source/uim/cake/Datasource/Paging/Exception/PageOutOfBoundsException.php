

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *

 * @since         3.5.0
 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.datasources.Paging\Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Exception raised when requested page number does not exist.
 */
class PageOutOfBoundsException : CakeException
{

    protected $_messageTemplate = "Page number %s could not be found.";
}

// phpcs:disable
class_exists("Cake\Datasource\Exception\PageOutOfBoundsException");
// phpcs:enable
