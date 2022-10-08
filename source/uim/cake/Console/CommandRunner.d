module uim.cake.console;

@safe:
import uim.cake;

import uim.cake.command\VersionCommand;
import uim.cake.console.command\HelpCommand;
import uim.cake.console.Exception\MissingOptionException;
import uim.cake.console.Exception\StopException;
import uim.cake.core.ConsoleApplicationInterface;
import uim.cake.core.ContainerApplicationInterface;
import uim.cake.core.PluginApplicationInterface;
import uim.cake.Event\IEventDispatcher;
import uim.cake.Event\EventDispatcherTrait;
import uim.cake.Event\EventManager;
import uim.cake.Event\IEventManager;
import uim.cake.Routing\Router;
import uim.cake.Routing\RoutingApplicationInterface;
import uim.cake.Utility\Inflector;
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
     * @var \Cake\Core\ConsoleApplicationInterface
     */
    protected $app;

    /**
     * The application console commands are being run for.
     *
     * @var \Cake\Console\ICommandFactory|null
     */
    protected $factory;

    /**
     * The root command name. Defaults to `cake`.
     *
     * @var string
     */
    protected $root;

    /**
     * Alias mappings.
     *
     * @var array<string>
     */
    protected myAliases = [];

    /**
     * Constructor
     *
     * @param \Cake\Core\ConsoleApplicationInterface $app The application to run CLI commands for.
     * @param string $root The root command name to be removed from argv.
     * @param \Cake\Console\ICommandFactory|null $factory Command factory instance.
     */
    this(
        ConsoleApplicationInterface $app,
        string $root = 'cake',
        ?ICommandFactory $factory = null
    ) {
        this.app = $app;
        this.root = $root;
        this.factory = $factory;
        this.aliases = [
            '--version' => 'version',
            '--help' => 'help',
            '-h' => 'help',
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
     * $runner.setAliases(['--version' => 'version']);
     * ```
     *
     * @param array<string> myAliases The map of aliases to replace.
     * @return this
     */
    auto setAliases(array myAliases) {
        this.aliases = myAliases;

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
     * @param \Cake\Console\ConsoleIo|null $io The ConsoleIo instance. Used primarily for testing.
     * @return int The exit code of the command.
     * @throws \RuntimeException
     */
    function run(array $argv, ?ConsoleIo $io = null): int
    {
        this.bootstrap();

        $commands = new CommandCollection([
            'help' => HelpCommand::class,
        ]);
        if (class_exists(VersionCommand::class)) {
            $commands.add('version', VersionCommand::class);
        }
        $commands = this.app.console($commands);

        if (this.app instanceof PluginApplicationInterface) {
            $commands = this.app.pluginConsole($commands);
        }
        this.dispatchEvent('Console.buildCommands', ['commands' => $commands]);
        this.loadRoutes();

        if (empty($argv)) {
            throw new RuntimeException('Cannot run any commands. No arguments received.');
        }
        // Remove the root executable segment
        array_shift($argv);

        $io = $io ?: new ConsoleIo();

        try {
            [myName, $argv] = this.longestCommandName($commands, $argv);
            myName = this.resolveName($commands, $io, myName);
        } catch (MissingOptionException $e) {
            $io.error($e.getFullMessage());

            return ICommand::CODE_ERROR;
        }

        myResult = ICommand::CODE_ERROR;
        $shell = this.getCommand($io, $commands, myName);
        if ($shell instanceof Shell) {
            myResult = this.runShell($shell, $argv);
        }
        if ($shell instanceof ICommand) {
            myResult = this.runCommand($shell, $argv, $io);
        }

        if (myResult === null || myResult === true) {
            return ICommand::CODE_SUCCESS;
        }
        if (is_int(myResult) && myResult >= 0 && myResult <= 255) {
            return myResult;
        }

        return ICommand::CODE_ERROR;
    }

    /**
     * Application bootstrap wrapper.
     *
     * Calls the application's `bootstrap()` hook. After the application the
     * plugins are bootstrapped.
     *
     * @return void
     */
    protected auto bootstrap(): void
    {
        this.app.bootstrap();
        if (this.app instanceof PluginApplicationInterface) {
            this.app.pluginBootstrap();
        }
    }

    /**
     * Get the application's event manager or the global one.
     *
     * @return \Cake\Event\IEventManager
     */
    auto getEventManager(): IEventManager
    {
        if (this.app instanceof PluginApplicationInterface) {
            return this.app.getEventManager();
        }

        return EventManager::instance();
    }

    /**
     * Get/set the application's event manager.
     *
     * If the application does not support events and this method is used as
     * a setter, an exception will be raised.
     *
     * @param \Cake\Event\IEventManager myEventManager The event manager to set.
     * @return this
     * @throws \InvalidArgumentException
     */
    auto setEventManager(IEventManager myEventManager) {
        if (this.app instanceof PluginApplicationInterface) {
            this.app.setEventManager(myEventManager);

            return this;
        }

        throw new InvalidArgumentException('Cannot set the event manager, the application does not support events.');
    }

    /**
     * Get the shell instance for a given command name
     *
     * @param \Cake\Console\ConsoleIo $io The IO wrapper for the created shell class.
     * @param \Cake\Console\CommandCollection $commands The command collection to find the shell in.
     * @param string myName The command name to find
     * @return \Cake\Console\ICommand|\Cake\Console\Shell
     */
    protected auto getCommand(ConsoleIo $io, CommandCollection $commands, string myName) {
        $instance = $commands.get(myName);
        if (is_string($instance)) {
            $instance = this.createCommand($instance, $io);
        }
        if ($instance instanceof Shell) {
            $instance.setRootName(this.root);
        }
        if ($instance instanceof ICommand) {
            $instance.setName("{this.root} {myName}");
        }
        if ($instance instanceof ICommandCollectionAware) {
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
     * @param \Cake\Console\CommandCollection $commands The command collection to check.
     * @param array $argv The CLI arguments.
     * @return array An array of the resolved name and modified argv.
     */
    protected auto longestCommandName(CommandCollection $commands, array $argv): array
    {
        for ($i = 3; $i > 1; $i--) {
            $parts = array_slice($argv, 0, $i);
            myName = implode(' ', $parts);
            if ($commands.has(myName)) {
                return [myName, array_slice($argv, $i)];
            }
        }
        myName = array_shift($argv);

        return [myName, $argv];
    }

    /**
     * Resolve the command name into a name that exists in the collection.
     *
     * Apply backwards compatible inflections and aliases.
     * Will step forward up to 3 tokens in $argv to generate
     * a command name in the CommandCollection. More specific
     * command names take precedence over less specific ones.
     *
     * @param \Cake\Console\CommandCollection $commands The command collection to check.
     * @param \Cake\Console\ConsoleIo $io ConsoleIo object for errors.
     * @param string|null myName The name from the CLI args.
     * @return string The resolved name.
     * @throws \Cake\Console\Exception\MissingOptionException
     */
    protected string resolveName(CommandCollection $commands, ConsoleIo $io, ?string myName)
    {
        if (!myName) {
            $io.err('<error>No command provided. Choose one of the available commands.</error>', 2);
            myName = 'help';
        }
        myName = this.aliases[myName] ?? myName;
        if (!$commands.has(myName)) {
            myName = Inflector::underscore(myName);
        }
        if (!$commands.has(myName)) {
            throw new MissingOptionException(
                "Unknown command `{this.root} {myName}`. " .
                "Run `{this.root} --help` to get the list of commands.",
                myName,
                $commands.keys()
            );
        }

        return myName;
    }

    /**
     * Execute a Command class.
     *
     * @param \Cake\Console\ICommand $command The command to run.
     * @param array $argv The CLI arguments to invoke.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null Exit code
     */
    protected auto runCommand(ICommand $command, array $argv, ConsoleIo $io): ?int
    {
        try {
            return $command.run($argv, $io);
        } catch (StopException $e) {
            return $e.getCode();
        }
    }

    /**
     * Execute a Shell class.
     *
     * @param \Cake\Console\Shell $shell The shell to run.
     * @param array $argv The CLI arguments to invoke.
     * @return int|bool|null Exit code
     */
    protected auto runShell(Shell $shell, array $argv) {
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
     * @param string myClassName Shell class name.
     * @param \Cake\Console\ConsoleIo $io The IO wrapper for the created shell class.
     * @return \Cake\Console\ICommand|\Cake\Console\Shell
     */
    protected auto createCommand(string myClassName, ConsoleIo $io) {
        if (!this.factory) {
            myContainer = null;
            if (this.app instanceof ContainerApplicationInterface) {
                myContainer = this.app.getContainer();
            }
            this.factory = new CommandFactory(myContainer);
        }

        $shell = this.factory.create(myClassName);
        if ($shell instanceof Shell) {
            $shell.setIo($io);
        }

        return $shell;
    }

    /**
     * Ensure that the application's routes are loaded.
     *
     * Console commands and shells often need to generate URLs.
     *
     * @return void
     */
    protected auto loadRoutes(): void
    {
        if (!(this.app instanceof RoutingApplicationInterface)) {
            return;
        }
        myBuilder = Router::createRouteBuilder('/');

        this.app.routes(myBuilder);
        if (this.app instanceof PluginApplicationInterface) {
            this.app.pluginRoutes(myBuilder);
        }
    }
}
