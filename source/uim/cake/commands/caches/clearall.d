module uim.cake.command;

@safe:
import uim.cake;

// CacheClearall command.
class CacheClearallCommand : Command {
    // Get the command name.
    static string defaultName() {
        return "cache clear_all";
    }

    /**
     * Hook method for defining this command"s option parser.
     *
     * @see https://book.UIM.org/4/en/console-commands/option-parsers.html
     * @param uim.cake.Console\ConsoleOptionParser $parser The parser to be defined
     * @return \Cake\Console\ConsoleOptionParser The built parser.
     */
    ConsoleOptionParser buildOptionParser(ConsoleOptionParser $parser) {
        $parser = super.buildOptionParser($parser);
        $parser.setDescription("Clear all data in all configured cache engines.");

        return $parser;
    }

    /**
     * Implement this method with your command"s logic.
     *
     * @param uim.cake.Console\Arguments $args The command arguments.
     * @param uim.cake.Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    int execute(Arguments $args, ConsoleIo $io) {
        auto engines = Cache::configured();
        foreach ($engine; engines) {
            this.executeCommand(CacheClearCommand::class, [$engine], $io);
        }

        return static::CODE_SUCCESS;
    }
}
