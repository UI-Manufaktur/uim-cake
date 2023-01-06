module uim.cake.commands;

@safe:
import uim.cake;

/**
 * Print out the version of CakePHP in use.
 */
class VersionCommand : Command {
    /**
     * Print out the version of CakePHP in use.
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     */
    Nullable!int execute(Arguments someArguments, ConsoleIo aConsoleIo)
    {
        $io.out(Configure::version());

        return static::CODE_SUCCESS;
    }
}
