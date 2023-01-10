

/**
 * Database Session save handler. Allows saving session information into a model.
 *
 * UIM(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         2.0.0
  */module uim.cake.http.Session;

import uim.cake.orm.locators.LocatorAwareTrait;
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
     */
    protected int _timeout;

    /**
     * Constructor. Looks at Session configuration information and
     * sets up the session model.
     *
     * @param array<string, mixed> aConfig The configuration for this engine. It requires the "model"
     * key to be present corresponding to the Table to use for managing the sessions.
     */
    this(Json aConfig = null) {
        if (isset(aConfig["tableLocator"])) {
            this.setTableLocator(aConfig["tableLocator"]);
        }
        $tableLocator = this.getTableLocator();

        if (empty(aConfig["model"])) {
            aConfig = $tableLocator.exists("Sessions") ? [] : ["table": "sessions", "allowFallbackClass": true];
            _table = $tableLocator.get("Sessions", aConfig);
        } else {
            _table = $tableLocator.get(aConfig["model"]);
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
    function setTimeout(int $timeout) {
        _timeout = $timeout;

        return this;
    }

    /**
     * Method called on open of a database session.
     *
     * @param string $path The path where to store/retrieve the session.
     * @param string aName The session name.
     * @return bool Success
     */
    bool open($path, $name) {
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
     * @param string $id ID that uniquely identifies session in database.
     * @return string|false Session data or false if it does not exist.
     */
    #[\ReturnTypeWillChange]
    function read($id) {
        /** @var string $pkField */
        $pkField = _table.getPrimaryKeys();
        $result = _table
            .find("all")
            .select(["data"])
            .where([$pkField: $id])
            .disableHydration()
            .first();

        if (empty($result)) {
            return "";
        }

        if (is_string($result["data"])) {
            return $result["data"];
        }

        $session = stream_get_contents($result["data"]);

        if ($session == false) {
            return "";
        }

        return $session;
    }

    /**
     * Helper function called on write for database sessions.
     *
     * @param string $id ID that uniquely identifies session in database.
     * @param string $data The data to be saved.
     * @return bool True for successful write, false otherwise.
     */
    bool write($id, $data) {
        if (!$id) {
            return false;
        }

        /** @var string $pkField */
        $pkField = _table.getPrimaryKeys();
        $session = _table.newEntity([
            $pkField: $id,
            "data": $data,
            "expires": time() + _timeout,
        ], ["accessibleFields": [$pkField: true]]);

        return (bool)_table.save($session);
    }

    /**
     * Method called on the destruction of a database session.
     *
     * @param string $id ID that uniquely identifies session in database.
     * @return bool True for successful delete, false otherwise.
     */
    bool destroy($id) {
        /** @var string $pkField */
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
        return _table.deleteAll(["expires <": time()]);
    }
}
