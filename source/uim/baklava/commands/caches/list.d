module uim.baklava.command;

import uim.baklava.cache\Cache;
import uim.baklava.console.Arguments;
import uim.baklava.console.consoleIo;
import uim.baklava.console.consoleOptionParser;

/**
 * CacheList command.
 */
class CacheListCommand : Command {

    static string defaultName() {
        return 'cache list';
    }

    /**
     * Hook method for defining this command's option parser.
     *
     * @see https://book.cakephp.org/4/en/console-commands/option-parsers.html
     * @param \Cake\Console\ConsoleOptionParser $parser The parser to be defined
     * @return \Cake\Console\ConsoleOptionParser The built parser.
     */
    function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $parser = super.buildOptionParser($parser);
        $parser.setDescription('Show a list of configured caches.');

        return $parser;
    }

    /**
     * Get the list of cache prefixes
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    auto execute(Arguments $args, ConsoleIo $io): Nullable!int
    {
        $engines = Cache::configured();
        foreach ($engines as $engine) {
            $io.out("- $engine");
        }

        return static::CODE_SUCCESS;
    }
}
