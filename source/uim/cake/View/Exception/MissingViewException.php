


 *


 * @since         3.0.0
  */
module uim.cake.View\Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Used when a view class file cannot be found.
 */
class MissingViewException : CakeException
{

    protected $_messageTemplate = "View class "%s" is missing.";
}
