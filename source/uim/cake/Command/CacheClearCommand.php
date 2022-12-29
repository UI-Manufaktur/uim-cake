


 *



 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Command;

import uim.cake.caches.Cache;
import uim.cake.caches.engines.ApcuEngine;
import uim.cake.caches.engines.WincacheEngine;
import uim.cake.caches.InvalidArgumentException;
import uim.cake.consoles.Arguments;
import uim.cake.consoles.ConsoleIo;
import uim.cake.consoles.ConsoleOptionParser;

/**
 * CacheClear command.
 */
class CacheClearCommand : Command
{

    public static function defaultName(): string
    {
        return "cache clear";
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
        $parser = parent::buildOptionParser($parser);
        $parser
            .setDescription("Clear all data in a single cache engine")
            .addArgument("engine", [
                "help": "The cache engine to clear." .
                    "For example, `cake cache clear _cake_model_` will clear the model cache." .
                    " Use `cake cache list` to list available engines.",
                "required": true,
            ]);

        return $parser;
    }

    /**
     * Implement this method with your command"s logic.
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    function execute(Arguments $args, ConsoleIo $io): ?int
    {
        $name = (string)$args.getArgument("engine");
        try {
            $io.out("Clearing {$name}");

            $engine = Cache::pool($name);
            Cache::clear($name);
            if ($engine instanceof ApcuEngine) {
                $io.warning("ApcuEngine detected: Cleared {$name} CLI cache successfully " .
                    "but {$name} web cache must be cleared separately.");
            } elseif ($engine instanceof WincacheEngine) {
                $io.warning("WincacheEngine detected: Cleared {$name} CLI cache successfully " .
                    "but {$name} web cache must be cleared separately.");
            } else {
                $io.out("<success>Cleared {$name} cache</success>");
            }
        } catch (InvalidArgumentException $e) {
            $io.error($e.getMessage());
            this.abort();
        }

        return static::CODE_SUCCESS;
    }
}
