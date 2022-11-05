module uim.baklava.command;

import uim.baklava.console.Arguments;
import uim.baklava.console.consoleIo;
import uim.baklava.console.consoleOptionParser;
import uim.baklava.Http\Exception\RedirectException;
import uim.baklava.Http\ServerRequest;
import uim.baklava.Routing\Exception\MissingRouteException;
import uim.baklava.Routing\Router;

/**
 * Provides interactive CLI tool for testing routes.
 */
class RoutesCheckCommand : Command {

    static string defaultName() {
        return 'routes check';
    }

    /**
     * Display all routes in an application
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    int execute(Arguments $args, ConsoleIo $io) {
        auto myUrl = $args.getArgument('url');
        try {
            myRequest = new ServerRequest(['url' => myUrl]);
            $route = Router::parseRequest(myRequest);
            myName = null;
            foreach (Router::routes() as $r) {
                if ($r.match($route)) {
                    myName = $r.options['_name'] ?? $r.getName();
                    break;
                }
            }

            unset($route['_matchedRoute']);
            ksort($route);

            $output = [
                ['Route name', 'URI template', 'Defaults'],
                [myName, myUrl, json_encode($route)],
            ];
            $io.helper('table').output($output);
            $io.out();
        } catch (RedirectException $e) {
            $output = [
                ['URI template', 'Redirect'],
                [myUrl, $e.getMessage()],
            ];
            $io.helper('table').output($output);
            $io.out();
        } catch (MissingRouteException $e) {
            $io.warning("'myUrl' did not match any routes.");
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
            'Check a URL string against the routes. ' .
            'Will output the routing parameters the route resolves to.'
        )
        .addArgument('url', [
            'help' => 'The URL to check.',
            'required' => true,
        ]);

        return $parser;
    }
}
