


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Exception;

import uim.cake.cores.exceptions.CakeException;

/**
 * Class MissingDriverException
 */
class MissingDriverException : CakeException
{

    protected $_messageTemplate = "Could not find driver `%s` for connection `%s`.";
}
