module uim.cake.TestSuite\Constraint\Session;

import uim.cake.utilities.Hash;
use PHPUnit\Framework\Constraint\Constraint;

/**
 * SessionEquals
 *
 * @internal
 */
class SessionEquals : Constraint
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
        return Hash::get(_SESSION, this.path) == $other;
    }

    /**
     * Assertion message
     */
    string toString() {
        return sprintf("is in session path \"%s\"", this.path);
    }
}
