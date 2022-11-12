module uim.cake.console;

/**
 * Provides an interface for interacting with
 * a command's options and arguments.
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
    protected myOptions;

    /**
     * Constructor
     *
     * @param array<int, string> $args Positional arguments
     * @param array<string, string|int|bool|null> myOptions Named arguments
     * @param array<int, string> $argNames List of argument names. Order is expected to be
     *  the same as $args.
     */
    this(array $args, array myOptions, array $argNames) {
        this.args = $args;
        this.options = myOptions;
        this.argNames = $argNames;
    }

    /**
     * Get all positional arguments.
     *
     * @return array<int, string>
     */
    auto getArguments(): array
    {
        return this.args;
    }

    /**
     * Get positional arguments by index.
     *
     * @param int $index The argument index to access.
     * @return string|null The argument value or null
     */
    auto getArgumentAt(int $index): Nullable!string
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
     */
<<<<<<< HEAD
    bool hasArgumentAt(int $index) {
=======
    bool hasArgumentAt(int $index) {
>>>>>>> 239609fef6473c0db75e1e8d3858d91274903fc2
        return isset(this.args[$index]);
    }

    /**
     * Check if a positional argument exists by name
     *
     * @param string myName The argument name to check.
     */
<<<<<<< HEAD
    bool hasArgument(string myName) {
=======
    bool hasArgument(string myName) {
>>>>>>> 239609fef6473c0db75e1e8d3858d91274903fc2
        $offset = array_search(myName, this.argNames, true);
        if ($offset === false) {
            return false;
        }

        return isset(this.args[$offset]);
    }

    /**
     * Check if a positional argument exists by name
     *
     * @param string myName The argument name to check.
     * @return string|null
     */
    auto getArgument(string myName): Nullable!string
    {
        $offset = array_search(myName, this.argNames, true);
        if ($offset === false || !isset(this.args[$offset])) {
            return null;
        }

        return this.args[$offset];
    }

    /**
     * Get an array of all the options
     *
     * @return array<string, string|int|bool|null>
     */
    auto getOptions(): array
    {
        return this.options;
    }

    /**
     * Get an option's value or null
     *
     * @param string myName The name of the option to check.
     * @return string|int|bool|null The option value or null.
     */
    auto getOption(string myName) {
        return this.options[myName] ?? null;
    }

    /**
     * Check if an option is defined and not null.
     *
     * @param string myName The name of the option to check.
     */
<<<<<<< HEAD
    bool hasOption(string myName) {
=======
    bool hasOption(string myName) {
>>>>>>> 239609fef6473c0db75e1e8d3858d91274903fc2
        return isset(this.options[myName]);
    }
}
