module uim.baklava.command;

import uim.baklava.console.Arguments;
import uim.baklava.console.consoleIo;
import uim.baklava.console.consoleOptionParser;
import uim.baklava.core.Plugin;

/**
 * Displays all currently loaded plugins.
 */
class PluginLoadedCommand : Command {

    static string defaultName() {
        return 'plugin loaded';
    }

    /**
     * Displays all currently loaded plugins.
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    auto execute(Arguments $args, ConsoleIo $io): Nullable!int
    {
        $loaded = Plugin::loaded();
        $io.out($loaded);

        return static::CODE_SUCCESS;
    }

    /**
     * Get the option parser.
     *
     * @param \Cake\Console\ConsoleOptionParser $parser The option parser to update
     * @return \Cake\Console\ConsoleOptionParser
     */
    function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $parser.setDescription('Displays all currently loaded plugins.');

        return $parser;
    }
}
