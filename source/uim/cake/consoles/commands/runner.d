module uim.cake.consoles;

@safe:
import uim.cake;

use InvalidArgumentException;
use RuntimeException;

/**
 * Run CLI commands for the provided application.
 */
class CommandRunner : IEventDispatcher
{
    use EventDispatcherTrait;

    /**
     * The application console commands are being run for.
     *
     * @var uim.cake.Core\IConsoleApplication
     */
    protected $app;

    /**
     * The application console commands are being run for.
     *
     * @var uim.cake.consoles.ICommandFactory|null
     */
    protected $factory;

    /**
     * The root command name. Defaults to `cake`.
     */
    protected string $root;

    // Alias mappings.
    protected string[] $aliases = null;

    /**
     * Constructor
     *
     * @param uim.cake.Core\IConsoleApplication $app The application to run CLI commands for.
     * @param string $root The root command name to be removed from argv.
     * @param uim.cake.consoles.ICommandFactory|null $factory Command factory instance.
     */
    this(
        IConsoleApplication $app,
        string $root = "cake",
        ?ICommandFactory $factory = null
    ) {
        this.app = $app;
        this.root = $root;
        this.factory = $factory;
        this.aliases = [
            "--version": "version",
            "--help": "help",
            "-h": "help",
        ];
    }

    /**
     * Replace the entire alias map for a runner.
     *
     * Aliases allow you to define alternate names for commands
     * in the collection. This can be useful to add top level switches
     * like `--version` or `-h`
     *
     * ### Usage
     *
     * ```
     * $runner.setAliases(["--version": "version"]);
     * ```
     *
     * @param array<string> $aliases The map of aliases to replace.
     * @return this
     */
    function setAliases(array $aliases) {
        this.aliases = $aliases;

        return this;
    }

    /**
     * Run the command contained in $argv.
     *
     * Use the application to do the following:
     *
     * - Bootstrap the application
     * - Create the CommandCollection using the console() hook on the application.
     * - Trigger the `Console.buildCommands` event of auto-wiring plugins.
     * - Run the requested command.
     *
     * @param array $argv The arguments from the CLI environment.
     * @param uim.cake.consoles.ConsoleIo|null $io The ConsoleIo instance. Used primarily for testing.
     * @return int The exit code of the command.
     * @throws \RuntimeException
     */
    int run(array $argv, ?ConsoleIo $io = null) {
        this.bootstrap();

        $commands = new CommandCollection([
            "help": HelpCommand::class,
        ]);
        if (class_exists(VersionCommand::class)) {
            $commands.add("version", VersionCommand::class);
        }
        $commands = this.app.console($commands);

        if (this.app instanceof IPluginApplication) {
            $commands = this.app.pluginConsole($commands);
        }
        this.dispatchEvent("Console.buildCommands", ["commands": $commands]);
        this.loadRoutes();

        if (empty($argv)) {
            throw new RuntimeException("Cannot run any commands. No arguments received.");
        }
        // Remove the root executable segment
        array_shift($argv);

        $io = $io ?: new ConsoleIo();

        try {
            [$name, $argv] = this.longestCommandName($commands, $argv);
            $name = this.resolveName($commands, $io, $name);
        } catch (MissingOptionException $e) {
            $io.error($e.getFullMessage());

            return ICommand::CODE_ERROR;
        }

        $result = ICommand::CODE_ERROR;
        $shell = this.getCommand($io, $commands, $name);
        if ($shell instanceof Shell) {
            $result = this.runShell($shell, $argv);
        }
        if ($shell instanceof ICommand) {
            $result = this.runCommand($shell, $argv, $io);
        }

        if ($result == null || $result == true) {
            return ICommand::CODE_SUCCESS;
        }
        if (is_int($result) && $result >= 0 && $result <= 255) {
            return $result;
        }

        return ICommand::CODE_ERROR;
    }

    /**
     * Application bootstrap wrapper.
     *
     * Calls the application"s `bootstrap()` hook. After the application the
     * plugins are bootstrapped.
     */
    protected void bootstrap() {
        this.app.bootstrap();
        if (this.app instanceof IPluginApplication) {
            this.app.pluginBootstrap();
        }
    }

    /**
     * Get the application"s event manager or the global one.
     *
     * @return uim.cake.events.IEventManager
     */
    function getEventManager(): IEventManager
    {
        if (this.app instanceof IPluginApplication) {
            return this.app.getEventManager();
        }

        return EventManager::instance();
    }

    /**
     * Get/set the application"s event manager.
     *
     * If the application does not support events and this method is used as
     * a setter, an exception will be raised.
     *
     * @param uim.cake.events.IEventManager $eventManager The event manager to set.
     * @return this
     * @throws \InvalidArgumentException
     */
    function setEventManager(IEventManager $eventManager) {
        if (this.app instanceof IPluginApplication) {
            this.app.setEventManager($eventManager);

            return this;
        }

        throw new InvalidArgumentException("Cannot set the event manager, the application does not support events.");
    }

