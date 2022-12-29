


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Exception;

import uim.cake.cores.exceptions.CakeException;

/**
 * Class MissingConnectionException
 */
class MissingConnectionException : CakeException
{

    protected $_messageTemplate = "Connection to %s could not be established: %s";
}
