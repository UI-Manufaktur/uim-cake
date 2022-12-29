


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.View\Exception;

import uim.cake.cores.exceptions.CakeException;

/**
 * Used when a view class file cannot be found.
 */
class MissingViewException : CakeException
{

    protected $_messageTemplate = "View class "%s" is missing.";
}
