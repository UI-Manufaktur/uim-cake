module uim.cake.TestSuite\Constraint\Session;

import uim.cake.http.Session;
import uim.cake.utilities.Hash;
use PHPUnit\Framework\AssertionFailedError;
use PHPUnit\Framework\Constraint\Constraint;

/**
 * FlashParamEquals
 *
 * @internal
 */
class FlashParamEquals : Constraint
{
    /**
     * @var uim.cake.http.Session
     */
    protected $session;

    /**
     */
    protected string aKey;

    /**
     */
    protected string $param;

    /**
     * @var int|null
     */
    protected $at;

    /**
     * Constructor
     *
     * @param uim.cake.http.Session|null $session Session
     * @param string aKey Flash key
     * @param string $param Param to check
     * @param int|null $at Expected index
     */
    this(?Session $session, string aKey, string $param, Nullable!int $at = null) {
        if (!$session) {
            $message = "There is no stored session data. Perhaps you need to run a request?";
            $message ~= " Additionally, ensure `this.enableRetainFlashMessages()` has been enabled for the test.";
            throw new AssertionFailedError($message);
        }

        this.session = $session;
        this.key = $key;
        this.param = $param;
        this.at = $at;
    }

    /**
     * Compare to flash message(s)
     *
     * @param mixed $other Value to compare with
     */
    bool matches($other) {
        // Server::run calls Session::close at the end of the request.
        // Which means, that we cannot use Session object here to access the session data.
        // Call to Session::read will start new session (and will erase the data).
        /** @psalm-suppress InvalidScalarArgument */
        $messages = (array)Hash::get(_SESSION, "Flash." ~ this.key);
        if (this.at) {
            /** @psalm-suppress InvalidScalarArgument */
            $messages = [Hash::get(_SESSION, "Flash." ~ this.key ~ "." ~ this.at)];
        }

        foreach ($messages as $message) {
            if (!isset($message[this.param])) {
                continue;
            }
            if ($message[this.param] == $other) {
                return true;
            }
        }

        return false;
    }

    /**
     * Assertion message string
     */
    string toString() {
        if (this.at != null) {
            return sprintf("is in \"%s\" %s #%d", this.key, this.param, this.at);
        }

        return sprintf("is in \"%s\" %s", this.key, this.param);
    }
}
