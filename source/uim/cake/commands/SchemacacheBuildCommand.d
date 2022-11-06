module uim.cakemmand;

import uim.cakensole.Arguments;
import uim.cakensole.consoleIo;
import uim.cakensole.consoleOptionParser;
import uim.caketabases.SchemaCache;
import uim.caketasources\ConnectionManager;
use RuntimeException;

/**
 * Provides CLI tool for updating schema cache.
 */
class SchemacacheBuildCommand : Command {
    /**
     * Get the command name.
     *
     * @return string
     */
    static string defaultName() {
        return 'schema_cache build';
    }

    /**
     * Display all routes in an application
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    auto execute(Arguments $args, ConsoleIo $io): Nullable!int
    {
        try {
            /** @var \Cake\Database\Connection myConnection */
            myConnection = ConnectionManager::get((string)$args.getOption('connection'));

            $cache = new SchemaCache(myConnection);
        } catch (RuntimeException $e) {
            $io.error($e.getMessage());

            return static::CODE_ERROR;
        }
        myTables = $cache.build($args.getArgument('name'));

        foreach (myTables as myTable) {
            $io.verbose(sprintf('Cached "%s"', myTable));
        }

        $io.out('<success>Cache build complete</success>');

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
            'Build all metadata caches for the connection. If a ' .
            'table name is provided, only that table will be cached.'
        ).addOption('connection', [
            'help' => 'The connection to build/clear metadata cache data for.',
            'short' => 'c',
            'default' => 'default',
        ]).addArgument('name', [
            'help' => 'A specific table you want to refresh cached data for.',
            'optional' => true,
        ]);

        return $parser;
    }
}
