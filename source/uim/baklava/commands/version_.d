module uim.baklava.command;

import uim.baklava.console.Arguments;
import uim.baklava.console.consoleIo;
import uim.baklava.core.Configure;

/**
 * Print out the version of CakePHP in use.
 */
class VersionCommand : Command {
    /**
     * Print out the version of CakePHP in use.
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int
     */
    int execute(Arguments $args, ConsoleIo $io) {
        $io.out(Configure::version());

        return static::CODE_SUCCESS;
    }
}
