module uim.cake.Console;

import uim.cake.consoles.exceptions.ConsoleException;
import uim.cake.consoles.exceptions.MissingOptionException;
import uim.cake.utilities.Inflector;
use LogicException;

/**
 * Handles parsing the ARGV in the command line and provides support
 * for GetOpt compatible option definition. Provides a builder pattern implementation
 * for creating shell option parsers.
 *
 * ### Options
 *
 * Named arguments come in two forms, long and short. Long arguments are preceded
 * by two - and give a more verbose option name. i.e. `--version`. Short arguments are
 * preceded by one - and are only one character long. They usually match with a long option,
 * and provide a more terse alternative.
 *
 * ### Using Options
 *
 * Options can be defined with both long and short forms. By using `$parser.addOption()`
 * you can define new options. The name of the option is used as its long form, and you
 * can supply an additional short form, with the `short` option. Short options should
 * only be one letter long. Using more than one letter for a short option will raise an exception.
 *
 * Calling options can be done using syntax similar to most *nix command line tools. Long options
 * cane either include an `=` or leave it out.
 *
 * `cake my_command --connection default --name=something`
 *
 * Short options can be defined singly or in groups.
 *
 * `cake my_command -cn`
 *
 * Short options can be combined into groups as seen above. Each letter in a group
 * will be treated as a separate option. The previous example is equivalent to:
 *
 * `cake my_command -c -n`
 *
 * Short options can also accept values:
 *
 * `cake my_command -c default`
 *
 * ### Positional arguments
 *
 * If no positional arguments are defined, all of them will be parsed. If you define positional
 * arguments any arguments greater than those defined will cause exceptions. Additionally you can
 * declare arguments as optional, by setting the required param to false.
 *
 * ```
 * $parser.addArgument("model", ["required": false]);
 * ```
 *
 * ### Providing Help text
 *
 * By providing help text for your positional arguments and named arguments, the ConsoleOptionParser
 * can generate a help display for you. You can view the help for shells by using the `--help` or `-h` switch.
 */
class ConsoleOptionParser
{
    /**
     * Description text - displays before options when help is generated
     *
     * @see uim.cake.consoles.ConsoleOptionParser::description()
     */
    protected string $_description = "";

    /**
     * Epilog text - displays after options when help is generated
     *
     * @see uim.cake.consoles.ConsoleOptionParser::epilog()
     */
    protected string $_epilog = "";

    /**
     * Option definitions.
     *
     * @see uim.cake.consoles.ConsoleOptionParser::addOption()
     * @var array<string, uim.cake.consoles.ConsoleInputOption>
     */
    protected $_options = [];

    /**
     * Map of short . long options, generated when using addOption()
     *
     * @var array<string, string>
     */
    protected $_shortOptions = [];

    /**
     * Positional argument definitions.
     *
     * @see uim.cake.consoles.ConsoleOptionParser::addArgument()
     * @var array<uim.cake.consoles.ConsoleInputArgument>
     */
    protected $_args = [];

    /**
     * Subcommands for this Shell.
     *
     * @see uim.cake.consoles.ConsoleOptionParser::addSubcommand()
     * @var array<string, uim.cake.consoles.ConsoleInputSubcommand>
     */
    protected $_subcommands = [];

    /**
     * Subcommand sorting option
     */
    protected bool $_subcommandSort = true;

    /**
     * Command name.
     */
    protected string $_command = "";

    /**
     * Array of args (argv).
     *
     * @var array
     */
    protected $_tokens = [];

    /**
     * Root alias used in help output
     *
     * @see uim.cake.consoles.HelpFormatter::setAlias()
     */
    protected string $rootName = "cake";

    /**
     * Construct an OptionParser so you can define its behavior
     *
     * @param string $command The command name this parser is for. The command name is used for generating help.
     * @param bool $defaultOptions Whether you want the verbose and quiet options set. Setting
     *  this to false will prevent the addition of `--verbose` & `--quiet` options.
     */
    this(string $command = "", bool $defaultOptions = true) {
        this.setCommand($command);

        this.addOption("help", [
            "short": "h",
            "help": "Display this help.",
            "boolean": true,
        ]);

        if ($defaultOptions) {
            this.addOption("verbose", [
                "short": "v",
                "help": "Enable verbose output.",
                "boolean": true,
            ]).addOption("quiet", [
                "short": "q",
                "help": "Enable quiet output.",
                "boolean": true,
            ]);
        }
    }

