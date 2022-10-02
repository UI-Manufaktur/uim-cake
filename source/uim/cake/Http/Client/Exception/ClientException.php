

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Http\Client\Exception;

use Psr\Http\Client\ClientExceptionInterface;
use RuntimeException;

/**
 * Thrown when a request cannot be sent or response cannot be parsed into a PSR-7 response object.
 */
class ClientException : RuntimeException : ClientExceptionInterface
{
}
