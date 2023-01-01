module uim.cake.console.commands.help;

@safe:
import uim.cake;

// Print out command list
class HelpCommand : BaseCommand : ICommandCollectionAware {
    // The command collection to get help on.
    protected CommandCollection commands;

    void setCommandCollection(CommandCollection $commands) {
        this.commands = $commands;
    }

    /**
     * Main function Prints out the list of commands.
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int
     */
    Nullable!int execute(Arguments $args, ConsoleIo $io) {
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
        foreach ($commands as myName: myClass) {
            if (is_object(myClass)) {
                myClass = get_class(myClass);
            }
            if (!isset($invert[myClass])) {
                $invert[myClass] = [];
            }
            $invert[myClass][] = myName;
        }
        myGrouped = [];
        myPlugins = Plugin::loaded();
        foreach ($invert as myClass: myNames) {
            preg_match("/^(.+)\\\\(Command|Shell)\\\\/", myClass, $matches);
            // Probably not a useful class
            if (empty($matches)) {
                continue;
            }
            $module = str_replace("\\", "/", $matches[1]);
            $prefix = "App";
            if ($module == "Cake") {
                $prefix = "CakePHP";
            } elseif (in_array($module, myPlugins, true)) {
                $prefix = $module;
            }
            $shortestName = this.getShortestName(myNames);
            if (indexOf($shortestName, ".") != false) {
                [, $shortestName] = explode(".", $shortestName, 2);
            }

            myGrouped[$prefix][] = $shortestName;
        }
        ksort(myGrouped);

        this.outputPaths($io);
        $io.out("<info>Available Commands:</info>", 2);

        foreach (myGrouped as $prefix: myNames) {
            $io.out("<info>{$prefix}</info>:");
            sort(myNames);
            foreach (myNames as myName) {
                $io.out(" - " ~ myName);
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
        myPaths = [];
        if (Configure::check("App.dir")) {
            $appPath = rtrim(Configure::read("App.dir"), DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
            // Extra space is to align output
            myPaths["app"] = " " ~ $appPath;
        }
        if (defined("ROOT")) {
            myPaths["root"] = rtrim(ROOT, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
        }
        if (defined("CORE_PATH")) {
            myPaths["core"] = rtrim(CORE_PATH, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
        }
        if (!count(myPaths)) {
            return;
        }
        $io.out("<info>Current Paths:</info>", 2);
        foreach (myPaths as myKey: myValue) {
            $io.out("* {myKey}: {myValue}");
        }
        $io.out("");
    }

    /**
     * @param array<string> myNames Names
     * @return string
     */
    protected string getShortestName(array myNames) {
        if (count(myNames) <= 1) {
            return array_shift(myNames);
        }

        usort(myNames, function ($a, $b) {
            return strlen($a) - strlen($b);
        });

        return array_shift(myNames);
    }

    /**
     * Output as XML
     *
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @param iterable $commands The command collection to output
     */
    protected void asXml(ConsoleIo $io, iterable $commands) {
        myShells = new SimpleXMLElement("<shells></shells>");
        foreach ($commands as myName: myClass) {
            if (is_object(myClass)) {
                myClass = get_class(myClass);
            }
            myShell = myShells.addChild("shell");
            myShell.addAttribute("name", myName);
            myShell.addAttribute("call_as", myName);
            myShell.addAttribute("provider", myClass);
            myShell.addAttribute("help", myName ~ " -h");
        }
        $io.setOutputAs(ConsoleOutput::RAW);
        $io.out(myShells.saveXML());
    }

    /**
     * Gets the option parser instance and configures it.
     *
     * @param uim.cake.consoles.ConsoleOptionParser $parser The parser to build
     * @return uim.cake.consoles.ConsoleOptionParser
     */
    protected ConsoleOptionParser buildOptionParser(ConsoleOptionParser $parser) {
        $parser.setDescription(
            "Get the list of available commands for this application."
        ).addOption("xml", [
            "help":"Get the listing as XML.",
            "boolean":true,
        ]);

        return $parser;
    }
}