    /**
     * Static factory method for creating new OptionParsers so you can chain methods off of them.
     *
     * @param string $command The command name this parser is for. The command name is used for generating help.
     * @param bool $defaultOptions Whether you want the verbose and quiet options set.
     * @return static
     */
    static function create(string $command, bool $defaultOptions = true) {
        return new static($command, $defaultOptions);
    }

    /**
     * Build a parser from an array. Uses an array like
     *
     * ```
     * $spec = [
     *      "description": "text",
     *      "epilog": "text",
     *      "arguments": [
     *          // list of arguments compatible with addArguments.
     *      ],
     *      "options": [
     *          // list of options compatible with addOptions
     *      ],
     *      "subcommands": [
     *          // list of subcommands to add.
     *      ]
     * ];
     * ```
     *
     * @param array<string, mixed> $spec The spec to build the OptionParser with.
     * @param bool $defaultOptions Whether you want the verbose and quiet options set.
     * @return static
     */
    static function buildFromArray(array $spec, bool $defaultOptions = true) {
        $parser = new static($spec["command"], $defaultOptions);
        if (!empty($spec["arguments"])) {
            $parser.addArguments($spec["arguments"]);
        }
        if (!empty($spec["options"])) {
            $parser.addOptions($spec["options"]);
        }
        if (!empty($spec["subcommands"])) {
            $parser.addSubcommands($spec["subcommands"]);
        }
        if (!empty($spec["description"])) {
            $parser.setDescription($spec["description"]);
        }
        if (!empty($spec["epilog"])) {
            $parser.setEpilog($spec["epilog"]);
        }

        return $parser;
    }

    /**
     * Returns an array representation of this parser.
     *
     * @return array<string, mixed>
     */
    function toArray(): array
    {
        return [
            "command": _command,
            "arguments": _args,
            "options": _options,
            "subcommands": _subcommands,
            "description": _description,
            "epilog": _epilog,
        ];
    }

    /**
     * Get or set the command name for shell/task.
     *
     * @param uim.cake.consoles.ConsoleOptionParser|array $spec ConsoleOptionParser or spec to merge with.
     * @return this
     */
    function merge($spec) {
        if ($spec instanceof ConsoleOptionParser) {
            $spec = $spec.toArray();
        }
        if (!empty($spec["arguments"])) {
            this.addArguments($spec["arguments"]);
        }
        if (!empty($spec["options"])) {
            this.addOptions($spec["options"]);
        }
        if (!empty($spec["subcommands"])) {
            this.addSubcommands($spec["subcommands"]);
        }
        if (!empty($spec["description"])) {
            this.setDescription($spec["description"]);
        }
        if (!empty($spec["epilog"])) {
            this.setEpilog($spec["epilog"]);
        }

        return this;
    }

    /**
     * Sets the command name for shell/task.
     *
     * @param string $text The text to set.
     * @return this
     */
    function setCommand(string $text) {
        _command = Inflector::underscore($text);

        return this;
    }

    /**
     * Gets the command name for shell/task.
     *
     * @return string The value of the command.
     */
    string getCommand() {
        return _command;
    }

    /**
     * Sets the description text for shell/task.
     *
     * @param array<string>|string $text The text to set. If an array the
     *   text will be imploded with "\n".
     * @return this
     */
    function setDescription($text) {
        if (is_array($text)) {
            $text = implode("\n", $text);
        }
        _description = $text;

        return this;
    }

    /**
     * Gets the description text for shell/task.
     *
     * @return string The value of the description
     */
    string getDescription() {
        return _description;
    }

    /**
     * Sets an epilog to the parser. The epilog is added to the end of
     * the options and arguments listing when help is generated.
     *
     * @param array<string>|string $text The text to set. If an array the text will
     *   be imploded with "\n".
     * @return this
     */
    function setEpilog($text) {
        if (is_array($text)) {
            $text = implode("\n", $text);
        }
        _epilog = $text;

        return this;
    }

