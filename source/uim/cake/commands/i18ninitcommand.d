module uim.cake.commands;

@safe:
import uim.cake;

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
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    Nullable!int execute(Arguments someArguments, ConsoleIo aConsoleIo) {
        $language = $args.getArgument("language");
        if (!$language) {
            $language = $io.ask("Please specify language code, e.g. `en`, `eng`, `en_US` etc.");
        }
        if (strlen($language) < 2) {
            $io.err("Invalid language code. Valid is `en`, `eng`, `en_US` etc.");

            return static::CODE_ERROR;
        }

        $paths = App::path("locales");
        if ($args.hasOption("plugin")) {
            $plugin = Inflector::camelize((string)$args.getOption("plugin"));
            $paths = [Plugin::path($plugin) ~ "resources" ~ DIRECTORY_SEPARATOR ~ "locales" ~ DIRECTORY_SEPARATOR];
        }

        $response = $io.ask("What folder?", rtrim($paths[0], DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR);
        $sourceFolder = rtrim($response, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
        $targetFolder = $sourceFolder . $language . DIRECTORY_SEPARATOR;
        if (!is_dir($targetFolder)) {
            mkdir($targetFolder, 0775, true);
        }

        $count = 0;
        $iterator = new DirectoryIterator($sourceFolder);
        foreach ($iterator as $fileinfo) {
            if (!$fileinfo.isFile()) {
                continue;
            }
            $filename = $fileinfo.getFilename();
            $newFilename = $fileinfo.getBasename(".pot");
            $newFilename ~= ".po";

            $io.createFile($targetFolder . $newFilename, file_get_contents($sourceFolder . $filename));
            $count++;
        }

        $io.out("Generated " ~ $count ~ " PO files in " ~ $targetFolder);

        return static::CODE_SUCCESS;
    }

    /**
     * Gets the option parser instance and configures it.
     *
     * @param uim.cake.consoles.ConsoleOptionParser $parser The parser to update
     * @return uim.cake.consoles.ConsoleOptionParser
     */
    function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $parser.setDescription("Initialize a language PO file from the POT file")
           .addOption("plugin", [
               "help": "The plugin to create a PO file in.",
               "short": "p",
           ])
           .addArgument("language", [
               "help": "Two-letter language code to create PO files for.",
           ]);

        return $parser;
    }
}
