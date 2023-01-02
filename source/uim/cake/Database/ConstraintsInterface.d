module uim.cake.databases;

import uim.cake.datasources.IConnection;

/**
 * Defines the interface for a fixture that needs to manage constraints.
 *
 * If an implementation of `Cake\Datasource\FixtureInterface` also implements
 * this interface, the FixtureManager will use these methods to manage
 * a fixtures constraints.
 */
interface IConstraints
{
    /**
     * Build and execute SQL queries necessary to create the constraints for the
     * fixture
     *
     * @param uim.cake.Datasource\IConnection $connection An instance of the database
     *  into which the constraints will be created.
     * @return bool on success or if there are no constraints to create, or false on failure
     */
    bool createConstraints(IConnection $connection);

    /**
     * Build and execute SQL queries necessary to drop the constraints for the
     * fixture
     *
     * @param uim.cake.Datasource\IConnection $connection An instance of the database
     *  into which the constraints will be dropped.
     * @return bool on success or if there are no constraints to drop, or false on failure
     */
    bool dropConstraints(IConnection $connection);
}
