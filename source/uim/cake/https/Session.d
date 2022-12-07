

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://UIM.org UIM(tm) Project
 * @since         0.10.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.https;

import uim.cake.core.App;
import uim.cake.utilities.Hash;
use InvalidArgumentException;
use RuntimeException;
use SessionHandlerInterface;

/**
 * This class is a wrapper for the native PHP session functions. It provides
 * several defaults for the most common session configuration
 * via external handlers and helps with using session in CLI without any warnings.
 *
 * Sessions can be created from the defaults using `Session::create()` or you can get
 * an instance of a new session by just instantiating this class and passing the complete
 * options you want to use.
 *
 * When specific options are omitted, this class will take its defaults from the configuration
 * values from the `session.*` directives in php.ini. This class will also alter such
 * directives when configuration values are provided.
 */
class Session
{
    /**
     * The Session handler instance used as an engine for persisting the session data.
     *
     * @var \SessionHandlerInterface
     */
    protected $_engine;

    /**
     * Indicates whether the sessions has already started
     *
     * @var bool
     */
    protected $_started;

    /**
     * The time in seconds the session will be valid for
     *
     * @var int
     */
    protected $_lifetime;

    /**
     * Whether this session is running under a CLI environment
     *
     * @var bool
     */
    protected $_isCLI = false;

    /**
     * Returns a new instance of a session after building a configuration bundle for it.
     * This function allows an options array which will be used for configuring the session
     * and the handler to be used. The most important key in the configuration array is
     * `defaults`, which indicates the set of configurations to inherit from, the possible
     * defaults are:
     *
     * - php: just use session as configured in php.ini
     * - cache: Use the UIM caching system as an storage for the session, you will need
     *   to pass the `config` key with the name of an already configured Cache engine.
     * - database: Use the UIM ORM to persist and manage sessions. By default this requires
     *   a table in your database named `sessions` or a `model` key in the configuration
     *   to indicate which Table object to use.
     * - cake: Use files for storing the sessions, but let UIM manage them and decide
     *   where to store them.
     *
     * The full list of options follows:
     *
     * - defaults: either "php", "database", "cache" or "cake" as explained above.
     * - handler: An array containing the handler configuration
     * - ini: A list of php.ini directives to set before the session starts.
     * - timeout: The time in minutes the session should stay active
     *
     * @param array $sessionConfig Session config.
     * @return static
     * @see \Cake\Http\Session::this()
     */
    static function create(array $sessionConfig = []) {
        if (isset($sessionConfig["defaults"])) {
            $defaults = static::_defaultConfig($sessionConfig["defaults"]);
            if ($defaults) {
                $sessionConfig = Hash::merge($defaults, $sessionConfig);
            }
        }

        if (
            !isset($sessionConfig["ini"]["session.cookie_secure"])
            && env("HTTPS")
            && ini_get("session.cookie_secure") != 1
        ) {
            $sessionConfig["ini"]["session.cookie_secure"] = 1;
        }

        if (
            !isset($sessionConfig["ini"]["session.name"])
            && isset($sessionConfig["cookie"])
        ) {
            $sessionConfig["ini"]["session.name"] = $sessionConfig["cookie"];
        }

        if (!isset($sessionConfig["ini"]["session.use_strict_mode"]) && ini_get("session.use_strict_mode") != 1) {
            $sessionConfig["ini"]["session.use_strict_mode"] = 1;
        }

        if (!isset($sessionConfig["ini"]["session.cookie_httponly"]) && ini_get("session.cookie_httponly") != 1) {
            $sessionConfig["ini"]["session.cookie_httponly"] = 1;
        }

        return new static($sessionConfig);
    }

