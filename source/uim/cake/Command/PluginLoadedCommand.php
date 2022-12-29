


 *



  */
module uim.cake.Command;

import uim.cake.consoles.Arguments;
import uim.cake.consoles.ConsoleIo;
import uim.cake.consoles.ConsoleOptionParser;
import uim.cake.core.Plugin;

/**
 * Displays all currently loaded plugins.
 */
class PluginLoadedCommand : Command
{

    public static function defaultName(): string
    {
        return "plugin loaded";
    }

    /**
     * Displays all currently loaded plugins.
     *
     * @param uim.cake.Console\Arguments $args The command arguments.
     * @param uim.cake.Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    function execute(Arguments $args, ConsoleIo $io): ?int
    {
        $loaded = Plugin::loaded();
        $io.out($loaded);

        return static::CODE_SUCCESS;
    }

    /**
     * Get the option parser.
     *
     * @param uim.cake.Console\ConsoleOptionParser $parser The option parser to update
     * @return uim.cake.Console\ConsoleOptionParser
     */
    function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $parser.setDescription("Displays all currently loaded plugins.");

        return $parser;
    }
}
