

/**
 * MissingEntityException file
 *

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://UIM.org UIM(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.orm.Exception;

import uim.cake.core.exceptions\CakeException;

/**
 * Exception raised when an Entity could not be found.
 */
class MissingEntityException : CakeException
{
    /**
     * @var string
     */
    protected $_messageTemplate = "Entity class %s could not be found.";
}
