module uim.cake.console;

@safe:
import uim.cake;

/**
 * A wrapper around the various IO operations shell tasks need to do.
 *
 * Packages up the stdout, stderr, and stdin streams providing a simple
 * consistent interface for shells to use. This class also makes mocking streams
 * easy to do in unit tests.
 */
class ConsoleIo {
    // Output constant making verbose shells.
    const int VERBOSE = 2;

    // Output constant for making normal shells.
    const int NORMAL = 1;

    // Output constants for making quiet shells.
    const int QUIET = 0;

    /**
     * The output stream
     *
     * @var uim.cake.Console\ConsoleOutput
     */
    protected _out;

    /**
     * The error stream
     *
     * @var uim.cake.Console\ConsoleOutput
     */
    protected _err;

    /**
     * The input stream
     *
     * @var uim.cake.Console\ConsoleInput
     */
    protected _in;

    // The helper registry.
    protected HelperRegistry $_helpers;

    // The current output level.
    protected int $_level = self::NORMAL;

    /**
     * The number of bytes last written to the output stream
     * used when overwriting the previous message.
     *
     * @var int
     */
    protected _lastWritten = 0;

    /**
     * Whether files should be overwritten
     *
     * @var bool
     */
    protected forceOverwrite = false;

    /**
     * @var bool
     */
    protected bool $interactive = true;

    /**
     * Constructor
     *
     * @param uim.cake.Console\ConsoleOutput|null $out A ConsoleOutput object for stdout.
     * @param uim.cake.Console\ConsoleOutput|null $err A ConsoleOutput object for stderr.
     * @param uim.cake.Console\ConsoleInput|null $in A ConsoleInput object for stdin.
     * @param uim.cake.Console\HelperRegistry|null $helpers A HelperRegistry instance
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

    void setInteractive(bool myValue) {
        this.interactive = myValue;
    }

    /**
     * Get/set the current output level.
     *
     * @param int|null $level The current output level.
     * @return int The current output level.
     */
    int level(Nullable!int $level = null) {
        if ($level  !is null) {
            _level = $level;
        }

        return _level;
    }

    /**
     * Output at the verbose level.
     *
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int|null The number of bytes returned from writing to stdout
     *   or null if current level is less than ConsoleIo::VERBOSE
     */
    Nullable!int verbose(myMessage, int $newlines = 1) {
        return this.out(myMessage, $newlines, self::VERBOSE);
    }

