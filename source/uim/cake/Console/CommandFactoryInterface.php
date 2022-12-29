

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *


 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Console;

/**
 * An interface for abstracting creation of command and shell instances.
 */
interface CommandFactoryInterface
{
    /**
     * The factory method for creating Command and Shell instances.
     *
     * @param string $className Command/Shell class name.
     * @return uim.cake.Console\Shell|uim.cake.Console\ICommand
     */
    function create(string $className);
}
