


 *


 * @since         3.6.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Command;

import uim.cake.consoles.Arguments;
import uim.cake.consoles.ConsoleIo;
import uim.cake.cores.Configure;

/**
 * Print out the version of CakePHP in use.
 */
class VersionCommand : Command
{
    /**
     * Print out the version of CakePHP in use.
     *
     * @param uim.cake.Console\Arguments $args The command arguments.
     * @param uim.cake.Console\ConsoleIo $io The console io
     * @return int
     */
    function execute(Arguments $args, ConsoleIo $io): ?int
    {
        $io.out(Configure::version());

        return static::CODE_SUCCESS;
    }
}
