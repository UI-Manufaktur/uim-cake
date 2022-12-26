


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Exception;

import uim.cake.cores.Exception\CakeException;

/**
 * Class MissingExtensionException
 */
class MissingExtensionException : CakeException
{
    /**
     * @inheritDoc
     */
    // phpcs:ignore Generic.Files.LineLength
    protected $_messageTemplate = 'Database driver %s cannot be used due to a missing PHP extension or unmet dependency. Requested by connection "%s"';
}
