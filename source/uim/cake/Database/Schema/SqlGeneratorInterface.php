
module uim.cake.databases.Schema;

import uim.cake.databases.Connection;

/**
 * An interface used by TableSchema objects.
 */
interface SqlGeneratorInterface
{
    /**
     * Generate the SQL to create the Table.
     *
     * Uses the connection to access the schema dialect
     * to generate platform specific SQL.
     *
     * @param uim.cake.databases.Connection $connection The connection to generate SQL for.
     * @return array List of SQL statements to create the table and the
     *    required indexes.
     */
    function createSql(Connection $connection): array;

    /**
     * Generate the SQL to drop a table.
     *
     * Uses the connection to access the schema dialect to generate platform
     * specific SQL.
     *
     * @param uim.cake.databases.Connection $connection The connection to generate SQL for.
     * @return array SQL to drop a table.
     */
    function dropSql(Connection $connection): array;

    /**
     * Generate the SQL statements to truncate a table
     *
     * @param uim.cake.databases.Connection $connection The connection to generate SQL for.
     * @return array SQL to truncate a table.
     */
    function truncateSql(Connection $connection): array;

    /**
     * Generate the SQL statements to add the constraints to the table
     *
     * @param uim.cake.databases.Connection $connection The connection to generate SQL for.
     * @return array SQL to add the constraints.
     */
    function addConstraintSql(Connection $connection): array;

    /**
     * Generate the SQL statements to drop the constraints to the table
     *
     * @param uim.cake.databases.Connection $connection The connection to generate SQL for.
     * @return array SQL to drop a table.
     */
    function dropConstraintSql(Connection $connection): array;
}
