

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
module uim.cake.ORM\Exception;

use Cake\Core\Exception\CakeException;

/**
 * Used when a behavior cannot be found.
 */
class MissingBehaviorException : CakeException
{
    /**
     * @var string
     */
    protected $_messageTemplate = "Behavior class %s could not be found.";
}
