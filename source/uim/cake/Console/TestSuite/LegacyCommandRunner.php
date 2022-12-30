module uim.cake.consoles.TestSuite;

import uim.cake.consoles.ConsoleIo;

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
     * @param uim.cake.consoles.ConsoleIo|null $io A ConsoleIo instance.
     * @return int
     */
    function run(array $argv, ?ConsoleIo $io = null): int
    {
        $dispatcher = new LegacyShellDispatcher($argv, true, $io);

        return $dispatcher.dispatch();
    }
}
