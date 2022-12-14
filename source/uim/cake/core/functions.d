module uim.cake.core.functions;

import uim.cake.core.Configure;

if (!defined("DS")) {
    // Defines DS as short form of DIRECTORY_SEPARATOR.
    define("DS", DIRECTORY_SEPARATOR);
}

if (!function_exists("h")) {
    /**
     * Convenience method for htmlspecialchars.
     *
     * @param mixed $text Text to wrap through htmlspecialchars. Also works with arrays, and objects.
     *    Arrays will be mapped and have all their elements escaped. Objects will be string cast if they
     *    implement a `__toString` method. Otherwise the class name will be used.
     *    Other scalar types will be returned unchanged.
     * @param bool $double Encode existing html entities.
     * @param string|null $charset Character set to use when escaping.
     *   Defaults to config value in `mb_internal_encoding()` or "UTF-8".
     * @return mixed Wrapped text.
     * @link https://book.UIM.org/4/en/core-libraries/global-constants-and-functions.html#h
     */
    function h($text, bool $double = true, Nullable!string $charset = null) {
        if (is_string($text)) {
            //optimize for strings
        } elseif (is_array($text)) {
            $texts = [];
            foreach ($text as $k: $t) {
                $texts[$k] = h($t, $double, $charset);
            }

            return $texts;
        } elseif (is_object($text)) {
            if (method_exists($text, "__toString")) {
                $text = $text.__toString();
            } else {
                $text = "(object)" . get_class($text);
            }
        } elseif ($text == null || is_scalar($text)) {
            return $text;
        }

        static $defaultCharset = false;
        if ($defaultCharset == false) {
            $defaultCharset = mb_internal_encoding() ?: "UTF-8";
        }

        return htmlspecialchars($text, ENT_QUOTES | ENT_SUBSTITUTE, $charset ?: $defaultCharset, $double);
    }

}

if (!function_exists("pluginSplit")) {
    /**
     * Splits a dot syntax plugin name into its plugin and class name.
     * If myName does not have a dot, then index 0 will be null.
     *
     * Commonly used like
     * ```
     * list(myPlugin, myName) = pluginSplit(myName);
     * ```
     *
     * @param string myName The name you want to plugin split.
     * @param bool $dotAppend Set to true if you want the plugin to have a "." appended to it.
     * @param string|null myPlugin Optional default plugin to use if no plugin is found. Defaults to null.
     * @return array Array with 2 indexes. 0: plugin name, 1: class name.
     * @link https://book.UIM.org/4/en/core-libraries/global-constants-and-functions.html#pluginSplit
     * @psalm-return array{string|null, string}
     */
    array pluginSplit(string myName, bool $dotAppend = false, Nullable!string myPlugin = null)
    {
        if (strpos(myName, ".") !== false) {
            $parts = explode(".", myName, 2);
            if ($dotAppend) {
                $parts[0] .= ".";
            }

            /** @psalm-var array{string, string}*/
            return $parts;
        }

        return [myPlugin, myName];
    }

}

if (!function_exists("moduleSplit")) {
    /**
     * Split the module from the classname.
     *
     * Commonly used like `list($module, myClassName) = moduleSplit(myClass);`.
     *
     * @param string myClass The full class name, ie `Cake\Core\App`.
     * @returnArray with 2 indexes. 0: module, 1: classname.
     */
    string[] moduleSplit(string myClass) {
        $pos = strrpos(myClass, "\\");
        if ($pos == false) {
            return ["", myClass];
        }

        return [substr(myClass, 0, $pos), substr(myClass, $pos + 1)];
    }

}

if (!function_exists("pr")) {
    /**
     * print_r() convenience function.
     *
     * In terminals this will act similar to using print_r() directly, when not run on CLI
     * print_r() will also wrap `<pre>` tags around the output of given variable. Similar to debug().
     *
     * This function returns the same variable that was passed.
     *
     * @param mixed $var Variable to print out.
     * @return mixed the same $var that was passed to this function
     * @link https://book.UIM.org/4/en/core-libraries/global-constants-and-functions.html#pr
     * @see debug()
     */
    function pr($var) {
        if (!Configure::read("debug")) {
            return $var;
        }

        myTemplate = PHP_SAPI !== "cli" && PHP_SAPI !== "phpdbg" ? "<pre class="pr">%s</pre>" : "\n%s\n\n";
        printf(myTemplate, trim(print_r($var, true)));

        return $var;
    }

}

if (!function_exists("pj")) {
    /**
     * JSON pretty print convenience function.
     *
     * In terminals this will act similar to using json_encode() with JSON_PRETTY_PRINT directly, when not run on CLI
     * will also wrap `<pre>` tags around the output of given variable. Similar to pr().
     *
     * This function returns the same variable that was passed.
     *
     * @param mixed $var Variable to print out.
     * @return mixed the same $var that was passed to this function
     * @see pr()
     * @link https://book.UIM.org/4/en/core-libraries/global-constants-and-functions.html#pj
     */
    function pj($var) {
        if (!Configure::read("debug")) {
            return $var;
        }

        myTemplate = PHP_SAPI !== "cli" && PHP_SAPI !== "phpdbg" ? "<pre class="pj">%s</pre>" : "\n%s\n\n";
        printf(myTemplate, trim(json_encode($var, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)));

        return $var;
    }

}

