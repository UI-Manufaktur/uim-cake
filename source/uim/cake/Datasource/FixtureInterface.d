module uim.cake.Datasource;

/**
 * Defines the interface that testing fixtures use.
 */
interface FixtureInterface
{
    /**
     * Create the fixture schema/mapping/definition
     *
     * @param \Cake\Datasource\ConnectionInterface myConnection An instance of the connection the fixture should be created on.
     * @return bool True on success, false on failure.
     */
    bool create(ConnectionInterface myConnection);

    /**
     * Run after all tests executed, should remove the table/collection from the connection.
     *
     * @param \Cake\Datasource\ConnectionInterface myConnection An instance of the connection the fixture should be removed from.
     * @return bool True on success, false on failure.
     */
    bool drop(ConnectionInterface myConnection);

    /**
     * Run before each test is executed.
     *
     * Should insert all the records into the test database.
     *
     * @param \Cake\Datasource\ConnectionInterface myConnection An instance of the connection
     *   into which the records will be inserted.
     * @return \Cake\Database\IStatement|bool on success or if there are no records to insert,
     *  or false on failure.
     */
    function insert(ConnectionInterface myConnection);

    /**
     * Truncates the current fixture.
     *
     * @param \Cake\Datasource\ConnectionInterface myConnection A reference to a db instance
     * @return bool
     */
    bool truncate(ConnectionInterface myConnection);

    /**
     * Get the connection name this fixture should be inserted into.
     *
     * @return string
     */
    function connection(): string;

    /**
     * Get the table/collection name for this fixture.
     *
     * @return string
     */
    function sourceName(): string;
}
