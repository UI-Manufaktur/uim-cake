module uim.cakemmand;

import uim.cake.caches\Cache;
import uim.cake.console.Arguments;
import uim.cake.console.consoleIo;
import uim.cake.console.consoleOptionParser;

/**
 * CacheClearall command.
 */
class CacheClearallCommand : Command {
    /**
     * Get the command name.
     */
    static string defaultName() {
        return "cache clear_all";
    }

    /**
     * Hook method for defining this command"s option parser.
     *
     * @see https://book.cakephp.org/4/en/console-commands/option-parsers.html
     * @param \Cake\Console\ConsoleOptionParser $parser The parser to be defined
     * @return \Cake\Console\ConsoleOptionParser The built parser.
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
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    int execute(Arguments $args, ConsoleIo $io) {
        $engines = Cache::configured();
        foreach ($engines as $engine) {
            this.executeCommand(CacheClearCommand::class, [$engine], $io);
        }

        return static::CODE_SUCCESS;
    }
}
