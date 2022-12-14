/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.databases;

@safe:
import uim.cake;

/**
 * Defines the interface for a fixture that needs to manage constraints.
 *
 * If an implementation of `Cake\Datasource\IFixture` also :
 * this interface, the FixtureManager will use these methods to manage
 * a fixtures constraints.
 */
interface IConstraints {
    /**
     * Build and execute SQL queries necessary to create the constraints for the
     * fixture
     *
     * @param \Cake\Datasource\IConnection myConnection An instance of the database
     *  into which the constraints will be created.
     * @return bool on success or if there are no constraints to create, or false on failure
     */
    bool createConstraints(IConnection myConnection);

    /**
     * Build and execute SQL queries necessary to drop the constraints for the
     * fixture
     *
     * @param \Cake\Datasource\IConnection myConnection An instance of the database
     *  into which the constraints will be dropped.
     * @return bool on success or if there are no constraints to drop, or false on failure
     */
    bool dropConstraints(IConnection myConnection);
}