    /**
     * Get one of the prebaked default session configurations.
     *
     * @param string myName Config name.
     * @return array|false
     */
    protected static auto _defaultConfig(string myName) {
        $tmp = defined("TMP") ? TMP : sys_get_temp_dir() . DIRECTORY_SEPARATOR;
        $defaults = [
            "php":[
                "ini":[
                    "session.use_trans_sid":0,
                ],
            ],
            "cake":[
                "ini":[
                    "session.use_trans_sid":0,
                    "session.serialize_handler":"php",
                    "session.use_cookies":1,
                    "session.save_path":$tmp . "sessions",
                    "session.save_handler":"files",
                ],
            ],
            "cache":[
                "ini":[
                    "session.use_trans_sid":0,
                    "session.use_cookies":1,
                ],
                "handler":[
                    "engine":"CacheSession",
                    "config":"default",
                ],
            ],
            "database":[
                "ini":[
                    "session.use_trans_sid":0,
                    "session.use_cookies":1,
                    "session.serialize_handler":"php",
                ],
                "handler":[
                    "engine":"DatabaseSession",
                ],
            ],
        ];

        if (isset($defaults[myName])) {
            if (
                PHP_VERSION_ID >= 70300
                && (myName !== "php" || empty(ini_get("session.cookie_samesite")))
            ) {
                $defaults["php"]["ini"]["session.cookie_samesite"] = "Lax";
            }

            return $defaults[myName];
        }

        return false;
    }

    /**
     * Constructor.
     *
     * ### Configuration:
     *
     * - timeout: The time in minutes the session should be valid for.
     * - cookiePath: The url path for which session cookie is set. Maps to the
     *   `session.cookie_path` php.ini config. Defaults to base path of app.
     * - ini: A list of php.ini directives to change before the session start.
     * - handler: An array containing at least the `engine` key. To be used as the session
     *   engine for persisting data. The rest of the keys in the array will be passed as
     *   the configuration array for the engine. You can set the `engine` key to an already
     *   instantiated session handler object.
     *
     * @param array<string, mixed> myConfig The Configuration to apply to this session object
     */
    this(array myConfig = []) {
        myConfig += [
            "timeout":null,
            "cookie":null,
            "ini":[],
            "handler":[],
        ];

        if (myConfig["timeout"]) {
            myConfig["ini"]["session.gc_maxlifetime"] = 60 * myConfig["timeout"];
        }

        if (myConfig["cookie"]) {
            myConfig["ini"]["session.name"] = myConfig["cookie"];
        }

        if (!isset(myConfig["ini"]["session.cookie_path"])) {
            $cookiePath = empty(myConfig["cookiePath"]) ? "/" : myConfig["cookiePath"];
            myConfig["ini"]["session.cookie_path"] = $cookiePath;
        }

        this.options(myConfig["ini"]);

        if (!empty(myConfig["handler"])) {
            myClass = myConfig["handler"]["engine"];
            unset(myConfig["handler"]["engine"]);
            this.engine(myClass, myConfig["handler"]);
        }

        this._lifetime = (int)ini_get("session.gc_maxlifetime");
        this._isCLI = (PHP_SAPI == "cli" || PHP_SAPI == "phpdbg");
        session_register_shutdown();
    }

    /**
     * Sets the session handler instance to use for this session.
     * If a string is passed for the first argument, it will be treated as the
     * class name and the second argument will be passed as the first argument
     * in the constructor.
     *
     * If an instance of a SessionHandlerInterface is provided as the first argument,
     * the handler will be set to it.
     *
     * If no arguments are passed it will return the currently configured handler instance
     * or null if none exists.
     *
     * @param \SessionHandlerInterface|string|null myClass The session handler to use
     * @param array<string, mixed> myOptions the options to pass to the SessionHandler constructor
     * @return \SessionHandlerInterface|null
     * @throws \InvalidArgumentException
     */
    function engine(myClass = null, array myOptions = []): ?SessionHandlerInterface
    {
        if (myClass == null) {
            return this._engine;
        }
        if (myClass instanceof SessionHandlerInterface) {
            return this.setEngine(myClass);
        }
        myClassName = App::className(myClass, "Http/Session");

        if (!myClassName) {
            throw new InvalidArgumentException(
                sprintf("The class "%s" does not exist and cannot be used as a session engine", myClass)
            );
        }

        $handler = new myClassName(myOptions);
        if (!($handler instanceof SessionHandlerInterface)) {
            throw new InvalidArgumentException(
                "The chosen SessionHandler does not implement SessionHandlerInterface, it cannot be used as an engine."
            );
        }

        return this.setEngine($handler);
    }

