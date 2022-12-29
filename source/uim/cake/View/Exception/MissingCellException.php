


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.View\Exception;

import uim.cake.cores.exceptions.CakeException;

/**
 * Used when a cell class file cannot be found.
 */
class MissingCellException : CakeException
{

    protected $_messageTemplate = "Cell class %s is missing.";
}
