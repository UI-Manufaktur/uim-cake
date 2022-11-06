module uim.cakensole;

import uim.cakensole.Exception\ConsoleException;
import uim.cakensole.Exception\MissingOptionException;
import uim.cakeilities.Inflector;
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
 * $parser.addArgument('model', ['required' => false]);
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
     * @see \Cake\Console\ConsoleOptionParser::description()
     * @var string
     */
    protected $_description = '';

    /**
     * Epilog text - displays after options when help is generated
     *
     * @see \Cake\Console\ConsoleOptionParser::epilog()
     * @var string
     */
    protected $_epilog = '';

    /**
     * Option definitions.
     *
     * @see \Cake\Console\ConsoleOptionParser::addOption()
     * @var array<string, \Cake\Console\ConsoleInputOption>
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
     * @see \Cake\Console\ConsoleOptionParser::addArgument()
     * @var array<\Cake\Console\ConsoleInputArgument>
     */
    protected $_args = [];

    /**
     * Subcommands for this Shell.
     *
     * @see \Cake\Console\ConsoleOptionParser::addSubcommand()
     * @var array<string, \Cake\Console\ConsoleInputSubcommand>
     */
    protected $_subcommands = [];

    /**
     * Subcommand sorting option
     *
     * @var bool
     */
    protected $_subcommandSort = true;

    /**
     * Command name.
     *
     * @var string
     */
    protected $_command = '';

    /**
     * Array of args (argv).
     *
     * @var array
     */
    protected $_tokens = [];

    /**
     * Root alias used in help output
     *
     * @see \Cake\Console\HelpFormatter::setAlias()
     * @var string
     */
    protected $rootName = 'cake';

    /**
     * Construct an OptionParser so you can define its behavior
     *
     * @param string $command The command name this parser is for. The command name is used for generating help.
     * @param bool $defaultOptions Whether you want the verbose and quiet options set. Setting
     *  this to false will prevent the addition of `--verbose` & `--quiet` options.
     */
    this(string $command = '', bool $defaultOptions = true) {
        this.setCommand($command);

        this.addOption('help', [
            'short' => 'h',
            'help' => 'Display this help.',
            'boolean' => true,
        ]);

        if ($defaultOptions) {
            this.addOption('verbose', [
                'short' => 'v',
                'help' => 'Enable verbose output.',
                'boolean' => true,
            ]).addOption('quiet', [
                'short' => 'q',
                'help' => 'Enable quiet output.',
                'boolean' => true,
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
     *      'description' => 'text',
     *      'epilog' => 'text',
     *      'arguments' => [
     *          // list of arguments compatible with addArguments.
     *      ],
     *      'options' => [
     *          // list of options compatible with addOptions
     *      ],
     *      'subcommands' => [
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
        $parser = new static($spec['command'], $defaultOptions);
        if (!empty($spec['arguments'])) {
            $parser.addArguments($spec['arguments']);
        }
        if (!empty($spec['options'])) {
            $parser.addOptions($spec['options']);
        }
        if (!empty($spec['subcommands'])) {
            $parser.addSubcommands($spec['subcommands']);
        }
        if (!empty($spec['description'])) {
            $parser.setDescription($spec['description']);
        }
        if (!empty($spec['epilog'])) {
            $parser.setEpilog($spec['epilog']);
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
        myResult = [
            'command' => this._command,
            'arguments' => this._args,
            'options' => this._options,
            'subcommands' => this._subcommands,
            'description' => this._description,
            'epilog' => this._epilog,
        ];

        return myResult;
    }

    /**
     * Get or set the command name for shell/task.
     *
     * @param \Cake\Console\ConsoleOptionParser|array $spec ConsoleOptionParser or spec to merge with.
     * @return this
     */
    function merge($spec) {
        if ($spec instanceof ConsoleOptionParser) {
            $spec = $spec.toArray();
        }
        if (!empty($spec['arguments'])) {
            this.addArguments($spec['arguments']);
        }
        if (!empty($spec['options'])) {
            this.addOptions($spec['options']);
        }
        if (!empty($spec['subcommands'])) {
            this.addSubcommands($spec['subcommands']);
        }
        if (!empty($spec['description'])) {
            this.setDescription($spec['description']);
        }
        if (!empty($spec['epilog'])) {
            this.setEpilog($spec['epilog']);
        }

        return this;
    }

    /**
     * Sets the command name for shell/task.
     *
     * @param string $text The text to set.
     * @return this
     */
    auto setCommand(string $text) {
        this._command = Inflector::underscore($text);

        return this;
    }

    /**
     * Gets the command name for shell/task.
     *
     * @return string The value of the command.
     */
    string getCommand() {
        return this._command;
    }

    /**
     * Sets the description text for shell/task.
     *
     * @param array<string>|string $text The text to set. If an array the
     *   text will be imploded with "\n".
     * @return this
     */
    auto setDescription($text) {
        if (is_array($text)) {
            $text = implode("\n", $text);
        }
        this._description = $text;

        return this;
    }

    /**
     * Gets the description text for shell/task.
     *
     * @return string The value of the description
     */
    string getDescription() {
        return this._description;
    }

    /**
     * Sets an epilog to the parser. The epilog is added to the end of
     * the options and arguments listing when help is generated.
     *
     * @param array<string>|string $text The text to set. If an array the text will
     *   be imploded with "\n".
     * @return this
     */
    auto setEpilog($text) {
        if (is_array($text)) {
            $text = implode("\n", $text);
        }
        this._epilog = $text;

        return this;
    }

    /**
     * Gets the epilog.
     *
     * @return string The value of the epilog.
     */
    string getEpilog() {
        return this._epilog;
    }

    /**
     * Enables sorting of subcommands
     *
     * @param bool myValue Whether to sort subcommands
     * @return this
     */
    function enableSubcommandSort(bool myValue = true) {
        this._subcommandSort = myValue;

        return this;
    }

    /**
     * Checks whether sorting is enabled for subcommands.
     */
    bool isSubcommandSortEnabled() {
        return this._subcommandSort;
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
     * - `boolean` - The option uses no value, it's just a boolean switch. Defaults to false.
     *    If an option is defined as boolean, it will always be added to the parsed params. If no present
     *    it will be false, if present it will be true.
     * - `multiple` - The option can be provided multiple times. The parsed option
     *   will be an array of values when this option is enabled.
     * - `choices` A list of valid choices for this option. If left empty all values are valid..
     *   An exception will be raised when parse() encounters an invalid value.
     *
     * @param \Cake\Console\ConsoleInputOption|string myName The long name you want to the value to be parsed out
     *   as when options are parsed. Will also accept an instance of ConsoleInputOption.
     * @param array<string, mixed> myOptions An array of parameters that define the behavior of the option
     * @return this
     */
    function addOption(myName, array myOptions = []) {
        if (myName instanceof ConsoleInputOption) {
            $option = myName;
            myName = $option.name();
        } else {
            $defaults = [
                'short' => '',
                'help' => '',
                'default' => null,
                'boolean' => false,
                'multiple' => false,
                'choices' => [],
                'required' => false,
            ];
            myOptions += $defaults;
            $option = new ConsoleInputOption(
                myName,
                myOptions['short'],
                myOptions['help'],
                myOptions['boolean'],
                myOptions['default'],
                myOptions['choices'],
                myOptions['multiple'],
                myOptions['required']
            );
        }
        this._options[myName] = $option;
        asort(this._options);
        if ($option.short()) {
            this._shortOptions[$option.short()] = myName;
            asort(this._shortOptions);
        }

        return this;
    }

    /**
     * Remove an option from the option parser.
     *
     * @param string myName The option name to remove.
     * @return this
     */
    function removeOption(string myName) {
        unset(this._options[myName]);

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
     * @param \Cake\Console\ConsoleInputArgument|string myName The name of the argument.
     *   Will also accept an instance of ConsoleInputArgument.
     * @param array<string, mixed> myParams Parameters for the argument, see above.
     * @return this
     */
    function addArgument(myName, array myParams = []) {
        if (myName instanceof ConsoleInputArgument) {
            $arg = myName;
            $index = count(this._args);
        } else {
            $defaults = [
                'name' => myName,
                'help' => '',
                'index' => count(this._args),
                'required' => false,
                'choices' => [],
            ];
            myOptions = myParams + $defaults;
            $index = myOptions['index'];
            unset(myOptions['index']);
            $arg = new ConsoleInputArgument(myOptions);
        }
        foreach (this._args as $a) {
            if ($a.isEqualTo($arg)) {
                return this;
            }
            if (!empty(myOptions['required']) && !$a.isRequired()) {
                throw new LogicException('A required argument cannot follow an optional one');
            }
        }
        this._args[$index] = $arg;
        ksort(this._args);

        return this;
    }

    /**
     * Add multiple arguments at once. Take an array of argument definitions.
     * The keys are used as the argument names, and the values as params for the argument.
     *
     * @param array $args Array of arguments to add.
     * @see \Cake\Console\ConsoleOptionParser::addArgument()
     * @return this
     */
    function addArguments(array $args) {
        foreach ($args as myName => myParams) {
            if (myParams instanceof ConsoleInputArgument) {
                myName = myParams;
                myParams = [];
            }
            this.addArgument(myName, myParams);
        }

        return this;
    }

    /**
     * Add multiple options at once. Takes an array of option definitions.
     * The keys are used as option names, and the values as params for the option.
     *
     * @param array<string, mixed> myOptions Array of options to add.
     * @see \Cake\Console\ConsoleOptionParser::addOption()
     * @return this
     */
    function addOptions(array myOptions) {
        foreach (myOptions as myName => myParams) {
            if (myParams instanceof ConsoleInputOption) {
                myName = myParams;
                myParams = [];
            }
            this.addOption(myName, myParams);
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
     * @param \Cake\Console\ConsoleInputSubcommand|string myName Name of the subcommand.
     *   Will also accept an instance of ConsoleInputSubcommand.
     * @param array<string, mixed> myOptions Array of params, see above.
     * @return this
     */
    function addSubcommand(myName, array myOptions = []) {
        if (myName instanceof ConsoleInputSubcommand) {
            $command = myName;
            myName = $command.name();
        } else {
            myName = Inflector::underscore(myName);
            $defaults = [
                'name' => myName,
                'help' => '',
                'parser' => null,
            ];
            myOptions += $defaults;

            $command = new ConsoleInputSubcommand(myOptions);
        }
        this._subcommands[myName] = $command;
        if (this._subcommandSort) {
            asort(this._subcommands);
        }

        return this;
    }

    /**
     * Remove a subcommand from the option parser.
     *
     * @param string myName The subcommand name to remove.
     * @return this
     */
    function removeSubcommand(string myName) {
        unset(this._subcommands[myName]);

        return this;
    }

    /**
     * Add multiple subcommands at once.
     *
     * @param array<string, mixed> $commands Array of subcommands.
     * @return this
     */
    function addSubcommands(array $commands) {
        foreach ($commands as myName => myParams) {
            if (myParams instanceof ConsoleInputSubcommand) {
                myName = myParams;
                myParams = [];
            }
            this.addSubcommand(myName, myParams);
        }

        return this;
    }

    /**
     * Gets the arguments defined in the parser.
     *
     * @return array<\Cake\Console\ConsoleInputArgument>
     */
    function arguments() {
        return this._args;
    }

    /**
     * Get the list of argument names.
     *
     * @return array<string>
     */
    function argumentNames() {
        $out = [];
        foreach (this._args as $arg) {
            $out[] = $arg.name();
        }

        return $out;
    }

    /**
     * Get the defined options in the parser.
     *
     * @return array<string, \Cake\Console\ConsoleInputOption>
     */
    function options() {
        return this._options;
    }

    /**
     * Get the array of defined subcommands
     *
     * @return array<string, \Cake\Console\ConsoleInputSubcommand>
     */
    function subcommands() {
        return this._subcommands;
    }

    /**
     * Parse the argv array into a set of params and args. If $command is not null
     * and $command is equal to a subcommand that has a parser, that parser will be used
     * to parse the $argv
     *
     * @param array $argv Array of args (argv) to parse.
     * @return array [myParams, $args]
     * @throws \Cake\Console\Exception\ConsoleException When an invalid parameter is encountered.
     */
    function parse(array $argv): array
    {
        $command = isset($argv[0]) ? Inflector::underscore($argv[0]) : null;
        if (isset(this._subcommands[$command])) {
            array_shift($argv);
        }
        if (isset(this._subcommands[$command]) && this._subcommands[$command].parser()) {
            /** @psalm-suppress PossiblyNullReference */
            return this._subcommands[$command].parser().parse($argv);
        }
        myParams = $args = [];
        this._tokens = $argv;
        while (($token = array_shift(this._tokens)) !== null) {
            $token = (string)$token;
            if (isset(this._subcommands[$token])) {
                continue;
            }
            if (substr($token, 0, 2) === '--') {
                myParams = this._parseLongOption($token, myParams);
            } elseif (substr($token, 0, 1) === '-') {
                myParams = this._parseShortOption($token, myParams);
            } else {
                $args = this._parseArg($token, $args);
            }
        }
        foreach (this._args as $i => $arg) {
            if ($arg.isRequired() && !isset($args[$i]) && empty(myParams['help'])) {
                throw new ConsoleException(
                    sprintf('Missing required argument. The `%s` argument is required.', $arg.name())
                );
            }
        }
        foreach (this._options as $option) {
            myName = $option.name();
            $isBoolean = $option.isBoolean();
            $default = $option.defaultValue();

            if ($default !== null && !isset(myParams[myName]) && !$isBoolean) {
                myParams[myName] = $default;
            }
            if ($isBoolean && !isset(myParams[myName])) {
                myParams[myName] = false;
            }
            if ($option.isRequired() && !isset(myParams[myName])) {
                throw new ConsoleException(
                    sprintf('Missing required option. The `%s` option is required and has no default value.', myName)
                );
            }
        }

        return [myParams, $args];
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
    function help(Nullable!string $subcommand = null, string $format = 'text', int $width = 72) {
        if ($subcommand === null) {
            $formatter = new HelpFormatter(this);
            $formatter.setAlias(this.rootName);

            if ($format === 'text') {
                return $formatter.text($width);
            }
            if ($format === 'xml') {
                return (string)$formatter.xml();
            }
        }
        $subcommand = (string)$subcommand;

        if (isset(this._subcommands[$subcommand])) {
            $command = this._subcommands[$subcommand];
            $subparser = $command.parser();

            // Generate a parser as the subcommand didn't define one.
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
            $subparser.setCommand(this.getCommand() . ' ' . $subcommand);
            $subparser.setRootName(this.rootName);

            return $subparser.help(null, $format, $width);
        }

        $rootCommand = this.getCommand();
        myMessage = sprintf(
            'Unable to find the `%s %s` subcommand. See `bin/%s %s --help`.',
            $rootCommand,
            $subcommand,
            this.rootName,
            $rootCommand
        );
        throw new MissingOptionException(
            myMessage,
            $subcommand,
            array_keys(this.subcommands())
        );
    }

    /**
     * Set the root name used in the HelpFormatter
     *
     * @param string myName The root command name
     * @return this
     */
    auto setRootName(string myName) {
        this.rootName = myName;

        return this;
    }

    /**
     * Parse the value for a long option out of this._tokens. Will handle
     * options with an `=` in them.
     *
     * @param string $option The option to parse.
     * @param array<string, mixed> myParams The params to append the parsed value into
     * @return array Params with $option added in.
     */
    protected auto _parseLongOption(string $option, array myParams): array
    {
        myName = substr($option, 2);
        if (strpos(myName, '=') !== false) {
            [myName, myValue] = explode('=', myName, 2);
            array_unshift(this._tokens, myValue);
        }

        return this._parseOption(myName, myParams);
    }

    /**
     * Parse the value for a short option out of this._tokens
     * If the $option is a combination of multiple shortcuts like -otf
     * they will be shifted onto the token stack and parsed individually.
     *
     * @param string $option The option to parse.
     * @param array<string, mixed> myParams The params to append the parsed value into
     * @return array<string, mixed> Params with $option added in.
     * @throws \Cake\Console\Exception\ConsoleException When unknown short options are encountered.
     */
    protected auto _parseShortOption(string $option, array myParams): array
    {
        myKey = substr($option, 1);
        if (strlen(myKey) > 1) {
            $flags = str_split(myKey);
            myKey = $flags[0];
            for ($i = 1, $len = count($flags); $i < $len; $i++) {
                array_unshift(this._tokens, '-' . $flags[$i]);
            }
        }
        if (!isset(this._shortOptions[myKey])) {
            myOptions = [];
            foreach (this._shortOptions as $short => $long) {
                myOptions[] = "{$short} (short for `--{$long}`)";
            }
            throw new MissingOptionException(
                "Unknown short option `{myKey}`.",
                myKey,
                myOptions
            );
        }
        myName = this._shortOptions[myKey];

        return this._parseOption(myName, myParams);
    }

    /**
     * Parse an option by its name index.
     *
     * @param string myName The name to parse.
     * @param array<string, mixed> myParams The params to append the parsed value into
     * @return array<string, mixed> Params with $option added in.
     * @throws \Cake\Console\Exception\ConsoleException
     */
    protected auto _parseOption(string myName, array myParams): array
    {
        if (!isset(this._options[myName])) {
            throw new MissingOptionException(
                "Unknown option `{myName}`.",
                myName,
                array_keys(this._options)
            );
        }
        $option = this._options[myName];
        $isBoolean = $option.isBoolean();
        $nextValue = this._nextToken();
        $emptyNextValue = (empty($nextValue) && $nextValue !== '0');
        if (!$isBoolean && !$emptyNextValue && !this._optionExists($nextValue)) {
            array_shift(this._tokens);
            myValue = $nextValue;
        } elseif ($isBoolean) {
            myValue = true;
        } else {
            myValue = (string)$option.defaultValue();
        }

        $option.validChoice(myValue);
        if ($option.acceptsMultiple()) {
            myParams[myName][] = myValue;
        } else {
            myParams[myName] = myValue;
        }

        return myParams;
    }

    /**
     * Check to see if myName has an option (short/long) defined for it.
     *
     * @param string myName The name of the option.
     * @return bool
     */
    protected bool _optionExists(string myName) {
        if (substr(myName, 0, 2) === '--') {
            return isset(this._options[substr(myName, 2)]);
        }
        if (myName[0] === '-' && myName[1] !== '-') {
            return isset(this._shortOptions[myName[1]]);
        }

        return false;
    }

    /**
     * Parse an argument, and ensure that the argument doesn't exceed the number of arguments
     * and that the argument is a valid choice.
     *
     * @param string $argument The argument to append
     * @param array $args The array of parsed args to append to.
     * @return array<string> Args
     * @throws \Cake\Console\Exception\ConsoleException
     */
    protected auto _parseArg(string $argument, array $args): array
    {
        if (empty(this._args)) {
            $args[] = $argument;

            return $args;
        }
        $next = count($args);
        if (!isset(this._args[$next])) {
            $expected = count(this._args);
            throw new ConsoleException(
                "Received too many arguments. Got {$next} but only {$expected} arguments are defined."
            );
        }

        this._args[$next].validChoice($argument);
        $args[] = $argument;

        return $args;
    }

    /**
     * Find the next token in the argv set.
     *
     * @return string next token or ''
     */
    protected string _nextToken() {
        return this._tokens[0] ?? '';
    }
}