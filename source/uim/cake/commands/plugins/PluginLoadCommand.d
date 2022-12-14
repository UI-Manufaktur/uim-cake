module uim.cake.command;

import uim.cake.console.Arguments;
import uim.cake.console.consoleIo;
import uim.cake.console.consoleOptionParser;
import uim.cake.core.exceptions\MissingPluginException;
import uim.cake.core.Plugin;

/**
 * Command for loading plugins.
 *
 * @psalm-suppress PropertyNotSetInConstructor
 */
class PluginLoadCommand : Command {

    static string defaultName() {
        return "plugin load";
    }

    /**
     * Arguments
     *
     * @var uim.cake.consoles.Arguments
     */
    protected args;

    /**
     * Console IO
     *
     * @var uim.cake.consoles.ConsoleIo
     */
    protected io;

    /**
     * Execute the command
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    int execute(Arguments $args, ConsoleIo $io) {
        this.io = $io;
        this.args = $args;

        myPlugin = $args.getArgument("plugin") ?? "";
        try {
            Plugin::getCollection().findPath(myPlugin);
        } catch (MissingPluginException $e) {
            this.io.err($e.getMessage());
            this.io.err("Ensure you have the correct spelling and casing.");

            return static::CODE_ERROR;
        }

        $app = APP ~ "Application.php";
        if (file_exists($app)) {
            this.modifyApplication($app, myPlugin);

            return static::CODE_SUCCESS;
        }

        return static::CODE_ERROR;
    }

    /**
     * Modify the application class
     *
     * @param string app The Application file to modify.
     * @param string myPlugin The plugin name to add.
     */
    protected void modifyApplication(string app, string myPlugin) {
        myContentss = file_get_contents($app);

        // Find start of bootstrap
        if (!preg_match("/^(\s+)function bootstrap(?:\s*)\(\)/mu", myContentss, $matches, PREG_OFFSET_CAPTURE)) {
            this.io.err("Your Application class does not have a bootstrap() method. Please add one.");
            this.abort();
        }

        $offset = $matches[0][1];
        $indent = $matches[1][0];

        // Find closing function bracket
        if (!preg_match("/^$indent\}\n$/mu", myContentss, $matches, PREG_OFFSET_CAPTURE, $offset)) {
            this.io.err("Your Application class does not have a bootstrap() method. Please add one.");
            this.abort();
        }

        $append = "$indent    \this.addPlugin('%s');\n";
        $insert = replace(", []", "", sprintf($append, myPlugin));

        $offset = $matches[0][1];
        myContentss = subreplace(myContentss, $insert, $offset, 0);

        file_put_contents($app, myContentss);

        this.io.out("");
        this.io.out(sprintf("%s modified", $app));
    }

    /**
     * Get the option parser.
     *
     * @param uim.cake.consoles.ConsoleOptionParser $parser The option parser to update
     * @return uim.cake.consoles.ConsoleOptionParser
     */
    ConsoleOptionParser buildOptionParser(ConsoleOptionParser $parser) {
        $parser.setDescription([
            "Command for loading plugins.",
        ])
        .addArgument("plugin", [
            "help":"Name of the plugin to load. Must be in CamelCase format. Example: cake plugin load Example",
            "required":true,
        ]);

        return $parser;
    }
}