    /**
     * Gets the epilog.
     *
     * @return string The value of the epilog.
     */
    string getEpilog() {
        return _epilog;
    }

    /**
     * Enables sorting of subcommands
     *
     * @param bool $value Whether to sort subcommands
     * @return this
     */
    function enableSubcommandSort(bool $value = true) {
        _subcommandSort = $value;

        return this;
    }

    /**
     * Checks whether sorting is enabled for subcommands.
     *
     * @return bool
     */
    bool isSubcommandSortEnabled() {
        return _subcommandSort;
    }

    /**
     * Add an option to the option parser. Options allow you to define optional or required
     * parameters for your console application. Options are defined by the parameters they use.
     *
     * ### Options
     *
     * - `short` - The single letter variant for this option, leave undefined for none.
     * - `help` - Help text for this option. Used when generating help for the option.
     * - `default` - The default value for this option. Defaults are added into the parsed params when the
     *    attached option is not provided or has no value. Using default and boolean together will not work.
     *    are added into the parsed parameters when the option is undefined. Defaults to null.
     * - `boolean` - The option uses no value, it"s just a boolean switch. Defaults to false.
     *    If an option is defined as boolean, it will always be added to the parsed params. If no present
     *    it will be false, if present it will be true.
     * - `multiple` - The option can be provided multiple times. The parsed option
     *   will be an array of values when this option is enabled.
     * - `choices` A list of valid choices for this option. If left empty all values are valid..
     *   An exception will be raised when parse() encounters an invalid value.
     *
     * @param uim.cake.consoles.ConsoleInputOption|string aName The long name you want to the value to be parsed out
     *   as when options are parsed. Will also accept an instance of ConsoleInputOption.
     * @param array<string, mixed> $options An array of parameters that define the behavior of the option
     * @return this
     */
    function addOption($name, array $options = []) {
        if ($name instanceof ConsoleInputOption) {
            $option = $name;
            $name = $option.name();
        } else {
            $defaults = [
                "short": "",
                "help": "",
                "default": null,
                "boolean": false,
                "multiple": false,
                "choices": [],
                "required": false,
                "prompt": null,
            ];
            $options += $defaults;
            $option = new ConsoleInputOption(
                $name,
                $options["short"],
                $options["help"],
                $options["boolean"],
                $options["default"],
                $options["choices"],
                $options["multiple"],
                $options["required"],
                $options["prompt"]
            );
        }
        _options[$name] = $option;
        asort(_options);
        if ($option.short()) {
            _shortOptions[$option.short()] = $name;
            asort(_shortOptions);
        }

        return this;
    }

    /**
     * Remove an option from the option parser.
     *
     * @param string aName The option name to remove.
     * @return this
     */
    function removeOption(string aName) {
        unset(_options[$name]);

        return this;
    }

    /**
     * Add a positional argument to the option parser.
     *
     * ### Params
     *
     * - `help` The help text to display for this argument.
     * - `required` Whether this parameter is required.
     * - `index` The index for the arg, if left undefined the argument will be put
     *   onto the end of the arguments. If you define the same index twice the first
     *   option will be overwritten.
     * - `choices` A list of valid choices for this argument. If left empty all values are valid..
     *   An exception will be raised when parse() encounters an invalid value.
     *
     * @param uim.cake.consoles.ConsoleInputArgument|string aName The name of the argument.
     *   Will also accept an instance of ConsoleInputArgument.
     * @param array<string, mixed> $params Parameters for the argument, see above.
     * @return this
     */
    function addArgument($name, array $params = []) {
        if ($name instanceof ConsoleInputArgument) {
            $arg = $name;
            $index = count(_args);
        } else {
            $defaults = [
                "name": $name,
                "help": "",
                "index": count(_args),
                "required": false,
                "choices": [],
            ];
            $options = $params + $defaults;
            $index = $options["index"];
            unset($options["index"]);
            $arg = new ConsoleInputArgument($options);
        }
        foreach (_args as $a) {
            if ($a.isEqualTo($arg)) {
                return this;
            }
            if (!empty($options["required"]) && !$a.isRequired()) {
                throw new LogicException("A required argument cannot follow an optional one");
            }
        }
        _args[$index] = $arg;
        ksort(_args);

        return this;
    }

