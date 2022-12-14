module uim.cake.commands;

@safe:
import uim.cake;

/**
 * Command for symlinking / copying plugin assets to app"s webroot.
 *
 * @psalm-suppress PropertyNotSetInConstructor
 */
class PluginAssetsSymlinkCommand : Command {
    use PluginAssetsTrait;


    static string defaultName() {
        return "plugin assets symlink";
    }

    /**
     * Execute the command
     *
     * Attempt to symlink plugin assets to app"s webroot. If symlinking fails it
     * fallbacks to copying the assets. For vendor namespaced plugin, parent folder
     * for vendor name are created if required.
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    Nullable!int execute(Arguments someArguments, ConsoleIo aConsoleIo) {
        this.io = $io;
        this.args = $args;

        $name = $args.getArgument("name");
        canOverwrite = (bool)$args.getOption("overwrite");
        _process(_list($name), false, canOverwrite);

        return static::CODE_SUCCESS;
    }

    /**
     * Get the option parser.
     *
     * @param uim.cake.consoles.ConsoleOptionParser $parser The option parser to update
     * @return uim.cake.consoles.ConsoleOptionParser
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
