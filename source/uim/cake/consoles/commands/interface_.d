module uim.cake.console.commands.interface_;

@safe:
import uim.cake;

// Describe the interface between a command and the surrounding console libraries.
interface ICommand {
    // Default error code
    public const int CODE_ERROR = 1;

    // Default success code
    public const int CODE_SUCCESS = 0;

    // Set the name this command uses in the collection.
    auto name(string myName);

    // Run the command.
    Nullable!int run(array $argv, ConsoleIo $io);
}
