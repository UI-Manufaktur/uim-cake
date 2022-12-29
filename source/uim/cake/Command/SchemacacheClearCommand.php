


 *


 * @since         3.6.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Command;

import uim.cake.consoles.Arguments;
import uim.cake.consoles.ConsoleIo;
import uim.cake.consoles.ConsoleOptionParser;
import uim.cake.databases.SchemaCache;
import uim.cake.Datasource\ConnectionManager;
use RuntimeException;

/**
 * Provides CLI tool for clearing schema cache.
 */
class SchemacacheClearCommand : Command
{
    /**
     * Get the command name.
     *
     * @return string
     */
    public static function defaultName(): string
    {
        return "schema_cache clear";
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
        try {
            /** @var \Cake\Database\Connection $connection */
            $connection = ConnectionManager::get((string)$args.getOption("connection"));

            $cache = new SchemaCache($connection);
        } catch (RuntimeException $e) {
            $io.error($e.getMessage());

            return static::CODE_ERROR;
        }
        $tables = $cache.clear($args.getArgument("name"));

        foreach ($tables as $table) {
            $io.verbose(sprintf("Cleared "%s"", $table));
        }

        $io.out("<success>Cache clear complete</success>");

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
            "Clear all metadata caches for the connection. If a " .
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
