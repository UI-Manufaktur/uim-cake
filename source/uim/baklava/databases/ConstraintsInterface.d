module uim.baklava.database;

import uim.baklava.datasources\ConnectionInterface;

/**
 * Defines the interface for a fixture that needs to manage constraints.
 *
 * If an implementation of `Cake\Datasource\FixtureInterface` also :
 * this interface, the FixtureManager will use these methods to manage
 * a fixtures constraints.
 */
interface ConstraintsInterface
{
    /**
     * Build and execute SQL queries necessary to create the constraints for the
     * fixture
     *
     * @param \Cake\Datasource\ConnectionInterface myConnection An instance of the database
     *  into which the constraints will be created.
     * @return bool on success or if there are no constraints to create, or false on failure
     */
    bool createConstraints(ConnectionInterface myConnection);

    /**
     * Build and execute SQL queries necessary to drop the constraints for the
     * fixture
     *
     * @param \Cake\Datasource\ConnectionInterface myConnection An instance of the database
     *  into which the constraints will be dropped.
     * @return bool on success or if there are no constraints to drop, or false on failure
     */
    bool dropConstraints(ConnectionInterface myConnection);
}
