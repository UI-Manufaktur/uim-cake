module uim.cake.commands;

@safe:
import uim.cake;

/**
 * Provides interactive CLI tool for testing routes.
 */
class RoutesCheckCommand : Command {

    static string defaultName()
    {
        return "routes check";
    }

    /**
     * Display all routes in an application
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    Nullable!int execute(Arguments someArguments, ConsoleIo aConsoleIo)
    {
        $url = $args.getArgument("url");
        try {
            $request = new ServerRequest(["url": $url]);
            $route = Router::parseRequest($request);
            $name = null;
            foreach (Router::routes() as $r) {
                if ($r.match($route)) {
                    $name = $r.options["_name"] ?? $r.getName();
                    break;
                }
            }

            unset($route["_route"], $route["_matchedRoute"]);
            ksort($route);

            $output = [
                ["Route name", "URI template", "Defaults"],
                [$name, $url, json_encode($route)],
            ];
            $io.helper("table").output($output);
            $io.out();
        } catch (RedirectException $e) {
            $output = [
                ["URI template", "Redirect"],
                [$url, $e.getMessage()],
            ];
            $io.helper("table").output($output);
            $io.out();
        } catch (MissingRouteException $e) {
            $io.warning(""$url" did not match any routes.");
            $io.out();

            return static::CODE_ERROR;
        }

        return static::CODE_SUCCESS;
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
            "Check a URL string against the routes~ " ~
            "Will output the routing parameters the route resolves to."
        )
        .addArgument("url", [
            "help": "The URL to check.",
            "required": true,
        ]);

        return $parser;
    }
}
