module uim.cake.command;

import uim.cake.console.Arguments;
import uim.cake.console.consoleIo;
import uim.cake.core.Configure;

/**
 * Print out the version of UIM in use.
 */
class VersionCommand : Command {
    /**
     * Print out the version of UIM in use.
     *
     * @param uim.cake.Console\Arguments $args The command arguments.
     * @param uim.cake.Console\ConsoleIo $io The console io
     * @return int
     */
    int execute(Arguments $args, ConsoleIo $io) {
        $io.out(Configure::version());

        return static::CODE_SUCCESS;
    }
}
