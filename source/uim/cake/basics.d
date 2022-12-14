/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module 

import uim.cake.core.Configure;
import uim.cake.errors.Debugger;
use Psy\Shell as PsyShell;

define("SECOND", 1);
define("MINUTE", 60);
define("HOUR", 3600);
define("DAY", 86400);
define("WEEK", 604800);
define("MONTH", 2592000);
define("YEAR", 31536000);

if (!function_exists("debug")) {
    /**
     * Prints out debug information about given variable and returns the
     * variable that was passed.
     *
     * Only runs if debug mode is enabled.
     *
     * @param mixed $var Variable to show debug information for.
     * @param bool|null $showHtml If set to true, the method prints the debug data in a browser-friendly way.
     * @param bool $showFrom If set to true, the method prints from where the function was called.
     * @return mixed The same $var that was passed
     * @link https://book.cakephp.org/4/en/development/debugging.html#basic-debugging
     * @link https://book.cakephp.org/4/en/core-libraries/global-constants-and-functions.html#debug
     */
    function debug($var, $showHtml = null, $showFrom = true) {
        if (!Configure::read("debug")) {
            return $var;
        }

        $location = null;
        if ($showFrom) {
            $trace = Debugger::trace(["start": 1, "depth": 2, "format": "array"]);
            /** @psalm-suppress PossiblyInvalidArrayOffset */
            $location = [
                "line": $trace[0]["line"],
                "file": $trace[0]["file"],
            ];
        }

        Debugger::printVar($var, $location, $showHtml);

        return $var;
    }

}

if (!function_exists("stackTrace")) {
    /**
     * Outputs a stack trace based on the supplied options.
     *
     * ### Options
     *
     * - `depth` - The number of stack frames to return. Defaults to 999
     * - `args` - Should arguments for functions be shown? If true, the arguments for each method call
     *   will be displayed.
     * - `start` - The stack frame to start generating a trace from. Defaults to 1
     *
     * @param array<string, mixed> $options Format for outputting stack trace
     */
    void stackTrace(STRINGAA someOptions = null) {
        if (!Configure::read("debug")) {
            return;
        }

        $options += ["start": 0];
        $options["start"]++;

        /** @var string $trace */
        $trace = Debugger::trace($options);
        echo $trace;
    }

}

if (!function_exists("breakpoint")) {
    /**
     * Command to return the eval-able code to startup PsySH in interactive debugger
     * Works the same way as eval(\Psy\sh());
     * psy/psysh must be loaded in your project
     *
     * ```
     * eval(breakpoint());
     * ```
     *
     * @return string|null
     * @link https://psysh.org/
     */
    Nullable!string breakpoint() {
        if ((PHP_SAPI == "cli" || PHP_SAPI == "phpdbg") && class_exists(PsyShell::class)) {
            return "extract(\Psy\Shell::debug(get_defined_vars(), isset(this) ? this : null));";
        }
        trigger_error(
            "psy/psysh must be installed and you must be in a CLI environment to use the breakpoint function",
            E_USER_WARNING
        );

        return null;
    }
}

if (!function_exists("dd")) {
    /**
     * Prints out debug information about given variable and dies.
     *
     * Only runs if debug mode is enabled.
     * It will otherwise just continue code execution and ignore this function.
     *
     * @param mixed $var Variable to show debug information for.
     * @param bool|null $showHtml If set to true, the method prints the debug data in a browser-friendly way.
     * @return void
     * @link https://book.cakephp.org/4/en/development/debugging.html#basic-debugging
     */
    void dd($var, $showHtml = null) {
        if (!Configure::read("debug")) {
            return;
        }

        $trace = Debugger::trace(["start": 1, "depth": 2, "format": "array"]);
        /** @psalm-suppress PossiblyInvalidArrayOffset */
        $location = [
            "line": $trace[0]["line"],
            "file": $trace[0]["file"],
        ];

        Debugger::printVar($var, $location, $showHtml);
        die(1);
    }
}
