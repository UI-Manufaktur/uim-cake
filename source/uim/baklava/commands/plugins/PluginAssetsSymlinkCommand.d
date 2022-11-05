module uim.baklava.command;

import uim.baklava.console.Arguments;
import uim.baklava.console.consoleIo;
import uim.baklava.console.consoleOptionParser;

/**
 * Command for symlinking / copying plugin assets to app's webroot.
 *
 * @psalm-suppress PropertyNotSetInConstructor
 */
class PluginAssetsSymlinkCommand : Command {
    use PluginAssetsTrait;


    static string defaultName() {
        return 'plugin assets symlink';
    }

    /**
     * Execute the command
     *
     * Attempt to symlink plugin assets to app's webroot. If symlinking fails it
     * fallbacks to copying the assets. For vendor moduled plugin, parent folder
     * for vendor name are created if required.
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    auto execute(Arguments $args, ConsoleIo $io): Nullable!int
    {
        this.io = $io;
        this.args = $args;

        myName = $args.getArgument('name');
        $overwrite = (bool)$args.getOption('overwrite');
        this._process(this._list(myName), false, $overwrite);

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
        $parser.setDescription([
            'Symlink (copy as fallback) plugin assets to app\'s webroot.',
        ]).addArgument('name', [
            'help' => 'A specific plugin you want to symlink assets for.',
            'optional' => true,
        ]).addOption('overwrite', [
            'help' => 'Overwrite existing symlink / folder / files.',
            'default' => false,
            'boolean' => true,
        ]);

        return $parser;
    }
}
