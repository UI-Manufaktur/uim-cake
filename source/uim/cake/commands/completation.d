module uim.cakemmand;

import uim.cake.console.Arguments;
import uim.cake.console.commandCollection;
import uim.cake.console.commandCollectionAwareInterface;
import uim.cake.console.consoleIo;
import uim.cake.console.consoleOptionParser;
import uim.cake.console.Shell;
import uim.cakeilities.Inflector;
use ReflectionClass;
use ReflectionMethod;

/**
 * Provide command completion shells such as bash.
 */
class CompletionCommand : Command : ICommandCollectionAware
{
    /**
     * @var \Cake\Console\CommandCollection
     */
    protected $commands;

    /**
     * Set the command collection used to get completion data on.
     *
     * @param \Cake\Console\CommandCollection $commands The command collection
     */
    void setCommandCollection(CommandCollection $commands) {
        this.commands = $commands;
    }

    /**
     * Gets the option parser instance and configures it.
     *
     * @param \Cake\Console\ConsoleOptionParser $parser The parser to build
     * @return \Cake\Console\ConsoleOptionParser
     */
    function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        myModes = [
            "commands" => "Output a list of available commands",
            "subcommands" => "Output a list of available sub-commands for a command",
            "options" => "Output a list of available options for a command and possible subcommand.",
            "fuzzy" => "Does nothing. Only for backwards compatibility",
        ];
        myModeHelp = "";
        foreach (myModes as myKey => $help) {
            myModeHelp .= "- <info>{myKey}</info> {$help}\n";
        }

        $parser.setDescription(
            "Used by shells like bash to autocomplete command name, options and arguments"
        ).addArgument("mode", [
            "help" => "The type of thing to get completion on.",
            "required" => true,
            "choices" => array_keys(myModes),
        ]).addArgument("command", [
            "help" => "The command name to get information on.",
            "required" => false,
        ]).addArgument("subcommand", [
            "help" => "The sub-command related to command to get information on.",
            "required" => false,
        ]).setEpilog([
            "The various modes allow you to get help information on commands and their arguments.",
            "The available modes are:",
            "",
            myModeHelp,
            "",
            "This command is not intended to be called manually, and should be invoked from a " .
                "terminal completion script.",
        ]);

        return $parser;
    }

    /**
     * Main function Prints out the list of commands.
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int
     */
    auto execute(Arguments $args, ConsoleIo $io): Nullable!int
    {
        myMode = $args.getArgument("mode");
        switch (myMode) {
            case "commands":
                return this.getCommands($args, $io);
            case "subcommands":
                return this.getSubcommands($args, $io);
            case "options":
                return this.getOptions($args, $io);
            case "fuzzy":
                return static::CODE_SUCCESS;
            default:
                $io.err("Invalid mode chosen.");
        }

        return static::CODE_SUCCESS;
    }

    /**
     * Get the list of defined commands.
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int
     */
    protected int getCommands(Arguments $args, ConsoleIo $io) {
        myOptions = [];
        foreach (this.commands as myKey => myValue) {
            $parts = explode(" ", myKey);
            myOptions[] = $parts[0];
        }
        myOptions = array_unique(myOptions);
        $io.out(implode(" ", myOptions));

        return static::CODE_SUCCESS;
    }

    /**
     * Get the list of defined sub-commands.
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int
     */
    protected int getSubcommands(Arguments $args, ConsoleIo $io) {
        myName = $args.getArgument("command");
        if (myName === null || myName == "") {
            return static::CODE_SUCCESS;
        }

        myOptions = [];
        foreach (this.commands as myKey => myValue) {
            $parts = explode(" ", myKey);
            if ($parts[0] !== myName) {
                continue;
            }

            // Space separate command name, collect
            // hits as subcommands
            if (count($parts) > 1) {
                myOptions[] = implode(" ", array_slice($parts, 1));
                continue;
            }

            // Handle class strings
            if (is_string(myValue)) {
                $reflection = new ReflectionClass(myValue);
                myValue = $reflection.newInstance();
            }
            if (myValue instanceof Shell) {
                myShellCommands = this.shellSubcommands(myValue);
                myOptions = array_merge(myOptions, myShellCommands);
            }
        }
        myOptions = array_unique(myOptions);
        $io.out(implode(" ", myOptions));

        return static::CODE_SUCCESS;
    }

    /**
     * Reflect the subcommands names out of a shell.
     *
     * @param \Cake\Console\Shell myShell The shell to get commands for
     * @return array<string> A list of commands
     */
    protected auto shellSubcommands(Shell myShell): array
    {
        myShell.initialize();
        myShell.loadTasks();

        $optionParser = myShell.getOptionParser();
        $subcommands = $optionParser.subcommands();

        $output = array_keys($subcommands);

        // If there are no formal subcommands all methods
        // on a shell are "subcommands"
        if (count($subcommands) === 0) {
            /** @psalm-suppress DeprecatedClass */
            $coreShellReflection = new ReflectionClass(Shell::class);
            $reflection = new ReflectionClass(myShell);
            foreach ($reflection.getMethods(ReflectionMethod::IS_PUBLIC) as $method) {
                if (
                    myShell.hasMethod($method.getName())
                    && !$coreShellReflection.hasMethod($method.getName())
                ) {
                    $output[] = $method.getName();
                }
            }
        }
        $taskNames = array_map("Cake\Utility\Inflector::underscore", myShell.taskNames);
        $output = array_merge($output, $taskNames);

        return array_unique($output);
    }

    /**
     * Get the options for a command or subcommand
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int
     */
    protected auto getOptions(Arguments $args, ConsoleIo $io): Nullable!int
    {
        myName = $args.getArgument("command");
        $subcommand = $args.getArgument("subcommand");

        myOptions = [];
        foreach (this.commands as myKey => myValue) {
            $parts = explode(" ", myKey);
            if ($parts[0] !== myName) {
                continue;
            }
            if ($subcommand && !isset($parts[1])) {
                continue;
            }
            if ($subcommand && isset($parts[1]) && $parts[1] !== $subcommand) {
                continue;
            }

            // Handle class strings
            if (is_string(myValue)) {
                $reflection = new ReflectionClass(myValue);
                myValue = $reflection.newInstance();
            }
            $parser = null;
            if (myValue instanceof Command) {
                $parser = myValue.getOptionParser();
            }
            if (myValue instanceof Shell) {
                myValue.initialize();
                myValue.loadTasks();

                $parser = myValue.getOptionParser();
                $subcommand = Inflector::camelize((string)$subcommand);
                if ($subcommand && myValue.hasTask($subcommand)) {
                    $parser = myValue.{$subcommand}.getOptionParser();
                }
            }

            if ($parser) {
                foreach ($parser.options() as myName => $option) {
                    myOptions[] = "--myName";
                    $short = $option.short();
                    if ($short) {
                        myOptions[] = "-$short";
                    }
                }
            }
        }
        myOptions = array_unique(myOptions);
        $io.out(implode(" ", myOptions));

        return static::CODE_SUCCESS;
    }
}
