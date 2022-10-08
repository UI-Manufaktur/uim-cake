

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.controller\Exception;

import uim.cake.Http\Exception\BadRequestException;

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
     *
     * @return string
     */
    string getType()
    {
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
    auto setReason(?string $reason = null) {
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
