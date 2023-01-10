module uim.cake.commands;

@safe:
import uim.cake;

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
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    Nullable!int execute(Arguments someArguments, ConsoleIo aConsoleIo) {
        try {
            $args = _splitArgs($args.getArguments());
            $url = Router::url($args);
            $io.out("> $url");
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
    protected string/bool[] _splitArgs(array $args) {
        $out = [];
        foreach ($args as $arg) {
            if (strpos($arg, ":") != false) {
                [$key, $value] = explode(":", $arg);
                if (hasAllValues($value, ["true", "false"], true)) {
                    $value = $value == "true";
                }
                $out[$key] = $value;
            } else {
                $out[] = $arg;
            }
        }

        return $out;
    }

    /**
     * Get the option parser.
     *
     * @param uim.cake.consoles.ConsoleOptionParser $parser The option parser to update
     * @return uim.cake.consoles.ConsoleOptionParser
     */
    function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $parser.setDescription(
            "Check a routing array against the routes~ " ~
            "Will output the URL if there is a match." ~
            "\n\n" ~
            "Routing parameters should be supplied in a key:value format~ " ~
            "For example `controller:Articles action:view 2`"
        );

        return $parser;
    }
}
