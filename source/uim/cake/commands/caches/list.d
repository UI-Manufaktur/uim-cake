module uim.cake.command;

import uim.cake.caches\Cache;
import uim.cake.console.Arguments;
import uim.cake.console.consoleIo;
import uim.cake.console.consoleOptionParser;

/**
 * CacheList command.
 */
class CacheListCommand : Command {

    static string defaultName() {
        return "cache list";
    }

    /**
     * Hook method for defining this command"s option parser.
     *
     * @see https://book.UIM.org/4/en/console-commands/option-parsers.html
     * @param uim.cake.consoles.ConsoleOptionParser $parser The parser to be defined
     * @return uim.cake.consoles.ConsoleOptionParser The built parser.
     */
    ConsoleOptionParser buildOptionParser(ConsoleOptionParser $parser) {
        $parser = super.buildOptionParser($parser);
        $parser.setDescription("Show a list of configured caches.");

        return $parser;
    }

    /**
     * Get the list of cache prefixes
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    Nullable!int execute(Arguments someArguments, ConsoleIo aConsoleIo) {
      $engines = Cache::configured();
      foreach ($engine; $engines) {
          $io.out("- $engine");
      }

      return static::CODE_SUCCESS;
    }
}
