/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.controllers.exceptions.security;

@safe:
import uim.cake;

// Security exception - used when SecurityComponent detects any issue with the current request
class SecurityException : BadRequestException {
    // Security Exception type
    protected string _type = "secure";

    /**
     * Reason for request blackhole
     *
     */
    protected Nullable!string _reason;

    /**
     * Getter for type
     */
    string getType() {
        return _type;
    }

    /**
     * Set Message
     *
     * @param string $message Exception message
     */
    void setMessage(string aMessage) {
        this.message = aMessage;
    }

    /**
     * Set Reason
     *
     * @param string|null $reason Reason details
     * @return this
     */
    function setReason(Nullable!string $reason = null) {
        _reason = $reason;

        return this;
    }

    /**
     * Get Reason
     *
     * @return string|null
     */
    Nullable!string getReason() {
        return _reason;
    }
}
