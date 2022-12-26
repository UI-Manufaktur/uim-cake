


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.View\Exception;

import uim.cake.cores.Exception\CakeException;

/**
 * Used when a view class file cannot be found.
 */
class MissingViewException : CakeException
{
    /**
     * @inheritDoc
     */
    protected $_messageTemplate = 'View class "%s" is missing.';
}
