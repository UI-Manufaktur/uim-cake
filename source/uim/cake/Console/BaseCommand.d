module uim.cake.console;

import uim.cake.console.Exception\ConsoleException;
import uim.cake.console.Exception\StopException;
import uim.cake.Utility\Inflector;
use InvalidArgumentException;
use RuntimeException;

/**
 * Base class for console commands.
 *
 * Provides hooks for common command features:
 *
 * - `initialize` Acts as a post-construct hook.
 * - `buildOptionParser` Build/Configure the option parser for your command.
 * - `execute` Execute your command with parsed Arguments and ConsoleIo
 */
abstract class BaseCommand : ICommand
{
    /**
     * The name of this command.
     *
     * @var string
     */
    protected string myName = 'cake unknown';


    auto setName(string myName)
    {
        if (strpos(myName, ' ') < 1) {
            throw new InvalidArgumentException(
                "The name '{myName}' is missing a space. Names should look like `cake routes`"
            );
        }
        this.name = myName;

        return this;
    }

    /**
     * Get the command name.
     *
     * @return string
     */
    auto getName(): string
    {
        return this.name;
    }

    /**
     * Get the root command name.
     *
     * @return string
     */
    auto getRootName(): string
    {
        [$root] = explode(' ', this.name);

        return $root;
    }

    /**
     * Get the command name.
     *
     * Returns the command name based on class name.
     * For e.g. for a command with class name `UpdateTableCommand` the default
     * name returned would be `'update_table'`.
     *
     * @return string
     */
    static string defaultName() {
        $pos = strrpos(static::class, '\\');
        /** @psalm-suppress PossiblyFalseOperand */
        myName = substr(static::class, $pos + 1, -7);
        myName = Inflector::underscore(myName);

        return myName;
    }

    /**
     * Get the option parser.
     *
     * You can override buildOptionParser() to define your options & arguments.
     *
     * @return \Cake\Console\ConsoleOptionParser
     * @throws \RuntimeException When the parser is invalid
     */
    auto getOptionParser(): ConsoleOptionParser
    {
        [$root, myName] = explode(' ', this.name, 2);
        $parser = new ConsoleOptionParser(myName);
        $parser.setRootName($root);

        $parser = this.buildOptionParser($parser);
        if ($parser.subcommands()) {
            throw new RuntimeException(
                'You cannot add sub-commands to `Command` sub-classes. Instead make a separate command.'
            );
        }

        return $parser;
    }

    /**
     * Hook method for defining this command's option parser.
     *
     * @param \Cake\Console\ConsoleOptionParser $parser The parser to be defined
     * @return \Cake\Console\ConsoleOptionParser The built parser.
     */
    protected auto buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        return $parser;
    }

    /**
     * Hook method invoked by CakePHP when a command is about to be executed.
     *
     * Override this method and implement expensive/important setup steps that
     * should not run on every command run. This method will be called *before*
     * the options and arguments are validated and processed.
     *
     * @return void
     */
    function initialize(): void
    {
    }


    function run(array $argv, ConsoleIo $io): ?int
    {
        this.initialize();

        $parser = this.getOptionParser();
        try {
            [myOptions, $arguments] = $parser.parse($argv);
            $args = new Arguments(
                $arguments,
                myOptions,
                $parser.argumentNames()
            );
        } catch (ConsoleException $e) {
            $io.err('Error: ' . $e.getMessage());

            return static::CODE_ERROR;
        }
        this.setOutputLevel($args, $io);

        if ($args.getOption('help')) {
            this.displayHelp($parser, $args, $io);

            return static::CODE_SUCCESS;
        }

        if ($args.getOption('quiet')) {
            $io.setInteractive(false);
        }

        return this.execute($args, $io);
    }

    /**
     * Output help content
     *
     * @param \Cake\Console\ConsoleOptionParser $parser The option parser.
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return void
     */
    protected auto displayHelp(ConsoleOptionParser $parser, Arguments $args, ConsoleIo $io): void
    {
        $format = 'text';
        if ($args.getArgumentAt(0) === 'xml') {
            $format = 'xml';
            $io.setOutputAs(ConsoleOutput::RAW);
        }

        $io.out($parser.help(null, $format));
    }

    /**
     * Set the output level based on the Arguments.
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return void
     */
    protected auto setOutputLevel(Arguments $args, ConsoleIo $io): void
    {
        $io.setLoggers(ConsoleIo::NORMAL);
        if ($args.getOption('quiet')) {
            $io.level(ConsoleIo::QUIET);
            $io.setLoggers(ConsoleIo::QUIET);
        }
        if ($args.getOption('verbose')) {
            $io.level(ConsoleIo::VERBOSE);
            $io.setLoggers(ConsoleIo::VERBOSE);
        }
    }

    /**
     * Implement this method with your command's logic.
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null|void The exit code or null for success
     */
    abstract auto execute(Arguments $args, ConsoleIo $io);

    /**
     * Halt the the current process with a StopException.
     *
     * @param int $code The exit code to use.
     * @throws \Cake\Console\Exception\StopException
     * @return void
     */
    function abort(int $code = self::CODE_ERROR): void
    {
        throw new StopException('Command aborted', $code);
    }

    /**
     * Execute another command with the provided set of arguments.
     *
     * If you are using a string command name, that command's dependencies
     * will not be resolved with the application container. Instead you will
     * need to pass the command as an object with all of its dependencies.
     *
     * @param \Cake\Console\ICommand|string $command The command class name or command instance.
     * @param array $args The arguments to invoke the command with.
     * @param \Cake\Console\ConsoleIo|null $io The ConsoleIo instance to use for the executed command.
     * @return int|null The exit code or null for success of the command.
     */
    auto executeCommand($command, array $args = [], ?ConsoleIo $io = null): ?int
    {
        if (is_string($command)) {
            if (!class_exists($command)) {
                throw new InvalidArgumentException("Command class '{$command}' does not exist.");
            }
            $command = new $command();
        }
        if (!$command instanceof ICommand) {
            $commandType = getTypeName($command);
            throw new InvalidArgumentException(
                "Command '{$commandType}' is not a subclass of Cake\Console\ICommand."
            );
        }
        $io = $io ?: new ConsoleIo();

        try {
            return $command.run($args, $io);
        } catch (StopException $e) {
            return $e.getCode();
        }
    }
}
