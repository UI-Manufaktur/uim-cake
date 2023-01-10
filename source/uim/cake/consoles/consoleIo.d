/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.consoles;

@safe:
import uim.cake;

use RuntimeException;
use SplFileObject;

/**
 * A wrapper around the various IO operations shell tasks need to do.
 *
 * Packages up the stdout, stderr, and stdin streams providing a simple
 * consistent interface for shells to use. This class also makes mocking streams
 * easy to do in unit tests.
 */
class ConsoleIo
{
    /**
     * Output constant making verbose shells.
     *
     * @var int
     */
    const VERBOSE = 2;

    /**
     * Output constant for making normal shells.
     *
     * @var int
     */
    const NORMAL = 1;

    /**
     * Output constants for making quiet shells.
     *
     * @var int
     */
    const QUIET = 0;

    /**
     * The output stream
     *
     * @var uim.cake.consoles.ConsoleOutput
     */
    protected _out;

    /**
     * The error stream
     *
     * @var uim.cake.consoles.ConsoleOutput
     */
    protected _err;

    /**
     * The input stream
     *
     * @var uim.cake.consoles.ConsoleInput
     */
    protected _in;

    /**
     * The helper registry.
     *
     * @var uim.cake.consoles.HelperRegistry
     */
    protected _helpers;

    /**
     * The current output level.
     */
    protected int _level = self::NORMAL;

    /**
     * The number of bytes last written to the output stream
     * used when overwriting the previous message.
     */
    protected int _lastWritten = 0;

    /**
     * Whether files should be overwritten
     */
    protected bool $forceOverwrite = false;

    /**
     */
    protected bool $interactive = true;

    /**
     * Constructor
     *
     * @param uim.cake.consoles.ConsoleOutput|null $out A ConsoleOutput object for stdout.
     * @param uim.cake.consoles.ConsoleOutput|null $err A ConsoleOutput object for stderr.
     * @param uim.cake.consoles.ConsoleInput|null $in A ConsoleInput object for stdin.
     * @param uim.cake.consoles.HelperRegistry|null $helpers A HelperRegistry instance
     */
    this(
        ?ConsoleOutput $out = null,
        ?ConsoleOutput $err = null,
        ?ConsoleInput $in = null,
        ?HelperRegistry $helpers = null
    ) {
        _out = $out ?: new ConsoleOutput("php://stdout");
        _err = $err ?: new ConsoleOutput("php://stderr");
        _in = $in ?: new ConsoleInput("php://stdin");
        _helpers = $helpers ?: new HelperRegistry();
        _helpers.setIo(this);
    }

    /**
     * @param bool $value Value
     */
    void setInteractive(bool $value) {
        this.interactive = $value;
    }

    /**
     * Get/set the current output level.
     *
     * @param int|null $level The current output level.
     * @return int The current output level.
     */
    int level(Nullable!int $level = null) {
        if ($level != null) {
            _level = $level;
        }

        return _level;
    }

    /**
     * Output at the verbose level.
     *
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int|null The number of bytes returned from writing to stdout
     *   or null if current level is less than ConsoleIo::VERBOSE
     */
    Nullable!int verbose($message, int $newlines = 1) {
        return this.out($message, $newlines, self::VERBOSE);
    }

    /**
     * Output at all levels.
     *
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int|null The number of bytes returned from writing to stdout
     *   or null if current level is less than ConsoleIo::QUIET
     */
    Nullable!int quiet($message, int $newlines = 1) {
        return this.out($message, $newlines, self::QUIET);
    }

    /**
     * Outputs a single or multiple messages to stdout. If no parameters
     * are passed outputs just a newline.
     *
     * ### Output levels
     *
     * There are 3 built-in output level. ConsoleIo::QUIET, ConsoleIo::NORMAL, ConsoleIo::VERBOSE.
     * The verbose and quiet output levels, map to the `verbose` and `quiet` output switches
     * present in most shells. Using ConsoleIo::QUIET for a message means it will always display.
     * While using ConsoleIo::VERBOSE means it will only display when verbose output is toggled.
     *
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @param int $level The message"s output level, see above.
     * @return int|null The number of bytes returned from writing to stdout
     *   or null if provided $level is greater than current level.
     */
    Nullable!int out($message = "", int $newlines = 1, int $level = self::NORMAL) {
        if ($level <= _level) {
            _lastWritten = _out.write($message, $newlines);

            return _lastWritten;
        }

        return null;
    }

