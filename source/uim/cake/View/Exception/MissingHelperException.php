

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
module uim.cake.View\Exception;

use Cake\Core\Exception\CakeException;

/**
 * Used when a helper cannot be found.
 */
class MissingHelperException : CakeException
{
    /**
     * @inheritDoc
     */
    protected $_messageTemplate = "Helper class %s could not be found.";
}
