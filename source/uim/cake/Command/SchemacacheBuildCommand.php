


 *


 * @since         3.6.0
  */
module uim.cake.Command;

import uim.cake.consoles.Arguments;
import uim.cake.consoles.ConsoleIo;
import uim.cake.consoles.ConsoleOptionParser;
import uim.cake.databases.SchemaCache;
import uim.cake.datasources.ConnectionManager;
use RuntimeException;

/**
 * Provides CLI tool for updating schema cache.
 */
class SchemacacheBuildCommand : Command
{
    /**
     * Get the command name.
     *
     * @return string
     */
    public static function defaultName(): string
    {
        return "schema_cache build";
    }

    /**
     * Display all routes in an application
     *
     * @param uim.cake.Console\Arguments $args The command arguments.
     * @param uim.cake.Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    function execute(Arguments $args, ConsoleIo $io): ?int
    {
        try {
            /** @var uim.cake.Database\Connection $connection */
            $connection = ConnectionManager::get((string)$args.getOption("connection"));

            $cache = new SchemaCache($connection);
        } catch (RuntimeException $e) {
            $io.error($e.getMessage());

            return static::CODE_ERROR;
        }
        $tables = $cache.build($args.getArgument("name"));

        foreach ($tables as $table) {
            $io.verbose(sprintf("Cached "%s"", $table));
        }

        $io.out("<success>Cache build complete</success>");

        return static::CODE_SUCCESS;
    }

    /**
     * Get the option parser.
     *
     * @param uim.cake.Console\ConsoleOptionParser $parser The option parser to update
     * @return uim.cake.Console\ConsoleOptionParser
     */
    function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $parser.setDescription(
            "Build all metadata caches for the connection. If a " .
            "table name is provided, only that table will be cached."
        ).addOption("connection", [
            "help": "The connection to build/clear metadata cache data for.",
            "short": "c",
            "default": "default",
        ]).addArgument("name", [
            "help": "A specific table you want to refresh cached data for.",
            "required": false,
        ]);

        return $parser;
    }
}
