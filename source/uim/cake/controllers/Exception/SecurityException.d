module uim.cake.controllers\Exception;

import uim.caketps\Exception\BadRequestException;

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
    protected $_type = "secure";

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
     */
    void setMessage(string myMessage) {
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
