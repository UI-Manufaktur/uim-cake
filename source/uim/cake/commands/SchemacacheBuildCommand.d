module uim.cake.command;

@safe:
import uim.cake;
use RuntimeException;

/**
 * Provides CLI tool for updating schema cache.
 */
class SchemacacheBuildCommand : Command {
    /**
     * Get the command name.
     */
    static string defaultName() {
        return "schema_cache build";
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
            /** @var DDBConnection myConnection */
            myConnection = ConnectionManager::get((string)$args.getOption("connection"));

            $cache = new SchemaCache(myConnection);
        } catch (RuntimeException $e) {
            $io.error($e.getMessage());

            return static::CODE_ERROR;
        }
        myTables = $cache.build($args.getArgument("name"));

        foreach (myTable; myTables) {
            $io.verbose(sprintf("Cached '%s'", myTable));
        }

        $io.out("<success>Cache build complete</success>");

        return static::CODE_SUCCESS;
    }

    /**
     * Get the option parser.
     *
     * @param uim.cake.consoles.ConsoleOptionParser $parser The option parser to update
     * @return uim.cake.consoles.ConsoleOptionParser
     */
    ConsoleOptionParser buildOptionParser(ConsoleOptionParser $parser) {
        $parser.setDescription(
            "Build all metadata caches for the connection. If a " ~
            "table name is provided, only that table will be cached."
        ).addOption("connection", [
            "help":"The connection to build/clear metadata cache data for.",
            "short":"c",
            "default":"default",
        ]).addArgument("name", [
            "help":"A specific table you want to refresh cached data for.",
            "optional":true,
        ]);

        return $parser;
    }
}
