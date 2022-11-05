module uim.baklava.console;

import uim.baklava.console.Exception\MissingShellException;
import uim.baklava.console.Exception\StopException;
import uim.baklava.core.App;
import uim.baklava.core.Configure;
import uim.baklava.core.Plugin;
import uim.baklava.Log\Log;
import uim.baklava.Shell\Task\CommandTask;
import uim.baklava.utikities.Inflector;

/**
 * Shell dispatcher handles dispatching CLI commands.
 *
 * Consult /bin/cake.php for how this class is used in practice.
 *
 * @deprecated 3.6.0 ShellDispatcher and Shell will be removed in 5.0
 */
class ShellDispatcher
{
    /**
     * Contains arguments parsed from the command line.
     *
     * @var array
     */
    public $args = [];

    /**
     * List of connected aliases.
     *
     * @var array<string, string>
     */
    protected static $_aliases = [];

    /**
     * Constructor
     *
     * The execution of the script is stopped after dispatching the request with
     * a status code of either 0 or 1 according to the result of the dispatch.
     *
     * @param array $args the argv from PHP
     * @param bool $bootstrap Should the environment be bootstrapped.
     */
    this(array $args = [], bool $bootstrap = true) {
        set_time_limit(0);
        this.args = $args;

        this.addShortPluginAliases();

        if ($bootstrap) {
            this._initEnvironment();
        }
    }

    /**
     * Add an alias for a shell command.
     *
     * Aliases allow you to call shells by alternate names. This is most
     * useful when dealing with plugin shells that you want to have shorter
     * names for.
     *
     * If you re-use an alias the last alias set will be the one available.
     *
     * ### Usage
     *
     * Aliasing a shell named ClassName:
     *
     * ```
     * this.alias('alias', 'ClassName');
     * ```
     *
     * Getting the original name for a given alias:
     *
     * ```
     * this.alias('alias');
     * ```
     *
     * @param string $short The new short name for the shell.
     * @param string|null $original The original full name for the shell.
     * @return string|null The aliased class name, or null if the alias does not exist
     */
    static string alias(string $short, ?string $original = null) {
        $short = Inflector::camelize($short);
        if ($original) {
            static::$_aliases[$short] = $original;
        }

        return static::$_aliases[$short] ?? null;
    }

    /**
     * Clear any aliases that have been set.
     *
     * @return void
     */
    static function resetAliases(): void
    {
        static::$_aliases = [];
    }

    /**
     * Run the dispatcher
     *
     * @param array $argv The argv from PHP
     * @param array $extra Extra parameters
     * @return int The exit code of the shell process.
     */
    static function run(array $argv, array $extra = []): int
    {
        $dispatcher = new ShellDispatcher($argv);

        return $dispatcher.dispatch($extra);
    }

    /**
     * Defines current working environment.
     *
     * @return void
     * @throws \Cake\Core\Exception\CakeException
     */
    protected auto _initEnvironment(): void
    {
        this._bootstrap();

        if (function_exists('ini_set')) {
            ini_set('html_errors', '0');
            ini_set('implicit_flush', '1');
            ini_set('max_execution_time', '0');
        }

        this.shiftArgs();
    }

    /**
     * Initializes the environment and loads the CakePHP core.
     *
     * @return void
     */
    protected auto _bootstrap() {
        if (!Configure::read('App.fullBaseUrl')) {
            Configure.write('App.fullBaseUrl', 'http://localhost');
        }
    }

    /**
     * Dispatches a CLI request
     *
     * Converts a shell command result into an exit code. Null/True
     * are treated as success. All other return values are an error.
     *
     * @param array $extra Extra parameters that you can manually pass to the Shell
     * to be dispatched.
     * Built-in extra parameter is :
     *
     * - `requested` : if used, will prevent the Shell welcome message to be displayed
     * @return int The CLI command exit code. 0 is success.
     */
    function dispatch(array $extra = []): int
    {
        try {
            myResult = this._dispatch($extra);
        } catch (StopException $e) {
            $code = $e.getCode();

            return $code;
        }
        if (myResult === null || myResult === true) {
            /** @psalm-suppress DeprecatedClass */
            return Shell::CODE_SUCCESS;
        }
        if (is_int(myResult)) {
            return myResult;
        }

        /** @psalm-suppress DeprecatedClass */
        return Shell::CODE_ERROR;
    }

    /**
     * Dispatch a request.
     *
     * @param array $extra Extra parameters that you can manually pass to the Shell
     * to be dispatched.
     * Built-in extra parameter is :
     *
     * - `requested` : if used, will prevent the Shell welcome message to be displayed
     * @return int|bool|null
     * @throws \Cake\Console\Exception\MissingShellMethodException
     */
    protected auto _dispatch(array $extra = []) {
        $shellName = this.shiftArgs();

        if (!$shellName) {
            this.help();

            return false;
        }
        if (in_array($shellName, ['help', '--help', '-h'], true)) {
            this.help();

            return true;
        }
        if (in_array($shellName, ['version', '--version'], true)) {
            this.version();

            return true;
        }

        $shell = this.findShell($shellName);

        $shell.initialize();

        return $shell.runCommand(this.args, true, $extra);
    }

