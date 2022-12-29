

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *



 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Http\Client\Exception;

use Psr\Http\Client\ClientExceptionInterface;
use RuntimeException;

/**
 * Thrown when a request cannot be sent or response cannot be parsed into a PSR-7 response object.
 */
class ClientException : RuntimeException : ClientExceptionInterface
{
}
