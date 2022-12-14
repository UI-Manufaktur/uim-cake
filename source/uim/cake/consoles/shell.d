/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.consoles;

@safe:
import uim.cake;

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
#[\AllowDynamicProperties]
class Shell
{
    use LocatorAwareTrait;
    use LogTrait;
    use MergeVariablesTrait;
    use ModelAwareTrait;

    /**
     * Default error code
     *
     * @var int
     */
    const CODE_ERROR = 1;

    /**
     * Default success code
     *
     * @var int
     */
    const CODE_SUCCESS = 0;

    /**
     * Output constant making verbose shells.
     *
     * @var int
     */
    const VERBOSE = ConsoleIo::VERBOSE;

    /**
     * Output constant for making normal shells.
     *
     * @var int
     */
    const NORMAL = ConsoleIo::NORMAL;

    /**
     * Output constants for making quiet shells.
     *
     * @var int
     */
    const QUIET = ConsoleIo::QUIET;

    /**
     * An instance of ConsoleOptionParser that has been configured for this class.
     *
     * @var uim.cake.consoles.ConsoleOptionParser
     */
    $OptionParser;

    /**
     * If true, the script will ask for permission to perform actions.
     *
     * @var bool
     */
    $interactive = true;

    /**
     * Contains command switches parsed from the command line.
     *
     * @var array
     */
    $params = null;

    /**
     * The command (method/task) that is being run.
     *
     * @var string|null
     */
    $command;

    /**
     * Contains arguments parsed from the command line.
     *
     * @var array
     */
    $args = null;

    /**
     * The name of the shell in camelized.
     *
     * @var string
     */
    $name;

    /**
     * The name of the plugin the shell belongs to.
     * Is automatically set by ShellDispatcher when a shell is constructed.
     *
     * @var string
     */
    $plugin;

    /**
     * Contains tasks to load and instantiate
     *
     * @var array|bool
     * @link https://book.cakephp.org/4/en/console-commands/shells.html#shell-tasks
     */
    $tasks = null;

    /**
     * Contains the loaded tasks
     *
     * @var array<string>
     */
    $taskNames = null;

    /**
     * Task Collection for the command, used to create Tasks.
     *
     * @var uim.cake.consoles.TaskRegistry
     */
    $Tasks;

    /**
     * Normalized map of tasks.
     *
     * @var array<string, array>
     */
    protected _taskMap = null;

    /**
     * ConsoleIo instance.
     *
     * @var uim.cake.consoles.ConsoleIo
     */
    protected _io;

    /**
     * The root command name used when generating help output.
     */
    protected string $rootName = "cake";

    /**
     * Constructs this Shell instance.
     *
     * @param uim.cake.consoles.ConsoleIo|null $io An io instance.
     * @param uim.cake.orm.Locator\ILocator|null $locator Table locator instance.
     * @link https://book.cakephp.org/4/en/console-commands/shells.html
     */
    this(?ConsoleIo $io = null, ?ILocator $locator = null) {
        if (!this.name) {
            [, $class] = namespaceSplit(static::class);
            this.name = replace(["Shell", "Task"], "", $class);
        }
        _io = $io ?: new ConsoleIo();
        _tableLocator = $locator;

        this.modelFactory("Table", [this.getTableLocator(), "get"]);
        this.Tasks = new TaskRegistry(this);

        _mergeVars(
            ["tasks"],
            ["associative": ["tasks"]]
        );

        if (isset(this.modelClass)) {
            this.loadModel();
        }
    }

    /**
     * Set the root command name for help output.
     *
     * @param string aName The name of the root command.
     * @return this
     */
    function setRootName(string aName) {
        this.rootName = $name;

        return this;
    }

    /**
     * Get the io object for this shell.
     *
     * @return uim.cake.consoles.ConsoleIo The current ConsoleIo object.
     */
    function getIo(): ConsoleIo
    {
        return _io;
    }

    /**
     * Set the io object for this shell.
     *
     * @param uim.cake.consoles.ConsoleIo $io The ConsoleIo object to use.
     */
    void setIo(ConsoleIo $io) {
        _io = $io;
    }

