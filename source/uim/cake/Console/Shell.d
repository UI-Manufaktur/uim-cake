module uim.cake.console;

import uim.cake.console.Exception\ConsoleException;
import uim.cake.console.Exception\StopException;
import uim.cake.core.App;
import uim.cake.core.Exception\CakeException;
import uim.cake.Datasource\ModelAwareTrait;
import uim.cake.Filesystem\Filesystem;
import uim.cake.Log\LogTrait;
import uim.cake.ORM\Locator\LocatorAwareTrait;
import uim.cake.ORM\Locator\ILocator;
import uim.cake.Utility\Inflector;
import uim.cake.Utility\MergeVariablesTrait;
import uim.cake.Utility\Text;
use ReflectionException;
use ReflectionMethod;
use RuntimeException;

/**
 * Base class for command-line utilities for automating programmer chores.
 *
 * Is the equivalent of Cake\Controller\Controller on the command line.
 *
 * @deprecated 3.6.0 ShellDispatcher and Shell will be removed in 5.0
 * @method int|bool|null|void main(...$args) Main entry method for the shell.
 */
class Shell {
    use LocatorAwareTrait;
    use LogTrait;
    use MergeVariablesTrait;
    use ModelAwareTrait;

    /**
     * Default error code
     *
     * @var int
     */
    public const CODE_ERROR = 1;

    /**
     * Default success code
     *
     * @var int
     */
    public const CODE_SUCCESS = 0;

    /**
     * Output constant making verbose shells.
     *
     * @var int
     */
    public const VERBOSE = ConsoleIo::VERBOSE;

    /**
     * Output constant for making normal shells.
     *
     * @var int
     */
    public const NORMAL = ConsoleIo::NORMAL;

    /**
     * Output constants for making quiet shells.
     *
     * @var int
     */
    public const QUIET = ConsoleIo::QUIET;

    /**
     * An instance of ConsoleOptionParser that has been configured for this class.
     *
     * @var \Cake\Console\ConsoleOptionParser
     */
    public $OptionParser;

    /**
     * If true, the script will ask for permission to perform actions.
     *
     * @var bool
     */
    public $interactive = true;

    /**
     * Contains command switches parsed from the command line.
     *
     * @var array
     */
    public myParams = [];

    /**
     * The command (method/task) that is being run.
     *
     * @var string|null
     */
    public $command;

    /**
     * Contains arguments parsed from the command line.
     *
     * @var array
     */
    public $args = [];

    /**
     * The name of the shell in camelized.
     *
     * @var string
     */
    public myName;

    /**
     * The name of the plugin the shell belongs to.
     * Is automatically set by ShellDispatcher when a shell is constructed.
     *
     * @var string
     */
    public myPlugin;

    /**
     * Contains tasks to load and instantiate
     *
     * @var array|bool
     * @link https://book.cakephp.org/4/en/console-and-shells.html#Shell::$tasks
     */
    public $tasks = [];

    /**
     * Contains the loaded tasks
     *
     * @var array<string>
     */
    public $taskNames = [];

    /**
     * Task Collection for the command, used to create Tasks.
     *
     * @var \Cake\Console\TaskRegistry
     */
    public $Tasks;

    /**
     * Normalized map of tasks.
     *
     * @var array<string, array>
     */
    protected $_taskMap = [];

    /**
     * ConsoleIo instance.
     *
     * @var \Cake\Console\ConsoleIo
     */
    protected $_io;

    /**
     * The root command name used when generating help output.
     *
     * @var string
     */
    protected $rootName = 'cake';

    /**
     * Constructs this Shell instance.
     *
     * @param \Cake\Console\ConsoleIo|null $io An io instance.
     * @param \Cake\ORM\Locator\ILocator|null $locator Table locator instance.
     * @link https://book.cakephp.org/4/en/console-and-shells.html#Shell
     */
    this(?ConsoleIo $io = null, ?ILocator $locator = null) {
        if (!this.name) {
            [, myClass] = moduleSplit(static::class);
            this.name = str_replace(['Shell', 'Task'], '', myClass);
        }
        this._io = $io ?: new ConsoleIo();
        this._tableLocator = $locator;

        this.modelFactory('Table', [this.getTableLocator(), 'get']);
        this.Tasks = new TaskRegistry(this);

        this._mergeVars(
            ['tasks'],
            ['associative' => ['tasks']]
        );

        if (isset(this.modelClass)) {
            this.loadModel();
        }
    }

