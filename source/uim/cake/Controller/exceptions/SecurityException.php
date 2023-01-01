module uim.cake.controllers.Exception;

import uim.cake.http.exceptions.BadRequestException;

/**
 * Security exception - used when SecurityComponent detects any issue with the current request
 */
class SecurityException : BadRequestException
{
    /**
     * Security Exception type
     *
     */
    protected string $_type = "secure";

    /**
     * Reason for request blackhole
     *
     * @var string|null
     */
    protected $_reason;

    /**
     * Getter for type
     */
    string getType()
    {
        return _type;
    }

    /**
     * Set Message
     *
     * @param string $message Exception message
     */
    void setMessage(string $message) {
        this.message = $message;
    }

    /**
     * Set Reason
     *
     * @param string|null $reason Reason details
     * @return this
     */
    function setReason(?string $reason = null) {
        _reason = $reason;

        return this;
    }

    /**
     * Get Reason
     *
     * @return string|null
     */
    function getReason(): ?string
    {
        return _reason;
    }
}
