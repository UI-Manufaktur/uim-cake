
module uim.cake.Command;

import uim.cake.consoles.Arguments;
import uim.cake.consoles.ConsoleIo;
import uim.cake.consoles.ConsoleOptionParser;

/**
 * Command for removing plugin assets from app"s webroot.
 *
 * @psalm-suppress PropertyNotSetInConstructor
 */
class PluginAssetsRemoveCommand : Command
{
    use PluginAssetsTrait;


    static function defaultName(): string
    {
        return "plugin assets remove";
    }

    /**
     * Execute the command
     *
     * Remove plugin assets from app"s webroot.
     *
     * @param uim.cake.Console\Arguments $args The command arguments.
     * @param uim.cake.Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    function execute(Arguments $args, ConsoleIo $io): ?int
    {
        this.io = $io;
        this.args = $args;

        $name = $args.getArgument("name");
        $plugins = _list($name);

        foreach ($plugins as $plugin: $config) {
            this.io.out();
            this.io.out("For plugin: " . $plugin);
            this.io.hr();

            _remove($config);
        }

        this.io.out();
        this.io.out("Done");

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
        $parser.setDescription([
            "Remove plugin assets from app\"s webroot.",
        ]).addArgument("name", [
            "help": "A specific plugin you want to remove.",
            "required": false,
        ]);

        return $parser;
    }
}
