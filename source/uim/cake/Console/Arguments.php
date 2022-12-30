module uim.cake.Console;

/**
 * Provides an interface for interacting with
 * a command"s options and arguments.
 */
class Arguments
{
    /**
     * Positional argument name map
     *
     * @var array<int, string>
     */
    protected $argNames;

    /**
     * Positional arguments.
     *
     * @var array<int, string>
     */
    protected $args;

    /**
     * Named options
     *
     * @var array<string, string|int|bool|null>
     */
    protected $options;

    /**
     * Constructor
     *
     * @param array<int, string> $args Positional arguments
     * @param array<string, string|int|bool|null> $options Named arguments
     * @param array<int, string> $argNames List of argument names. Order is expected to be
     *  the same as $args.
     */
    this(array $args, array $options, array $argNames) {
        this.args = $args;
        this.options = $options;
        this.argNames = $argNames;
    }

    /**
     * Get all positional arguments.
     *
     * @return array<int, string>
     */
    function getArguments(): array
    {
        return this.args;
    }

    /**
     * Get positional arguments by index.
     *
     * @param int $index The argument index to access.
     * @return string|null The argument value or null
     */
    function getArgumentAt(int $index): ?string
    {
        if (this.hasArgumentAt($index)) {
            return this.args[$index];
        }

        return null;
    }

    /**
     * Check if a positional argument exists
     *
     * @param int $index The argument index to check.
     * @return bool
     */
    bool hasArgumentAt(int $index) {
        return isset(this.args[$index]);
    }

    /**
     * Check if a positional argument exists by name
     *
     * @param string $name The argument name to check.
     * @return bool
     */
    bool hasArgument(string $name) {
        $offset = array_search($name, this.argNames, true);
        if ($offset == false) {
            return false;
        }

        return isset(this.args[$offset]);
    }

    /**
     * Check if a positional argument exists by name
     *
     * @param string $name The argument name to check.
     * @return string|null
     */
    function getArgument(string $name): ?string
    {
        $offset = array_search($name, this.argNames, true);
        if ($offset == false || !isset(this.args[$offset])) {
            return null;
        }

        return this.args[$offset];
    }

    /**
     * Get an array of all the options
     *
     * @return array<string, string|int|bool|null>
     */
    function getOptions(): array
    {
        return this.options;
    }

    /**
     * Get an option"s value or null
     *
     * @param string $name The name of the option to check.
     * @return string|int|bool|null The option value or null.
     */
    function getOption(string $name) {
        return this.options[$name] ?? null;
    }

    /**
     * Check if an option is defined and not null.
     *
     * @param string $name The name of the option to check.
     * @return bool
     */
    bool hasOption(string $name) {
        return isset(this.options[$name]);
    }
}
