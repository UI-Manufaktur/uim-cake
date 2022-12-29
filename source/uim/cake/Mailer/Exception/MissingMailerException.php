


 *


 * @since         3.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Mailer\Exception;

import uim.cake.cores.exceptions.CakeException;

/**
 * Used when a mailer cannot be found.
 */
class MissingMailerException : CakeException
{

    protected $_messageTemplate = "Mailer class "%s" could not be found.";
}
