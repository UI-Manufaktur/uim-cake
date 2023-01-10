/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.https\Session;

import uim.cake.orm.locators\LocatorAwareTrait;
use SessionHandlerInterface;

/**
 * DatabaseSession provides methods to be used with Session.
 */
class DatabaseSession : SessionHandlerInterface
{
    use LocatorAwareTrait;

    /**
     * Reference to the table handling the session data
     *
     * @var DORMTable
     */
    protected _table;

    /**
     * Number of seconds to mark the session as expired
     *
     * @var int
     */
    protected _timeout;

    /**
     * Constructor. Looks at Session configuration information and
     * sets up the session model.
     *
     * @param array<string, mixed> myConfig The configuration for this engine. It requires the "model"
     * key to be present corresponding to the Table to use for managing the sessions.
     */
    this(array myConfig = null) {
        if (isset(myConfig["tableLocator"])) {
            this.setTableLocator(myConfig["tableLocator"]);
        }
        myTableLocator = this.getTableLocator();

        if (empty(myConfig["model"])) {
            myConfig = myTableLocator.exists("Sessions") ? [] : ["table":"sessions", "allowFallbackClass":true];
            _table = myTableLocator.get("Sessions", myConfig);
        } else {
            _table = myTableLocator.get(myConfig["model"]);
        }

        _timeout = (int)ini_get("session.gc_maxlifetime");
    }

    /**
     * Set the timeout value for sessions.
     *
     * Primarily used in testing.
     *
     * @param int $timeout The timeout duration.
     * @return this
     */
    auto setTimeout(int $timeout) {
        _timeout = $timeout;

        return this;
    }

    /**
     * Method called on open of a database session.
     *
     * @param string myPath The path where to store/retrieve the session.
     * @param string myName The session name.
     * @return bool Success
     */
    bool open(myPath, myName) {
        return true;
    }

    /**
     * Method called on close of a database session.
     *
     * @return bool Success
     */
    bool close() {
        return true;
    }

    /**
     * Method used to read from a database session.
     *
     * @param string id ID that uniquely identifies session in database.
     * @return string|false Session data or false if it does not exist.
     */
    #[\ReturnTypeWillChange]
    function read($id) {
        /** @var string pkField */
        $pkField = _table.getPrimaryKeys();
        myResult = _table
            .find("all")
            .select(["data"])
            .where([$pkField: $id])
            .disableHydration()
            .first();

        if (empty(myResult)) {
            return "";
        }

        if (is_string(myResult["data"])) {
            return myResult["data"];
        }

        $session = stream_get_contents(myResult["data"]);

        if ($session == false) {
            return "";
        }

        return $session;
    }

    /**
     * Helper function called on write for database sessions.
     *
     * @param string id ID that uniquely identifies session in database.
     * @param string myData The data to be saved.
     * @return bool True for successful write, false otherwise.
     */
    bool write($id, myData) {
        if (!$id) {
            return false;
        }

        /** @var string pkField */
        $pkField = _table.getPrimaryKeys();
        $session = _table.newEntity([
            $pkField: $id,
            "data":myData,
            "expires":time() + _timeout,
        ], ["accessibleFields":[$pkField: true]]);

        return (bool)_table.save($session);
    }

    /**
     * Method called on the destruction of a database session.
     *
     * @param string id ID that uniquely identifies session in database.
     * @return bool True for successful delete, false otherwise.
     */
    bool destroy($id) {
        /** @var string pkField */
        $pkField = _table.getPrimaryKeys();
        _table.deleteAll([$pkField: $id]);

        return true;
    }

    /**
     * Helper function called on gc for database sessions.
     *
     * @param int $maxlifetime Sessions that have not updated for the last maxlifetime seconds will be removed.
     * @return int|false The number of deleted sessions on success, or false on failure.
     */
    #[\ReturnTypeWillChange]
    function gc($maxlifetime) {
        return _table.deleteAll(["expires <":time()]);
    }
}