    /**
     * Set the root command name for help output.
     *
     * @param string myName The name of the root command.
     * @return this
     */
    auto setRootName(string myName) {
        this.rootName = myName;

        return this;
    }

    /**
     * Get the io object for this shell.
     *
     * @return \Cake\Console\ConsoleIo The current ConsoleIo object.
     */
    auto getIo(): ConsoleIo
    {
        return this._io;
    }

    /**
     * Set the io object for this shell.
     *
     * @param \Cake\Console\ConsoleIo $io The ConsoleIo object to use.
     * @return void
     */
    auto setIo(ConsoleIo $io): void
    {
        this._io = $io;
    }

    /**
     * Initializes the Shell
     * acts as constructor for subclasses
     * allows configuration of tasks prior to shell execution
     *
     * @return void
     * @link https://book.cakephp.org/4/en/console-and-shells.html#Cake\Console\ConsoleOptionParser::initialize
     */
    function initialize(): void
    {
        this.loadTasks();
    }

    /**
     * Starts up the Shell and displays the welcome message.
     * Allows for checking and configuring prior to command or main execution
     *
     * Override this method if you want to remove the welcome information,
     * or otherwise modify the pre-command flow.
     *
     * @return void
     * @link https://book.cakephp.org/4/en/console-and-shells.html#Cake\Console\ConsoleOptionParser::startup
     */
    function startup(): void
    {
        if (!this.param('requested')) {
            this._welcome();
        }
    }

    /**
     * Displays a header for the shell
     *
     * @return void
     */
    protected auto _welcome(): void
    {
    }

    /**
     * Loads tasks defined in public $tasks
     *
     * @return true
     */
    bool loadTasks() {
        if (this.tasks === true || empty(this.tasks)) {
            return true;
        }
        this._taskMap = this.Tasks.normalizeArray(this.tasks);
        this.taskNames = array_merge(this.taskNames, array_keys(this._taskMap));

        this._validateTasks();

        return true;
    }

    /**
     * Checks that the tasks in the task map are actually available
     *
     * @throws \RuntimeException
     * @return void
     */
    protected auto _validateTasks(): void
    {
        foreach (this._taskMap as $taskName => $task) {
            myClass = App::className($task['class'], 'Shell/Task', 'Task');
            if (myClass === null) {
                throw new RuntimeException(sprintf(
                    'Task `%s` not found. Maybe you made a typo or a plugin is missing or not loaded?',
                    $taskName
                ));
            }
        }
    }

    /**
     * Check to see if this shell has a task with the provided name.
     *
     * @param string $task The task name to check.
     * @return bool Success
     * @link https://book.cakephp.org/4/en/console-and-shells.html#shell-tasks
     */
    bool hasTask(string $task) {
        return isset(this._taskMap[Inflector::camelize($task)]);
    }

    /**
     * Check to see if this shell has a callable method by the given name.
     *
     * @param string myName The method name to check.
     * @return bool
     * @link https://book.cakephp.org/4/en/console-and-shells.html#shell-tasks
     */
    bool hasMethod(string myName) {
        try {
            $method = new ReflectionMethod(this, myName);
            if (!$method.isPublic()) {
                return false;
            }

            return $method.getDeclaringClass().name !== self::class;
        } catch (ReflectionException $e) {
            return false;
        }
    }

