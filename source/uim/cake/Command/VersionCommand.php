


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.6.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Command;

import uim.cake.consoles.Arguments;
import uim.cake.consoles.ConsoleIo;
import uim.cake.Core\Configure;

/**
 * Print out the version of CakePHP in use.
 */
class VersionCommand : Command
{
    /**
     * Print out the version of CakePHP in use.
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int
     */
    function execute(Arguments $args, ConsoleIo $io): ?int
    {
        $io.out(Configure::version());

        return static::CODE_SUCCESS;
    }
}