    /**
     * Add multiple arguments at once. Take an array of argument definitions.
     * The keys are used as the argument names, and the values as params for the argument.
     *
     * @param array $args Array of arguments to add.
     * @see uim.cake.consoles.ConsoleOptionParser::addArgument()
     * @return this
     */
    function addArguments(array $args) {
        foreach ($args as $name: $params) {
            if ($params instanceof ConsoleInputArgument) {
                $name = $params;
                $params = [];
            }
            this.addArgument($name, $params);
        }

        return this;
    }

    /**
     * Add multiple options at once. Takes an array of option definitions.
     * The keys are used as option names, and the values as params for the option.
     *
     * @param array<string, mixed> $options Array of options to add.
     * @see uim.cake.consoles.ConsoleOptionParser::addOption()
     * @return this
     */
    function addOptions(array $options) {
        foreach ($options as $name: $params) {
            if ($params instanceof ConsoleInputOption) {
                $name = $params;
                $params = [];
            }
            this.addOption($name, $params);
        }

        return this;
    }

    /**
     * Append a subcommand to the subcommand list.
     * Subcommands are usually methods on your Shell, but can also be used to document Tasks.
     *
     * ### Options
     *
     * - `help` - Help text for the subcommand.
     * - `parser` - A ConsoleOptionParser for the subcommand. This allows you to create method
     *    specific option parsers. When help is generated for a subcommand, if a parser is present
     *    it will be used.
     *
     * @param uim.cake.consoles.ConsoleInputSubcommand|string aName Name of the subcommand.
     *   Will also accept an instance of ConsoleInputSubcommand.
     * @param array<string, mixed> $options Array of params, see above.
     * @return this
     */
    function addSubcommand($name, array $options = []) {
        if ($name instanceof ConsoleInputSubcommand) {
            $command = $name;
            $name = $command.name();
        } else {
            $name = Inflector::underscore($name);
            $defaults = [
                "name": $name,
                "help": "",
                "parser": null,
            ];
            $options += $defaults;

            $command = new ConsoleInputSubcommand($options);
        }
        _subcommands[$name] = $command;
        if (_subcommandSort) {
            asort(_subcommands);
        }

        return this;
    }

    /**
     * Remove a subcommand from the option parser.
     *
     * @param string aName The subcommand name to remove.
     * @return this
     */
    function removeSubcommand(string aName) {
        unset(_subcommands[$name]);

        return this;
    }

    /**
     * Add multiple subcommands at once.
     *
     * @param array<string, mixed> $commands Array of subcommands.
     * @return this
     */
    function addSubcommands(array $commands) {
        foreach ($commands as $name: $params) {
            if ($params instanceof ConsoleInputSubcommand) {
                $name = $params;
                $params = [];
            }
            this.addSubcommand($name, $params);
        }

        return this;
    }

    /**
     * Gets the arguments defined in the parser.
     *
     * @return array<uim.cake.consoles.ConsoleInputArgument>
     */
    function arguments() {
        return _args;
    }

    /**
     * Get the list of argument names.
     */
    string[] argumentNames() {
        $out = [];
        foreach (_args as $arg) {
            $out[] = $arg.name();
        }

        return $out;
    }

    /**
     * Get the defined options in the parser.
     *
     * @return array<string, uim.cake.consoles.ConsoleInputOption>
     */
    function options() {
        return _options;
    }

    /**
     * Get the array of defined subcommands
     *
     * @return array<string, uim.cake.consoles.ConsoleInputSubcommand>
     */
    function subcommands() {
        return _subcommands;
    }

