module uim.cake.database.Retry;

import uim.cake.core.Retry\RetryStrategyInterface;
import uim.cake.database.Connection;
use Exception;

/**
 * Makes sure the connection to the database is alive before authorizing
 * the retry of an action.
 *
 * @internal
 */
class ReconnectStrategy : RetryStrategyInterface
{
    /**
     * The list of error strings to match when looking for a disconnection error.
     *
     * This is a static variable to enable opcache to inline the values.
     *
     * @var array<string>
     */
    protected static $causes = [
        'gone away',
        'Lost connection',
        'Transaction() on null',
        'closed the connection unexpectedly',
        'closed unexpectedly',
        'deadlock avoided',
        'decryption failed or bad record mac',
        'is dead or not enabled',
        'no connection to the server',
        'query_wait_timeout',
        'reset by peer',
        'terminate due to client_idle_limit',
        'while sending',
        'writing data to the connection',
    ];

    /**
     * The connection to check for validity
     *
     * @var \Cake\Database\Connection
     */
    protected myConnection;

    /**
     * Creates the ReconnectStrategy object by storing a reference to the
     * passed connection. This reference will be used to automatically
     * reconnect to the server in case of failure.
     *
     * @param \Cake\Database\Connection myConnection The connection to check
     */
    this(Connection myConnection) {
        this.connection = myConnection;
    }

    /**
     * {@inheritDoc}
     *
     * Checks whether the exception was caused by a lost connection,
     * and returns true if it was able to successfully reconnect.
     */
    bool shouldRetry(Exception myException, int $retryCount) {
        myMessage = myException.getMessage();

        foreach (static::$causes as $cause) {
            if (strstr(myMessage, $cause) !== false) {
                return this.reconnect();
            }
        }

        return false;
    }

    /**
     * Tries to re-establish the connection to the server, if it is safe to do so
     *
     * @return bool Whether the connection was re-established
     */
    bool auto reconnect() {
        if (this.connection.inTransaction()) {
            // It is not safe to blindly reconnect in the middle of a transaction
            return false;
        }

        try {
            // Make sure we free any resources associated with the old connection
            this.connection.disconnect();
        } catch (Exception $e) {
        }

        try {
            this.connection.connect();
            this.connection.log('[RECONNECT]');

            return true;
        } catch (Exception $e) {
            // If there was an error connecting again, don't report it back,
            // let the retry handler do it.
            return false;
        }
    }
}