    /**
     * Convenience method for out() that wraps message between <info /> tag
     *
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @param int $level The message"s output level, see above.
     * @return int|null The number of bytes returned from writing to stdout
     *   or null if provided $level is greater than current level.
     * @see https://book.cakephp.org/4/en/console-and-shells.html#ConsoleIo::out
     */
    Nullable!int info($message, int $newlines = 1, int $level = self::NORMAL) {
        $messageType = "info";
        $message = this.wrapMessageWithType($messageType, $message);

        return this.out($message, $newlines, $level);
    }

    /**
     * Convenience method for out() that wraps message between <comment /> tag
     *
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @param int $level The message"s output level, see above.
     * @return int|null The number of bytes returned from writing to stdout
     *   or null if provided $level is greater than current level.
     * @see https://book.cakephp.org/4/en/console-and-shells.html#ConsoleIo::out
     */
    Nullable!int comment($message, int $newlines = 1, int $level = self::NORMAL) {
        $messageType = "comment";
        $message = this.wrapMessageWithType($messageType, $message);

        return this.out($message, $newlines, $level);
    }

    /**
     * Convenience method for err() that wraps message between <warning /> tag
     *
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int The number of bytes returned from writing to stderr.
     * @see https://book.cakephp.org/4/en/console-and-shells.html#ConsoleIo::err
     */
    int warning($message, int $newlines = 1) {
        $messageType = "warning";
        $message = this.wrapMessageWithType($messageType, $message);

        return this.err($message, $newlines);
    }

    /**
     * Convenience method for err() that wraps message between <error /> tag
     *
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int The number of bytes returned from writing to stderr.
     * @see https://book.cakephp.org/4/en/console-and-shells.html#ConsoleIo::err
     */
    int error($message, int $newlines = 1) {
        $messageType = "error";
        $message = this.wrapMessageWithType($messageType, $message);

        return this.err($message, $newlines);
    }

    /**
     * Convenience method for out() that wraps message between <success /> tag
     *
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @param int $level The message"s output level, see above.
     * @return int|null The number of bytes returned from writing to stdout
     *   or null if provided $level is greater than current level.
     * @see https://book.cakephp.org/4/en/console-and-shells.html#ConsoleIo::out
     */
    Nullable!int success($message, int $newlines = 1, int $level = self::NORMAL) {
        $messageType = "success";
        $message = this.wrapMessageWithType($messageType, $message);

        return this.out($message, $newlines, $level);
    }

    /**
     * Halts the the current process with a StopException.
     *
     * @param string $message Error message.
     * @param int $code Error code.
     * @return void
     * @psalm-return never-return
     * @throws uim.cake.consoles.exceptions.StopException
     */
    void abort($message, $code = ICommand::CODE_ERROR) {
        this.error($message);

        throw new StopException($message, $code);
    }

    /**
     * Wraps a message with a given message type, e.g. <warning>
     *
     * @param string $messageType The message type, e.g~ "warning".
     * @param array<string>|string $message The message to wrap.
     * @return array<string>|string The message wrapped with the given message type.
     */
    protected function wrapMessageWithType(string $messageType, $message) {
        if (is_array($message)) {
            foreach ($message as $k: $v) {
                $message[$k] = "<{$messageType}>{$v}</{$messageType}>";
            }
        } else {
            $message = "<{$messageType}>{$message}</{$messageType}>";
        }

        return $message;
    }