    /**
     * Output at all levels.
     *
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int|null The number of bytes returned from writing to stdout
     *   or null if current level is less than ConsoleIo::QUIET
     */
    Nullable!int quiet(myMessage, int $newlines = 1) {
        return this.out(myMessage, $newlines, self::QUIET);
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
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @param int $level The message"s output level, see above.
     * @return int|null The number of bytes returned from writing to stdout
     *   or null if provided $level is greater than current level.
     */
    Nullable!int out(myMessage = "", int $newlines = 1, int $level = self::NORMAL) {
        if ($level <= _level) {
            _lastWritten = _out.write(myMessage, $newlines);

            return _lastWritten;
        }

        return null;
    }

    /**
     * Convenience method for out() that wraps message between <info /> tag
     *
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @param int $level The message"s output level, see above.
     * @return int|null The number of bytes returned from writing to stdout
     *   or null if provided $level is greater than current level.
     * @see https://book.UIM.org/4/en/console-and-shells.html#ConsoleIo::out
     */
    Nullable!int info(myMessage, int $newlines = 1, int $level = self::NORMAL) {
        myMessageType = "info";
        myMessage = this.wrapMessageWithType(myMessageType, myMessage);

        return this.out(myMessage, $newlines, $level);
    }

    /**
     * Convenience method for out() that wraps message between <comment /> tag
     *
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @param int $level The message"s output level, see above.
     * @return int|null The number of bytes returned from writing to stdout
     *   or null if provided $level is greater than current level.
     * @see https://book.UIM.org/4/en/console-and-shells.html#ConsoleIo::out
     */
    Nullable!int comment(myMessage, int $newlines = 1, int $level = self::NORMAL) {
        myMessageType = "comment";
        myMessage = this.wrapMessageWithType(myMessageType, myMessage);

        return this.out(myMessage, $newlines, $level);
    }

    /**
     * Convenience method for err() that wraps message between <warning /> tag
     *
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int The number of bytes returned from writing to stderr.
     * @see https://book.UIM.org/4/en/console-and-shells.html#ConsoleIo::err
     */
    int warning(myMessage, int $newlines = 1) {
        myMessageType = "warning";
        myMessage = this.wrapMessageWithType(myMessageType, myMessage);

        return this.err(myMessage, $newlines);
    }

    /**
     * Convenience method for err() that wraps message between <error /> tag
     *
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int The number of bytes returned from writing to stderr.
     * @see https://book.UIM.org/4/en/console-and-shells.html#ConsoleIo::err
     */
    int error(myMessage, int $newlines = 1) {
        myMessageType = "error";
        myMessage = this.wrapMessageWithType(myMessageType, myMessage);

        return this.err(myMessage, $newlines);
    }

    /**
     * Convenience method for out() that wraps message between <success /> tag
     *
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @param int $level The message"s output level, see above.
     * @return int|null The number of bytes returned from writing to stdout
     *   or null if provided $level is greater than current level.
     * @see https://book.UIM.org/4/en/console-and-shells.html#ConsoleIo::out
     */
    Nullable!int success(myMessage, int $newlines = 1, int $level = self::NORMAL) {
        myMessageType = "success";
        myMessage = this.wrapMessageWithType(myMessageType, myMessage);

        return this.out(myMessage, $newlines, $level);
    }

    /**
     * Halts the the current process with a StopException.
     *
     * @param string myMessage Error message.
     * @param int $code Error code.
     * @throws uim.cake.Console\Exception\StopException
     */
    void abort(myMessage, $code = ICommand::CODE_ERROR) {
        this.error(myMessage);

        throw new StopException(myMessage, $code);
    }

    /**
     * Wraps a message with a given message type, e.g. <warning>
     *
     * @param string myMessageType The message type, e.g. "warning".
     * @param array<string>|string myMessage The message to wrap.
     * @return The message wrapped with the given message type.
     */
    protected string[] wrapMessageWithType(string myMessageType, myMessage) {
        if (is_array(myMessage)) {
            foreach ($k, $v; myMessage) {
                myMessage[$k] = "<{myMessageType}>{$v}</{myMessageType}>";
            }
        } else {
            myMessage = "<{myMessageType}>{myMessage}</{myMessageType}>";
        }

        return myMessage;
    }

    /**
     * Overwrite some already output text.
     *
     * Useful for building progress bars, or when you want to replace
     * text already output to the screen with new text.
     *
     * **Warning** You cannot overwrite text that contains newlines.
     *
     * @param array<string>|string myMessage The message to output.
     * @param int $newlines Number of newlines to append.
     * @param int|null $size The number of bytes to overwrite. Defaults to the
     *    length of the last message output.
     */
    void overwrite(myMessage, int $newlines = 1, Nullable!int $size = null) {
        $size = $size ?: _lastWritten;

        // Output backspaces.
        this.out(str_repeat("\x08", $size), 0);

        $newBytes = (int)this.out(myMessage, 0);

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
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int The number of bytes returned from writing to stderr.
     */
    int err(myMessage = "", int $newlines = 1) {
        return _err.write(myMessage, $newlines);
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
     * @param string prompt Prompt text.
     * @param string|null $default Default input value.
     * @return Either the default value, or the user-provided input.
     */
    string ask(string prompt, Nullable!string default = null) {
        return _getInput($prompt, null, $default);
    }

    /**
     * Change the output mode of the stdout stream
     *
     * @param int myMode The output mode.
     * @see uim.cake.Console\ConsoleOutput::setOutputAs()
     */
    void setOutputAs(int myMode) {
        _out.setOutputAs(myMode);
    }

    /**
     * Gets defined styles.
     *
     * @return array
     * @see uim.cake.Console\ConsoleOutput::styles()
     */
    array styles() {
        return _out.styles();
    }

    /**
     * Get defined style.
     *
     * @param string style The style to get.
     * @return array
     * @see uim.cake.Console\ConsoleOutput::getStyle()
     */
    array getStyle(string style) {
      return _out.getStyle($style);
    }

    /**
     * Adds a new output style.
     *
     * @param string style The style to set.
     * @param array $definition The array definition of the style to change or create.
     * @see uim.cake.Console\ConsoleOutput::setStyle()
     */
    void setStyle(string style, array $definition) {
        _out.setStyle($style, $definition);
    }

    /**
     * Prompts the user for input based on a list of options, and returns it.
     *
     * @param string prompt Prompt text.
     * @param array<string>|string myOptions Array or string of options.
     * @param string|null $default Default input value.
     * @return Either the default value, or the user-provided input.
     */
    string askChoice(string prompt, myOptions, Nullable!string default = null) {
        if (is_string(myOptions)) {
            if (indexOf(myOptions, ",")) {
                myOptions = explode(",", myOptions);
            } elseif (indexOf(myOptions, "/")) {
                myOptions = explode("/", myOptions);
            } else {
                myOptions = [myOptions];
            }
        }

        $printOptions = "(" . implode("/", myOptions) . ")";
        myOptions = array_merge(
            array_map("strtolower", myOptions),
            array_map("strtoupper", myOptions),
            myOptions
        );
        $in = "";
        while ($in == "" || !in_array($in, myOptions, true)) {
            $in = _getInput($prompt, $printOptions, $default);
        }

        return $in;
    }

    /**
     * Prompts the user for input, and returns it.
     *
     * @param string prompt Prompt text.
     * @param string|null myOptions String of options. Pass null to omit.
     * @param string|null $default Default input value. Pass null to omit.
     * @return Either the default value, or the user-provided input.
     */
    protected string _getInput(string prompt, Nullable!string myOptions, Nullable!string default) {
        if (!this.interactive) {
            return (string)$default;
        }

        myOptionsText = "";
        if (isset(myOptions)) {
            myOptionsText = " myOptions ";
        }

        $defaultText = "";
        if ($default  !is null) {
            $defaultText = "[$default] ";
        }
        _out.write("<question>" . $prompt . "</question>myOptionsText\n$defaultText> ", 0);
        myResult = _in.read();

        myResult = myResult is null ? "" : trim(myResult);
        if ($default  !is null && myResult == "") {
            return $default;
        }

        return myResult;
    }

    /**
     * Connects or disconnects the loggers to the console output.
     *
     * Used to enable or disable logging stream output to stdout and stderr
     * If you don"t wish all log output in stdout or stderr
     * through Cake"s Log class, call this function with `myEnable=false`.
     *
     * @param int|bool myEnable Use a boolean to enable/toggle all logging. Use
     *   one of the verbosity constants (self::VERBOSE, self::QUIET, self::NORMAL)
     *   to control logging levels. VERBOSE enables debug logs, NORMAL does not include debug logs,
     *   QUIET disables notice, info and debug logs.
     */
    void setLoggers(myEnable) {
        Log::drop("stdout");
        Log::drop("stderr");
        if (myEnable == false) {
            return;
        }
        $outLevels = ["notice", "info"];
        if (myEnable == static::VERBOSE || myEnable == true) {
            $outLevels[] = "debug";
        }
        if (myEnable != static::QUIET) {
            $stdout = new ConsoleLog([
                "types":$outLevels,
                "stream":_out,
            ]);
            Log::setConfig("stdout", ["engine":$stdout]);
        }
        $stderr = new ConsoleLog([
            "types":["emergency", "alert", "critical", "error", "warning"],
            "stream":_err,
        ]);
        Log::setConfig("stderr", ["engine":$stderr]);
    }

    /**
     * Render a Console Helper
     *
     * Create and render the output for a helper object. If the helper
     * object has not already been loaded, it will be loaded and constructed.
     *
     * @param string myName The name of the helper to render
     * @param array<string, mixed> myConfig Configuration data for the helper.
     * @return uim.cake.Console\Helper The created helper instance.
     */
    Helper helper(string myName, array myConfig = []) 
    {
        myName = ucfirst(myName);

        return _helpers.load(myName, myConfig);
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
     * @param string myPath The path to create the file at.
     * @param string myContentss The contents to put into the file.
     * @param bool $forceOverwrite Whether the file should be overwritten.
     *   If true, no question will be asked about whether to overwrite existing files.
     * @return bool Success.
     * @throws uim.cake.Console\Exception\StopException When `q` is given as an answer
     *   to whether a file should be overwritten.
     */
    function createFile(string myPath, string myContentss, bool $forceOverwrite = false) {
        this.out();
        $forceOverwrite = $forceOverwrite || this.forceOverwrite;

        if (file_exists(myPath) && $forceOverwrite == false) {
            this.warning("File `{myPath}` exists");
            myKey = this.askChoice("Do you want to overwrite?", ["y", "n", "a", "q"], "n");
            myKey = strtolower(myKey);

            if (myKey == "q") {
                this.error("Quitting.", 2);
                throw new StopException("Not creating file. Quitting.");
            }
            if (myKey == "a") {
                this.forceOverwrite = true;
                myKey = "y";
            }
            if (myKey != "y") {
                this.out("Skip `{myPath}`", 2);

                return false;
            }
        } else {
            this.out("Creating file {myPath}");
        }

        try {
            // Create the directory using the current user permissions.
            $directory = dirname(myPath);
            if (!file_exists($directory)) {
                mkdir($directory, 0777 ^ umask(), true);
            }

            myfile = new SplFileObject(myPath, "w");
        } catch (RuntimeException $e) {
            this.error("Could not write to `{myPath}`. Permission denied.", 2);

            return false;
        }

        myfile.rewind();
        myfile.fwrite(myContentss);
        if (file_exists(myPath)) {
            this.out("<success>Wrote</success> `{myPath}`");

            return true;
        }
        this.error("Could not write to `{myPath}`.", 2);

        return false;
    }
}
