


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Exception;

import uim.cake.Core\Exception\CakeException;

/**
 * Class MissingConnectionException
 */
class MissingConnectionException : CakeException
{
    /**
     * @inheritDoc
     */
    protected $_messageTemplate = 'Connection to %s could not be established: %s';
}