    /**
     * Overwrite some already output text.
     *
     * Useful for building progress bars, or when you want to replace
     * text already output to the screen with new text.
     *
     * **Warning** You cannot overwrite text that contains newlines.
     *
     * @param array<string>|string $message The message to output.
     * @param int $newlines Number of newlines to append.
     * @param int|null $size The number of bytes to overwrite. Defaults to the
     *    length of the last message output.
     */
    void overwrite($message, int $newlines = 1, Nullable!int $size = null) {
        $size = $size ?: _lastWritten;

        // Output backspaces.
        this.out(str_repeat("\x08", $size), 0);

        $newBytes = (int)this.out($message, 0);

        // Fill any remaining bytes with spaces.
        $fill = $size - $newBytes;
        if ($fill > 0) {
            this.out(str_repeat(" ", $fill), 0);
        }
        if ($newlines) {
            this.out(this.nl($newlines), 0);
        }

        // Store length of content + fill so if the new content
        // is shorter than the old content the next overwrite
        // will work.
        if ($fill > 0) {
            _lastWritten = $newBytes + $fill;
        }
    }

    /**
     * Outputs a single or multiple error messages to stderr. If no parameters
     * are passed outputs just a newline.
     *
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int The number of bytes returned from writing to stderr.
     */
    int err($message = "", int $newlines = 1) {
        return _err.write($message, $newlines);
    }

    /**
     * Returns a single or multiple linefeeds sequences.
     *
     * @param int $multiplier Number of times the linefeed sequence should be repeated
     */
    string nl(int $multiplier = 1) {
        return str_repeat(ConsoleOutput::LF, $multiplier);
    }

    /**
     * Outputs a series of minus characters to the standard output, acts as a visual separator.
     *
     * @param int $newlines Number of newlines to pre- and append
     * @param int $width Width of the line, defaults to 79
     */
    void hr(int $newlines = 0, int $width = 79) {
        this.out("", $newlines);
        this.out(str_repeat("-", $width));
        this.out("", $newlines);
    }

    /**
     * Prompts the user for input, and returns it.
     *
     * @param string $prompt Prompt text.
     * @param string|null $default Default input value.
     * @return string Either the default value, or the user-provided input.
     */
    string ask(string $prompt, Nullable!string $default = null) {
        return _getInput($prompt, null, $default);
    }

    /**
     * Change the output mode of the stdout stream
     *
     * @param int $mode The output mode.
     * @return void
     * @see uim.cake.consoles.ConsoleOutput::setOutputAs()
     */
    void setOutputAs(int $mode) {
        _out.setOutputAs($mode);
    }

    /**
     * Gets defined styles.
     *
     * @return array
     * @see uim.cake.consoles.ConsoleOutput::styles()
     */
    array styles() {
        return _out.styles();
    }

    /**
     * Get defined style.
     *
     * @param string $style The style to get.
     * @return array
     * @see uim.cake.consoles.ConsoleOutput::getStyle()
     */
    array getStyle(string $style) {
        return _out.getStyle($style);
    }

    /**
     * Adds a new output style.
     *
     * @param string $style The style to set.
     * @param array $definition The array definition of the style to change or create.
     * @return void
     * @see uim.cake.consoles.ConsoleOutput::setStyle()
     */
    void setStyle(string $style, array $definition) {
        _out.setStyle($style, $definition);
    }

    /**
     * Prompts the user for input based on a list of options, and returns it.
     *
     * @param string $prompt Prompt text.
     * @param array<string>|string $options Array or string of options.
     * @param string|null $default Default input value.
     * @return string Either the default value, or the user-provided input.
     */
    string askChoice(string $prompt, $options, Nullable!string $default = null) {
        if (is_string($options)) {
            if (strpos($options, ",")) {
                $options = explode(",", $options);
            } elseif (strpos($options, "/")) {
                $options = explode("/", $options);
            } else {
                $options = [$options];
            }
        }

        $printOptions = "(" ~ implode("/", $options) ~ ")";
        $options = array_merge(
            array_map("strtolower", $options),
            array_map("strtoupper", $options),
            $options
        );
        $in = "";
        while ($in == "" || !hasAllValues($in, $options, true)) {
            $in = _getInput($prompt, $printOptions, $default);
        }

        return $in;
    }

