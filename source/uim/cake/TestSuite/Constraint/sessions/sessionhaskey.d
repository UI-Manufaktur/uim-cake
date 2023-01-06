

 * @since         4.1.0

 */module uim.cake.TestSuite\Constraint\Session;

import uim.cake.utilities.Hash;
use PHPUnit\Framework\Constraint\Constraint;

/**
 * SessionHasKey
 *
 * @internal
 */
class SessionHasKey : Constraint
{
    /**
     */
    protected string $path;

    /**
     * Constructor
     *
     * @param string $path Session Path
     */
    this(string $path) {
        this.path = $path;
    }

    /**
     * Compare session value
     *
     * @param mixed $other Value to compare with
     */
    bool matches($other) {
        // Server::run calls Session::close at the end of the request.
        // Which means, that we cannot use Session object here to access the session data.
        // Call to Session::read will start new session (and will erase the data).
        /** @psalm-suppress InvalidScalarArgument */
        return Hash::check(_SESSION, this.path) == true;
    }

    /**
     * Assertion message
     */
    string toString() {
        return "is a path present in the session";
    }
}
