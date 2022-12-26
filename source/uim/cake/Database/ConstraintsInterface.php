


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         4.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Database;

import uim.cake.Datasource\ConnectionInterface;

/**
 * Defines the interface for a fixture that needs to manage constraints.
 *
 * If an implementation of `Cake\Datasource\FixtureInterface` also implements
 * this interface, the FixtureManager will use these methods to manage
 * a fixtures constraints.
 */
interface ConstraintsInterface
{
    /**
     * Build and execute SQL queries necessary to create the constraints for the
     * fixture
     *
     * @param \Cake\Datasource\ConnectionInterface $connection An instance of the database
     *  into which the constraints will be created.
     * @return bool on success or if there are no constraints to create, or false on failure
     */
    function createConstraints(ConnectionInterface $connection): bool;

    /**
     * Build and execute SQL queries necessary to drop the constraints for the
     * fixture
     *
     * @param \Cake\Datasource\ConnectionInterface $connection An instance of the database
     *  into which the constraints will be dropped.
     * @return bool on success or if there are no constraints to drop, or false on failure
     */
    function dropConstraints(ConnectionInterface $connection): bool;
}
