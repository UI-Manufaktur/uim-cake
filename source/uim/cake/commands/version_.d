module uim.cake.command;

@safe:
import uim.cake;

/**
 * Print out the version of UIM in use.
 */
class VersionCommand : Command {
    /**
     * Print out the version of UIM in use.
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int
     */
    int execute(Arguments $args, ConsoleIo $io) {
        $io.out(Configure::version());

        return static::CODE_SUCCESS;
    }
}