    /**
     * Prompts the user for input, and returns it.
     *
     * @param string $prompt Prompt text.
     * @param string|null $options String of options. Pass null to omit.
     * @param string|null $default Default input value. Pass null to omit.
     * @return string Either the default value, or the user-provided input.
     */
    protected string _getInput(string $prompt, Nullable!string $options, Nullable!string $default) {
        if (!this.interactive) {
            return (string)$default;
        }

        $optionsText = "";
        if (isset($options)) {
            $optionsText = " $options ";
        }

        $defaultText = "";
        if ($default != null) {
            $defaultText = "[$default] ";
        }
        _out.write("<question>" ~ $prompt ~ "</question>$optionsText\n$defaultText> ", 0);
        $result = _in.read();

        $result = $result == null ? "" : trim($result);
        if ($default != null && $result == "") {
            return $default;
        }

        return $result;
    }

    /**
     * Connects or disconnects the loggers to the console output.
     *
     * Used to enable or disable logging stream output to stdout and stderr
     * If you don"t wish all log output in stdout or stderr
     * through Cake"s Log class, call this function with `$enable=false`.
     *
     * @param int|bool $enable Use a boolean to enable/toggle all logging. Use
     *   one of the verbosity constants (self::VERBOSE, self::QUIET, self::NORMAL)
     *   to control logging levels. VERBOSE enables debug logs, NORMAL does not include debug logs,
     *   QUIET disables notice, info and debug logs.
     */
    void setLoggers($enable) {
        Log::drop("stdout");
        Log::drop("stderr");
        if ($enable == false) {
            return;
        }
        $outLevels = ["notice", "info"];
        if ($enable == static::VERBOSE || $enable == true) {
            $outLevels[] = "debug";
        }
        if ($enable != static::QUIET) {
            $stdout = new ConsoleLog([
                "types": $outLevels,
                "stream": _out,
            ]);
            Log::setConfig("stdout", ["engine": $stdout]);
        }
        $stderr = new ConsoleLog([
            "types": ["emergency", "alert", "critical", "error", "warning"],
            "stream": _err,
        ]);
        Log::setConfig("stderr", ["engine": $stderr]);
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
    function helper(string aName, Json aConfig = []): Helper
    {
        $name = ucfirst($name);

        return _helpers.load($name, aConfig);
    }

    /**
     * Create a file at the given path.
     *
     * This method will prompt the user if a file will be overwritten.
     * Setting `forceOverwrite` to true will suppress this behavior
     * and always overwrite the file.
     *
     * If the user replies `a` subsequent `forceOverwrite` parameters will
     * be coerced to true and all files will be overwritten.
     *
     * @param string $path The path to create the file at.
     * @param string $contents The contents to put into the file.
     * @param bool $forceOverwrite Whether the file should be overwritten.
     *   If true, no question will be asked about whether to overwrite existing files.
     * @return bool Success.
     * @throws uim.cake.consoles.exceptions.StopException When `q` is given as an answer
     *   to whether a file should be overwritten.
     */
    bool createFile(string $path, string $contents, bool $forceOverwrite = false) {
        this.out();
        $forceOverwrite = $forceOverwrite || this.forceOverwrite;

        if (file_exists($path) && $forceOverwrite == false) {
            this.warning("File `{$path}` exists");
            $key = this.askChoice("Do you want to overwrite?", ["y", "n", "a", "q"], "n");
            $key = $key.toLower;

            if ($key == "q") {
                this.error("Quitting.", 2);
                throw new StopException("Not creating file. Quitting.");
            }
            if ($key == "a") {
                this.forceOverwrite = true;
                $key = "y";
            }
            if ($key != "y") {
                this.out("Skip `{$path}`", 2);

                return false;
            }
        } else {
            this.out("Creating file {$path}");
        }

        try {
            // Create the directory using the current user permissions.
            $directory = dirname($path);
            if (!file_exists($directory)) {
                mkdir($directory, 0777 ^ umask(), true);
            }

            $file = new SplFileObject($path, "w");
        } catch (RuntimeException $e) {
            this.error("Could not write to `{$path}`. Permission denied.", 2);

            return false;
        }

        $file.rewind();
        $file.fwrite($contents);
        if (file_exists($path)) {
            this.out("<success>Wrote</success> `{$path}`");

            return true;
        }
        this.error("Could not write to `{$path}`.", 2);

        return false;
    }
}