    /**
     * Get the shell instance for a given command name
     *
     * @param uim.cake.consoles.ConsoleIo $io The IO wrapper for the created shell class.
     * @param uim.cake.consoles.CommandCollection $commands The command collection to find the shell in.
     * @param string aName The command name to find
     * @return uim.cake.consoles.ICommand|uim.cake.consoles.Shell
     */
    protected function getCommand(ConsoleIo $io, CommandCollection $commands, string aName) {
        $instance = $commands.get($name);
        if (is_string($instance)) {
            $instance = this.createCommand($instance, $io);
        }
        if ($instance instanceof Shell) {
            $instance.setRootName(this.root);
        }
        if ($instance instanceof ICommand) {
            $instance.setName("{this.root} {$name}");
        }
        if ($instance instanceof CommandCollectionAwareInterface) {
            $instance.setCommandCollection($commands);
        }

        return $instance;
    }

    /**
     * Build the longest command name that exists in the collection
     *
     * Build the longest command name that matches a
     * defined command. This will traverse a maximum of 3 tokens.
     *
     * @param uim.cake.consoles.CommandCollection $commands The command collection to check.
     * @param array $argv The CLI arguments.
     * @return array An array of the resolved name and modified argv.
     */
    protected array longestCommandName(CommandCollection $commands, array $argv) {
        for ($i = 3; $i > 1; $i--) {
            $parts = array_slice($argv, 0, $i);
            $name = implode(" ", $parts);
            if ($commands.has($name)) {
                return [$name, array_slice($argv, $i)];
            }
        }
        $name = array_shift($argv);

        return [$name, $argv];
    }

    /**
     * Resolve the command name into a name that exists in the collection.
     *
     * Apply backwards compatible inflections and aliases.
     * Will step forward up to 3 tokens in $argv to generate
     * a command name in the CommandCollection. More specific
     * command names take precedence over less specific ones.
     *
     * @param uim.cake.consoles.CommandCollection $commands The command collection to check.
     * @param uim.cake.consoles.ConsoleIo $io ConsoleIo object for errors.
     * @param string|null $name The name from the CLI args.
     * @return string The resolved name.
     * @throws uim.cake.consoles.exceptions.MissingOptionException
     */
    protected string resolveName(CommandCollection $commands, ConsoleIo $io, Nullable!string aName) {
        if (!$name) {
            $io.err("<error>No command provided. Choose one of the available commands.</error>", 2);
            $name = "help";
        }
        $name = this.aliases[$name] ?? $name;
        if (!$commands.has($name)) {
            $name = Inflector::underscore($name);
        }
        if (!$commands.has($name)) {
            throw new MissingOptionException(
                "Unknown command `{this.root} {$name}`~ " ~
                "Run `{this.root} --help` to get the list of commands.",
                $name,
                $commands.keys()
            );
        }

        return $name;
    }

    /**
     * Execute a Command class.
     *
     * @param uim.cake.consoles.ICommand $command The command to run.
     * @param array $argv The CLI arguments to invoke.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int|null Exit code
     */
    protected Nullable!int runCommand(ICommand $command, array $argv, ConsoleIo $io) {
        try {
            return $command.run($argv, $io);
        } catch (StopException $e) {
            return $e.getCode();
        }
    }

    /**
     * Execute a Shell class.
     *
     * @param uim.cake.consoles.Shell $shell The shell to run.
     * @param array $argv The CLI arguments to invoke.
     * @return int|bool|null Exit code
     */
    protected function runShell(Shell $shell, array $argv) {
        try {
            $shell.initialize();

            return $shell.runCommand($argv, true);
        } catch (StopException $e) {
            return $e.getCode();
        }
    }

    /**
     * The wrapper for creating shell instances.
     *
     * @param string $className Shell class name.
     * @param uim.cake.consoles.ConsoleIo $io The IO wrapper for the created shell class.
     * @return uim.cake.consoles.ICommand|uim.cake.consoles.Shell
     */
    protected function createCommand(string $className, ConsoleIo $io) {
        if (!this.factory) {
            $container = null;
            if (this.app instanceof IContainerApplication) {
                $container = this.app.getContainer();
            }
            this.factory = new CommandFactory($container);
        }

        $shell = this.factory.create($className);
        if ($shell instanceof Shell) {
            $shell.setIo($io);
        }

        return $shell;
    }

    /**
     * Ensure that the application"s routes are loaded.
     *
     * Console commands and shells often need to generate URLs.
     */
    protected void loadRoutes() {
        if (!(this.app instanceof IRoutingApplication)) {
            return;
        }
        $builder = Router::createRouteBuilder("/");

        this.app.routes($builder);
        if (this.app instanceof IPluginApplication) {
            this.app.pluginRoutes($builder);
        }
    }
}
