


 *


 * @since         3.6.0
  */
module uim.cake.consoles.Command;

use ArrayIterator;
import uim.cake.consoles.Arguments;
import uim.cake.consoles.BaseCommand;
import uim.cake.consoles.CommandCollection;
import uim.cake.consoles.CommandCollectionAwareInterface;
import uim.cake.consoles.ConsoleIo;
import uim.cake.consoles.ConsoleOptionParser;
import uim.cake.consoles.ConsoleOutput;
import uim.cake.core.Configure;
import uim.cake.core.Plugin;
use SimpleXMLElement;

/**
 * Print out command list
 */
class HelpCommand : BaseCommand : CommandCollectionAwareInterface
{
    /**
     * The command collection to get help on.
     *
     * @var uim.cake.Console\CommandCollection
     */
    protected $commands;


    function setCommandCollection(CommandCollection $commands): void
    {
        this.commands = $commands;
    }

    /**
     * Main function Prints out the list of commands.
     *
     * @param uim.cake.Console\Arguments $args The command arguments.
     * @param uim.cake.Console\ConsoleIo $io The console io
     * @return int
     */
    function execute(Arguments $args, ConsoleIo $io): ?int
    {
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
     * @param uim.cake.Console\ConsoleIo $io The console io
     * @param iterable $commands The command collection to output.
     * @return void
     */
    protected function asText(ConsoleIo $io, iterable $commands): void
    {
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
            $namespace = str_replace("\\", "/", $matches[1]);
            $prefix = "App";
            if ($namespace == "Cake") {
                $prefix = "CakePHP";
            } elseif (in_array($namespace, $plugins, true)) {
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
                $io.out(" - " . $data["name"]);
                if ($data["description"]) {
                    $io.info(str_pad(" \u{2514}", 13, "\u{2500}") . " " . $data["description"]);
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
     * @param uim.cake.Console\ConsoleIo $io IO object.
     * @return void
     */
    protected function outputPaths(ConsoleIo $io): void
    {
        $paths = [];
        if (Configure::check("App.dir")) {
            $appPath = rtrim(Configure::read("App.dir"), DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
            // Extra space is to align output
            $paths["app"] = " " . $appPath;
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
     * @return string
     */
    protected function getShortestName(array $names): string
    {
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
     * @param uim.cake.Console\ConsoleIo $io The console io
     * @param iterable $commands The command collection to output
     * @return void
     */
    protected function asXml(ConsoleIo $io, iterable $commands): void
    {
        $shells = new SimpleXMLElement("<shells></shells>");
        foreach ($commands as $name: $class) {
            if (is_object($class)) {
                $class = get_class($class);
            }
            $shell = $shells.addChild("shell");
            $shell.addAttribute("name", $name);
            $shell.addAttribute("call_as", $name);
            $shell.addAttribute("provider", $class);
            $shell.addAttribute("help", $name . " -h");
        }
        $io.setOutputAs(ConsoleOutput::RAW);
        $io.out($shells.saveXML());
    }

    /**
     * Gets the option parser instance and configures it.
     *
     * @param uim.cake.Console\ConsoleOptionParser $parser The parser to build
     * @return uim.cake.Console\ConsoleOptionParser
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
