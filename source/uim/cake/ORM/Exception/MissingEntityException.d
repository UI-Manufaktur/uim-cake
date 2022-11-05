

/**
 * MissingEntityException file
 *

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.orm.Exception;

import uim.baklava.core.Exception\CakeException;

/**
 * Exception raised when an Entity could not be found.
 */
class MissingEntityException : CakeException
{
    /**
     * @var string
     */
    protected $_messageTemplate = 'Entity class %s could not be found.';
}
