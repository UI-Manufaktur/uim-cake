module uim.cake.commands;

@safe:
import uim.cake;

/**
 * Command for removing plugin assets from app"s webroot.
 *
 * @psalm-suppress PropertyNotSetInConstructor
 */
class PluginAssetsRemoveCommand : Command {
    use PluginAssetsTrait;


    static string defaultName() {
        return "plugin assets remove";
    }

    /**
     * Execute the command
     *
     * Remove plugin assets from app"s webroot.
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    Nullable!int execute(Arguments someArguments, ConsoleIo aConsoleIo) {
        this.io = $io;
        this.args = $args;

        $name = $args.getArgument("name");
        $plugins = _list($name);

        foreach ($plugins as $plugin: aConfig) {
            this.io.out();
            this.io.out("For plugin: " ~ $plugin);
            this.io.hr();

            _remove(aConfig);
        }

        this.io.out();
        this.io.out("Done");

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
            "Remove plugin assets from app\"s webroot.",
        ]).addArgument("name", [
            "help": "A specific plugin you want to remove.",
            "required": false,
        ]);

        return $parser;
    }
}
