

/**
 * CakePHP(tm) : Rapid Development Framework (http://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @since         3.5.0
 * @license       http://www.opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite;

import uim.cake.console.consoleIo;

/**
 * Class that dispatches to the legacy ShellDispatcher using the same signature
 * as the newer CommandRunner
 */
class LegacyCommandRunner
{
    /**
     * Mimics functionality of Cake\Console\CommandRunner
     *
     * @param array $argv Argument array
     * @param \Cake\Console\ConsoleIo|null $io A ConsoleIo instance.
     * @return int
     */
    function run(array $argv, ?ConsoleIo $io = null): int
    {
        $dispatcher = new LegacyShellDispatcher($argv, true, $io);

        return $dispatcher.dispatch();
    }
}
