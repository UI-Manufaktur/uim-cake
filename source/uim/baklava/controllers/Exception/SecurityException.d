module uim.baklava.controller\Exception;

import uim.baklava.https\Exception\BadRequestException;

/**
 * Security exception - used when SecurityComponent detects any issue with the current request
 */
class SecurityException : BadRequestException
{
    /**
     * Security Exception type
     *
     * @var string
     */
    protected $_type = 'secure';

    /**
     * Reason for request blackhole
     *
     * @var string|null
     */
    protected $_reason;

    /**
     * Getter for type
     */
    string getType() {
        return this._type;
    }

    /**
     * Set Message
     *
     * @param string myMessage Exception message
     * @return void
     */
    auto setMessage(string myMessage): void
    {
        this.message = myMessage;
    }

    /**
     * Set Reason
     * @param string|null $reason Reason details
     */
    auto setReason(Nullable!string $reason = null) {
        this._reason = $reason;

        return this;
    }

    /**
     * Get Reason
     */
    string getReason() {
        return this._reason;
    }
}