    /**
     * Dispatch a command to another Shell. Similar to Object::requestAction()
     * but intended for running shells from other shells.
     *
     * ### Usage:
     *
     * With a string command:
     *
     * ```
     * return this.dispatchShell('schema create DbAcl');
     * ```
     *
     * Avoid using this form if you have string arguments, with spaces in them.
     * The dispatched will be invoked incorrectly. Only use this form for simple
     * command dispatching.
     *
     * With an array command:
     *
     * ```
     * return this.dispatchShell('schema', 'create', 'i18n', '--dry');
     * ```
     *
     * With an array having two key / value pairs:
     *
     *  - `command` can accept either a string or an array. Represents the command to dispatch
     *  - `extra` can accept an array of extra parameters to pass on to the dispatcher. This
     *    parameters will be available in the `param` property of the called `Shell`
     *
     * `return this.dispatchShell([
     *      'command' => 'schema create DbAcl',
     *      'extra' => ['param' => 'value']
     * ]);`
     *
     * or
     *
     * `return this.dispatchShell([
     *      'command' => ['schema', 'create', 'DbAcl'],
     *      'extra' => ['param' => 'value']
     * ]);`
     *
     * @return int The CLI command exit code. 0 is success.
     * @link https://book.cakephp.org/4/en/console-and-shells.html#invoking-other-shells-from-your-shell
     */
    function dispatchShell(): int
    {
        [$args, $extra] = this.parseDispatchArguments(func_get_args());

        $extra['requested'] = $extra['requested'] ?? true;
        /** @psalm-suppress DeprecatedClass */
        $dispatcher = new ShellDispatcher($args, false);

        return $dispatcher.dispatch($extra);
    }

    /**
     * Parses the arguments for the dispatchShell() method.
     *
     * @param array $args Arguments fetch from the dispatchShell() method with
     * func_get_args()
     * @return array First value has to be an array of the command arguments.
     * Second value has to be an array of extra parameter to pass on to the dispatcher
     */
    function parseDispatchArguments(array $args): array
    {
        $extra = [];

        if (is_string($args[0]) && count($args) === 1) {
            $args = explode(' ', $args[0]);

            return [$args, $extra];
        }

        if (is_array($args[0]) && !empty($args[0]['command'])) {
            $command = $args[0]['command'];
            if (is_string($command)) {
                $command = explode(' ', $command);
            }

            if (!empty($args[0]['extra'])) {
                $extra = $args[0]['extra'];
            }

            return [$command, $extra];
        }

        return [$args, $extra];
    }

    /**
     * Runs the Shell with the provided argv.
     *
     * Delegates calls to Tasks and resolves methods inside the class. Commands are looked
     * up with the following order:
     *
     * - Method on the shell.
     * - Matching task name.
     * - `main()` method.
     *
     * If a shell : a `main()` method, all missing method calls will be sent to
     * `main()` with the original method name in the argv.
     *
     * For tasks to be invoked they *must* be exposed as subcommands. If you define any subcommands,
     * you must define all the subcommands your shell needs, whether they be methods on this class
     * or methods on tasks.
     *
     * @param array $argv Array of arguments to run the shell with. This array should be missing the shell name.
     * @param bool $autoMethod Set to true to allow any public method to be called even if it
     *   was not defined as a subcommand. This is used by ShellDispatcher to make building simple shells easy.
     * @param array $extra Extra parameters that you can manually pass to the Shell
     * to be dispatched.
     * Built-in extra parameter is :
     *
     * - `requested` : if used, will prevent the Shell welcome message to be displayed
     * @return int|bool|null
     * @link https://book.cakephp.org/4/en/console-and-shells.html#the-cakephp-console
     */
    function runCommand(array $argv, bool $autoMethod = false, array $extra = []) {
        $command = isset($argv[0]) ? Inflector::underscore($argv[0]) : null;
        this.OptionParser = this.getOptionParser();
        try {
            [this.params, this.args] = this.OptionParser.parse($argv);
        } catch (ConsoleException $e) {
            this.err('Error: ' . $e.getMessage());

            return false;
        }

        this.params = array_merge(this.params, $extra);
        this._setOutputLevel();
        this.command = $command;
        if ($command && !empty(this.params['help'])) {
            return this._displayHelp($command);
        }

        $subcommands = this.OptionParser.subcommands();
        $method = Inflector::camelize((string)$command);
        $isMethod = this.hasMethod($method);

        if ($isMethod && $autoMethod && count($subcommands) === 0) {
            array_shift(this.args);
            this.startup();

            return this.$method(...this.args);
        }

        if ($isMethod && isset($subcommands[$command])) {
            this.startup();

            return this.$method(...this.args);
        }

        if ($command && this.hasTask($command) && isset($subcommands[$command])) {
            this.startup();
            array_shift($argv);

            return this.{$method}.runCommand($argv, false, ['requested' => true]);
        }

        if (this.hasMethod('main')) {
            this.command = 'main';
            this.startup();

            return this.main(...this.args);
        }

        this.err('No subcommand provided. Choose one of the available subcommands.', 2);
        try {
            this._io.err(this.OptionParser.help($command));
        } catch (ConsoleException $e) {
            this.err('Error: ' . $e.getMessage());
        }

        return false;
    }