    /**
     * Parse the argv array into a set of params and args. If $command is not null
     * and $command is equal to a subcommand that has a parser, that parser will be used
     * to parse the $argv
     *
     * @param array $argv Array of args (argv) to parse.
     * @param uim.cake.consoles.ConsoleIo|null $io A ConsoleIo instance or null. If null prompt options will error.
     * @return array [$params, $args]
     * @throws uim.cake.consoles.exceptions.ConsoleException When an invalid parameter is encountered.
     */
    function parse(array $argv, ?ConsoleIo $io = null): array
    {
        $command = isset($argv[0]) ? Inflector::underscore($argv[0]) : null;
        if (isset(_subcommands[$command])) {
            array_shift($argv);
        }
        if (isset(_subcommands[$command]) && _subcommands[$command].parser()) {
            /** @psalm-suppress PossiblyNullReference */
            return _subcommands[$command].parser().parse($argv, $io);
        }
        $params = $args = [];
        _tokens = $argv;
        while (($token = array_shift(_tokens)) != null) {
            $token = (string)$token;
            if (isset(_subcommands[$token])) {
                continue;
            }
            if (substr($token, 0, 2) == "--") {
                $params = _parseLongOption($token, $params);
            } elseif (substr($token, 0, 1) == "-") {
                $params = _parseShortOption($token, $params);
            } else {
                $args = _parseArg($token, $args);
            }
        }

        if (isset($params["help"])) {
            return [$params, $args];
        }

        foreach (_args as $i: $arg) {
            if ($arg.isRequired() && !isset($args[$i])) {
                throw new ConsoleException(
                    sprintf("Missing required argument. The `%s` argument is required.", $arg.name())
                );
            }
        }
        foreach (_options as $option) {
            $name = $option.name();
            $isBoolean = $option.isBoolean();
            $default = $option.defaultValue();

            $useDefault = !isset($params[$name]);
            if ($default != null && $useDefault && !$isBoolean) {
                $params[$name] = $default;
            }
            if ($isBoolean && $useDefault) {
                $params[$name] = false;
            }
            $prompt = $option.prompt();
            if (!isset($params[$name]) && $prompt) {
                if (!$io) {
                    throw new ConsoleException(
                        "Cannot use interactive option prompts without a ConsoleIo instance~ " ~
                        "Please provide a `$io` parameter to `parse()`."
                    );
                }
                $choices = $option.choices();
                if ($choices) {
                    $value = $io.askChoice($prompt, $choices);
                } else {
                    $value = $io.ask($prompt);
                }
                $params[$name] = $value;
            }
            if ($option.isRequired() && !isset($params[$name])) {
                throw new ConsoleException(
                    sprintf("Missing required option. The `%s` option is required and has no default value.", $name)
                );
            }
        }

        return [$params, $args];
    }

    /**
     * Gets formatted help for this parser object.
     *
     * Generates help text based on the description, options, arguments, subcommands and epilog
     * in the parser.
     *
     * @param string|null $subcommand If present and a valid subcommand that has a linked parser.
     *    That subcommands help will be shown instead.
     * @param string $format Define the output format, can be text or XML
     * @param int $width The width to format user content to. Defaults to 72
     * @return string Generated help.
     */
    string help(?string $subcommand = null, string $format = "text", int $width = 72) {
        if ($subcommand == null) {
            $formatter = new HelpFormatter(this);
            $formatter.setAlias(this.rootName);

            if ($format == "text") {
                return $formatter.text($width);
            }
            if ($format == "xml") {
                return (string)$formatter.xml();
            }
        }
        $subcommand = (string)$subcommand;

        if (isset(_subcommands[$subcommand])) {
            $command = _subcommands[$subcommand];
            $subparser = $command.parser();

            // Generate a parser as the subcommand didn"t define one.
            if (!($subparser instanceof self)) {
                // $subparser = clone this;
                $subparser = new self($subcommand);
                $subparser
                    .setDescription($command.getRawHelp())
                    .addOptions(this.options())
                    .addArguments(this.arguments());
            }
            if ($subparser.getDescription() == "") {
                $subparser.setDescription($command.getRawHelp());
            }
            $subparser.setCommand(this.getCommand() ~ " " ~ $subcommand);
            $subparser.setRootName(this.rootName);

            return $subparser.help(null, $format, $width);
        }

        $rootCommand = this.getCommand();
        $message = sprintf(
            "Unable to find the `%s %s` subcommand. See `bin/%s %s --help`.",
            $rootCommand,
            $subcommand,
            this.rootName,
            $rootCommand
        );
        throw new MissingOptionException(
            $message,
            $subcommand,
            array_keys(this.subcommands())
        );
    }

    /**
     * Set the root name used in the HelpFormatter
     *
     * @param string aName The root command name
     * @return this
     */
    function setRootName(string aName) {
        this.rootName = $name;

        return this;
    }

