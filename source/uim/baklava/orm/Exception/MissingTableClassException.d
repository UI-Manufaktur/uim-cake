

/**
 * MissingTableClassException class
 *

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.orm.Exception;

import uim.cake.core.exceptions\CakeException;

/**
 * Exception raised when a Table could not be found.
 */
class MissingTableClassException : CakeException
{
    /**
     * @var string
     */
    protected $_messageTemplate = 'Table class %s could not be found.';
}
