


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Command;

import uim.cake.consoles.Arguments;
import uim.cake.consoles.ConsoleIo;
import uim.cake.consoles.ConsoleOptionParser;

/**
 * Command for symlinking / copying plugin assets to app"s webroot.
 *
 * @psalm-suppress PropertyNotSetInConstructor
 */
class PluginAssetsSymlinkCommand : Command
{
    use PluginAssetsTrait;


    public static function defaultName(): string
    {
        return "plugin assets symlink";
    }

    /**
     * Execute the command
     *
     * Attempt to symlink plugin assets to app"s webroot. If symlinking fails it
     * fallbacks to copying the assets. For vendor namespaced plugin, parent folder
     * for vendor name are created if required.
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    function execute(Arguments $args, ConsoleIo $io): ?int
    {
        this.io = $io;
        this.args = $args;

        $name = $args.getArgument("name");
        $overwrite = (bool)$args.getOption("overwrite");
        _process(_list($name), false, $overwrite);

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
            "Symlink (copy as fallback) plugin assets to app\"s webroot.",
        ]).addArgument("name", [
            "help": "A specific plugin you want to symlink assets for.",
            "required": false,
        ]).addOption("overwrite", [
            "help": "Overwrite existing symlink / folder / files.",
            "default": false,
            "boolean": true,
        ]);

        return $parser;
    }
}
