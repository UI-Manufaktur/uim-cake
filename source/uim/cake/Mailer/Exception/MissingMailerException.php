


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Mailer\Exception;

import uim.cake.cores.Exception\CakeException;

/**
 * Used when a mailer cannot be found.
 */
class MissingMailerException : CakeException
{
    /**
     * @inheritDoc
     */
    protected $_messageTemplate = "Mailer class "%s" could not be found.";
}
