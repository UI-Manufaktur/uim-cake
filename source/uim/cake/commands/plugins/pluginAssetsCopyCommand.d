module uim.cake.command;

import uim.cake.console.Arguments;
import uim.cake.console.consoleIo;
import uim.cake.console.consoleOptionParser;

/**
 * Command for copying plugin assets to app"s webroot.
 *
 * @psalm-suppress PropertyNotSetInConstructor
 */
class PluginAssetsCopyCommand : Command {
    use PluginAssetsTrait;


    static string defaultName() {
        return "plugin assets copy";
    }

    /**
     * Execute the command
     *
     * Copying plugin assets to app"s webroot. For vendor moduled plugin,
     * parent folder for vendor name are created if required.
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    Nullable!int execute(Arguments someArguments, ConsoleIo aConsoleIo) {
      this.io = $io;
      this.args = $args;

      myName = $args.getArgument("name");
      $overwrite = (bool)$args.getOption("overwrite");
      _process(_list(myName), true, $overwrite);

      return static::CODE_SUCCESS;
    }

    /**
     * Get the option parser.
     *
     * @param uim.cake.consoles.ConsoleOptionParser $parser The option parser to update
     * @return uim.cake.consoles.ConsoleOptionParser
     */
    ConsoleOptionParser buildOptionParser(ConsoleOptionParser $parser) {
        $parser.setDescription([
            "Copy plugin assets to app\"s webroot.",
        ]).addArgument("name", [
            "help":"A specific plugin you want to copy assets for.",
            "optional":true,
        ]).addOption("overwrite", [
            "help":"Overwrite existing symlink / folder / files.",
            "default":false,
            "boolean":true,
        ]);

        return $parser;
    }
}
