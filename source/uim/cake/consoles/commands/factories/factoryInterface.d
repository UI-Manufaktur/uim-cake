module uim.cake.consoles;

@safe:
import uim.cake;

// An interface for abstracting creation of command and shell instances.
interface ICommandFactory {
    // The factory method for creating Command and Shell instances.
    ICommand create(string myClassName);
}