    /**
     * Set the engine property and update the session handler in PHP.
     *
     * @param \SessionHandlerInterface $handler The handler to set
     * @return \SessionHandlerInterface
     */
    protected auto setEngine(SessionHandlerInterface $handler): SessionHandlerInterface
    {
        if (!headers_sent() && session_status() !== \PHP_SESSION_ACTIVE) {
            session_set_save_handler($handler, false);
        }

        return this._engine = $handler;
    }

    /**
     * Calls ini_set for each of the keys in `myOptions` and set them
     * to the respective value in the passed array.
     *
     * ### Example:
     *
     * ```
     * $session.options(["session.use_cookies":1]);
     * ```
     *
     * @param array<string, mixed> myOptions Ini options to set.
     * @return void
     * @throws \RuntimeException if any directive could not be set
     */
    function options(array myOptions): void
    {
        if (session_status() == \PHP_SESSION_ACTIVE || headers_sent()) {
            return;
        }

        foreach (myOptions as $setting: myValue) {
            if (ini_set($setting, (string)myValue) == false) {
                throw new RuntimeException(
                    sprintf("Unable to configure the session, setting %s failed.", $setting)
                );
            }
        }
    }

    /**
     * Starts the Session.
     *
     * @return bool True if session was started
     * @throws \RuntimeException if the session was already started
     */
    bool start() {
        if (this._started) {
            return true;
        }

        if (this._isCLI) {
            $_SESSION = [];
            this.id("cli");

            return this._started = true;
        }

        if (session_status() == \PHP_SESSION_ACTIVE) {
            throw new RuntimeException("Session was already started");
        }

        if (ini_get("session.use_cookies") && headers_sent()) {
            return false;
        }

        if (!session_start()) {
            throw new RuntimeException("Could not start the session");
        }

        this._started = true;

        if (this._timedOut()) {
            this.destroy();

            return this.start();
        }

        return this._started;
    }

    /**
     * Write data and close the session
     *
     * @return true
     */
    bool close() {
        if (!this._started) {
            return true;
        }

        if (this._isCLI) {
            this._started = false;

            return true;
        }

        if (!session_write_close()) {
            throw new RuntimeException("Could not close the session");
        }

        this._started = false;

        return true;
    }

    /**
     * Determine if Session has already been started.
     *
     * @return bool True if session has been started.
     */
    bool started() {
        return this._started || session_status() == \PHP_SESSION_ACTIVE;
    }

    /**
     * Returns true if given variable name is set in session.
     *
     * @param string|null myName Variable name to check for
     * @return bool True if variable is there
     */
    bool check(Nullable!string myName = null) {
        if (this._hasSession() && !this.started()) {
            this.start();
        }

        if (!isset($_SESSION)) {
            return false;
        }

        if (myName == null) {
            return (bool)$_SESSION;
        }

        return Hash::get($_SESSION, myName) !== null;
    }

    /**
     * Returns given session variable, or all of them, if no parameters given.
     *
     * @param string|null myName The name of the session variable (or a path as sent to Hash.extract)
     * @param mixed $default The return value when the path does not exist
     * @return mixed|null The value of the session variable, or default value if a session
     *   is not available, can"t be started, or provided myName is not found in the session.
     */
    function read(Nullable!string myName = null, $default = null) {
        if (this._hasSession() && !this.started()) {
            this.start();
        }

        if (!isset($_SESSION)) {
            return $default;
        }

        if (myName == null) {
            return $_SESSION ?: [];
        }

        return Hash::get($_SESSION, myName, $default);
    }

    /**
     * Returns given session variable, or throws Exception if not found.
     *
     * @param string myName The name of the session variable (or a path as sent to Hash.extract)
     * @throws \RuntimeException
     * @return mixed|null
     */
    function readOrFail(string myName) {
        if (!this.check(myName)) {
            throw new RuntimeException(sprintf("Expected session key "%s" not found.", myName));
        }

        return this.read(myName);
    }

