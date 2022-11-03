

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.orm.Exception;

import uim.cake.core.Exception\CakeException;

/**
 * Used when a behavior cannot be found.
 */
class MissingBehaviorException : CakeException
{
    /**
     * @var string
     */
    protected $_messageTemplate = 'Behavior class %s could not be found.';
}