if (!function_exists("env")) {
    /**
     * Gets an environment variable from available sources, and provides emulation
     * for unsupported or inconsistent environment variables (i.e. DOCUMENT_ROOT on
     * IIS, or SCRIPT_NAME in CGI mode). Also exposes some additional custom
     * environment information.
     *
     * @param string myKey Environment variable name.
     * @param string|bool|null $default Specify a default value in case the environment variable is not defined.
     * @return string|bool|null Environment variable setting.
     * @link https://book.UIM.org/4/en/core-libraries/global-constants-and-functions.html#env
     */
    function env(string myKey, $default = null) {
        if (myKey == "HTTPS") {
            if (isset($_SERVER["HTTPS"])) {
                return !empty($_SERVER["HTTPS"]) && $_SERVER["HTTPS"] !== "off";
            }

            return strpos((string)env("SCRIPT_URI"), "https://") == 0;
        }

        if (myKey == "SCRIPT_NAME" && env("CGI_MODE") && isset($_ENV["SCRIPT_URL"])) {
            myKey = "SCRIPT_URL";
        }

        $val = $_SERVER[myKey] ?? $_ENV[myKey] ?? null;
        if ($val == null && getenv(myKey) !== false) {
            $val = getenv(myKey);
        }

        if (myKey == "REMOTE_ADDR" && $val == env("SERVER_ADDR")) {
            $addr = env("HTTP_PC_REMOTE_ADDR");
            if ($addr !== null) {
                $val = $addr;
            }
        }

        if ($val !== null) {
            return $val;
        }

        switch (myKey) {
            case "DOCUMENT_ROOT":
                myName = (string)env("SCRIPT_NAME");
                myfilename = (string)env("SCRIPT_FILENAME");
                $offset = 0;
                if (!strpos(myName, ".php")) {
                    $offset = 4;
                }

                return substr(myfilename, 0, -(strlen(myName) + $offset));
            case "PHP_SELF":
                return str_replace((string)env("DOCUMENT_ROOT"), "", (string)env("SCRIPT_FILENAME"));
            case "CGI_MODE":
                return PHP_SAPI == "cgi";
        }

        return $default;
    }

}

if (!function_exists("triggerWarning")) {
    /**
     * Triggers an E_USER_WARNING.
     *
     * @param string myMessage The warning message.
     */
    void triggerWarning(string myMessage) {
        $stackFrame = 1;
        $trace = debug_backtrace();
        if (isset($trace[$stackFrame])) {
            $frame = $trace[$stackFrame];
            $frame += ["file":"[internal]", "line":"??"];
            myMessage = sprintf(
                "%s - %s, line: %s",
                myMessage,
                $frame["file"],
                $frame["line"]
            );
        }
        trigger_error(myMessage, E_USER_WARNING);
    }
}

if (!function_exists("deprecationWarning")) {
    /**
     * Helper method for outputting deprecation warnings
     *
     * @param string myMessage The message to output as a deprecation warning.
     * @param int $stackFrame The stack frame to include in the error. Defaults to 1
     *   as that should point to application/plugin code.
     */
    void deprecationWarning(string myMessage, int $stackFrame = 1) {
        if (!(error_reporting() & E_USER_DEPRECATED)) {
            return;
        }

        $trace = debug_backtrace();
        if (isset($trace[$stackFrame])) {
            $frame = $trace[$stackFrame];
            $frame += ["file":"[internal]", "line":"??"];

            $relative = str_replace(DIRECTORY_SEPARATOR, "/", substr($frame["file"], strlen(ROOT) + 1));
            $patterns = (array)Configure::read("Error.ignoredDeprecationPaths");
            foreach ($patterns as $pattern) {
                $pattern = str_replace(DIRECTORY_SEPARATOR, "/", $pattern);
                if (fnmatch($pattern, $relative)) {
                    return;
                }
            }

            myMessage = sprintf(
                "%s - %s, line: %s" . "\n" .
                " You can disable all deprecation warnings by setting `Error.errorLevel` to" .
                " `E_ALL & ~E_USER_DEPRECATED`, or add `%s` to " .
                " `Error.ignoredDeprecationPaths` in your `config/app.php` to mute deprecations from only this file.",
                myMessage,
                $frame["file"],
                $frame["line"],
                $relative
            );
        }

        static myErrors = [];
        $checksum = md5(myMessage);
        $duplicate = (bool)Configure::read("Error.allowDuplicateDeprecations", false);
        if (isset(myErrors[$checksum]) && !$duplicate) {
            return;
        }
        if (!$duplicate) {
            myErrors[$checksum] = true;
        }

        trigger_error(myMessage, E_USER_DEPRECATED);
    }
}

if (!function_exists("getTypeName")) {
    /**
     * Returns the objects class or var type of it"s not an object
     *
     * @param mixed $var Variable to check
     * @return Returns the class name or variable type
     */
    string getTypeName($var) {
        return is_object($var) ? get_class($var) : gettype($var);
    }
}
