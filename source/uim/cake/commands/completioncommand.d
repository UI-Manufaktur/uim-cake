module uim.cake.commands;

@safe:
import uim.cake;

use ReflectionClass;
use ReflectionMethod;

/**
 * Provide command completion shells such as bash.
 */
class CompletionCommand : Command : CommandCollectionAwareInterface
{
    /**
     * @var uim.cake.consoles.CommandCollection
     */
    protected $commands;

    /**
     * Set the command collection used to get completion data on.
     *
     * @param uim.cake.consoles.CommandCollection $commands The command collection
     */
    void setCommandCollection(CommandCollection $commands) {
        this.commands = $commands;
    }

    /**
     * Gets the option parser instance and configures it.
     *
     * @param uim.cake.consoles.ConsoleOptionParser $parser The parser to build
     * @return uim.cake.consoles.ConsoleOptionParser
     */
    function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $modes = [
            "commands": "Output a list of available commands",
            "subcommands": "Output a list of available sub-commands for a command",
            "options": "Output a list of available options for a command and possible subcommand.",
            "fuzzy": "Does nothing. Only for backwards compatibility",
        ];
        $modeHelp = "";
        foreach ($modes as $key: $help) {
            $modeHelp ~= "- <info>{$key}</info> {$help}\n";
        }

        $parser.setDescription(
            "Used by shells like bash to autocomplete command name, options and arguments"
        ).addArgument("mode", [
            "help": "The type of thing to get completion on.",
            "required": true,
            "choices": array_keys($modes),
        ]).addArgument("command", [
            "help": "The command name to get information on.",
            "required": false,
        ]).addArgument("subcommand", [
            "help": "The sub-command related to command to get information on.",
            "required": false,
        ]).setEpilog([
            "The various modes allow you to get help information on commands and their arguments.",
            "The available modes are:",
            "",
            $modeHelp,
            "",
            "This command is not intended to be called manually, and should be invoked from a " ~
                "terminal completion script.",
        ]);

        return $parser;
    }

    /**
     * Main function Prints out the list of commands.
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     */
    Nullable!int execute(Arguments someArguments, ConsoleIo aConsoleIo) {
        $mode = $args.getArgument("mode");
        switch ($mode) {
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
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     */
    protected int getCommands(Arguments $args, ConsoleIo $io) {
        $options = null;
        foreach (this.commands as $key: $value) {
            $parts = explode(" ", $key);
            $options[] = $parts[0];
        }
        $options = array_unique($options);
        $io.out(implode(" ", $options));

        return static::CODE_SUCCESS;
    }

    /**
     * Get the list of defined sub-commands.
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     */
    protected int getSubcommands(Arguments $args, ConsoleIo $io) {
        $name = $args.getArgument("command");
        if ($name == null || $name == "") {
            return static::CODE_SUCCESS;
        }

        $options = null;
        foreach (this.commands as $key: $value) {
            $parts = explode(" ", $key);
            if ($parts[0] != $name) {
                continue;
            }

            // Space separate command name, collect
            // hits as subcommands
            if (count($parts) > 1) {
                $options[] = implode(" ", array_slice($parts, 1));
                continue;
            }

            // Handle class strings
            if (is_string($value)) {
                $reflection = new ReflectionClass($value);
                $value = $reflection.newInstance();
            }
            if ($value instanceof Shell) {
                $shellCommands = this.shellSubcommands($value);
                $options = array_merge($options, $shellCommands);
            }
        }
        $options = array_unique($options);
        $io.out(implode(" ", $options));

        return static::CODE_SUCCESS;
    }

    /**
     * Reflect the subcommands names out of a shell.
     *
     * @param uim.cake.consoles.Shell $shell The shell to get commands for
     * @return array<string> A list of commands
     */
    protected string[] shellSubcommands(Shell $shell) {
        $shell.initialize();
        $shell.loadTasks();

        $optionParser = $shell.getOptionParser();
        $subcommands = $optionParser.subcommands();

        $output = array_keys($subcommands);

        // If there are no formal subcommands all methods
        // on a shell are "subcommands"
        if (count($subcommands) == 0) {
            /** @psalm-suppress DeprecatedClass */
            $coreShellReflection = new ReflectionClass(Shell::class);
            $reflection = new ReflectionClass($shell);
            foreach ($reflection.getMethods(ReflectionMethod::IS_PUBLIC) as $method) {
                if (
                    $shell.hasMethod($method.getName())
                    && !$coreShellReflection.hasMethod($method.getName())
                ) {
                    $output[] = $method.getName();
                }
            }
        }
        $taskNames = array_map("Cake\Utility\Inflector::underscore", $shell.taskNames);
        $output = array_merge($output, $taskNames);

        return array_unique($output);
    }

    /**
     * Get the options for a command or subcommand
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     */
    protected Nullable!int getOptions(Arguments $args, ConsoleIo $io) {
        $name = $args.getArgument("command");
        $subcommand = $args.getArgument("subcommand");

        $options = null;
        foreach (this.commands as $key: $value) {
            $parts = explode(" ", $key);
            if ($parts[0] != $name) {
                continue;
            }
            if ($subcommand && !isset($parts[1])) {
                continue;
            }
            if ($subcommand && isset($parts[1]) && $parts[1] != $subcommand) {
                continue;
            }

            // Handle class strings
            if (is_string($value)) {
                $reflection = new ReflectionClass($value);
                $value = $reflection.newInstance();
            }
            $parser = null;
            if ($value instanceof Command) {
                $parser = $value.getOptionParser();
            }
            if ($value instanceof Shell) {
                $value.initialize();
                $value.loadTasks();

                $parser = $value.getOptionParser();
                $subcommand = Inflector::camelize((string)$subcommand);
                if ($subcommand && $value.hasTask($subcommand)) {
                    $parser = $value.{$subcommand}.getOptionParser();
                }
            }

            if ($parser) {
                foreach ($parser.options() as $name: $option) {
                    $options[] = "--$name";
                    $short = $option.short();
                    if ($short) {
                        $options[] = "-$short";
                    }
                }
            }
        }
        $options = array_unique($options);
        $io.out(implode(" ", $options));

        return static::CODE_SUCCESS;
    }
}
