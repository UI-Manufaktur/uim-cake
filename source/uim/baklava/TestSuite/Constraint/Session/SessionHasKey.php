module uim.baklava.TestSuite\Constraint\Session;

import uim.baklava.utilities.Hash;
use PHPUnit\Framework\Constraint\Constraint;

/**
 * SessionHasKey
 *
 * @internal
 */
class SessionHasKey : Constraint
{
    /**
     * @var string
     */
    protected myPath;

    /**
     * Constructor
     *
     * @param string myPath Session Path
     */
    this(string myPath) {
        this.path = myPath;
    }

    /**
     * Compare session value
     *
     * @param mixed $other Value to compare with
     * @return bool
     */
    function matches($other): bool
    {
        // Server::run calls Session::close at the end of the request.
        // Which means, that we cannot use Session object here to access the session data.
        // Call to Session::read will start new session (and will erase the data).
        return Hash::check($_SESSION, this.path) === true;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return 'is a path present in the session';
    }
}
