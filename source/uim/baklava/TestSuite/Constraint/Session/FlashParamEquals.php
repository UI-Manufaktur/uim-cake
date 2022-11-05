module uim.baklava.TestSuite\Constraint\Session;

import uim.baklava.https\Session;
import uim.baklava.utikities.Hash;
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
     * @var \Cake\Http\Session
     */
    protected $session;

    /**
     * @var string
     */
    protected myKey;

    /**
     * @var string
     */
    protected $param;

    /**
     * @var int|null
     */
    protected $at;

    /**
     * Constructor
     *
     * @param \Cake\Http\Session|null $session Session
     * @param string myKey Flash key
     * @param string $param Param to check
     * @param int|null $at Expected index
     */
    this(?Session $session, string myKey, string $param, Nullable!int $at = null) {
        if (!$session) {
            myMessage = 'There is no stored session data. Perhaps you need to run a request?';
            myMessage .= ' Additionally, ensure `this.enableRetainFlashMessages()` has been enabled for the test.';
            throw new AssertionFailedError(myMessage);
        }

        this.session = $session;
        this.key = myKey;
        this.param = $param;
        this.at = $at;
    }

    /**
     * Compare to flash message(s)
     *
     * @param mixed $other Value to compare with
     * @return bool
     */
    function matches($other): bool
    {
        // Server::run calls Session::close at the end of the request.
        // Which means, that we cannot use Session object here to access the session data.
        // Call to Session::read will start new session (and will erase the data).

        myMessages = (array)Hash::get($_SESSION, 'Flash.' . this.key);
        if (this.at) {
            myMessages = [Hash::get($_SESSION, 'Flash.' . this.key . '.' . this.at)];
        }

        foreach (myMessages as myMessage) {
            if (!isset(myMessage[this.param])) {
                continue;
            }
            if (myMessage[this.param] === $other) {
                return true;
            }
        }

        return false;
    }

    /**
     * Assertion message string
     *
     * @return string
     */
    function toString(): string
    {
        if (this.at !== null) {
            return sprintf('is in \'%s\' %s #%d', this.key, this.param, this.at);
        }

        return sprintf('is in \'%s\' %s', this.key, this.param);
    }
}