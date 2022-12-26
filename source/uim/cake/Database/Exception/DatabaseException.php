


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Exception;

import uim.cake.cores.Exception\CakeException;

/**
 * Exception for the database package.
 */
class DatabaseException : CakeException
{
}

// phpcs:disable
class_exists('Cake\Database\Exception');
// phpcs:enable
