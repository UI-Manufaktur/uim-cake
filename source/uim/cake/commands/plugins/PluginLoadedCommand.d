module uim.cake.command;

import uim.cake.console.Arguments;
import uim.cake.console.consoleIo;
import uim.cake.console.consoleOptionParser;
import uim.cake.core.Plugin;

/**
 * Displays all currently loaded plugins.
 */
class PluginLoadedCommand : Command {

    static string defaultName() {
        return "plugin loaded";
    }

    /**
     * Displays all currently loaded plugins.
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    Nullable!int execute(Arguments someArguments, ConsoleIo aConsoleIo) {
        $loaded = Plugin::loaded();
        $io.out($loaded);

        return static::CODE_SUCCESS;
    }

    /**
     * Get the option parser.
     *
     * @param uim.cake.consoles.ConsoleOptionParser $parser The option parser to update
     * @return uim.cake.consoles.ConsoleOptionParser
     */
    ConsoleOptionParser buildOptionParser(ConsoleOptionParser $parser) {
        $parser.setDescription("Displays all currently loaded plugins.");

        return $parser;
    }
}
