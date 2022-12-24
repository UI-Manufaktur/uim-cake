

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Controller\Exception;

use Cake\Http\Exception\BadRequestException;

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
    function getType(): string
    {
        return _type;
    }

    /**
     * Set Message
     *
     * @param string $message Exception message
     * @return void
     */
    function setMessage(string $message): void
    {
        this.message = $message;
    }

    /**
     * Set Reason
     *
     * @param string|null $reason Reason details
     * @return this
     */
    function setReason(?string $reason = null)
    {
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