    /**
     * Set the output level based on the parameters.
     *
     * This reconfigures both the output level for out()
     * and the configured stdout/stderr logging
     *
     * @return void
     */
    protected auto _setOutputLevel(): void
    {
        this._io.setLoggers(ConsoleIo::NORMAL);
        if (!empty(this.params['quiet'])) {
            this._io.level(ConsoleIo::QUIET);
            this._io.setLoggers(ConsoleIo::QUIET);
        }
        if (!empty(this.params['verbose'])) {
            this._io.level(ConsoleIo::VERBOSE);
            this._io.setLoggers(ConsoleIo::VERBOSE);
        }
    }

    /**
     * Display the help in the correct format
     *
     * @param string|null $command The command to get help for.
     * @return int|null The number of bytes returned from writing to stdout.
     */
    protected auto _displayHelp(?string $command = null) {
        $format = 'text';
        if (!empty(this.args[0]) && this.args[0] === 'xml') {
            $format = 'xml';
            this._io.setOutputAs(ConsoleOutput::RAW);
        } else {
            this._welcome();
        }

        $subcommands = this.OptionParser.subcommands();
        if ($command !== null) {
            $command = isset($subcommands[$command]) ? $command : null;
        }

        return this.out(this.OptionParser.help($command, $format));
    }

    /**
     * Gets the option parser instance and configures it.
     *
     * By overriding this method you can configure the ConsoleOptionParser before returning it.
     *
     * @return \Cake\Console\ConsoleOptionParser
     * @link https://book.cakephp.org/4/en/console-and-shells.html#configuring-options-and-generating-help
     */
    auto getOptionParser(): ConsoleOptionParser
    {
        myName = (this.plugin ? this.plugin . '.' : '') . this.name;
        $parser = new ConsoleOptionParser(myName);
        $parser.setRootName(this.rootName);

        return $parser;
    }

    /**
     * Overload get for lazy building of tasks
     *
     * @param string myName The task to get.
     * @return \Cake\Console\Shell Object of Task
     */
    auto __get(string myName) {
        if (empty(this.{myName}) && in_array(myName, this.taskNames, true)) {
            $properties = this._taskMap[myName];
            this.{myName} = this.Tasks.load($properties['class'], $properties['config']);
            this.{myName}.args = &this.args;
            this.{myName}.params = &this.params;
            this.{myName}.initialize();
            this.{myName}.loadTasks();
        }

        return this.{myName};
    }

    /**
     * Safely access the values in this.params.
     *
     * @param string myName The name of the parameter to get.
     * @return string|bool|null Value. Will return null if it doesn't exist.
     */
    function param(string myName) {
        return this.params[myName] ?? null;
    }

    /**
     * Prompts the user for input, and returns it.
     *
     * @param string $prompt Prompt text.
     * @param array<string>|string|null myOptions Array or string of options.
     * @param string|null $default Default input value.
     * @return string|null Either the default value, or the user-provided input.
     * @link https://book.cakephp.org/4/en/console-and-shells.html#Shell::in
     */
    function in(string $prompt, myOptions = null, ?string $default = null): ?string
    {
        if (!this.interactive) {
            return $default;
        }
        if (myOptions) {
            return this._io.askChoice($prompt, myOptions, $default);
        }

        return this._io.ask($prompt, $default);
    }

    /**
     * Wrap a block of text.
     * Allows you to set the width, and indenting on a block of text.
     *
     * ### Options
     *
     * - `width` The width to wrap to. Defaults to 72
     * - `wordWrap` Only wrap on words breaks (spaces) Defaults to true.
     * - `indent` Indent the text with the string provided. Defaults to null.
     *
     * @param string $text Text the text to format.
     * @param array<string, mixed>|int myOptions Array of options to use, or an integer to wrap the text to.
     * @return string Wrapped / indented text
     * @see \Cake\Utility\Text::wrap()
     * @link https://book.cakephp.org/4/en/console-and-shells.html#Shell::wrapText
     */
    function wrapText(string $text, myOptions = []): string
    {
        return Text::wrap($text, myOptions);
    }

