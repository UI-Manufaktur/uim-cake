module uim.cake.commands;

@safe:
import uim.cake;

// CacheClearall command.
class CacheClearallCommand : Command {
    //  Get the command name.
    static string defaultName() {
        return "cache clear_all";
    }

    /**
     * Hook method for defining this command"s option parser.
     *
     * @see https://book.cakephp.org/4/en/console-commands/option-parsers.html
     * @param uim.cake.consoles.ConsoleOptionParser $parser The parser to be defined
     * @return uim.cake.consoles.ConsoleOptionParser The built parser.
     */
    function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $parser = super.buildOptionParser($parser);
        $parser.setDescription("Clear all data in all configured cache engines.");

        return $parser;
    }

    /**
     * Implement this method with your command"s logic.
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    Nullable!int execute(Arguments someArguments, ConsoleIo aConsoleIo) {
        $engines = Cache::configured();
        foreach ($engines as $engine) {
            this.executeCommand(CacheClearCommand::class, [$engine], $io);
        }

        return static::CODE_SUCCESS;
    }
}
