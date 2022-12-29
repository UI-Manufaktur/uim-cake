module uim.cake.command;

import uim.cake.console.Arguments;
import uim.cake.console.consoleIo;
import uim.cake.console.consoleOptionParser;
import uim.cake.routings\Exception\MissingRouteException;
import uim.cake.routings\Router;

/**
 * Provides interactive CLI tools for URL generation
 */
class RoutesGenerateCommand : Command {

    static string defaultName() {
        return "routes generate";
    }

    /**
     * Display all routes in an application
     *
     * @param uim.cake.Console\Arguments $args The command arguments.
     * @param uim.cake.Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    Nullable!int execute(Arguments $args, ConsoleIo $io) {
        try {
            $args = _splitArgs($args.getArguments());
            myUrl = Router::url($args);
            $io.out("> myUrl");
            $io.out();
        } catch (MissingRouteException $e) {
            $io.err("<warning>The provided parameters do not match any routes.</warning>");
            $io.out();

            return static::CODE_ERROR;
        }

        return static::CODE_SUCCESS;
    }

    /**
     * Split the CLI arguments into a hash.
     *
     * @param array<string> $args The arguments to split.
     * @return array<string|bool>
     */
    protected array _splitArgs(array $args) {
        $out = [];
        foreach ($arg; $args) {
            if (indexOf($arg, ":") != false) {
                [myKey, myValue] = explode(":", $arg);
                if (in_array(myValue, ["true", "false"], true)) {
                    myValue = myValue == "true";
                }
                $out[myKey] = myValue;
            } else {
                $out[] = $arg;
            }
        }

        return $out;
    }

    /**
     * Get the option parser.
     *
     * @param uim.cake.Console\ConsoleOptionParser $parser The option parser to update
     * @return uim.cake.Console\ConsoleOptionParser
     */
    ConsoleOptionParser buildOptionParser(ConsoleOptionParser $parser) {
        $parser.setDescription(
            "Check a routing array against the routes. " .
            "Will output the URL if there is a match." .
            "\n\n" .
            "Routing parameters should be supplied in a key:value format. " .
            "For example `controller:Articles action:view 2`"
        );

        return $parser;
    }
}
