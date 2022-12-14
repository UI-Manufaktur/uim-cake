module uim.cake.commands;

@safe:
import uim.cake;
use RuntimeException;

/**
 * Provides CLI tool for clearing schema cache.
 */
class SchemacacheClearCommand : Command {
    /**
     * Get the command name.
     *
     * @return string
     */
    static string defaultName() {
        return "schema_cache clear";
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
            /** @var DDBConnection $connection */
            $connection = ConnectionManager::get((string)$args.getOption("connection"));

            $cache = new SchemaCache($connection);
        } catch (RuntimeException $e) {
            $io.error($e.getMessage());

            return static::CODE_ERROR;
        }
        $tables = $cache.clear($args.getArgument("name"));

        foreach ($tables as $table) {
            $io.verbose(sprintf("Cleared '%s'", $table));
        }

        $io.out("<success>Cache clear complete</success>");

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
            "Clear all metadata caches for the connection. If a " ~
            "table name is provided, only that table will be removed."
        ).addOption("connection", [
            "help": "The connection to build/clear metadata cache data for.",
            "short": "c",
            "default": "default",
        ]).addArgument("name", [
            "help": "A specific table you want to clear cached data for.",
            "required": false,
        ]);

        return $parser;
    }
}
