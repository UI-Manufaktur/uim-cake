module uim.cake.console;

import uim.cake.console.exceptions\MissingShellException;
import uim.cake.console.exceptions\StopException;
import uim.cake.core.App;
import uim.cake.core.Configure;
import uim.cake.core.Plugin;
import uim.cakegs\Log;
import uim.cake.shells.Task\CommandTask;
import uim.cakeilities.Inflector;

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
     * this.alias("alias", "ClassName");
     * ```
     *
     * Getting the original name for a given alias:
     *
     * ```
     * this.alias("alias");
     * ```
     *
     * @param string $short The new short name for the shell.
     * @param string|null $original The original full name for the shell.
     * @return string|null The aliased class name, or null if the alias does not exist
     */
    static string alias(string $short, Nullable!string $original = null) {
        $short = Inflector::camelize($short);
        if ($original) {
            static::$_aliases[$short] = $original;
        }

        return static::$_aliases[$short] ?? null;
    }

    /**
     * Clear any aliases that have been set.
     *
     */
    static void resetAliases() {
        static::$_aliases = [];
    }

    /**
     * Run the dispatcher
     *
     * @param array $argv The argv from PHP
     * @param array $extra Extra parameters
     * @return int The exit code of the shell process.
     */
    static int run(array $argv, array $extra = []) {
        $dispatcher = new ShellDispatcher($argv);

        return $dispatcher.dispatch($extra);
    }

    /**
     * Defines current working environment.
     *
     * @throws \Cake\Core\Exception\CakeException
     */
    protected void _initEnvironment() {
        this._bootstrap();

        if (function_exists("ini_set")) {
            ini_set("html_errors", "0");
            ini_set("implicit_flush", "1");
            ini_set("max_execution_time", "0");
        }

        this.shiftArgs();
    }

    // Initializes the environment and loads the UIM core.
    protected void _bootstrap() {
        if (!Configure::read("App.fullBaseUrl")) {
            Configure.write("App.fullBaseUrl", "http://localhost");
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
    int dispatch(array $extra = []) {
        try {
            myResult = this._dispatch($extra);
        } catch (StopException $e) {
            $code = $e.getCode();

            return $code;
        }
        if (myResult == null || myResult == true) {
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
        myShellName = this.shiftArgs();

        if (!myShellName) {
            this.help();

            return false;
        }
        if (in_array(myShellName, ["help", "--help", "-h"], true)) {
            this.help();

            return true;
        }
        if (in_array(myShellName, ["version", "--version"], true)) {
            this.version();

            return true;
        }

        myShell = this.findShell(myShellName);

        myShell.initialize();

        return myShell.runCommand(this.args, true, $extra);
    }

    /**
     * For all loaded plugins, add a short alias
     *
     * This permits a plugin which : a shell of the same name to be accessed
     * Using the shell name alone
     *
     * @return array the resultant list of aliases
     */
    array addShortPluginAliases() {
        myPlugins = Plugin::loaded();

        $io = new ConsoleIo();
        $task = new CommandTask($io);
        $io.setLoggers(false);
        $list = $task.getShellList() + ["app":[]];
        $fixed = array_flip($list["app"]) + array_flip($list["CORE"]);
        myAliases = $others = [];

        foreach (myPlugins as myPlugin) {
            if (!isset($list[myPlugin])) {
                continue;
            }

            foreach ($list[myPlugin] as myShell) {
                myAliases += [myShell: myPlugin];
                if (!isset($others[myShell])) {
                    $others[myShell] = [myPlugin];
                } else {
                    $others[myShell] = array_merge($others[myShell], [myPlugin]);
                }
            }
        }

        foreach (myAliases as myShell: myPlugin) {
            if (isset($fixed[myShell])) {
                Log::write(
                    "debug",
                    "command "myShell" in plugin "myPlugin" was not aliased, conflicts with another shell",
                    ["shell-dispatcher"]
                );
                continue;
            }

            $other = static::alias(myShell);
            if ($other) {
                if ($other !== myPlugin) {
                    Log::write(
                        "debug",
                        "command "myShell" in plugin "myPlugin" was not aliased, conflicts with "$other"",
                        ["shell-dispatcher"]
                    );
                }
                continue;
            }

            if (isset($others[myShell])) {
                $conflicts = array_diff($others[myShell], [myPlugin]);
                if (count($conflicts) > 0) {
                    $conflictList = implode("", "", $conflicts);
                    Log::write(
                        "debug",
                        "command "myShell" in plugin "myPlugin" was not aliased, conflicts with "$conflictList"",
                        ["shell-dispatcher"]
                    );
                }
            }

            static::alias(myShell, "myPlugin.myShell");
        }

        return static::$_aliases;
    }

    /**
     * Get shell to use, either plugin shell or application shell
     *
     * All paths in the loaded shell paths are searched, handles alias
     * dereferencing
     *
     * @param string myShell Optionally the name of a plugin
     * @return \Cake\Console\Shell A shell instance.
     * @throws \Cake\Console\Exception\MissingShellException when errors are encountered.
     */
    Shell findShell(string myShell): 
    {
        myClassName = this._shellExists(myShell);
        if (!myClassName) {
            myShell = this._handleAlias(myShell);
            myClassName = this._shellExists(myShell);
        }

        if (!myClassName) {
            throw new MissingShellException([
                "class":myShell,
            ]);
        }

        return this._createShell(myClassName, myShell);
    }

    /**
     * If the input matches an alias, return the aliased shell name
     *
     * @param string myShell Optionally the name of a plugin or alias
     * @return Shell name with plugin prefix
     */
    protected string _handleAlias(string myShell) {
        myAliased = static::alias(myShell);
        if (myAliased) {
            myShell = myAliased;
        }

        myClass = array_map("Cake\Utility\Inflector::camelize", explode(".", myShell));

        return implode(".", myClass);
    }

    /**
     * Check if a shell class exists for the given name.
     *
     * @param string myShell The shell name to look for.
     * @return string|null Either the classname or null.
     */
    protected string _shellExists(string myShell) {
        myClass = App::className(myShell, "Shell", "Shell");
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
    protected Shell _createShell(string myClassName, string $shortName) {
        [myPlugin] = pluginSplit($shortName);
        /** @var \Cake\Console\Shell $instance */
        $instance = new myClassName();
        $instance.plugin = trim((string)myPlugin, ".");

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
     */
    void help() {
        trigger_error(
            "Console help cannot be generated from Shell classes anymore. " .
            "Upgrade your application to import uim.cake.console.commandRunner instead.",
            E_USER_WARNING
        );
    }

    /**
     * Prints the currently installed version of UIM. Performs an internal dispatch to the CommandList Shell
     *
     */
    void version() {
        trigger_error(
            "Version information cannot be generated from Shell classes anymore. " .
            "Upgrade your application to import uim.cake.console.commandRunner instead.",
            E_USER_WARNING
        );
    }
}
