module uim.cake.databases.schemas;

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
    array createSql(Connection $connection);

    /**
     * Generate the SQL to drop a table.
     *
     * Uses the connection to access the schema dialect to generate platform
     * specific SQL.
     *
     * @param uim.cake.databases.Connection $connection The connection to generate SQL for.
     * @return array SQL to drop a table.
     */
    array dropSql(Connection $connection);

    /**
     * Generate the SQL statements to truncate a table
     *
     * @param uim.cake.databases.Connection $connection The connection to generate SQL for.
     * @return array SQL to truncate a table.
     */
    array truncateSql(Connection $connection);

    /**
     * Generate the SQL statements to add the constraints to the table
     *
     * @param uim.cake.databases.Connection $connection The connection to generate SQL for.
     * @return array SQL to add the constraints.
     */
    array addConstraintSql(Connection $connection);

    /**
     * Generate the SQL statements to drop the constraints to the table
     *
     * @param uim.cake.databases.Connection $connection The connection to generate SQL for.
     * @return array SQL to drop a table.
     */
    array dropConstraintSql(Connection $connection);
}
