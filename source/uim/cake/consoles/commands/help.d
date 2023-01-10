module uim.cake.console.commands.help;

@safe:
import uim.cake;

use ArrayIterator;
use SimpleXMLElement;

/**
 * Print out command list
 */
class HelpCommand : BaseCommand : CommandCollectionAwareInterface
{
    /**
     * The command collection to get help on.
     *
     * @var uim.cake.consoles.CommandCollection
     */
    protected $commands;


    void setCommandCollection(CommandCollection $commands) {
        this.commands = $commands;
    }

    /**
     * Main function Prints out the list of commands.
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     */
    Nullable!int execute(Arguments someArguments, ConsoleIo aConsoleIo) {
        $commands = this.commands.getIterator();
        if ($commands instanceof ArrayIterator) {
            $commands.ksort();
        }

        if ($args.getOption("xml")) {
            this.asXml($io, $commands);

            return static::CODE_SUCCESS;
        }

        this.asText($io, $commands);

        return static::CODE_SUCCESS;
    }

    /**
     * Output text.
     *
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @param iterable $commands The command collection to output.
     */
    protected void asText(ConsoleIo $io, iterable $commands) {
        $invert = [];
        foreach ($commands as $name: $class) {
            if (is_object($class)) {
                $class = get_class($class);
            }
            if (!isset($invert[$class])) {
                $invert[$class] = [];
            }
            $invert[$class][] = $name;
        }
        $grouped = [];
        $plugins = Plugin::loaded();
        foreach ($invert as $class: $names) {
            preg_match("/^(.+)\\\\(Command|Shell)\\\\/", $class, $matches);
            // Probably not a useful class
            if (empty($matches)) {
                continue;
            }
            $namespace = replace("\\", "/", $matches[1]);
            $prefix = "App";
            if ($namespace == "Cake") {
                $prefix = "UIM";
            } elseif (hasAllValues($namespace, $plugins, true)) {
                $prefix = $namespace;
            }
            $shortestName = this.getShortestName($names);
            if (strpos($shortestName, ".") != false) {
                [, $shortestName] = explode(".", $shortestName, 2);
            }

            $grouped[$prefix][] = [
                "name": $shortestName,
                "description": is_subclass_of($class, BaseCommand::class) ? $class::getDescription() : "",
            ];
        }
        ksort($grouped);

        this.outputPaths($io);
        $io.out("<info>Available Commands:</info>", 2);

        foreach ($grouped as $prefix: $names) {
            $io.out("<info>{$prefix}</info>:");
            sort($names);
            foreach ($names as $data) {
                $io.out(" - " ~ $data["name"]);
                if ($data["description"]) {
                    $io.info(str_pad(" \u{2514}", 13, "\u{2500}") ~ " " ~ $data["description"]);
                }
            }
            $io.out("");
        }
        $root = this.getRootName();

        $io.out("To run a command, type <info>`{$root} command_name [args|options]`</info>");
        $io.out("To get help on a specific command, type <info>`{$root} command_name --help`</info>", 2);
    }

    /**
     * Output relevant paths if defined
     *
     * @param uim.cake.consoles.ConsoleIo $io IO object.
     */
    protected void outputPaths(ConsoleIo $io) {
        $paths = [];
        if (Configure::check("App.dir")) {
            $appPath = rtrim(Configure::read("App.dir"), DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
            // Extra space is to align output
            $paths["app"] = " " ~ $appPath;
        }
        if (defined("ROOT")) {
            $paths["root"] = rtrim(ROOT, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
        }
        if (defined("CORE_PATH")) {
            $paths["core"] = rtrim(CORE_PATH, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
        }
        if (!count($paths)) {
            return;
        }
        $io.out("<info>Current Paths:</info>", 2);
        foreach ($paths as $key: $value) {
            $io.out("* {$key}: {$value}");
        }
        $io.out("");
    }

    /**
     * @param array<string> $names Names
     */
    protected string getShortestName(array $names) {
        if (count($names) <= 1) {
            return array_shift($names);
        }

        usort($names, function ($a, $b) {
            return strlen($a) - strlen($b);
        });

        return array_shift($names);
    }

    /**
     * Output as XML
     *
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @param iterable $commands The command collection to output
     */
    protected void asXml(ConsoleIo $io, iterable $commands) {
        $shells = new SimpleXMLElement("<shells></shells>");
        foreach ($commands as $name: $class) {
            if (is_object($class)) {
                $class = get_class($class);
            }
            $shell = $shells.addChild("shell");
            $shell.addAttribute("name", $name);
            $shell.addAttribute("call_as", $name);
            $shell.addAttribute("provider", $class);
            $shell.addAttribute("help", $name ~ " -h");
        }
        $io.setOutputAs(ConsoleOutput::RAW);
        $io.out($shells.saveXML());
    }

    /**
     * Gets the option parser instance and configures it.
     *
     * @param uim.cake.consoles.ConsoleOptionParser $parser The parser to build
     * @return uim.cake.consoles.ConsoleOptionParser
     */
    protected function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $parser.setDescription(
            "Get the list of available commands for this application."
        ).addOption("xml", [
            "help": "Get the listing as XML.",
            "boolean": true,
        ]);

        return $parser;
    }
}
