


 *


 * @since         3.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Command;

import uim.cake.consoles.Arguments;
import uim.cake.consoles.ConsoleIo;
import uim.cake.consoles.ConsoleOptionParser;
import uim.cake.https.Exception\RedirectException;
import uim.cake.https.ServerRequest;
import uim.cake.Routing\Exception\MissingRouteException;
import uim.cake.Routing\Router;

/**
 * Provides interactive CLI tool for testing routes.
 */
class RoutesCheckCommand : Command
{

    public static function defaultName(): string
    {
        return "routes check";
    }

    /**
     * Display all routes in an application
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    function execute(Arguments $args, ConsoleIo $io): ?int
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
     * @param \Cake\Console\ConsoleOptionParser $parser The option parser to update
     * @return \Cake\Console\ConsoleOptionParser
     */
    function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $parser.setDescription(
            "Check a URL string against the routes. " .
            "Will output the routing parameters the route resolves to."
        )
        .addArgument("url", [
            "help": "The URL to check.",
            "required": true,
        ]);

        return $parser;
    }
}