    /**
     * Output at the verbose level.
     *
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int|null The number of bytes returned from writing to stdout.
     */
    function verbose(myMessage, int $newlines = 1): ?int
    {
        return this._io.verbose(myMessage, $newlines);
    }

    /**
     * Output at all levels.
     *
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int|null The number of bytes returned from writing to stdout.
     */
    function quiet(myMessage, int $newlines = 1): ?int
    {
        return this._io.quiet(myMessage, $newlines);
    }

    /**
     * Outputs a single or multiple messages to stdout. If no parameters
     * are passed outputs just a newline.
     *
     * ### Output levels
     *
     * There are 3 built-in output level. Shell::QUIET, Shell::NORMAL, Shell::VERBOSE.
     * The verbose and quiet output levels, map to the `verbose` and `quiet` output switches
     * present in most shells. Using Shell::QUIET for a message means it will always display.
     * While using Shell::VERBOSE means it will only display when verbose output is toggled.
     *
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @param int $level The message's output level, see above.
     * @return int|null The number of bytes returned from writing to stdout.
     * @link https://book.cakephp.org/4/en/console-and-shells.html#Shell::out
     */
    function out(myMessage, int $newlines = 1, int $level = Shell::NORMAL): ?int
    {
        return this._io.out(myMessage, $newlines, $level);
    }

    /**
     * Outputs a single or multiple error messages to stderr. If no parameters
     * are passed outputs just a newline.
     *
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int The number of bytes returned from writing to stderr.
     */
    function err(myMessage, int $newlines = 1): int
    {
        return this._io.error(myMessage, $newlines);
    }

    /**
     * Convenience method for out() that wraps message between <info /> tag
     *
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @param int $level The message's output level, see above.
     * @return int|null The number of bytes returned from writing to stdout.
     * @see https://book.cakephp.org/4/en/console-and-shells.html#Shell::out
     */
    function info(myMessage, int $newlines = 1, int $level = Shell::NORMAL): ?int
    {
        return this._io.info(myMessage, $newlines, $level);
    }

    /**
     * Convenience method for err() that wraps message between <warning /> tag
     *
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int The number of bytes returned from writing to stderr.
     * @see https://book.cakephp.org/4/en/console-and-shells.html#Shell::err
     */
    function warn(myMessage, int $newlines = 1): int
    {
        return this._io.warning(myMessage, $newlines);
    }

    /**
     * Convenience method for out() that wraps message between <success /> tag
     *
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @param int $level The message's output level, see above.
     * @return int|null The number of bytes returned from writing to stdout.
     * @see https://book.cakephp.org/4/en/console-and-shells.html#Shell::out
     */
    function success(myMessage, int $newlines = 1, int $level = Shell::NORMAL): ?int
    {
        return this._io.success(myMessage, $newlines, $level);
    }

    /**
     * Returns a single or multiple linefeeds sequences.
     *
     * @param int $multiplier Number of times the linefeed sequence should be repeated
     * @return string
     * @link https://book.cakephp.org/4/en/console-and-shells.html#Shell::nl
     */
    function nl(int $multiplier = 1): string
    {
        return this._io.nl($multiplier);
    }

    /**
     * Outputs a series of minus characters to the standard output, acts as a visual separator.
     *
     * @param int $newlines Number of newlines to pre- and append
     * @param int $width Width of the line, defaults to 63
     * @return void
     * @link https://book.cakephp.org/4/en/console-and-shells.html#Shell::hr
     */
    function hr(int $newlines = 0, int $width = 63): void
    {
        this._io.hr($newlines, $width);
    }

    /**
     * Displays a formatted error message
     * and exits the application with an error code.
     *
     * @param string myMessage The error message
     * @param int $exitCode The exit code for the shell task.
     * @throws \Cake\Console\Exception\StopException
     * @return void
     * @link https://book.cakephp.org/4/en/console-and-shells.html#styling-output
     * @psalm-return never-return
     */
    function abort(string myMessage, int $exitCode = self::CODE_ERROR): void
    {
        this._io.err('<error>' . myMessage . '</error>');
        throw new StopException(myMessage, $exitCode);
    }

