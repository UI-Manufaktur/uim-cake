module uim.cake.command;

import uim.cake.console.Arguments;
import uim.cake.console.consoleIo;
import uim.cake.console.consoleOptionParser;

/**
 * Command for unloading plugins.
 */
class PluginUnloadCommand : Command {
    /**
     * @inheritDoc
     */
    static string defaultName() {
        return 'plugin unload';
    }

    /**
     * Execute the command
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    int execute(Arguments $args, ConsoleIo $io) {
        myPlugin = $args.getArgument('plugin');
        if (!myPlugin) {
            $io.err('You must provide a plugin name in CamelCase format.');
            $io.err('To unload an "Example" plugin, run `cake plugin unload Example`.');

            return static::CODE_ERROR;
        }

        $app = APP . 'Application.php';
        if (file_exists($app) && this.modifyApplication($app, myPlugin)) {
            $io.out('');
            $io.out(sprintf('%s modified', $app));

            return static::CODE_SUCCESS;
        }

        return static::CODE_ERROR;
    }

    /**
     * Modify the application class.
     *
     * @param string $app Path to the application to update.
     * @param string myPlugin Name of plugin.
     * @return bool If modify passed.
     */
    protected auto modifyApplication(string $app, string myPlugin): bool
    {
        myPlugin = preg_quote(myPlugin, '/');
        myFinder = "/
            # whitespace and addPlugin call
            \s*\\\this\-\>addPlugin\(
            # plugin name in quotes of any kind
            \s*['\"]{myPlugin}['\"]
            # method arguments assuming a literal array with multiline args
            (\s*,[\s\\n]*\[(\\n.*|.*){0,5}\][\\n\s]*)?
            # closing paren of method
            \);/mx";

        myContents = file_get_contents($app);
        $newContent = preg_replace(myFinder, '', myContents);

        if ($newContent === myContents) {
            return false;
        }

        file_put_contents($app, $newContent);

        return true;
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
            'Command for unloading plugins.',
        ])
        .addArgument('plugin', [
            'help' => 'Name of the plugin to unload.',
        ]);

        return $parser;
    }
}
