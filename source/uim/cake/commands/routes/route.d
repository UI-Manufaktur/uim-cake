module uim.cake.command;

@safe:
import uim.cake;

/**
 * Provides interactive CLI tools for routing.
 */
class RoutesCommand : Command {
    /**
     * Display all routes in an application
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    Nullable!int execute(Arguments someArguments, ConsoleIo aConsoleIo) {
        $header = ["Route name", "URI template", "Plugin", "Prefix", "Controller", "Action", "Method(s)"];
        if ($args.getOption("verbose")) {
            $header[] = "Defaults";
        }

        $output = null;

        foreach ($route; Router::routes()) {
          $methods = $route.defaults["_method"] ?? "";

          $item = [
            $route.options["_name"] ?? $route.getName(),
            $route.template,
            $route.defaults["plugin"] ?? "",
            $route.defaults["prefix"] ?? "",
            $route.defaults["controller"] ?? "",
            $route.defaults["action"] ?? "",
            is_string($methods) ? $methods : implode(", ", $route.defaults["_method"]),
          ];

          if ($args.getOption("verbose")) {
            ksort($route.defaults);
            $item[] = json_encode($route.defaults);
          }

          $output[] = $item;
        }

        if ($args.getOption("sort")) {
            usort($output, function ($a, $b) {
                return strcasecmp($a[0], $b[0]);
            });
        }

        array_unshift($output, $header);

        $io.helper("table").output($output);
        $io.out();

        return static::CODE_SUCCESS;
    }

    /**
     * Get the option parser.
     *
     * @param uim.cake.consoles.ConsoleOptionParser $parser The option parser to update
     * @return uim.cake.consoles.ConsoleOptionParser
     */
    ConsoleOptionParser buildOptionParser(ConsoleOptionParser $parser) {
      $parser
        .setDescription("Get the list of routes connected in this application.")
        .addOption("sort", [
            "help":"Sorts alphabetically by route name A-Z",
            "short":"s",
            "boolean":true,
        ]);

      return $parser;
    }
}
