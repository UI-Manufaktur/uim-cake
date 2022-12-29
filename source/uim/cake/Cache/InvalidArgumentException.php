

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *


 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Cache;

import uim.cake.cores.exceptions.CakeException;
use Psr\SimpleCache\InvalidArgumentException as InvalidArgumentInterface;

/**
 * Exception raised when cache keys are invalid.
 */
class InvalidArgumentException : CakeException : InvalidArgumentInterface
{
}