    /**
     * Parse the value for a long option out of _tokens. Will handle
     * options with an `=` in them.
     *
     * @param string $option The option to parse.
     * @param array<string, mixed> $params The params to append the parsed value into
     * @return array Params with $option added in.
     */
    protected function _parseLongOption(string $option, array $params): array
    {
        $name = substr($option, 2);
        if (strpos($name, "=") != false) {
            [$name, $value] = explode("=", $name, 2);
            array_unshift(_tokens, $value);
        }

        return _parseOption($name, $params);
    }

    /**
     * Parse the value for a short option out of _tokens
     * If the $option is a combination of multiple shortcuts like -otf
     * they will be shifted onto the token stack and parsed individually.
     *
     * @param string $option The option to parse.
     * @param array<string, mixed> $params The params to append the parsed value into
     * @return array<string, mixed> Params with $option added in.
     * @throws uim.cake.consoles.exceptions.ConsoleException When unknown short options are encountered.
     */
    protected function _parseShortOption(string $option, array $params): array
    {
        $key = substr($option, 1);
        if (strlen($key) > 1) {
            $flags = str_split($key);
            $key = $flags[0];
            for ($i = 1, $len = count($flags); $i < $len; $i++) {
                array_unshift(_tokens, "-" ~ $flags[$i]);
            }
        }
        if (!isset(_shortOptions[$key])) {
            $options = [];
            foreach (_shortOptions as $short: $long) {
                $options[] = "{$short} (short for `--{$long}`)";
            }
            throw new MissingOptionException(
                "Unknown short option `{$key}`.",
                $key,
                $options
            );
        }
        $name = _shortOptions[$key];

        return _parseOption($name, $params);
    }

    /**
     * Parse an option by its name index.
     *
     * @param string aName The name to parse.
     * @param array<string, mixed> $params The params to append the parsed value into
     * @return array<string, mixed> Params with $option added in.
     * @throws uim.cake.consoles.exceptions.ConsoleException
     */
    protected function _parseOption(string aName, array $params): array
    {
        if (!isset(_options[$name])) {
            throw new MissingOptionException(
                "Unknown option `{$name}`.",
                $name,
                array_keys(_options)
            );
        }
        $option = _options[$name];
        $isBoolean = $option.isBoolean();
        $nextValue = _nextToken();
        $emptyNextValue = (empty($nextValue) && $nextValue != "0");
        if (!$isBoolean && !$emptyNextValue && !_optionExists($nextValue)) {
            array_shift(_tokens);
            $value = $nextValue;
        } elseif ($isBoolean) {
            $value = true;
        } else {
            $value = (string)$option.defaultValue();
        }

        $option.validChoice($value);
        if ($option.acceptsMultiple()) {
            $params[$name][] = $value;
        } else {
            $params[$name] = $value;
        }

        return $params;
    }

    /**
     * Check to see if $name has an option (short/long) defined for it.
     *
     * @param string aName The name of the option.
     * @return bool
     */
    protected bool _optionExists(string aName) {
        if (substr($name, 0, 2) == "--") {
            return isset(_options[substr($name, 2)]);
        }
        if ($name[0] == "-" && $name[1] != "-") {
            return isset(_shortOptions[$name[1]]);
        }

        return false;
    }

    /**
     * Parse an argument, and ensure that the argument doesn"t exceed the number of arguments
     * and that the argument is a valid choice.
     *
     * @param string $argument The argument to append
     * @param array $args The array of parsed args to append to.
     * @return array<string> Args
     * @throws uim.cake.consoles.exceptions.ConsoleException
     */
    protected function _parseArg(string $argument, array $args): array
    {
        if (empty(_args)) {
            $args[] = $argument;

            return $args;
        }
        $next = count($args);
        if (!isset(_args[$next])) {
            $expected = count(_args);
            throw new ConsoleException(
                "Received too many arguments. Got {$next} but only {$expected} arguments are defined."
            );
        }

        _args[$next].validChoice($argument);
        $args[] = $argument;

        return $args;
    }

    /**
     * Find the next token in the argv set.
     *
     * @return string next token or ""
     */
    protected string _nextToken() {
        return _tokens[0] ?? "";
    }
}