    /**
     * For all loaded plugins, add a short alias
     *
     * This permits a plugin which : a shell of the same name to be accessed
     * Using the shell name alone
     *
     * @return array the resultant list of aliases
     */
    function addShortPluginAliases(): array
    {
        myPlugins = Plugin::loaded();

        $io = new ConsoleIo();
        $task = new CommandTask($io);
        $io.setLoggers(false);
        $list = $task.getShellList() + ['app' => []];
        $fixed = array_flip($list['app']) + array_flip($list['CORE']);
        myAliases = $others = [];

        foreach (myPlugins as myPlugin) {
            if (!isset($list[myPlugin])) {
                continue;
            }

            foreach ($list[myPlugin] as $shell) {
                myAliases += [$shell => myPlugin];
                if (!isset($others[$shell])) {
                    $others[$shell] = [myPlugin];
                } else {
                    $others[$shell] = array_merge($others[$shell], [myPlugin]);
                }
            }
        }

        foreach (myAliases as $shell => myPlugin) {
            if (isset($fixed[$shell])) {
                Log::write(
                    'debug',
                    "command '$shell' in plugin 'myPlugin' was not aliased, conflicts with another shell",
                    ['shell-dispatcher']
                );
                continue;
            }

            $other = static::alias($shell);
            if ($other) {
                if ($other !== myPlugin) {
                    Log::write(
                        'debug',
                        "command '$shell' in plugin 'myPlugin' was not aliased, conflicts with '$other'",
                        ['shell-dispatcher']
                    );
                }
                continue;
            }

            if (isset($others[$shell])) {
                $conflicts = array_diff($others[$shell], [myPlugin]);
                if (count($conflicts) > 0) {
                    $conflictList = implode("', '", $conflicts);
                    Log::write(
                        'debug',
                        "command '$shell' in plugin 'myPlugin' was not aliased, conflicts with '$conflictList'",
                        ['shell-dispatcher']
                    );
                }
            }

            static::alias($shell, "myPlugin.$shell");
        }

        return static::$_aliases;
    }

    /**
     * Get shell to use, either plugin shell or application shell
     *
     * All paths in the loaded shell paths are searched, handles alias
     * dereferencing
     *
     * @param string $shell Optionally the name of a plugin
     * @return \Cake\Console\Shell A shell instance.
     * @throws \Cake\Console\Exception\MissingShellException when errors are encountered.
     */
    function findShell(string $shell): Shell
    {
        myClassName = this._shellExists($shell);
        if (!myClassName) {
            $shell = this._handleAlias($shell);
            myClassName = this._shellExists($shell);
        }

        if (!myClassName) {
            throw new MissingShellException([
                'class' => $shell,
            ]);
        }

        return this._createShell(myClassName, $shell);
    }

    /**
     * If the input matches an alias, return the aliased shell name
     *
     * @param string $shell Optionally the name of a plugin or alias
     * @return string Shell name with plugin prefix
     */
    protected string _handleAlias(string $shell) {
        myAliased = static::alias($shell);
        if (myAliased) {
            $shell = myAliased;
        }

        myClass = array_map('Cake\Utility\Inflector::camelize', explode('.', $shell));

        return implode('.', myClass);
    }

    /**
     * Check if a shell class exists for the given name.
     *
     * @param string $shell The shell name to look for.
     * @return string|null Either the classname or null.
     */
    protected string _shellExists(string $shell) {
        myClass = App::className($shell, 'Shell', 'Shell');
        if (myClass) {
            return myClass;
        }

        return null;
    }

    /**
     * Create the given shell name, and set the plugin property
     *
     * @param string myClassName The class name to instantiate
     * @param string $shortName The plugin-prefixed shell name
     * @return \Cake\Console\Shell A shell instance.
     */
    protected auto _createShell(string myClassName, string $shortName): Shell
    {
        [myPlugin] = pluginSplit($shortName);
        /** @var \Cake\Console\Shell $instance */
        $instance = new myClassName();
        $instance.plugin = trim((string)myPlugin, '.');

        return $instance;
    }

    /**
     * Removes first argument and shifts other arguments up
     *
     * @return mixed Null if there are no arguments otherwise the shifted argument
     */
    function shiftArgs() {
        return array_shift(this.args);
    }

    /**
     * Shows console help. Performs an internal dispatch to the CommandList Shell
     *
     * @return void
     */
    function help(): void
    {
        trigger_error(
            'Console help cannot be generated from Shell classes anymore. ' .
            'Upgrade your application to import uim.baklava.console.commandRunner instead.',
            E_USER_WARNING
        );
    }

    /**
     * Prints the currently installed version of CakePHP. Performs an internal dispatch to the CommandList Shell
     *
     * @return void
     */
    function version(): void
    {
        trigger_error(
            'Version information cannot be generated from Shell classes anymore. ' .
            'Upgrade your application to import uim.baklava.console.commandRunner instead.',
            E_USER_WARNING
        );
    }
}