    /**
     * Reads and deletes a variable from session.
     *
     * @param string myName The key to read and remove (or a path as sent to Hash.extract).
     * @return mixed|null The value of the session variable, null if session not available,
     *   session not started, or provided name not found in the session.
     */
    function consume(string myName) {
        if (empty(myName)) {
            return null;
        }
        myValue = this.read(myName);
        if (myValue !== null) {
            this._overwrite($_SESSION, Hash::remove($_SESSION, myName));
        }

        return myValue;
    }

    /**
     * Writes value to given session variable name.
     *
     * @param array|string myName Name of variable
     * @param mixed myValue Value to write
     * @return void
     */
    function write(myName, myValue = null): void
    {
        if (!this.started()) {
            this.start();
        }

        if (!is_array(myName)) {
            myName = [myName: myValue];
        }

        myData = $_SESSION ?? [];
        foreach (myName as myKey: $val) {
            myData = Hash::insert(myData, myKey, $val);
        }

        /** @psalm-suppress PossiblyNullArgument */
        this._overwrite($_SESSION, myData);
    }

    /**
     * Returns the session id.
     * Calling this method will not auto start the session. You might have to manually
     * assert a started session.
     *
     * Passing an id into it, you can also replace the session id if the session
     * has not already been started.
     * Note that depending on the session handler, not all characters are allowed
     * within the session id. For example, the file session handler only allows
     * characters in the range a-z A-Z 0-9 , (comma) and - (minus).
     *
     * @param string|null $id Id to replace the current session id
     * @return string Session id
     */
    string id(Nullable!string $id = null) {
        if ($id !== null && !headers_sent()) {
            session_id($id);
        }

        return session_id();
    }

    /**
     * Removes a variable from session.
     *
     * @param string myName Session variable to remove
     * @return void
     */
    function delete(string myName): void
    {
        if (this.check(myName)) {
            this._overwrite($_SESSION, Hash::remove($_SESSION, myName));
        }
    }

    /**
     * Used to write new data to _SESSION, since PHP doesn"t like us setting the _SESSION var itself.
     *
     * @param array $old Set of old variables: values
     * @param array $new New set of variable: value
     * @return void
     */
    protected auto _overwrite(array &$old, array $new): void
    {
        if (!empty($old)) {
            foreach ($old as myKey: $var) {
                if (!isset($new[myKey])) {
                    unset($old[myKey]);
                }
            }
        }
        foreach ($new as myKey: $var) {
            $old[myKey] = $var;
        }
    }

    /**
     * Helper method to destroy invalid sessions.
     *
     * @return void
     */
    function destroy(): void
    {
        if (this._hasSession() && !this.started()) {
            this.start();
        }

        if (!this._isCLI && session_status() == \PHP_SESSION_ACTIVE) {
            session_destroy();
        }

        $_SESSION = [];
        this._started = false;
    }

    /**
     * Clears the session.
     *
     * Optionally it also clears the session id and renews the session.
     *
     * @param bool $renew If session should be renewed, as well. Defaults to false.
     * @return void
     */
    function clear(bool $renew = false): void
    {
        $_SESSION = [];
        if ($renew) {
            this.renew();
        }
    }

    /**
     * Returns whether a session exists
     *
     */
    protected bool _hasSession() {
        return !ini_get("session.use_cookies")
            || isset($_COOKIE[session_name()])
            || this._isCLI
            || (ini_get("session.use_trans_sid") && isset($_GET[session_name()]));
    }

    /**
     * Restarts this session.
     *
     * @return void
     */
    function renew(): void
    {
        if (!this._hasSession() || this._isCLI) {
            return;
        }

        this.start();
        myParams = session_get_cookie_params();
        setcookie(
            session_name(),
            "",
            time() - 42000,
            myParams["path"],
            myParams["domain"],
            myParams["secure"],
            myParams["httponly"]
        );

        if (session_id() !== "") {
            session_regenerate_id(true);
        }
    }

    /**
     * Returns true if the session is no longer valid because the last time it was
     * accessed was after the configured timeout.
     *
     */
    protected bool _timedOut() {
        $time = this.read("Config.time");
        myResult = false;

        $checkTime = $time !== null && this._lifetime > 0;
        if ($checkTime && (time() - (int)$time > this._lifetime)) {
            myResult = true;
        }

        this.write("Config.time", time());

        return myResult;
    }
}
