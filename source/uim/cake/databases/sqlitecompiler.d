module uim.cake.databases;

@safe:
import uim.cake;

/**
 * Responsible for compiling a Query object into its SQL representation
 * for SQLite
 *
 * @internal
 */
class SqliteCompiler : QueryCompiler
{
    /**
     * SQLite does not support ORDER BY in UNION queries.
     */
    protected bool $_orderedUnion = false;
}
