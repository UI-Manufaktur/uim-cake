module uim.baklava.command;

import uim.baklava.cache\Cache;
import uim.baklava.cache\Engine\ApcuEngine;
import uim.baklava.cache\Engine\WincacheEngine;
import uim.baklava.cache\InvalidArgumentException;
import uim.baklava.console.Arguments;
import uim.baklava.console.consoleIo;
import uim.baklava.console.consoleOptionParser;

/**
 * CacheClear command.
 */
class CacheClearCommand : Command {

    static string defaultName() {
        return 'cache clear';
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
        $parser
            .setDescription('Clear all data in a single cache engine')
            .addArgument('engine', [
                'help' => 'The cache engine to clear.' .
                    'For example, `cake cache clear _cake_model_` will clear the model cache.' .
                    ' Use `cake cache list` to list available engines.',
                'required' => true,
            ]);

        return $parser;
    }

    /**
     * Implement this method with your command's logic.
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    auto execute(Arguments $args, ConsoleIo $io): ?int
    {
        myName = (string)$args.getArgument('engine');
        try {
            $io.out("Clearing {myName}");

            $engine = Cache::pool(myName);
            Cache::clear(myName);
            if ($engine instanceof ApcuEngine) {
                $io.warning("ApcuEngine detected: Cleared {myName} CLI cache successfully " .
                    "but {myName} web cache must be cleared separately.");
            } elseif ($engine instanceof WincacheEngine) {
                $io.warning("WincacheEngine detected: Cleared {myName} CLI cache successfully " .
                    "but {myName} web cache must be cleared separately.");
            } else {
                $io.out("<success>Cleared {myName} cache</success>");
            }
        } catch (InvalidArgumentException $e) {
            $io.error($e.getMessage());
            this.abort();
        }

        return static::CODE_SUCCESS;
    }
}
