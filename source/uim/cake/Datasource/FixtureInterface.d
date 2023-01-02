module uim.cake.Datasource;

/**
 * Defines the interface that testing fixtures use.
 */
interface FixtureInterface
{
    /**
     * Create the fixture schema/mapping/definition
     *
     * @param uim.cake.Datasource\ConnectionInterface $connection An instance of the connection the fixture should be created on.
     * @return bool True on success, false on failure.
     */
    function create(ConnectionInterface $connection): bool;

    /**
     * Run after all tests executed, should remove the table/collection from the connection.
     *
     * @param uim.cake.Datasource\ConnectionInterface $connection An instance of the connection the fixture should be removed from.
     * @return bool True on success, false on failure.
     */
    function drop(ConnectionInterface $connection): bool;

    /**
     * Run before each test is executed.
     *
     * Should insert all the records into the test database.
     *
     * @param uim.cake.Datasource\ConnectionInterface $connection An instance of the connection
     *   into which the records will be inserted.
     * @return uim.cake.databases.StatementInterface|bool on success or if there are no records to insert,
     *  or false on failure.
     */
    function insert(ConnectionInterface $connection);

    /**
     * Truncates the current fixture.
     *
     * @param uim.cake.Datasource\ConnectionInterface $connection A reference to a db instance
     */
    bool truncate(ConnectionInterface $connection): bool;

    // Get the connection name this fixture should be inserted into.
    string connection();

    // Get the table/collection name for this fixture.
    string sourceName();
}
