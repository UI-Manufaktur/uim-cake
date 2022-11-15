module uim.cake.console;

/**
 * Describe the interface between a command
 * and the surrounding console libraries.
 */
interface ICommand
{
    /**
     * Default error code
     *
     * @var int
     */
    public const CODE_ERROR = 1;

    /**
     * Default success code
     *
     * @var int
     */
    public const CODE_SUCCESS = 0;

    /**
     * Set the name this command uses in the collection.
     *
     * Generally invoked by the CommandCollection when the command is added.
     * Required to have at least one space in the name so that the root
     * command can be calculated.
     *
     * @param string myName The name the command uses in the collection.
     * @return this
     * @throws \InvalidArgumentException
     */
    auto setName(string myName);

    /**
     * Run the command.
     *
     * @param array $argv Arguments from the CLI environment.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null Exit code or null for success.
     */
    function run(array $argv, ConsoleIo $io): Nullable!int;
}