    /**
     * Initializes the Shell
     * acts as constructor for subclasses
     * allows configuration of tasks prior to shell execution
     *
     * @return void
     * @link https://book.cakephp.org/4/en/console-and-shells.html#Cake\Console\ConsoleOptionParser::initialize
     */
    void initialize() {
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
    void startup() {
        if (!this.param("requested")) {
            _welcome();
        }
    }

    /**
     * Displays a header for the shell
     */
    protected void _welcome() {
    }

    /**
     * Loads tasks defined in $tasks
     *
     * @return true
     */
    bool loadTasks() {
        if (this.tasks == true || empty(this.tasks)) {
            return true;
        }
        _taskMap = this.Tasks.normalizeArray(this.tasks);
        this.taskNames = array_merge(this.taskNames, array_keys(_taskMap));

        _validateTasks();

        return true;
    }

    /**
     * Checks that the tasks in the task map are actually available
     *
     * @throws \RuntimeException
     */
    protected void _validateTasks() {
        foreach (_taskMap as $taskName: $task) {
            $class = App::className($task["class"], "Shell/Task", "Task");
            if ($class == null) {
                throw new RuntimeException(sprintf(
                    "Task `%s` not found. Maybe you made a typo or a plugin is missing or not loaded?",
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
        return isset(_taskMap[Inflector::camelize($task)]);
    }

    /**
     * Check to see if this shell has a callable method by the given name.
     *
     * @param string aName The method name to check.
     * @return bool
     * @link https://book.cakephp.org/4/en/console-and-shells.html#shell-tasks
     */
    bool hasMethod(string aName) {
        try {
            $method = new ReflectionMethod(this, $name);
            if (!$method.isPublic()) {
                return false;
            }

            return $method.getDeclaringClass().name != self::class;
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
     * return this.dispatchShell("schema create DbAcl");
     * ```
     *
     * Avoid using this form if you have string arguments, with spaces in them.
     * The dispatched will be invoked incorrectly. Only use this form for simple
     * command dispatching.
     *
     * With an array command:
     *
     * ```
     * return this.dispatchShell("schema", "create", "i18n", "--dry");
     * ```
     *
     * With an array having two key / value pairs:
     *
     *  - `command` can accept either a string or an array. Represents the command to dispatch
     *  - `extra` can accept an array of extra parameters to pass on to the dispatcher. This
     *    parameters will be available in the `param` property of the called `Shell`
     *
     * `return this.dispatchShell([
     *      "command": "schema create DbAcl",
     *      "extra": ["param": "value"]
     * ]);`
     *
     * or
     *
     * `return this.dispatchShell([
     *      "command": ["schema", "create", "DbAcl"],
     *      "extra": ["param": "value"]
     * ]);`
     *
     * @return int The CLI command exit code. 0 is success.
     * @link https://book.cakephp.org/4/en/console-and-shells.html#invoking-other-shells-from-your-shell
     */
    int dispatchShell() {
        [$args, $extra] = this.parseDispatchArguments(func_get_args());

        $extra["requested"] = $extra["requested"] ?? true;
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
    array parseDispatchArguments(array $args) {
        $extra = null;

        if (is_string($args[0]) && count($args) == 1) {
            $args = explode(" ", $args[0]);

            return [$args, $extra];
        }

        if (is_array($args[0]) && !empty($args[0]["command"])) {
            $command = $args[0]["command"];
            if (is_string($command)) {
                $command = explode(" ", $command);
            }

            if (!empty($args[0]["extra"])) {
                $extra = $args[0]["extra"];
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
     * @param bool $autoMethod Set to true to allow any method to be called even if it
     *   was not defined as a subcommand. This is used by ShellDispatcher to make building simple shells easy.
     * @param array $extra Extra parameters that you can manually pass to the Shell
     * to be dispatched.
     * Built-in extra parameter is :
     *
     * - `requested` : if used, will prevent the Shell welcome message to be displayed
     * @return int|bool|null
     * @link https://book.cakephp.org/4/en/console-and-shells.html#the-cakephp-console
     */
    function runCommand(array $argv, bool $autoMethod = false, array $extra = null) {
        $command = isset($argv[0]) ? Inflector::underscore($argv[0]) : null;
        this.OptionParser = this.getOptionParser();
        try {
            [this.params, this.args] = this.OptionParser.parse($argv, _io);
        } catch (ConsoleException $e) {
            this.err("Error: " ~ $e.getMessage());

            return false;
        }

        this.params = array_merge(this.params, $extra);
        _setOutputLevel();
        this.command = $command;
        if ($command && !empty(this.params["help"])) {
            return _displayHelp($command);
        }

        $subcommands = this.OptionParser.subcommands();
        $method = Inflector::camelize((string)$command);
        $isMethod = this.hasMethod($method);

        if ($isMethod && $autoMethod && count($subcommands) == 0) {
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

            return this.{$method}.runCommand($argv, false, ["requested": true]);
        }

        if (this.hasMethod("main")) {
            this.command = "main";
            this.startup();

            return this.main(...this.args);
        }

        this.err("No subcommand provided. Choose one of the available subcommands.", 2);
        try {
            _io.err(this.OptionParser.help($command));
        } catch (ConsoleException $e) {
            this.err("Error: " ~ $e.getMessage());
        }

        return false;
    }

    /**
     * Set the output level based on the parameters.
     *
     * This reconfigures both the output level for out()
     * and the configured stdout/stderr logging
     */
    protected void _setOutputLevel() {
        _io.setLoggers(ConsoleIo::NORMAL);
        if (!empty(this.params["quiet"])) {
            _io.level(ConsoleIo::QUIET);
            _io.setLoggers(ConsoleIo::QUIET);
        }
        if (!empty(this.params["verbose"])) {
            _io.level(ConsoleIo::VERBOSE);
            _io.setLoggers(ConsoleIo::VERBOSE);
        }
    }

    /**
     * Display the help in the correct format
     *
     * @param string|null $command The command to get help for.
     * @return int|null The number of bytes returned from writing to stdout.
     */
    protected function _displayHelp(Nullable!string $command = null) {
        $format = "text";
        if (!empty(this.args[0]) && this.args[0] == "xml") {
            $format = "xml";
            _io.setOutputAs(ConsoleOutput::RAW);
        } else {
            _welcome();
        }

        $subcommands = this.OptionParser.subcommands();
        if ($command != null) {
            $command = isset($subcommands[$command]) ? $command : null;
        }

        return this.out(this.OptionParser.help($command, $format));
    }

    /**
     * Gets the option parser instance and configures it.
     *
     * By overriding this method you can configure the ConsoleOptionParser before returning it.
     *
     * @return uim.cake.consoles.ConsoleOptionParser
     * @link https://book.cakephp.org/4/en/console-and-shells.html#configuring-options-and-generating-help
     */
    function getOptionParser(): ConsoleOptionParser
    {
        $name = (this.plugin ? this.plugin ~ "." : "") . this.name;
        $parser = new ConsoleOptionParser($name);
        $parser.setRootName(this.rootName);

        return $parser;
    }

    /**
     * Overload get for lazy building of tasks
     *
     * @param string aName The task to get.
     * @return uim.cake.consoles.Shell Object of Task
     */
    function __get(string aName) {
        if (empty(this.{$name}) && hasAllValues($name, this.taskNames, true)) {
            $properties = _taskMap[$name];
            this.{$name} = this.Tasks.load($properties["class"], $properties["config"]);
            this.{$name}.args = &this.args;
            this.{$name}.params = &this.params;
            this.{$name}.initialize();
            this.{$name}.loadTasks();
        }

        return this.{$name};
    }

    /**
     * Safely access the values in this.params.
     *
     * @param string aName The name of the parameter to get.
     * @return string|bool|null Value. Will return null if it doesn"t exist.
     */
    function param(string aName) {
        return this.params[$name] ?? null;
    }

    /**
     * Prompts the user for input, and returns it.
     *
     * @param string $prompt Prompt text.
     * @param array<string>|string|null $options Array or string of options.
     * @param string|null $default Default input value.
     * @return string|null Either the default value, or the user-provided input.
     * @link https://book.cakephp.org/4/en/console-and-shells.html#Shell::in
     */
    Nullable!string in(string $prompt, $options = null, Nullable!string $default = null) {
        if (!this.interactive) {
            return $default;
        }
        if ($options) {
            return _io.askChoice($prompt, $options, $default);
        }

        return _io.ask($prompt, $default);
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
     * @param array<string, mixed>|int $options Array of options to use, or an integer to wrap the text to.
     * @return string Wrapped / indented text
     * @see uim.cake.Utility\Text::wrap()
     * @link https://book.cakephp.org/4/en/console-and-shells.html#Shell::wrapText
     */
    string wrapText(string $text, $options = null) {
        return Text::wrap($text, $options);
    }

    /**
     * Output at the verbose level.
     *
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int|null The number of bytes returned from writing to stdout.
     */
    Nullable!int verbose($message, int $newlines = 1) {
        return _io.verbose($message, $newlines);
    }

    /**
     * Output at all levels.
     *
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int|null The number of bytes returned from writing to stdout.
     */
    Nullable!int quiet($message, int $newlines = 1) {
        return _io.quiet($message, $newlines);
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
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @param int $level The message"s output level, see above.
     * @return int|null The number of bytes returned from writing to stdout.
     * @link https://book.cakephp.org/4/en/console-and-shells.html#Shell::out
     */
    Nullable!int out($message, int $newlines = 1, int $level = Shell::NORMAL) {
        return _io.out($message, $newlines, $level);
    }

    /**
     * Outputs a single or multiple error messages to stderr. If no parameters
     * are passed outputs just a newline.
     *
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int The number of bytes returned from writing to stderr.
     */
    int err($message, int $newlines = 1) {
        return _io.error($message, $newlines);
    }

    /**
     * Convenience method for out() that wraps message between <info /> tag
     *
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @param int $level The message"s output level, see above.
     * @return int|null The number of bytes returned from writing to stdout.
     * @see https://book.cakephp.org/4/en/console-and-shells.html#Shell::out
     */
    Nullable!int info($message, int $newlines = 1, int $level = Shell::NORMAL) {
        return _io.info($message, $newlines, $level);
    }

    /**
     * Convenience method for err() that wraps message between <warning /> tag
     *
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int The number of bytes returned from writing to stderr.
     * @see https://book.cakephp.org/4/en/console-and-shells.html#Shell::err
     */
    function warn($message, int $newlines = 1) {
        return _io.warning($message, $newlines);
    }

    /**
     * Convenience method for out() that wraps message between <success /> tag
     *
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @param int $level The message"s output level, see above.
     * @return int|null The number of bytes returned from writing to stdout.
     * @see https://book.cakephp.org/4/en/console-and-shells.html#Shell::out
     */
    Nullable!int success($message, int $newlines = 1, int $level = Shell::NORMAL) {
        return _io.success($message, $newlines, $level);
    }

    /**
     * Returns a single or multiple linefeeds sequences.
     *
     * @param int $multiplier Number of times the linefeed sequence should be repeated
     * @return string
     * @link https://book.cakephp.org/4/en/console-and-shells.html#Shell::nl
     */
    string nl(int $multiplier = 1) {
        return _io.nl($multiplier);
    }

    /**
     * Outputs a series of minus characters to the standard output, acts as a visual separator.
     *
     * @param int $newlines Number of newlines to pre- and append
     * @param int $width Width of the line, defaults to 63
     * @return void
     * @link https://book.cakephp.org/4/en/console-and-shells.html#Shell::hr
     */
    void hr(int $newlines = 0, int $width = 63) {
        _io.hr($newlines, $width);
    }

    /**
     * Displays a formatted error message
     * and exits the application with an error code.
     *
     * @param string $message The error message
     * @param int $exitCode The exit code for the shell task.
     * @throws uim.cake.consoles.exceptions.StopException
     * @return void
     * @link https://book.cakephp.org/4/en/console-and-shells.html#styling-output
     * @psalm-return never-return
     */
    void abort(string $message, int $exitCode = self::CODE_ERROR) {
        _io.err("<error>" ~ $message ~ "</error>");
        throw new StopException($message, $exitCode);
    }

    /**
     * Clear the console
     *
     * @return void
     * @link https://book.cakephp.org/4/en/console-and-shells.html#console-output
     */
    void clear() {
        if (!empty(this.params["noclear"])) {
            return;
        }

        if (DIRECTORY_SEPARATOR == "/") {
            passthru("clear");
        } else {
            passthru("cls");
        }
    }

    /**
     * Creates a file at given path
     *
     * @param string $path Where to put the file.
     * @param string $contents Content to put in the file.
     * @return bool Success
     * @link https://book.cakephp.org/4/en/console-and-shells.html#creating-files
     */
    bool createFile(string $path, string $contents) {
        $path = replace(DIRECTORY_SEPARATOR . DIRECTORY_SEPARATOR, DIRECTORY_SEPARATOR, $path);

        _io.out();

        $fileExists = is_file($path);
        if ($fileExists && empty(this.params["force"]) && !this.interactive) {
            _io.out("<warning>File exists, skipping</warning>.");

            return false;
        }

        if ($fileExists && this.interactive && empty(this.params["force"])) {
            _io.out(sprintf("<warning>File `%s` exists</warning>", $path));
            $key = _io.askChoice("Do you want to overwrite?", ["y", "n", "a", "q"], "n");

            if ($key.toLower == "q") {
                _io.out("<error>Quitting</error>.", 2);
                _stop();

                return false;
            }
            if ($key.toLower == "a") {
                this.params["force"] = true;
                $key = "y";
            }
            if ($key.toLower != "y") {
                _io.out(sprintf("Skip `%s`", $path), 2);

                return false;
            }
        } else {
            this.out(sprintf("Creating file %s", $path));
        }

        try {
            $fs = new Filesystem();
            $fs.dumpFile($path, $contents);

            _io.out(sprintf("<success>Wrote</success> `%s`", $path));
        } catch (UIMException $e) {
            _io.err(sprintf("<error>Could not write to `%s`</error>.", $path), 2);

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
    string shortPath(string $file) {
        $shortPath = replace(ROOT, "", $file);
        $shortPath = replace(".." ~ DIRECTORY_SEPARATOR, "", $shortPath);
        $shortPath = replace(DIRECTORY_SEPARATOR, "/", $shortPath);

        return replace("//", DIRECTORY_SEPARATOR, $shortPath);
    }

    /**
     * Render a Console Helper
     *
     * Create and render the output for a helper object. If the helper
     * object has not already been loaded, it will be loaded and constructed.
     *
     * @param string aName The name of the helper to render
     * @param array<string, mixed> aConfig Configuration data for the helper.
     * @return uim.cake.consoles.Helper The created helper instance.
     */
    function helper(string aName, Json aConfig = null): Helper
    {
        return _io.helper($name, aConfig);
    }

    /**
     * Stop execution of the current script.
     * Raises a StopException to try and halt the execution.
     *
     * @param int $status see https://secure.php.net/exit for values
     * @throws uim.cake.consoles.exceptions.StopException
     */
    protected void _stop(int $status = self::CODE_SUCCESS) {
        throw new StopException("Halting error reached", $status);
    }

    /**
     * Returns an array that can be used to describe the internal state of this
     * object.
     *
     * @return array<string, mixed>
     */
    array __debugInfo() {
        return [
            "name": this.name,
            "plugin": this.plugin,
            "command": this.command,
            "tasks": this.tasks,
            "params": this.params,
            "args": this.args,
            "interactive": this.interactive,
        ];
    }
}
