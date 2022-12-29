


 *



  */
module uim.cake.databases.Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Class MissingDriverException
 */
class MissingDriverException : CakeException
{

    protected $_messageTemplate = "Could not find driver `%s` for connection `%s`.";
}
