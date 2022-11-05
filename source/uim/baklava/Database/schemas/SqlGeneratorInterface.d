module uim.baklava.databases.Schema;

import uim.baklava.databases.Connection;

/**
 * An interface used by TableSchema objects.
 */
interface ISqlGenerator
{
    /**
     * Generate the SQL to create the Table.
     *
     * Uses the connection to access the schema dialect
     * to generate platform specific SQL.
     *
     * @param \Cake\Database\Connection myConnection The connection to generate SQL for.
     * @return array List of SQL statements to create the table and the
     *    required indexes.
     */
    function createSql(Connection myConnection): array;

    /**
     * Generate the SQL to drop a table.
     *
     * Uses the connection to access the schema dialect to generate platform
     * specific SQL.
     *
     * @param \Cake\Database\Connection myConnection The connection to generate SQL for.
     * @return array SQL to drop a table.
     */
    function dropSql(Connection myConnection): array;

    /**
     * Generate the SQL statements to truncate a table
     *
     * @param \Cake\Database\Connection myConnection The connection to generate SQL for.
     * @return array SQL to truncate a table.
     */
    function truncateSql(Connection myConnection): array;

    /**
     * Generate the SQL statements to add the constraints to the table
     *
     * @param \Cake\Database\Connection myConnection The connection to generate SQL for.
     * @return array SQL to add the constraints.
     */
    function addConstraintSql(Connection myConnection): array;

    /**
     * Generate the SQL statements to drop the constraints to the table
     *
     * @param \Cake\Database\Connection myConnection The connection to generate SQL for.
     * @return array SQL to drop a table.
     */
    function dropConstraintSql(Connection myConnection): array;
}
