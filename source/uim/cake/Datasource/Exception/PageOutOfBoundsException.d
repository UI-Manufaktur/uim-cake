

/**
 * CakePHP(tm) : Rapid Development Framework (http://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @since         3.5.0
 * @license       http://www.opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Datasource\Exception;

import uim.cake.core.Exception\CakeException;

/**
 * Exception raised when requested page number does not exist.
 */
class PageOutOfBoundsException : CakeException
{
    /**
     * @inheritDoc
     */
    protected $_messageTemplate = 'Page number %s could not be found.';
}
