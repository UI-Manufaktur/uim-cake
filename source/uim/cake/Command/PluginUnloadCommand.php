
module uim.cake.commands;

import uim.cake.consoles.Arguments;
import uim.cake.consoles.ConsoleIo;
import uim.cake.consoles.ConsoleOptionParser;

/**
 * Command for unloading plugins.
 */
class PluginUnloadCommand : Command {

    static string defaultName()
    {
        return "plugin unload";
    }

    /**
     * Execute the command
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    function execute(Arguments $args, ConsoleIo $io): ?int
    {
        $plugin = $args.getArgument("plugin");
        if (!$plugin) {
            $io.err("You must provide a plugin name in CamelCase format.");
            $io.err("To unload an "Example" plugin, run `cake plugin unload Example`.");

            return static::CODE_ERROR;
        }

        $app = APP . "Application.php";
        if (file_exists($app) && this.modifyApplication($app, $plugin)) {
            $io.out("");
            $io.out(sprintf("%s modified", $app));

            return static::CODE_SUCCESS;
        }

        return static::CODE_ERROR;
    }

    /**
     * Modify the application class.
     *
     * @param string $app Path to the application to update.
     * @param string $plugin Name of plugin.
     * @return bool If modify passed.
     */
    protected bool modifyApplication(string $app, string $plugin) {
        $plugin = preg_quote($plugin, "/");
        $finder = "/
            # whitespace and addPlugin call
            \s*\\\this\-\>addPlugin\(
            # plugin name in quotes of any kind
            \s*["\"]{$plugin}["\"]
            # method arguments assuming a literal array with multiline args
            (\s*,[\s\\n]*\[(\\n.*|.*){0,5}\][\\n\s]*)?
            # closing paren of method
            \);/mx";

        $content = file_get_contents($app);
        $newContent = preg_replace($finder, "", $content);

        if ($newContent == $content) {
            return false;
        }

        file_put_contents($app, $newContent);

        return true;
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
            "Command for unloading plugins.",
        ])
        .addArgument("plugin", [
            "help": "Name of the plugin to unload.",
        ]);

        return $parser;
    }
}