    /**
     * Clear the console
     *
     * @return void
     * @link https://book.cakephp.org/4/en/console-and-shells.html#console-output
     */
    function clear(): void
    {
        if (!empty(this.params['noclear'])) {
            return;
        }

        if (DIRECTORY_SEPARATOR === '/') {
            passthru('clear');
        } else {
            passthru('cls');
        }
    }

    /**
     * Creates a file at given path
     *
     * @param string myPath Where to put the file.
     * @param string myContentss Content to put in the file.
     * @return bool Success
     * @link https://book.cakephp.org/4/en/console-and-shells.html#creating-files
     */
    bool createFile(string myPath, string myContentss) {
        myPath = str_replace(DIRECTORY_SEPARATOR . DIRECTORY_SEPARATOR, DIRECTORY_SEPARATOR, myPath);

        this._io.out();

        $fileExists = is_file(myPath);
        if ($fileExists && empty(this.params['force']) && !this.interactive) {
            this._io.out('<warning>File exists, skipping</warning>.');

            return false;
        }

        if ($fileExists && this.interactive && empty(this.params['force'])) {
            this._io.out(sprintf('<warning>File `%s` exists</warning>', myPath));
            myKey = this._io.askChoice('Do you want to overwrite?', ['y', 'n', 'a', 'q'], 'n');

            if (strtolower(myKey) === 'q') {
                this._io.out('<error>Quitting</error>.', 2);
                this._stop();

                return false;
            }
            if (strtolower(myKey) === 'a') {
                this.params['force'] = true;
                myKey = 'y';
            }
            if (strtolower(myKey) !== 'y') {
                this._io.out(sprintf('Skip `%s`', myPath), 2);

                return false;
            }
        } else {
            this.out(sprintf('Creating file %s', myPath));
        }

        try {
            $fs = new Filesystem();
            $fs.dumpFile(myPath, myContentss);

            this._io.out(sprintf('<success>Wrote</success> `%s`', myPath));
        } catch (CakeException $e) {
            this._io.err(sprintf('<error>Could not write to `%s`</error>.', myPath), 2);

            return false;
        }

        return true;
    }

    /**
     * Makes absolute file path easier to read
     *
     * @param string $file Absolute file path
     * @return string short path
     * @link https://book.cakephp.org/4/en/console-and-shells.html#Shell::shortPath
     */
    function shortPath(string absoluteFilePath): string
    {
        $shortPath = str_replace(ROOT, '', absoluteFilePath);
        $shortPath = str_replace('..' . DIRECTORY_SEPARATOR, '', $shortPath);
        $shortPath = str_replace(DIRECTORY_SEPARATOR, '/', $shortPath);

        return str_replace('//', DIRECTORY_SEPARATOR, $shortPath);
    }

    /**
     * Render a Console Helper
     *
     * Create and render the output for a helper object. If the helper
     * object has not already been loaded, it will be loaded and constructed.
     *
     * @param string myName The name of the helper to render
     * @param array<string, mixed> myConfig Configuration data for the helper.
     * @return \Cake\Console\Helper The created helper instance.
     */
    function helper(string myName, array myConfig = []): Helper
    {
        return this._io.helper(myName, myConfig);
    }

    /**
     * Stop execution of the current script.
     * Raises a StopException to try and halt the execution.
     *
     * @param int $status see https://secure.php.net/exit for values
     * @throws \Cake\Console\Exception\StopException
     * @return void
     */
    protected auto _stop(int $status = self::CODE_SUCCESS): void
    {
        throw new StopException('Halting error reached', $status);
    }

    /**
     * Returns an array that can be used to describe the internal state of this
     * object.
     *
     * @return array<string, mixed>
     */
    auto __debugInfo(): array
    {
        return [
            'name' => this.name,
            'plugin' => this.plugin,
            'command' => this.command,
            'tasks' => this.tasks,
            'params' => this.params,
            'args' => this.args,
            'interactive' => this.interactive,
        ];
    }
}
