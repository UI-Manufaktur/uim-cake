

/**
 * A class to contain and retain the session during integration testing.
 *

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.0.5
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite;

import uim.baklava.utikities.Hash;

/**
 * Read only access to the session during testing.
 */
class TestSession
{
    /**
     * @var array|null
     */
    protected $session;

    /**
     * @param array|null $session Session data.
     */
    this(?array $session) {
        this.session = $session;
    }

    /**
     * Returns true if given variable name is set in session.
     *
     * @param string|null myName Variable name to check for
     * @return bool True if variable is there
     */
    function check(?string myName = null): bool
    {
        if (this.session === null) {
            return false;
        }

        if (myName === null) {
            return (bool)this.session;
        }

        return Hash::get(this.session, myName) !== null;
    }

    /**
     * Returns given session variable, or all of them, if no parameters given.
     *
     * @param string|null myName The name of the session variable (or a path as sent to Hash.extract)
     * @return mixed The value of the session variable, null if session not available,
     *   session not started, or provided name not found in the session.
     */
    function read(?string myName = null) {
        if (this.session === null) {
            return null;
        }

        if (myName === null) {
            return this.session ?: [];
        }

        return Hash::get(this.session, myName);
    }
}
