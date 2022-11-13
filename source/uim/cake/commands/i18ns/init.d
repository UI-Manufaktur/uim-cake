module uim.cakemmand;

import uim.cake.console.Arguments;
import uim.cake.console.consoleIo;
import uim.cake.console.consoleOptionParser;
import uim.cakere.App;
import uim.cakere.Plugin;
import uim.cakeilities.Inflector;
use DirectoryIterator;

/**
 * Command for interactive I18N management.
 */
class I18nInitCommand : Command {

    static string defaultName() {
        return "i18n init";
    }

    /**
     * Execute the command
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    int execute(Arguments $args, ConsoleIo $io) {
        auto myLanguage = $args.getArgument("language");
        if (!myLanguage) {
            myLanguage = $io.ask("Please specify language code, e.g. `en`, `eng`, `en_US` etc.");
        }
        if (strlen(myLanguage) < 2) {
            $io.err("Invalid language code. Valid is `en`, `eng`, `en_US` etc.");

            return static::CODE_ERROR;
        }

        myPaths = App::path("locales");
        if ($args.hasOption("plugin")) {
            myPlugin = Inflector::camelize((string)$args.getOption("plugin"));
            myPaths = [Plugin::path(myPlugin) . "resources" . DIRECTORY_SEPARATOR . "locales" . DIRECTORY_SEPARATOR];
        }

        $response = $io.ask("What folder?", rtrim(myPaths[0], DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR);
        $sourceFolder = rtrim($response, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
        myTargetFolder = $sourceFolder . myLanguage . DIRECTORY_SEPARATOR;
        if (!is_dir(myTargetFolder)) {
            mkdir(myTargetFolder, 0775, true);
        }

        auto myCount = 0;
        $iterator = new DirectoryIterator($sourceFolder);
        foreach ($iterator as myfileinfo) {
            if (!myfileinfo.isFile()) {
                continue;
            }
            myfilename = myfileinfo.getFilename();
            $newFilename = myfileinfo.getBasename(".pot");
            $newFilename .= ".po";

            $io.createFile(myTargetFolder . $newFilename, file_get_contents($sourceFolder . myfilename));
            myCount++;
        }

        $io.out("Generated " . myCount . " PO files in " . myTargetFolder);

        return static::CODE_SUCCESS;
    }

    /**
     * Gets the option parser instance and configures it.
     *
     * @param \Cake\Console\ConsoleOptionParser $parser The parser to update
     * @return \Cake\Console\ConsoleOptionParser
     */
    function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $parser.setDescription("Initialize a language PO file from the POT file")
           .addOption("plugin", [
               "help" => "The plugin to create a PO file in.",
               "short" => "p",
           ])
           .addArgument("language", [
               "help" => "Two-letter language code to create PO files for.",
           ]);

        return $parser;
    }
}
